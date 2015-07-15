//
//  CloudManager.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 6/25/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit
import CloudKit

let SYLoggingToCloudNotification = "SYLoggingToCloudNotification"

class CloudManager: NSObject {
   
    private static let singleton = CloudManager()
    
    private  struct Contants {
         private static let SurvivalCurrentGame = "SurvivalCurrentGame"
    }
    
    private let container:CKContainer!
    private let privateDB:CKDatabase!
    private let userInfo:CloudUserInfo!
    private var userLoggedIn:Bool = false
    private var recID: CKRecordID? = nil
    
    override init() {
        let container = CKContainer.defaultContainer()
        self.container = container
        self.privateDB = container.privateCloudDatabase
        self.userInfo = CloudUserInfo(container: container)
        super.init()
        cloudChanged(nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "cloudChanged:", name: NSUbiquityIdentityDidChangeNotification, object: nil)
        self.userInfo.getUserId(){
            recordID,error in
        }
    }
    
    internal var recordID:CKRecordID? {
        get { return recID != nil ? recID : self.userInfo.userRecordID }
    }
    
    class var sharedInstance: CloudManager {
        return CloudManager.singleton
    }
    
    //MARK:Tokens part of methods...
    
    private var prevTokenInternal:AnyObject?
    
    private var prevToken:AnyObject? {
        get {
            if (prevTokenInternal == nil) {
                prevTokenInternal = self.deserializePreviousCloudToken()
            }
            
            return prevTokenInternal
        }
    }
    
    private var curTokenInternal:AnyObject?
    
    private var curToken:AnyObject? {
        
        get {
            if (curTokenInternal == nil) {
                curTokenInternal = self.deserializeCurrentCloudToken()
            }
            return curTokenInternal
        }
    }
    
    //MARK: Other methods
    func cloudChanged(aNotification:NSNotification!) {
        let (token: AnyObject?,isPresent) = CloudManager.jacIsICloudAvailable()
        self.userLoggedIn = isPresent
        //TODO: transfer ownership to or from CloudKit to User Defaults...
        if let tokenProtocol  = token as? NSObjectProtocol {
            if !tokenProtocol.isEqual(self.curToken) {
                serializeAsPreviousCloudToken(self.curToken)
                serializeAsCurrentCloudToken(token)
                //TODO: transfer ownership to new user, or refresh purchases....
            }
        } else if let curToken = self.curToken as? NSObjectProtocol {
            serializeAsPreviousCloudToken(self.curToken)
            serializeAsCurrentCloudToken(nil)
            //user is not logged in.
            //TODO: transfer purhases of the previous user....
        } else {
            serializeAsCurrentCloudToken(nil)
        }
    }
    
    /* Checks if the user has logged into her iCloud account or not */
    private class func jacIsICloudAvailable() -> (AnyObject?,Bool) {
        let tokenObj = NSFileManager.defaultManager().ubiquityIdentityToken
        
        return (tokenObj,tokenObj != nil)
    }
    
    private func alertAboutPermissionGrant(accountStatus:CKAccountStatus = .NoAccount) {
        self.recID = nil
        
        if (accountStatus == .NoAccount) {
            NSNotificationCenter.defaultCenter().postNotificationName(SYLoggingToCloudNotification, object: self)
        }
        
    }
    
    internal func simulateAlertAboutPermissionGrant() -> Bool {
        
        if !self.userLoggedIn || self.curToken == nil {
            return true
        } else {
            return false
        }
    }
    
    internal func userLoggedIn(completion:(Bool -> Void)!) {
        
        if (self.userLoggedIn) {
            
            self.userInfo.loggedInToICloud { (accountStatus, error) -> () in
                completion(accountStatus == .Available)
            }
        }
        else {
            completion(false)
        }
    }
    
    internal func prepare() {
        
        if (self.userLoggedIn) {
            self.userInfo.loggedInToICloud { (accountStatus, error) -> () in
                if accountStatus == .Available {
                    self.userInfo.getUserInfo() {
                        [unowned self]
                        disUserInfo,error in
                        
                        if error == nil {
                            self.recID = disUserInfo.userRecordID
                        }
                        else {
                            self.alertAboutPermissionGrant()
                        }
                    }
                }
                else {
                    self.alertAboutPermissionGrant(accountStatus: accountStatus)
                }
            }
        }
        else {
            self.alertAboutPermissionGrant()
        }
    }
    
     //MARK: Survival Current Game Record
    
    private func addSurvivalCurrentGameRecord(product:IAPProduct,score:Int64,numberOfLives:Int,playedTime:NSTimeInterval,ratio:Float,completionHandler: ((CKRecord!,NSError!) -> Void)!) {
        
        let noteRecordID = CKRecordID(recordName: product.productIdentifier)
        let noteRecord = CKRecord(recordType: Contants.SurvivalCurrentGame,recordID:noteRecordID)
        
        updateSurvivalCurrentGameRecord(noteRecord, score: score, numberOfLives: numberOfLives, playedTime: playedTime, ratio: ratio, completionHandler: completionHandler)
    }
    
    private func getSurvivalCurrentGameRecord(productId:String!,completion:((CKRecord?,NSError!) -> Void)!) {
        
        let noteRecordID = CKRecordID(recordName: productId)
        self.container.privateCloudDatabase.fetchRecordWithID(noteRecordID){
                [unowned self]
                record,error in
                
                if (error != nil ) {
                    
                    println("Error \(error)")
                    
                    
                    if  CKErrorCode(rawValue: error.code) == CKErrorCode.UnknownItem  && error.domain == CKErrorDomain {
                        completion(nil,nil)
                    }
                    else {
                        completion(nil,error)
                    }
                }
                else {
                    completion(record, nil)
                }
        }
    }
    
    internal func getSurvivalCurrentGameLastRecord(completion:((CKRecord?,NSError!) -> Void)!) {
        
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: Contants.SurvivalCurrentGame, predicate: predicate)
        self.privateDB.performQuery(query, inZoneWithID: nil) { results, error in
            //println("\(error.code == CKErrorCode.InvalidArguments.rawValue) -   InvalidArguments")
            if (error == nil) {
                
                if let lastRecord = results.last as? CKRecord {
                    completion(lastRecord,nil)
                }
            }
            else {
                
                if  CKErrorCode(rawValue: error.code) == CKErrorCode.UnknownItem  && error.domain == CKErrorDomain {
                    completion(nil,nil)
                }
                else {
                    completion(nil,error)
                }
            }
        }
    }
    
    private func updateSurvivalCurrentGameRecord(noteRecord:CKRecord!,score:Int64,numberOfLives:Int,playedTime:NSTimeInterval,ratio:Float,completionHandler: ((CKRecord!,NSError!) -> Void)!) {
        
        noteRecord.setSurvivalCurrentGameScore(score)
        noteRecord.setSurvivalCurrentGameNumberOfLives(numberOfLives)
        noteRecord.setValue(NSNumber(double: playedTime), forKey: "playedTime")
        noteRecord.setValue(NSNumber(float:ratio), forKey: "ratio")
        
        self.privateDB.saveRecord(noteRecord, completionHandler: completionHandler)
    }
    
   
    internal func updateSurvivalCurrentGameLastRecord(score:Int64,numberOfLives:Int,playedTime:NSTimeInterval,ratio:Float,completionHandler: ((CKRecord!,NSError!) -> Void)!) {
        
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: Contants.SurvivalCurrentGame, predicate: predicate)
        self.privateDB.performQuery(query, inZoneWithID: nil) { results, error in
            
            if (error == nil) {
                
                if let lastRecord = results.last as? CKRecord {
                    
                    if (numberOfLives == 0 && ratio == 0) {
                        let curRecID = lastRecord.recordID
                        self.privateDB.deleteRecordWithID(curRecID) {
                            item,error in
                            completionHandler(nil,error)
                        }
                    }
                    else {
                        self.updateSurvivalCurrentGameRecord(lastRecord, score: score, numberOfLives: numberOfLives, playedTime: playedTime, ratio: ratio, completionHandler: completionHandler)
                    }
                }
            }
            else {
                completionHandler(nil,error)
            }
        }
    }
    
    internal func createSurvivalCurrentGameRecord(product:IAPProduct,score:Int64,numberOfLives:Int,playedTime:NSTimeInterval,ratio:Float,completionHandler: ((CKRecord!,NSError!) -> Void)!) {
    
        self.getSurvivalCurrentGameRecord(product.productIdentifier) {
            [unowned self]
            record,error  in
            
            if record != nil {
                self.updateSurvivalCurrentGameRecord(record, score: score, numberOfLives: numberOfLives, playedTime: playedTime, ratio: ratio, completionHandler: completionHandler)
            }
            else  if error != nil{
                completionHandler(nil,error)
            }
            else {
                self.addSurvivalCurrentGameRecord(product,score:score,numberOfLives:numberOfLives,playedTime:playedTime,ratio: ratio == 0  ? 1 : ratio, completionHandler: completionHandler)
            }
        }
    }
    
}

extension CKRecord {
    
    var survivalCurrentGameScore:Int64 {
        get {
            if let number =  self.objectForKey("score") as? NSNumber {
                return number.longLongValue
            }
            else {
                return 0
            }
        }
    }
    
    func setSurvivalCurrentGameScore(score:Int64) {
        setValue(NSNumber(longLong: score) , forKey: "score")
    }
    
    var survivalCurrentGameNumberOfLives:Int {
        get {
            if let number =  self.objectForKey("numberOfLives") as? NSNumber {
                return number.longValue
            }
            else {
                return 0
            }
        }
    }
    
    func setSurvivalCurrentGameNumberOfLives(lives:Int) {
        setValue(NSNumber(long: lives) , forKey: "numberOfLives")
    }
    
    var survivalPlayedTime:NSTimeInterval {
        get {
            if let playedTimeObj = objectForKey("playedTime") as? NSNumber {
                return playedTimeObj.doubleValue
            }
            else {
                return 0
            }
        }
    }
    
    var survivalRatio:Float {
        get {
            if let ratio = objectForKey("ratio") as? NSNumber {
                return ratio.floatValue
            }
            else {
                return 0
            }
        }
    }
}

extension CloudManager {
    
    private struct TokenConstants {
        private static let previousToken = "previousToken.txt"
        private static let currentToken = "currentToken.txt"
    }
    
    
    
    //MARK: class methods
    private class func serializeCloudToken(token:AnyObject?, name tokenName:String?) -> Bool {
        
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        
        var fileName:String? = nil
        
        if let docDir = paths.last as? String {
            
            if let rToken = tokenName {
                fileName = docDir.stringByAppendingPathComponent(rToken)
            }
        }
        
        
        if let tokenObj = token as? NSObject {
            
            if let fileName = fileName {
                return NSKeyedArchiver.archiveRootObject(tokenObj, toFile: fileName)
            }
        }
        else {
            
              if let fileName = fileName {
                    var error:NSError? = nil
                    return NSFileManager.defaultManager().removeItemAtPath(fileName, error: &error)
                }
        }
        
        return false
    }
    
    private class func desirializeCloudToken(tokenName:String?) -> AnyObject? {
        
        if let rToken = tokenName {
            
            let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
            
            
            if let docDir = paths.last as? String {
                
                let fileName = docDir.stringByAppendingPathComponent(rToken)
                
                return NSKeyedUnarchiver.unarchiveObjectWithFile(fileName)
            }
            
        }
        
        return nil
    }
    
    //MARK: Previous Cloud Token
    private func deserializePreviousCloudToken() -> AnyObject? {
        let res: AnyObject? = CloudManager.desirializeCloudToken(TokenConstants.previousToken)
        self.prevTokenInternal = res
        return res
    }
    
    private func serializeAsPreviousCloudToken(token:AnyObject?) -> Bool {
        let res = CloudManager.serializeCloudToken(token, name: TokenConstants.previousToken)
        
        if (res){
            self.prevTokenInternal = token
        }
        else {
            self.prevTokenInternal = nil
        }
        return res
    }

    //MARK: Current Cloud Token
    private func deserializeCurrentCloudToken() -> AnyObject? {
        let res: AnyObject? =  CloudManager.desirializeCloudToken(TokenConstants.currentToken)
        self.curTokenInternal = res
        return res
    }
    
    private func serializeAsCurrentCloudToken(token:AnyObject?) -> Bool {
        let res = CloudManager.serializeCloudToken(token, name: TokenConstants.currentToken)
        
        if (res){
            self.curTokenInternal = token
        }
        else {
            self.curTokenInternal = nil
        }
        return res
    }
}

extension CloudManager {
    
    private struct GameConstants {
        static let TimeRecord = "Time"
        static let TimeRecordTimeKey = "Time"
        static let ScoreRecord = "Score"
        static let ScoreRecordScoreKey = "Score"
        static let SurvivalRecord = "SurvivalRecord"
        static let ScoreKey = "Score"
        static let TimeKey = "Time"
    }
    
    // Save survival values
    func submitSurvivalValues(items:[[String:AnyObject]], completionHandler:(([Int:NSTimeInterval]) -> Void)!) {
        
        let values = items
        let db = self.container.privateCloudDatabase
        var result = [Int:NSTimeInterval]()
        var count = values.count
        
        
        
        for index in 0...count - 1 {
            
            let record = CKRecord(recordType: GameConstants.SurvivalRecord)
            let curItem = values[index]
            let playedTime = curItem["time"] as! NSTimeInterval
            let score = (curItem["score"] as! NSNumber)
            
            record.setValue(score, forKey: GameConstants.ScoreKey)
            record.setValue(playedTime, forKey: GameConstants.TimeKey)
            
            db.saveRecord(record) {
                savedRecord,error in
                
                if (error != nil) {
                    var pauseVal:NSTimeInterval = 0
                    println("Error for index \(index). Error : \(error)")
                    
                    if error.code == CKErrorCode.RequestRateLimited.rawValue ||
                        error.code == CKErrorCode.ServiceUnavailable.rawValue {
                            
                            let retryAfter = error.userInfo![CKErrorRetryAfterKey] as! NSNumber
                            pauseVal = retryAfter.doubleValue
                    }
                    
                    objc_sync_enter(result)
                    
                    result[index] = pauseVal
                    count--
                    objc_sync_exit(result)
                }
                else {
                    
                    objc_sync_enter(result)
                    count--
                    objc_sync_exit(result)
                }
                
                if count == 0 {
                    completionHandler(result)
                }
            }
        }
    }
}
