//
//  GameLogicController.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 5/12/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit
import GameKit

enum GameLogicSelectedStrategy : Int {
    case None = 0, Survival = 1, Company = 2, Help = 3
}

enum AuthCase : Int {
    case None = 0, iCloud = 1, GameCenter = 2
}

let SYGameLogicManagerSoundNotification = "SYGameLogicManagerSoundNotification"

class GameLogicManager: NSObject {
    
    private static let sNoAdProductId = "sy.gamefun.jackACrasher.NoAds"
    private static let sNumberOfLives = "sy.gamefun.jackACrasher.ExtraLife"
    private static let sCurrentUserNameKey = "currentUser.sy.gamefun.jackACrasher"
    
    private var state:GameLogicSelectedStrategy = .None
    private var scoreValue:Float = 0
    private static var gSharedController:GameLogicManager!
    
    internal var survivalTotalScore:UInt64 = 0
    internal var survivalBestScore:Int64 = 0
    
    private let centerManager:GameCenterManager! = GameCenterManager.sharedInstance
    private let cloudManager:CloudManager! = CloudManager.sharedInstance
    private let odrManager:ODRManager! = ODRManager.sharedManager
    
    dynamic internal var isLoading:Bool = false
    
    internal func resetState() {
        self.state = .None
    }
    
    override init() {
        super.init()
        
        cloudChangedAuth()
        //gameCenterChangedAuth()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "cloudChangedAuth", name: SYiCloudAuthStatusChangeNotification, object: self.cloudManager)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "gameCenterChangedAuth", name: GameCenterManagerDidChangeAuth, object: self.centerManager)
    
        initODR()
        
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: SYiCloudAuthStatusChangeNotification, object: self.cloudManager)
        
          NSNotificationCenter.defaultCenter().removeObserver(self, name: GameCenterManagerDidChangeAuth, object: self.centerManager)
       deinitODR()
    }
    
    internal static var sharedInstance:GameLogicManager
        {
        get {
            if (GameLogicManager.gSharedController == nil) {
                var sharedPredicate:dispatch_once_t = 0
                dispatch_once(&sharedPredicate, { () -> Void in
                    GameLogicManager.gSharedController = GameLogicManager()
                })
            }
            return GameLogicManager.gSharedController
        }
    }
    
    
    //MARK: Survival
    internal func selectSurvival() {
        self.state = .Survival
        
        if (self.scoresSet) {
            self.isLoading = false
            return
        }
        
        self.isLoading = true
        
        self.getBestSurvivalScoreWithCompletionHandler { (bestScore, error) -> Void in
            if (error != nil) {
                self.isLoading = false
                print("Error \(error)")
                return
            }
            else {
                self.getTotalSurvivalScoreWithCompletionHandler({ (totalScore, error) -> Void in
                    if (error != nil) {
                        print("Error \(error)")
                        return
                    }
                    
                    self.survivalTotalScore  = totalScore
                    self.survivalBestScore  = bestScore
                    self.isLoading = false
                    
                })
            }
            
        }
        
    }
    
    private var scoresSet:Bool {
        get {
            return !isLoading && (self.survivalBestScore > 0 || self.survivalTotalScore > 0)
        }
    }
    
    //MARK: Public methods
    internal var isSurvival:Bool {
        get {
            return self.state == .Survival
        }
    }
    
    internal func getTotalSurvivalScoreWithCompletionHandler(completionHandler: ((UInt64, NSError?) -> Void)!)
    {
        
        let total = self.getFromDefaultsTotalSurvivalScore()
        
        if  (total != 0){
            completionHandler(total,nil)
            return
        }
        
        self.centerManager.getSurvivalScoresWithCompletionHandler({ (scores, error) -> Void in
            print("GK :  Score : \(scores)")
            if (error != nil) {
                completionHandler(UInt64.min,error)
                return
            }
            
            let totalScore = scores[0] as UInt64
            let bestScore = Int64(scores[1] as UInt64)
            
            self.storeInDefaultsSurvivalBestScore(bestScore,synch: false)
            self.storeInDefaultsSurvivalTotalScore(totalScore)
            
            completionHandler(totalScore,nil)
            
        })
    }
    
    internal func getBestTimeScoreWithCompletionHandler(completionHandler: ((Int64, NSError?) -> Void)!)
    {
        
        let bestTime = self.getFromDefaultsLongestGameTimeSurvivalScore()
        
        if  (bestTime != 0){
            completionHandler(bestTime,nil)
            return
        }
        self.centerManager.getSurvivalBestTimeScoreWithCompletionHandler({ (time, error) -> Void in
            print("GK : Best time : \(time)")
            if (error != nil) {
                completionHandler(0,error)
                return
            }
            
            self.storeInDefaultsLongesTimeScore(time)
            completionHandler(time,error)
        })
        
    }
    
    internal func getBestSurvivalScoreWithCompletionHandler(completionHandler: ((Int64, NSError?) -> Void)!)
    {
        
        let best = self.getFromDefaultsBestSurvivalScore()
        
        if  (best != 0){
            completionHandler(best,nil)
            return
        }
        self.centerManager.getSurvivalScoresWithCompletionHandler({ (scores, error) -> Void in
            print("GK : Scores : \(scores)")
            if (error != nil) {
                completionHandler(0,error)
                return
            }
            
            let totalScore = scores[0] as UInt64
            let bestScore = Int64(scores[1] as UInt64)
            
            self.storeInDefaultsSurvivalBestScore(bestScore,synch: false)
            self.storeInDefaultsSurvivalTotalScore(totalScore)
            
            completionHandler(bestScore,error)
        })
    }
    
    internal func storeSurvivalScores(info:[UInt64], completionHandler:((Bool ,NSError?)->Void)!) {
        
        let bestScore = Int64(info[0])
        let totalScore = info[1]
        let bestTime = NSTimeInterval(info.last!)
        
        let res = storeInDefaultsSurvivalBestScore(bestScore, synch:false) || storeInDefaultsSurvivalTotalScore(totalScore, synch:false) || storeInDefaultsLongesTimeScore(Int64(bestTime))
        
        self.centerManager.reportSurvivalBestScore(bestScore)
        self.centerManager.reportSurvivalGameTime(bestTime)
        
        completionHandler(res,self.centerManager.lastError)
    }
    
}

//MARK: Score's extension
extension GameLogicManager
{
    private struct Constants {
        static var  SurvivalLongestGame = "SurvivalLongestGameScore"
        static var  SurvivalBestScore = "SurvivalBestScore"
        static var  SurvivalScores = "SurvivalScores"
        static var  SurvivalTotalScore = "SurvivalTotalScore"
        static var  AppState = "AppState"
        static var  SurvivalCurrentGameInfoAdditionKey = "SurvivalCurrentGameInfoAdditionKey"
    }
    
    //MARK: Survival
    private func storeInDefaultsSurvivalTotalScore(score:UInt64,synch:Bool = true) -> Bool {
        return storeInDefaultsScoreForExtraKeyParam(Constants.SurvivalTotalScore, score: score, synch: synch)
    }
    
    private func storeInDefaultsSurvivalBestScore(score:Int64,synch:Bool = true) -> Bool {
        
        return storeInDefaultsScoreForExtraKeyParam(Constants.SurvivalBestScore, score: UInt64(score), synch: synch)
    }
    
    private func storeInDefaultsLongesTimeScore(score:Int64,synch:Bool = true) -> Bool {
        
        return storeInDefaultsScoreForExtraKeyParam(Constants.SurvivalLongestGame, score: UInt64(score), synch: synch)
    }
    
    private func storeInDefaultsScoreForExtraKeyParam(keypart:String,score:UInt64,synch:Bool = true) -> Bool {
        
        let key = getPlayerId().stringByAppendingString(keypart)
        
        NSUserDefaults.standardUserDefaults().setDouble(Double( score), forKey: key)
        if (synch) {
            return NSUserDefaults.standardUserDefaults().synchronize()
        }
        return true
    }
    
    private func storeInDefaultsSurvivalInfo(info:[UInt64]) ->Bool {
        assert(info.count == 2, "not all items are presented!")
        let bestScore  = Int64(info[0])
        let totalScore = info[1]
        
        return storeInDefaultsSurvivalTotalScore(totalScore)
            && storeInDefaultsSurvivalBestScore(bestScore)
    }
    
    private func getFromDefautsSurvivalInfo() -> [UInt64] {
        
        let time = getFromDefaultsLongestGameTimeSurvivalScore()
        let best = getFromDefaultsBestSurvivalScore()
        let total = getFromDefaultsTotalSurvivalScore()
        
        return [total,UInt64(best),UInt64(time)]
    }
    
    private func getFromDefaultsLongestGameTimeSurvivalScore() -> Int64 {
        
        return Int64(getFromDefaultsScoreWithKeyPart(getPlayerId(), keyPart: Constants.SurvivalLongestGame))
    }
    
    private func getFromDefaultsBestSurvivalScore() -> Int64 {
        
        return Int64(getFromDefaultsScoreWithKeyPart(getPlayerId(), keyPart: Constants.SurvivalBestScore))
    }
    
    private func getFromDefaultsTotalSurvivalScore() -> UInt64 {
        
        return getFromDefaultsScoreWithKeyPart(getPlayerId(), keyPart: Constants.SurvivalTotalScore)
    }
    
    private func getFromDefaultsScoreWithKeyPart(mainKey:String, keyPart:String) -> UInt64 {
        
        let key = mainKey.stringByAppendingString(keyPart)
        
        let total = UInt64(NSUserDefaults.standardUserDefaults().doubleForKey(key))
        
        return total
    }
    
    //MARK: App Manager
    
    internal func performPurchasesRestorationOnNeed() -> Bool {
        
        let fTime = !NSUserDefaults.standardUserDefaults().boolForKey(Constants.AppState)
        
        if (fTime) {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "handlePurchasesNotification:", name: IAPPurchaseNotification, object: PurchaseManager.sharedInstance)
            PurchaseManager.sharedInstance.restore()
            return true
        }
        return false
    }
    
    private func loginToiCloud(mainVC:UIViewController) {
    
        mainVC.alertWithTitle("Enable iCloud".syLocalizedString, message: "Please login into iCloud via Settings".syLocalizedString, actionTitle: "OK".syLocalizedString){
            
            mainVC.view.userInteractionEnabled = true
        }
    }
    
    // Update the UI according to the purchase request notification result
    func handlePurchasesNotification(aNotification:NSNotification!)
    {
        let pManager = aNotification.object as! PurchaseManager
        
        switch (pManager.status)
        {
        case .IAPPurchaseFailed:
            break
            // Switch to the iOSPurchasesList view controller when receiving a successful restore notification
        case .IAPRestoredFailed:
            break
        case .IAPDownloadFailed:
            break
        case .IAPDownloadStarted:
            // Notify the user that downloading is about to start when receiving a download started notification
            //self.hasDownloadContent = YES;
            //[self.view addSubview:self.statusMessage];
            break
            // Display a status message showing the download progress
        case .IAPDownloadInProgress:
            
            //self.hasDownloadContent = YES;
            //NSString *title = [[StoreManager sharedInstance] titleMatchingProductIdentifier:purchasesNotification.purchasedID];
            //NSString *displayedTitle = (title.length > 0) ? title : purchasesNotification.purchasedID;
            //self.statusMessage.text = [NSString stringWithFormat:@" Downloading %@   %.2f%%",displayedTitle, purchasesNotification.downloadProgress];
            //}
            break
            // Downloading is done, remove the status message
        case .IAPPurchaseSucceeded:
            
            break
        case .IAPRestoredSucceeded:
            
            NSNotificationCenter.defaultCenter().removeObserver(PurchaseManager.sharedInstance, name: IAPPurchaseNotification, object: self)
            
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: Constants.AppState)
            NSUserDefaults.standardUserDefaults().synchronize()
            
            break
        case .IAPDownloadSucceeded:
            break
        case .IAPPurchaseCancelled:
            break
        default:
            break
        }
    }
    
    //MARK: Consumable & non - Consumable purchases....
    
    func purchasedProduct(product:IAPProduct) {
        
        if let productInfo = product.productInfo {
            
            if productInfo.consumable {
                if productInfo.productIdentifier == GameLogicManager.sNumberOfLives {
                    
                    var amount = max(self.numberOfLivesForSurvivalGameFromDefaults(),1)
                    amount += productInfo.consumableAmount
                    
                    if self.setNumberOfLivesInDefaultsForSurvivalGame(amount) {
                        //TODO: dispatch notification about new amount of lives to VC
                       
                        CloudManager.sharedInstance.userLoggedIn() {
                            loggedIn in
                            
                            if !loggedIn {
                                
                                dispatch_async(dispatch_get_main_queue()) {
                                    if let navVC = UIApplication.sharedApplication().delegate?.window??.rootViewController as? UINavigationController {
                                        if let mainVC = navVC.topViewController {
                                            if let preseneted = mainVC.presentedViewController as? ShopDetailsViewController {
                                                preseneted.prepareForDispose()
                                                preseneted.dismissViewControllerAnimated(true) {
                                                    
                                                    self.loginToiCloud(mainVC)
                                                }
                                            }
                                            else {
                                                self.loginToiCloud(mainVC)
                                            }
                                            
                                        }
                                    }
                                }
                                return
                            }
                            
                            var playedTime:NSTimeInterval = 0
                            var score:Int64 = 0
                            var ratio:Float = 0
                            
                            if let navVC = UIApplication.sharedApplication().delegate?.window??.rootViewController as? UINavigationController {
                                if let mainVC = navVC.topViewController as? GameViewController {
                                    if let gameScene = mainVC.skView.scene as? GameScene {
                                        playedTime = gameScene.playedTime
                                        score = gameScene.currentGameScore
                                        ratio = gameScene.healthRatio
                                        gameScene.updatePlayerLives(extraLives: self.numberOfLivesForSurvivalGameFromDefaults())
                                    }
                                }
                            }
                            
                            if (ratio == 0 && playedTime == 0) {
                                ratio = 1
                            }
                            
                            CloudManager.sharedInstance.createSurvivalCurrentGameRecord(product, score: score, numberOfLives: amount, playedTime: playedTime, ratio: ratio) {
                                record,error in
                                
                                print("Error \(error)")
                            }
                        }
                    }
                }
            }
        }
    }
    
}

extension GameLogicManager {
    //TODO: Sometimes cloud kit returns record name latter than needed, therefore once playerId == recName, then == playerID
    
    internal func getPlayerId() -> String! {
        
        if let recName = getCloundPlayerId() {
            return recName
        } else if self.centerManager.isLocalUserAuthentificated {
            if let playerID = getGameCenterPlayerId() {
                return playerID
            }
        }
        return getAnonymousPlayerId()
    }
    
    
    private func getCloundPlayerId() -> String? {
        return self.cloudManager.recordID?.recordName
    }

    private func getGameCenterPlayerId() -> String? {
        return GameCenterManager.sharedInstance.playerID
    }
    
    internal func getAnonymousPlayerId() -> String {
        return "guest"
    }
        
    private func submitSurvivalItems(items:[[String:AnyObject]],completionHandler:((isError:Bool,delayInTime:UInt64)->Void)!) {
        
        self.cloudManager.submitSurvivalValues(items){
            failedIndexesDic  in
            
            var maxDelayInterval:NSTimeInterval = 0
            var newItems = [[String:AnyObject]]()
            
            for failedIndex in failedIndexesDic {
                let index = failedIndex.0
                let delayInterval = failedIndex.1
                
                if maxDelayInterval > delayInterval {
                    maxDelayInterval = delayInterval
                }
                newItems.append(items[index])
            }
            
            let curPlayerId = self.getPlayerId()
            let newKey = curPlayerId.stringByAppendingString(Constants.SurvivalScores)
            
            if failedIndexesDic.isEmpty {
                NSUserDefaults.standardUserDefaults().removeObjectForKey(newKey)
                if (NSUserDefaults.standardUserDefaults().synchronize()) {
                    completionHandler(isError:false,delayInTime:0)
                }
            } else {
                
                NSUserDefaults.standardUserDefaults().setObject(newItems, forKey: newKey)
                if (NSUserDefaults.standardUserDefaults().synchronize()) {
                    let delayTime = dispatch_time(DISPATCH_TIME_NOW,
                        Int64(maxDelayInterval * Double(NSEC_PER_SEC)))
                    
                    completionHandler(isError: true, delayInTime: delayTime)
                }
            }
        }
    }
    
    internal class func appendSurvivalGameValuesToDefaults(keyPart:String,score:Int64,time:NSTimeInterval) -> Bool {
        
        let key = keyPart.stringByAppendingString(Constants.SurvivalScores)
        
        var array:[AnyObject]! = NSUserDefaults.standardUserDefaults().arrayForKey(key)
        
        if array == nil  {
            array = [AnyObject]()
        }
        
        array.append(["score":NSNumber(longLong: score),"time":time])
        
        
        NSUserDefaults.standardUserDefaults().setObject(array, forKey: key)
        return NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    internal func appendSurvivalGameValuesToDefaults(score:Int64,time:NSTimeInterval) -> Bool {
        
       return GameLogicManager.appendSurvivalGameValuesToDefaults(getPlayerId(), score: score, time: time)
    }
    
    internal func storeSurvivalGameValuesToDefaults(items:[[String:AnyObject]]) -> Bool {
        
        let key = getPlayerId().stringByAppendingString(Constants.SurvivalScores)
        
        
        NSUserDefaults.standardUserDefaults().setObject(items, forKey: key)
        return NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    internal class func getSurvivalGameValuesFromDefaults(keyPair:String) -> [[String:AnyObject]]? {
        
        let newKey = keyPair.stringByAppendingString(Constants.SurvivalScores)
        
        let items = NSUserDefaults.standardUserDefaults().arrayForKey(newKey) as? [[String:AnyObject]]
        
        return items
    }
    
    internal func submitSurvivalGameValues(completionHandler:((isError:Bool)->Void)!) {
        
        let items = GameLogicManager.getSurvivalGameValuesFromDefaults(getPlayerId())
        
        if let items = items {
            
            self.submitSurvivalItems(items) {
                isError,delayInTime in
                
                if isError {
                    
                    dispatch_after(delayInTime, dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
                        [unowned self] in
                        
                        let newKey2 = self.getPlayerId().stringByAppendingString(Constants.SurvivalScores)
                        if let items2 = NSUserDefaults.standardUserDefaults().arrayForKey(newKey2) as? [[String:AnyObject]] {
                            
                            self.submitSurvivalItems(items2) {
                                isError, delayInTime   in
                                
                                completionHandler(isError: isError)
                            }
                        }
                    }
                }
                else {
                   completionHandler(isError: false)
                }
                
            }
        }
        else {
            completionHandler(isError: false)
        }
    }
    
    internal func reSchedulePlayedGamesInfoBasedOnId(completionHandler:((isError:Bool)->Void)!) -> Bool {
        
        let storedPlayerId = storedUserId()
        let curPlayerId = getPlayerId()
        
        if storedPlayerId != curPlayerId {
            
            if convertStoredValues(oldUserId: storedPlayerId, currentUserId: curPlayerId) {
                
                self.submitSurvivalGameValues(completionHandler)
                
                return true
            }
        }
        return false
    }
    
    internal func storedUserId() -> String! {
        return NSUserDefaults.standardUserDefaults().stringForKey(GameLogicManager.sCurrentUserNameKey)
    }
    
    internal func saveUserId(userId:String!) -> Bool {
        
        NSUserDefaults.standardUserDefaults().setObject(userId, forKey: GameLogicManager.sCurrentUserNameKey)
        
        return NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    internal func convertStoredValues(oldUserId prevUserId:String!, currentUserId userId:String!) -> Bool {
        
        let oldKey = prevUserId.stringByAppendingString(Constants.SurvivalScores)
        
        if let itemsArray = NSUserDefaults.standardUserDefaults().arrayForKey(oldKey) {
            
            let newKey = userId.stringByAppendingString(Constants.SurvivalScores)
            NSUserDefaults.standardUserDefaults().setObject(itemsArray, forKey: newKey)
            return saveUserId(userId)
        }
        return true
    }
    
    internal func hasStoredPurchaseOfNonConsumableWithIDInDefaults(productId:String) -> Bool {
        let key = getPlayerId().stringByAppendingString(productId)
        return NSUserDefaults.standardUserDefaults().boolForKey(key)
    }
    
    internal func storePurchaseInDefaultsForNonConsumableWithID(productId:String) -> Bool {
        let key = getPlayerId().stringByAppendingString(productId)
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: key)
        
        if productId == GameLogicManager.sNoAdProductId {
            return disableAdv() && disableAdvForAnonymousUser()
        }
        
        return NSUserDefaults.standardUserDefaults().synchronize()
    }
}

//MARK: Current Survival Game Logic 

extension GameLogicManager {
    
    private struct ConstantsSurvivalGameLogic {
        
        static let scoreKey = "score"
        static let playedTimeKey = "playedTime"
        static let ratioKey = "ratio"
        static let liveKey = "live"
    }
    
    internal func setNumberOfLivesInDefaultsForSurvivalGame(lives:SurvivalGameInfo.survivalNumberOfLives) -> Bool {
        
        var gameInfo = getCurrentSurvivalGameInfoFromDefaults()
        
        if gameInfo == nil {
            gameInfo = SurvivalGameInfo()
        }
        
        gameInfo!.numberOfLives = lives
        
        return storeCurrentSurvivalGameInfoInDefaults(gameInfo!)
    }
    
    internal func numberOfLivesForSurvivalGameFromDefaults() -> SurvivalGameInfo.survivalNumberOfLives {
        
        if let info = getCurrentSurvivalGameInfoFromDefaults() {
            return info.numberOfLives
        }
        return 0
    }
    
    internal func storeCurrentSurvivalGameInfoInDefaults(info:SurvivalGameInfo!) -> Bool {
        
        return GameLogicManager.storeCurrentSurvivalGameInfoInDefaultsWithKey(getPlayerId(), info: info)
    }
    
    private class func storeCurrentSurvivalGameInfoInDefaultsWithKey(keyPart:String, info:SurvivalGameInfo!) -> Bool {
        
        var resultDic = [String:AnyObject]()
        
        resultDic[ConstantsSurvivalGameLogic.scoreKey] = NSNumber(longLong: info.currentScore)
        resultDic[ConstantsSurvivalGameLogic.playedTimeKey] = NSNumber(double: info.playedTime)
        resultDic[ConstantsSurvivalGameLogic.ratioKey] = NSNumber(float: info.ratio)
        resultDic[ConstantsSurvivalGameLogic.liveKey] = info.numberOfLives
        
        let key = keyPart.stringByAppendingString(Constants.SurvivalCurrentGameInfoAdditionKey)
        NSUserDefaults.standardUserDefaults().setObject(resultDic, forKey: key)
        
        return NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    internal func updateCurrentSurvivalGameInfo(info:SurvivalGameInfo!,completion:((Bool)->Void)!) {
        
        if storeCurrentSurvivalGameInfoInDefaults(info) {
            
            CloudManager.sharedInstance.userLoggedIn() {
                loggedIn in
                
                if loggedIn {
                    
                    CloudManager.sharedInstance.updateSurvivalCurrentGameLastRecord(info.currentScore, numberOfLives: info.numberOfLives, playedTime: info.playedTime, ratio: info.ratio) {
                        record,error in
                        
                        if (error == nil && record != nil) {
                            completion(true)
                        }
                        else  {
                            completion(false)
                        }
                    }
                }
                else {
                    completion(false)
                }
            }
        }
    }
    
    internal func getCurrentSurvivalGameInfoFromDefaults() -> SurvivalGameInfo?{
        
        return GameLogicManager.getCurrentSurvivalGameInfoFromDefaultsWithPlayerId(getPlayerId())
    }
    
    private class func removeCurrentSurvivalGameInfoFromDefaultsWithPlayerId(playerId:String) -> Bool {
        
        let key = playerId.stringByAppendingString(Constants.SurvivalCurrentGameInfoAdditionKey)
        
        NSUserDefaults.standardUserDefaults().removeObjectForKey(key)
        
        return NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    private class func getCurrentSurvivalGameInfoFromDefaultsWithPlayerId(playerId:String) -> SurvivalGameInfo? {
        
        let key = playerId.stringByAppendingString(Constants.SurvivalCurrentGameInfoAdditionKey)
        
        if let resultDic = NSUserDefaults.standardUserDefaults().objectForKey(key) as? [String:AnyObject] {
            
            let gameInfo = SurvivalGameInfo()
            var foundOne = false
            
            if let number = resultDic[ConstantsSurvivalGameLogic.scoreKey] as? NSNumber {
                gameInfo.currentScore = number.longLongValue
                foundOne = true
            }else {
                gameInfo.currentScore = 0
            }
            
            if let number = resultDic[ConstantsSurvivalGameLogic.playedTimeKey] as? NSNumber {
                gameInfo.playedTime = number.doubleValue
                foundOne = true
            }else {
                gameInfo.playedTime = 0
            }
            
            if let number = resultDic[ConstantsSurvivalGameLogic.ratioKey] as? NSNumber {
                gameInfo.ratio = number.floatValue
                foundOne = true
            }else {
                gameInfo.ratio = 0
            }
            
            if let number = resultDic[ConstantsSurvivalGameLogic.liveKey] as? NSNumber {
                gameInfo.numberOfLives = number.integerValue
                foundOne = true
            }else {
                gameInfo.numberOfLives = 0
            }
            
            if foundOne { return gameInfo }
        }
        return nil
    }
    
    internal func accessSurvivalGameScores(completion:((SurvivalGameInfo?)->Void)!) {
        
        if let gameInfo = getCurrentSurvivalGameInfoFromDefaults() {
            
            if gameInfo.isExpired {
                completion(nil)
            }
            else {
                completion(gameInfo)
            }
            return
        }
        
            CloudManager.sharedInstance.getSurvivalCurrentGameLastRecord{
                [unowned self]
                record, error in
                
                if let record = record {
                    
                    let lives = record.survivalCurrentGameNumberOfLives
                    let score = record.survivalCurrentGameScore
                    let ratio = record.survivalRatio
                    let playedTime = record.survivalPlayedTime
                    
                    let info = SurvivalGameInfo()
                    info.numberOfLives = lives
                    info.playedTime = playedTime
                    info.ratio = ratio
                    info.currentScore = score
                    self.storeCurrentSurvivalGameInfoInDefaults(info)
                    
                    if info.isExpired {
                        completion(nil)
                    }
                    else {
                        completion(info)
                    }
                }
                else {
                    print("accessSurvivalGameScores. Error \(error)")
                    completion(nil)
                }
            }
    }
}

//MARK:Music sound
extension GameLogicManager {
    
    private struct SoundConstants {
        static let sNoSoundAdditionKey = "sNoSoundAdditionKey"
    }
    
    internal func storeGameSoundInfo(noSound:Bool) -> Bool {
        let def = NSUserDefaults.standardUserDefaults()
        let key = currentSoundKey
        def.setBool(noSound, forKey: key)
        return def.synchronize()
    }
    
    internal func gameSoundDisabled() -> Bool {
        return GameLogicManager.gameSoundDisabledForKey(self.getAnonymousPlayerId())
    }
    
    internal class func gameSoundDisabledForKey(keyPart:String) -> Bool {
        let def = NSUserDefaults.standardUserDefaults()
        let key = keyPart.stringByAppendingString(SoundConstants.sNoSoundAdditionKey)
        
        return def.boolForKey(key)
    }
    
    //HACK: No sound is stored for all peopler....
    internal var currentSoundKey:String {
        get {
            return /*getPlayerId()*/self.getAnonymousPlayerId().stringByAppendingString(SoundConstants.sNoSoundAdditionKey)
        }
    }
}

// MARK: Adv Logic 

extension GameLogicManager {
    
    var isAdvDisabled:Bool {
        get {
           return isAdvDisabledForKey(getPlayerId())
        }
    }
    
    func isAdvDisabledForKey(keyPart:String) -> Bool {
        
        let key = keyPart.stringByAppendingString(GameLogicManager.sNoAdProductId)
        
        return NSUserDefaults.standardUserDefaults().boolForKey(key)
    }
    
    func disableAdv() -> Bool {
        return setAdvState(getPlayerId(),disabled:true)
    }
    
    func disableAdvForAnonymousUser() -> Bool {
       return setAdvState(getAnonymousPlayerId(),disabled:true)
    }
    
    
    func enableAdv() -> Bool {
        return setAdvState(getPlayerId(),disabled:false)
    }
    
    private func setAdvState(keyPart:String, disabled:Bool) -> Bool {
        let userDef = NSUserDefaults.standardUserDefaults()
        let key = keyPart.stringByAppendingString(GameLogicManager.sNoAdProductId)
        
        if (!disabled) {
            //enabled... 
            if isAdvDisabled {
                userDef.removeObjectForKey(key)
            }
        }
        else {
            userDef.setBool(true, forKey: key)
        }
        return userDef.synchronize()
    }
}

//MARK: Auth Logic & it's change for Purchases...

extension GameLogicManager {
    
    private static let sCurrentAuthCaseKey = "sy.gamefun.jackACrasher.authCase"
    
    
    func storeAuthCase(authCase : AuthCase) -> Bool {
        
        NSUserDefaults.standardUserDefaults().setInteger(authCase.rawValue, forKey: GameLogicManager.sCurrentAuthCaseKey)
        
        return NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    func getAuthCase() -> AuthCase {
        let retInt = NSUserDefaults.standardUserDefaults().integerForKey(GameLogicManager.sCurrentAuthCaseKey)
        
        return AuthCase(rawValue: retInt)!
    }

    
    func transferOwnerShipOnNeed(authCase:AuthCase) -> Bool  {
        
        let oldAuthCase = getAuthCase()
        
        if (authCase == oldAuthCase) {
            return true
        }
        
        var oldAuthId : String? = nil
        
        switch oldAuthCase {
            case .GameCenter:
                
                oldAuthId = getGameCenterPlayerId()
            
                break
            case .iCloud:
                oldAuthId = getCloundPlayerId()
                break
            default :
                oldAuthId = getAnonymousPlayerId()
                break
        }
        
        
        if let oldAuthId = oldAuthId {
            
            //current survival info score...
            if let info = GameLogicManager.getCurrentSurvivalGameInfoFromDefaultsWithPlayerId(oldAuthId) {
                
                if info.isExpired {
                    GameLogicManager.removeCurrentSurvivalGameInfoFromDefaultsWithPlayerId(oldAuthId)
                }
                else {
                    storeCurrentSurvivalGameInfoInDefaults(info)
                }
            }
            
            //no sound settings....
            let noSound = GameLogicManager.gameSoundDisabledForKey(oldAuthId)
            
            storeGameSoundInfo(noSound)
            
            // transfer score & played time....
            if let items = GameLogicManager.getSurvivalGameValuesFromDefaults(oldAuthId) {
                self.storeSurvivalGameValuesToDefaults(items)
            }
            
            return true
            
        }
        
        
        return storeAuthCase(authCase)
    }
    
    func cloudChangedAuth() {
        
        self.cloudManager.userLoggedIn() {
            loggedIn in
            
            if (loggedIn) {
                self.transferOwnerShipOnNeed(.iCloud)
            }
            else  if self.centerManager.isLocalUserAuthentificated {
                //TODO: Determine if there is GC record...
                self.transferOwnerShipOnNeed(.GameCenter)
            }
            else {
                self.transferOwnerShipOnNeed(.None)
            }
        }
        
    }
    
    func gameCenterChangedAuth() {
        
        if !self.centerManager.isLocalUserAuthentificated {
            
            cloudChangedAuth()
        }
        else {
            
            NSNotificationCenter.defaultCenter().postNotificationName(SYGameLogicManagerSoundNotification, object: self)
            cloudChangedAuth()
        }
    }
}

//MARK: Screen Recording

extension GameLogicManager {
    
    private struct ScreenRecordingConstants {
        static let screenRecorderOldValueKey  = "screenRecorderOldValueKey"
    }
    
    var oldScreenRecordingValue:UInt64 {
        if let value = NSUserDefaults.standardUserDefaults().objectForKey(ScreenRecordingConstants.screenRecorderOldValueKey) as? UInt64
        {
            return value
        }
        return 0
    }
    
    func setScreenRecordingValue(value:UInt64) -> Bool {
        let key = ScreenRecordingConstants.screenRecorderOldValueKey
        if value == 0 {
            NSUserDefaults.standardUserDefaults().removeObjectForKey(key)
        }
        else {
            NSUserDefaults.standardUserDefaults().setDouble(Double(value), forKey: key)
        }
        return NSUserDefaults.standardUserDefaults().synchronize()
    }
}

//MARK: ODR Logic

extension GameLogicManager {
    
    struct ODRConstants {
        static let helpSet  = Set(arrayLiteral: "Help")
        static let soundSet = Set(arrayLiteral: "Sound")
        static let iapSet   = Set(arrayLiteral: "IAP")
    }
    
    func initODR() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "needToPurgeODR:", name: ODRManagerShouldEndAccessOfRequestNotitification, object: self.odrManager)
        
        self.odrManager.definePreservationPriorityForResources(ODRConstants.helpSet, priority: 0.1)
        self.odrManager.definePreservationPriorityForResources(ODRConstants.soundSet, priority: 0.9)
        self.odrManager.definePreservationPriorityForResources(ODRConstants.iapSet, priority: 0.5)
        
    }
    
    func deinitODR() {
         NSNotificationCenter.defaultCenter().removeObserver(self, name:ODRManagerShouldEndAccessOfRequestNotitification  , object:self.odrManager)
    }
    
    func  needToPurgeODR(notification:NSNotification) {
        
        if let userInfo = notification.userInfo {
            
            if let preservation = userInfo["preservation"] as? Double {
                
                let request = userInfo["request"] as! NSBundleResourceRequest
                
                let tVC = UIApplication.topViewController()
                
                let calcPreservation = self.odrManager.preservationPriorityForResource(request.tags)
                
                let isEqual = preservation == calcPreservation
                
                if (!isEqual) {
                    return
                }
                
                if request.tags == ODRConstants.soundSet  {
                        // high
                    
                    self.odrManager.endAcessingRequest(request.tags)
                    SoundManager.sharedInstance.disableSound()
                    self.storeGameSoundInfo(true)
                    
                    //TODO: place KVO in VC...
                    if let gVC = tVC as? GameMainViewController {
                        gVC.correctSoundButton()
                    }
                    else if let pVC = tVC as? PauseReturnViewController {
                        pVC.correctSoundButton()
                    }
                }
                else if request.tags == ODRConstants.iapSet {
                    
                    if !(tVC is ShopDetailsViewController) {
                        self.odrManager.endAcessingRequest(request.tags)
                    }
                }
                else if request.tags == ODRConstants.helpSet {
                    
                    if !(tVC is HelpViewController) {
                        self.odrManager.endAcessingRequest(request.tags)
                    }
                }
            }
        }
        
    }
    
}

