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
    
    private var state:GameLogicSelectedStrategy = .None
    private var scoreValue:Float = 0
    private static var gSharedController:GameLogicManager!
    
    internal var survivalTotalScore:UInt64 = 0
    internal var survivalBestScore:Int64 = 0
    
    private let centerManager:GameCenterManager! = GameCenterManager.sharedInstance
    
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
    
}
