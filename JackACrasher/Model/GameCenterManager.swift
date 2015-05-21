//
//  GameCenterManager.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 5/18/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit
import GameKit

@objc protocol GameCenterManagerDelegate {
    
    func processGameCenterAuth(error:NSError!)
    
}

let SurvivalBestScoreLbId  = "com.sygamefun.survival_best_score"
let SurvivalTotalScoreLbId = "com.sygamefun.survival_total_score"

let GameCenterManagerViewController = "GameCenterManagerViewController"
let singleton = GameCenterManager()

class GameCenterManager: NSObject {
   
    var authenticationViewController: UIViewController?
    var lastError: NSError?
    var gameCenterEnabled: Bool
    
    override init()
    {
        self.gameCenterEnabled = true
        super.init()
    }
    
    weak var delegate: GameCenterManagerDelegate?
    
    class var sharedInstance: GameCenterManager {
        return singleton
    }
    
    internal func authenticateLocalPlayer() {
        
        let localPlayer = GKLocalPlayer.localPlayer()
        
        if (!localPlayer.authenticated) {
            
            localPlayer.authenticateHandler = {(viewController : UIViewController!, error : NSError!) -> Void in
                //handle authentication
                print("Error \(error)")
            
                self.lastError = error
            
                if viewController != nil {
                    //3
                    self.authenticationViewController = viewController
                
                    NSNotificationCenter.defaultCenter().postNotificationName(GameCenterManagerViewController,
                    object: self)
                } else if localPlayer.authenticated {
                    //4
                    self.gameCenterEnabled = true
                } else {
                    //5
                    self.gameCenterEnabled = false
                }

            }
        }
    }
    
    //MARK: Score
    private func reportScore(score:Int64,context:UInt64 = 0, leaderboardId: String) {
        
        if (!gameCenterEnabled) {
            println("Game center is not available")
            return
        }
        
        let scoreReporter = GKScore(leaderboardIdentifier: leaderboardId)
        scoreReporter.value   = score
        scoreReporter.context = context
        
        GKScore.reportScores([scoreReporter], withCompletionHandler: { (error) -> Void in
            self.lastError = error
        })
       
    }
    
    private func getScoresFromLeaderboard(leaderboardId :String,completionHandler: (([AnyObject]!, AnyObject!, NSError!) -> Void)!) {
        
        if (!gameCenterEnabled) {
            println("Game center is not available")
            return
        }
        
        let lb = GKLeaderboard(players: [GKLocalPlayer.localPlayer()])
        lb.identifier = leaderboardId
        lb.timeScope = .AllTime
        
        lb.loadScoresWithCompletionHandler { (scores, error) -> Void in
            self.lastError  = error
            completionHandler(scores,lb.localPlayerScore,error)
        }
    }
    
    
    //MARK: Survival part
    internal func reportSurvivalTotalScore(score:UInt64) {
        
        let context = score/UInt64(Int64.max)
        let scoreDiff = Int64(score - context*UInt64(Int64.max))
        
        reportScore(scoreDiff,context:context, leaderboardId: SurvivalTotalScoreLbId)
    }
    
    internal func reportSurvivalBestScore(score:Int64) {
        reportScore(score, leaderboardId: SurvivalBestScoreLbId)
    }
    
    internal func getSurvivalBestScoreWithCompletionHandler(handler: (AnyObject!, NSError!) -> Void) {
        
        getScoresFromLeaderboard(SurvivalBestScoreLbId, completionHandler: { (scores, localPlayerScore, error) -> Void in
            handler(localPlayerScore,error)
        })
    }
    
    internal func getSurvivalTotalScoreWithCompletionHandler(handler: (AnyObject!, NSError!) -> Void) {
        
        getScoresFromLeaderboard(SurvivalTotalScoreLbId, completionHandler: { (scores, localPlayerScore, error) -> Void in
            var totalScore:UInt64 = 0
            for scoreAny in scores {
                let score = scoreAny as! GKScore
                totalScore += UInt64(score.value)
            }
            
            let context:UInt64 = UInt64(Float(totalScore)/Float(Int64.max))
            let reminder:Int64 = Int64(totalScore -  UInt64(Int64.max) * context)
            
            println("Local score \(localPlayerScore)")
            
            let score = GKScore(leaderboardIdentifier: SurvivalBestScoreLbId)
            score.value = reminder
            score.context = context
            
            handler(score,error)
        })
    }
    
    
}
