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
         private static let CloudIAPProductInfo = "CloudIAPProductInfo"
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
            if !tokenProtocol.isEqual(self.prevToken) {
                serializeAsPreviousCloudToken(self.curToken)
                serializeAsCurrentCloudToken(token)
                //user loggeed in and could change...
            }
        } else if let prevToken = self.prevToken as? NSObjectProtocol {
            serializeAsPreviousCloudToken(self.curToken)
            serializeAsCurrentCloudToken(nil)
            
            //user is not logged in.
        }
    }
    
    /* Checks if the user has logged into her iCloud account or not */
    private class func jacIsICloudAvailable() -> (AnyObject?,Bool) {
        if let token = NSFileManager.defaultManager().ubiquityIdentityToken{
            return (token,true)
        } else {
            return (nil,false)
        }
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
    
    //MARK: IAPProductInfo
    
    private func addIAPProductInfo(product:IAPProduct,completionHandler: ((CKRecord!,NSError!) -> Void)!) {
        
        let noteRecord = CKRecord(recordType: Contants.CloudIAPProductInfo)
        noteRecord.setValue(product.productInfo!.consumable ? 1 :0, forKey: "consumable")
        noteRecord.setValue(product.productInfo!.consumableAmount, forKey: "consumableAmount")
        noteRecord.setValue(product.productIdentifier, forKey: "productID")
        
        
        self.privateDB.saveRecord(noteRecord, completionHandler: completionHandler)
    }

    //MARK: IAPProductInfo Public
    internal func getIAPProductInfo(productId:String!,completion:((CKRecord!,NSError!) -> Void)!) {
        
       let query = CKQuery(recordType: Contants.CloudIAPProductInfo, predicate: NSPredicate(format: "productID = %@", productId))
        
        self.privateDB.performQuery(query, inZoneWithID: nil){
            [unowned self]
            array,error in
            
            if error != nil {
                println("Error \(error)")
                completion(nil,error)
            }
            else {
                
                if let lastItem = array.last as? CKRecord  {
                    completion(lastItem, nil)
                }
                else {
                    completion(nil,nil)
                }
            }
        }
    }
    
    internal func createAIPProductInfoOnNeed(product:IAPProduct,completionHandler: ((CKRecord!,NSError!) -> Void)!) {
    
        self.getIAPProductInfo(product.productIdentifier) {
            [unowned self]
            record,error  in
            
            if record != nil {
                completionHandler(record,nil)
            }
            else  if error != nil{
                completionHandler(nil,error)
            }
            else {
                self.addIAPProductInfo(product, completionHandler: completionHandler)
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
