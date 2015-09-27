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
let SurvivalLongestTimeLbId = "sygame.com.survival_longest_game_time"

let GameCenterManagerViewController = "GameCenterManagerViewController"
let singleton = GameCenterManager()

let kGameCenterManagerNeedToAuthPlayer = "kGameCenterManagerNeedToAuthPlayer"

class GameCenterManager: NSObject, GKGameCenterControllerDelegate {
   
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
    
    internal var playerID:String? {
        get {
            let player = GKLocalPlayer.localPlayer()
            
            if (player.authenticated) {
                return player.playerID
            }
            else {
                return player.displayName
            }
        }
    }
    
    //MARK: Authentification methods
    
    internal var isLocalUserAuthentificated:Bool {
        get { return self.gameCenterEnabled  && GKLocalPlayer.localPlayer().authenticated }
    }
    
    internal func authenticateLocalPlayer() {
        
        let localPlayer = GKLocalPlayer.localPlayer()
        
        if (!localPlayer.authenticated) {
            
            
            localPlayer.authenticateHandler = {(viewController : UIViewController?, error : NSError?) -> Void in
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
                    
                    NSNotificationCenter.defaultCenter().postNotificationName(kGameCenterManagerNeedToAuthPlayer, object: self)
                }

            }
        }
    }
    
    func showGKGameCenterViewController(viewController: UIViewController!) {
        
        if !gameCenterEnabled {
            print("Local player is not authenticated")
            return
        }
        
        //1
        let gameCenterViewController = GKGameCenterViewController()
        
        //2
        gameCenterViewController.gameCenterDelegate = self
        
        //3
        gameCenterViewController.viewState = .Leaderboards
        
        //4
        viewController.presentViewController(gameCenterViewController,
            animated: true, completion: nil)
    }
    
    //MARK: Achievements
    func reportAchievements(achievements: [GKAchievement]) {
        if !gameCenterEnabled {
            print("Local player is not authenticated")
            return
        }
        GKAchievement.reportAchievements(achievements) {(error) in
            self.lastError = error
        }
    }
    
    //MARK: Score
    
    
    private func reportScore(score:Int64,context:UInt64 = 0, leaderboardId: String) {
        
        if (!gameCenterEnabled) {
            print("Game center is not available")
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
            print("Game center is not available")
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
    internal func reportSurvivalGameTime(timeInterval: NSTimeInterval ) {
        
        assert(timeInterval <= NSTimeInterval(Int64.max), "Out of range!")
       let score = GKScore(leaderboardIdentifier: SurvivalLongestTimeLbId)
        score.value = Int64(timeInterval)
        
        GKScore.reportScores([score], withCompletionHandler: { (error) -> Void in
            self.lastError = error
        })
        
    }
    
    internal func reportSurvivalBestScore(score:Int64) {
        reportScore(score, leaderboardId: SurvivalBestScoreLbId)
    }
    
    internal func getSurvivalScoresWithCompletionHandler(handler: ([UInt64], NSError!) -> Void) {
        
        if (!self.gameCenterEnabled) {
            
            
            
            return
        }
        
        getScoresFromLeaderboard(SurvivalBestScoreLbId, completionHandler: { (scores, localPlayerScore, error) -> Void in
            
            let totalScore:UInt64 = 0
            var maxScore:Int64 = 0
            
            if (scores != nil) {
                for scoreAny in scores {
                    let score = scoreAny as! GKScore
                
                    if (maxScore < score.value ) {
                        maxScore = score.value
                    }
                }
            }
            
            
            if (localPlayerScore != nil) {
                print("Local score \(localPlayerScore)")
            
                if (maxScore < localPlayerScore.value ) {
                    maxScore = localPlayerScore.value
                }
            }
            
            handler([totalScore,UInt64(maxScore)],error)
        })
    }
    
    internal func getSurvivalBestTimeScoreWithCompletionHandler(handler:(Int64, NSError!) -> Void) {
        
        if (!self.gameCenterEnabled) {
            
            return
        }
        
        getScoresFromLeaderboard(SurvivalLongestTimeLbId, completionHandler: { (scores, localPlayerScore, error) -> Void in
            var maxScorePtr:GKScore? = nil
            for scoreAny in scores {
                let score = scoreAny as! GKScore
                if let maxScore = maxScorePtr {
                    if (maxScore.value < score.value ) {
                        maxScorePtr = score
                    }
                }
            }
            
            print("Local score \(localPlayerScore)")
            
            if (maxScorePtr == nil) {
                maxScorePtr = localPlayerScore as? GKScore
            }
            
            handler(maxScorePtr != nil ? maxScorePtr!.value : Int64(0),error)
        })
    }
    
    //MARK : Player's info access
    
    internal func getSmallPhotoForLocalPlayerWithHandler(handler:(UIImage?, NSError!) -> Void) {
        self.getSmallPhotoForPlayer(GKLocalPlayer.localPlayer(), handler: handler)
    }
    
    internal func getNormalPhotoForLocalPlayerWithHandler(handler:(UIImage?, NSError!) -> Void) {
        self.getNormalPhotoForPlayer(GKLocalPlayer.localPlayer(), handler: handler)
    }
    
    internal func getSmallPhotoForPlayer(player:AnyObject, handler :(UIImage?, NSError!) -> Void) {
        self.getPhotoForPlayer(player, andSize: GKPhotoSizeSmall, handler: handler)
    }
    
    internal func getNormalPhotoForPlayer(player:AnyObject, handler :(UIImage?, NSError!) -> Void) {
        self.getPhotoForPlayer(player, andSize: GKPhotoSizeNormal, handler: handler)
    }
    
    private func getPhotoForPlayer(playerObj:AnyObject?, andSize size:GKPhotoSize, handler:(UIImage?, NSError!) -> Void) {
    
        if (!self.gameCenterEnabled) {
            print("Local player is not authentificated")
            return
        }
        
        let localPlayer = GKLocalPlayer.localPlayer()
        if let playerAnyObj: AnyObject = playerObj {
            
            if (playerAnyObj is GKPlayer) {
                
                let player = playerAnyObj as! GKPlayer
                
                player.loadPhotoForSize(size, withCompletionHandler: { (image, error) -> Void in
                  
                    if (error != nil) {
                        print("Error \(error)")
                        
                        handler(nil,error)
                        return
                    }

                    handler(image,error)
                    return
                })
            } else if (playerAnyObj is String) {
                
                let playerStr = playerAnyObj as! String
                
                if (playerStr == localPlayer.playerID) {
                    
                    getPhotoForPlayer(localPlayer, andSize: size, handler:handler)
                    return
                }
                
                
                GKPlayer.loadPlayersForIdentifiers([playerStr], withCompletionHandler: { (players, error) -> Void in
                    
                    if (error != nil) {
                        print("Error \(error)")
                        
                        handler(nil,error)
                        return
                    }
                    
                    if let rPlayers =  players {
                    
                        if (rPlayers.isEmpty) {
                            return
                        }
                        
                        if let rPlayer = rPlayers.last {
                            self.getPhotoForPlayer(rPlayer, andSize: size, handler: handler)
                        }
                    }
                })
            }
            else {
                handler(nil,nil)
            }
        }
        else {
            getPhotoForPlayer(localPlayer, andSize: size, handler: handler)
        }
        
    }
    
    
    // MARK: GKGameCenterControllerDelegate methods
    func gameCenterViewControllerDidFinish(gameCenterViewController: GKGameCenterViewController) {
        
        gameCenterViewController.dismissViewControllerAnimated(true, completion: nil)
    }
}
