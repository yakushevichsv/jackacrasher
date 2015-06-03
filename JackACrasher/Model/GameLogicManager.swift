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
    
    internal var isSurvival:Bool {
        get {
            return self.state == .Survival
        }
    }
    
    internal func getTotalSurvivalScoreWithCompletionHandler(completionHandler: ((UInt64, NSError?) -> Void)!)
    {
        let totalScore = getFromDefaultsTotalSurvivalScore()
        
        if (totalScore == 0 ) {
            
            self.centerManager.getSurvivalTotalScoreWithCompletionHandler({ (totalScore, error) -> Void in
                println("GK : Total score : \(totalScore)")
                if (error != nil) {
                    completionHandler(0,error)
                    return
                }
                
                let tScore = totalScore as! GKScore
                
                let survivalTotalScore = tScore.context != 0 ?  tScore.context * UInt64(Int64.max) + UInt64(tScore.value) :  UInt64(tScore.value)
                
                self.storeInDefaultsSurvivalTotalScore(survivalTotalScore)
                
                completionHandler(survivalTotalScore,nil)
                
            })
        }
        else {
            completionHandler(totalScore,nil)
        }
    }
    
    internal func getBestSurvivalScoreWithCompletionHandler(completionHandler: ((Int64, NSError?) -> Void)!)
    {
        let bestScore = getFromDefaultsBestSurvivalScore()
        
        if (bestScore == 0 ) {
            
            self.centerManager.getSurvivalBestScoreWithCompletionHandler({ (bestScore, error) -> Void in
                println("GK : Best score : \(bestScore)")
                if (error != nil) {
                    completionHandler(0,error)
                    return
                }
                
                if let bScore = bestScore as? GKScore {
                
                    let survivalBestScore = bScore.value
                
                    self.storeInDefaultsSurvivalBestScore(survivalBestScore)
                
                    completionHandler(survivalBestScore,nil)
                }
                else {
                    completionHandler(0,error)
                }
                
            })
        }
        else {
            completionHandler(bestScore,nil)
        }
    }

    internal func storeSurvivalScores(info:[UInt64], completionHandler:((Bool ,NSError?)->Void)!) {
        
        let bestScore = Int64(info[0])
        let totalScore = info[1]
        
        storeInDefaultsSurvivalBestScore(bestScore)
        storeInDefaultsSurvivalTotalScore(totalScore)
        
       let res = NSUserDefaults.standardUserDefaults().synchronize()
        
        
        self.centerManager.reportSurvivalBestScore(bestScore)
        self.centerManager.reportSurvivalTotalScore(totalScore)
        
        
        completionHandler(res,self.centerManager.lastError)
    }
    
}

//MARK: Score's extension
extension GameLogicManager
{
    private struct Constants {
        static var  SurvivalTotalScore = "SurvivalTotalScore"
        static var  SurvivalBestScore = "SurvivalBestScore"
    }
    
    //MARK: Survival
    private func storeInDefaultsSurvivalTotalScore(score:UInt64) -> Bool {
        NSUserDefaults.standardUserDefaults().setDouble(Double( score), forKey: Constants.SurvivalTotalScore)
        return NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    private func storeInDefaultsSurvivalBestScore(score:Int64) -> Bool {
        NSUserDefaults.standardUserDefaults().setDouble(Double( score), forKey: Constants.SurvivalBestScore)
        return NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    
    
    private func storeInDefaultsSurvivalInfo(info:[UInt64]) ->Bool {
        assert(info.count == 2, "not all items are presented!")
        let bestScore  = Int64(info[0])
        let totalScore = info[1]
        
        return storeInDefaultsSurvivalTotalScore(totalScore)
         && storeInDefaultsSurvivalBestScore(bestScore)
    }
    
    private func getFromDefautsSurvivalInfo() -> [UInt64] {
        
        let total = getFromDefaultsTotalSurvivalScore()
        let best = getFromDefaultsBestSurvivalScore()
        
        return [total,UInt64(best)]
    }
    
    private func getFromDefaultsTotalSurvivalScore() -> UInt64 {
        
        let total = UInt64(NSUserDefaults.standardUserDefaults().doubleForKey(Constants.SurvivalTotalScore))
        
        return total
    }
    
    private func getFromDefaultsBestSurvivalScore() -> Int64 {
        
        let best = Int64(NSUserDefaults.standardUserDefaults().doubleForKey(Constants.SurvivalBestScore))
        
        return best
    }
    
}
