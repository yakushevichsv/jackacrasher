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
    
}
