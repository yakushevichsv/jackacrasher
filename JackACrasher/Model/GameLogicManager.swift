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


class GameLogicManager: NSObject {
    
    private static let sNoAdProductId = "sy.gamefun.jackACrasher.NoAds"
    private static let sNumberOfLives = "sy.gamefun.jackACrasher.NumberOfLives"
    private static let sCurrentUserNameKey = "currentUser.sy.gamefun.jackACrasher"
    
    private static let sCurrentUserTimePartKey  = "timePart.sy.gamefun.jackACrasher"
    private static let sCurrentUserScorePartKey = "scorePart.sy.gamefun.jackACrasher"
    
    private var state:GameLogicSelectedStrategy = .None
    private var scoreValue:Float = 0
    private static var gSharedController:GameLogicManager!
    
    internal var survivalTotalScore:UInt64 = 0
    internal var survivalBestScore:Int64 = 0
    
    private let centerManager:GameCenterManager! = GameCenterManager.sharedInstance
    private let cloudManager:CloudManager! = CloudManager.sharedInstance
    
    dynamic internal var isLoading:Bool = false
    
    internal func resetState() {
        self.state = .None
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
                println("Error \(error)")
                return
            }
            else {
                self.getTotalSurvivalScoreWithCompletionHandler({ (totalScore, error) -> Void in
                    if (error != nil) {
                        println("Error \(error)")
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
            println("GK :  Score : \(scores)")
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
            println("GK : Best time : \(time)")
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
            println("GK : Scores : \(scores)")
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
        static var  SurvivalTotalScore = "SurvivalTotalScore"
        static var  AppState = "AppState"
    }
    
    //MARK: Survival
    private func storeInDefaultsSurvivalTotalScore(score:UInt64,synch:Bool = true) -> Bool {
        NSUserDefaults.standardUserDefaults().setDouble(Double( score), forKey: Constants.SurvivalTotalScore)
        if (synch) {
            return NSUserDefaults.standardUserDefaults().synchronize()
        }
        return true
    }
    
    private func storeInDefaultsSurvivalBestScore(score:Int64,synch:Bool = true) -> Bool {
        NSUserDefaults.standardUserDefaults().setDouble(Double( score), forKey: Constants.SurvivalBestScore)
        if (synch) {
            return NSUserDefaults.standardUserDefaults().synchronize()
        }
        return true
    }
    
    private func storeInDefaultsLongesTimeScore(score:Int64,synch:Bool = true) -> Bool {
        NSUserDefaults.standardUserDefaults().setDouble(Double( score), forKey: Constants.SurvivalLongestGame)
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
        
        let total = Int64(NSUserDefaults.standardUserDefaults().doubleForKey(Constants.SurvivalLongestGame))
        
        return total
    }
    
    private func getFromDefaultsBestSurvivalScore() -> Int64 {
        
        let best = Int64(NSUserDefaults.standardUserDefaults().doubleForKey(Constants.SurvivalBestScore))
        
        return best
    }
    
    private func getFromDefaultsTotalSurvivalScore() -> UInt64 {
        
        let total = UInt64(NSUserDefaults.standardUserDefaults().doubleForKey(Constants.SurvivalTotalScore))
        
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
    
    // Update the UI according to the purchase request notification result
    func handlePurchasesNotification(aNotification:NSNotification!)
    {
        let pManager = aNotification.object as! PurchaseManager
        
        let userInfo = aNotification.userInfo
        
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
            CloudManager.sharedInstance.userLoggedIn() {
                loggedIn in
                
                if !loggedIn {
                    
                    //MARK: TODO use another way to store info about IAP...
                    //Use ID from Gamekit
                    //if there is an ID then set as default player....
                    // NSUserDefaults - setKeyFor "Default Playr ID"
                    
                    return
                }
                
                CloudManager.sharedInstance.createAIPProductInfoOnNeed(product) {
                    record,error in
                    
                    println("Error \(error)")
                }
            }
        }
    }
    
    
    
    
    
}

extension GameLogicManager {
    //MARK: Todo detect correct way to get ID, and access item locally of from CloudKit...
    
    internal func getPlayerId() -> String! {
        
        var playerId:String! = nil
        
        if let recName = self.cloudManager.recordID?.recordName {
            playerId = recName
        } else if let playerID = GameCenterManager.sharedInstance.playerID {
            playerId = playerID
        } else {
            playerId = "guest"
        }
        return playerId
    }
    
    internal func submitTimes(times:[NSTimeInterval],completionHandler:((isError:Bool,delayInTime:UInt64)->Void)!) {
        
        self.cloudManager.submitTimes(times) {
            failedIndexesDic  in
            
            var maxDelayInterval:NSTimeInterval = 0
            var newTimes:[NSTimeInterval] = [NSTimeInterval]()
            
            for failedIndex in failedIndexesDic {
                let index = failedIndex.0
                let delayInterval = failedIndex.1
                
                if maxDelayInterval > delayInterval {
                    maxDelayInterval = delayInterval
                }
                
                newTimes.append(times[index])
            }
            
            let curPlayerId = self.getPlayerId()
            let newTimeKey = curPlayerId.stringByAppendingString(GameLogicManager.sCurrentUserTimePartKey)
            
            
            if failedIndexesDic.isEmpty {
                NSUserDefaults.standardUserDefaults().removeObjectForKey(newTimeKey)
                if (NSUserDefaults.standardUserDefaults().synchronize()) {
                    completionHandler(isError:false,delayInTime:0)
                }
            } else {
                NSUserDefaults.standardUserDefaults().setObject(newTimes, forKey: newTimeKey)
                if (NSUserDefaults.standardUserDefaults().synchronize()) {
                    
                    let delayTime = dispatch_time(DISPATCH_TIME_NOW,
                        Int64(maxDelayInterval * Double(NSEC_PER_SEC)))
                    
                    completionHandler(isError: true, delayInTime: delayTime)
                }
            }
        }
    }
    
    internal func submitScores(scores:[Int64],completionHandler:((isError:Bool,delayInTime:UInt64)->Void)!) {
        
        self.cloudManager.submitScores(scores) {
            failedIndexesDic  in
            
            var maxDelayInterval:NSTimeInterval = 0
            var newScores:NSMutableArray = NSMutableArray()
            
            for failedIndex in failedIndexesDic {
                let index = failedIndex.0
                let delayInterval = failedIndex.1
                
                if maxDelayInterval > delayInterval {
                    maxDelayInterval = delayInterval
                }
                newScores.addObject(NSNumber(longLong: scores[index]))
            }
            
            let curPlayerId = self.getPlayerId()
            let newScoreKey = curPlayerId.stringByAppendingString(GameLogicManager.sCurrentUserScorePartKey)
            
            if failedIndexesDic.isEmpty {
                NSUserDefaults.standardUserDefaults().removeObjectForKey(newScoreKey)
                if (NSUserDefaults.standardUserDefaults().synchronize()) {
                    completionHandler(isError:false,delayInTime:0)
                }
            } else {
                
                NSUserDefaults.standardUserDefaults().setObject(newScores, forKey: newScoreKey)
                if (NSUserDefaults.standardUserDefaults().synchronize()) {
                    let delayTime = dispatch_time(DISPATCH_TIME_NOW,
                        Int64(maxDelayInterval * Double(NSEC_PER_SEC)))
                    
                    completionHandler(isError: true, delayInTime: delayTime)
                }
            }
        }
    }
    
    internal func appendSurvivalGameValuesToDefaults(score:Int64,time:NSTimeInterval) -> Bool {
        
        let newTimeKey = getPlayerId().stringByAppendingString(GameLogicManager.sCurrentUserTimePartKey)
        var times = NSUserDefaults.standardUserDefaults().arrayForKey(newTimeKey) as? [NSTimeInterval]
        
        let newScoreKey = getPlayerId().stringByAppendingString(GameLogicManager.sCurrentUserScorePartKey)
        var scoresPrivate = NSUserDefaults.standardUserDefaults().objectForKey(newScoreKey) as? NSArray
        
        var scores = scoresPrivate != nil ? NSMutableArray(array: scoresPrivate!) : NSMutableArray()
        
        if times == nil {
            times = [NSTimeInterval]()
        }
        
        
        times!.append(time)
        scores.addObject(NSNumber(longLong: score))
        
        
        NSUserDefaults.standardUserDefaults().setObject(scores, forKey: newScoreKey)
        NSUserDefaults.standardUserDefaults().setObject(times, forKey: newTimeKey)
        return NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    internal func submitSurvivalGameValues(completionHandler:((isError:Bool)->Void)!) {
        
        let newTimeKey = getPlayerId().stringByAppendingString(GameLogicManager.sCurrentUserTimePartKey)
        let times = NSUserDefaults.standardUserDefaults().arrayForKey(newTimeKey) as? [NSTimeInterval]
        
        let newScoreKey = getPlayerId().stringByAppendingString(GameLogicManager.sCurrentUserScorePartKey)
        let scores = NSUserDefaults.standardUserDefaults().objectForKey(newScoreKey) as? [Int64]
        
        var doneTimes:Bool = false
        var doneScores:Bool = false
        
        var scoreError:Bool = false
        var timeError:Bool = false
        
        if let times = times {
            
            self.submitTimes(times) {
                isError,delayInTime in
                
                timeError = isError
                
                if isError {
                    
                    dispatch_after(delayInTime, dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
                        [unowned self] in
                        
                        let newTimeKey = self.getPlayerId().stringByAppendingString(GameLogicManager.sCurrentUserTimePartKey)
                        if let times2 = NSUserDefaults.standardUserDefaults().arrayForKey(newTimeKey) as? [NSTimeInterval] {
                            
                            self.submitTimes(times2) {
                                isError, delayInTime   in
                                
                                timeError = isError
                                doneTimes = true
                                if (doneScores){
                                    doneTimes = false
                                    completionHandler(isError: timeError || scoreError)
                                }
                                
                            }
                            return
                        }
                    }
                }
                
                    doneTimes = true
                    if (doneScores){
                        doneTimes = false
                        completionHandler(isError: timeError || scoreError)
                    }
                
            }
        }
        
        if let scores = scores {
            
            self.submitScores(scores) {
                isError,delayInTime in
                
                scoreError = isError
                
                if isError {
                    
                    dispatch_after(delayInTime, dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
                        [unowned self] in
                        
                        let newKey = self.getPlayerId().stringByAppendingString(GameLogicManager.sCurrentUserScorePartKey)
                        if let score2 = NSUserDefaults.standardUserDefaults().objectForKey(newKey) as? [Int64] {
                            
                            self.submitScores(score2)
                                { isError, delayInTime   in
                                    
                                    scoreError = isError
                                    
                                    doneScores = true
                                    if (doneTimes){
                                        doneScores = false
                                        completionHandler(isError: timeError || scoreError)
                                    }
                            }
                            return
                        }
                    }
                }
                
                    doneScores = true
                    if (doneTimes){
                        doneScores = false
                        completionHandler(isError: timeError || scoreError)
                    }
                
            }
            
        }
        
        if scores == nil && times == nil {
            completionHandler(isError:scoreError || timeError)
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
        
        let oldTimeKey = prevUserId.stringByAppendingString(GameLogicManager.sCurrentUserTimePartKey)
        var flag:Bool = false
        if let times = NSUserDefaults.standardUserDefaults().arrayForKey(oldTimeKey) as? [NSTimeInterval] {
            
            let newTimeKey = userId.stringByAppendingString(GameLogicManager.sCurrentUserTimePartKey)
            
            NSUserDefaults.standardUserDefaults().setObject(times, forKey: newTimeKey)
            flag = true
        }
        
        let oldScoreKey = prevUserId.stringByAppendingString(GameLogicManager.sCurrentUserScorePartKey)
        
        if let scores = NSUserDefaults.standardUserDefaults().arrayForKey(oldScoreKey) as? [UInt] {
            
            let newKey = userId.stringByAppendingString(GameLogicManager.sCurrentUserScorePartKey)
            
            NSUserDefaults.standardUserDefaults().setObject(scores, forKey: newKey)
            flag = true
        }
        
        return flag && saveUserId(userId)
    }
    
    internal var needToDisplayAdv:Bool {
        get { return NSUserDefaults.standardUserDefaults().boolForKey(GameLogicManager.sNoAdProductId) }
    }
    
    internal var numberOfLives:Int {
        get {return NSUserDefaults.standardUserDefaults().integerForKey("")}
    }
    
    internal func increaseNumberOfLives(amount:Int) {
        
    }
    
    internal func decreaseNumberOfLives(amount:Int){
        
    }
}
