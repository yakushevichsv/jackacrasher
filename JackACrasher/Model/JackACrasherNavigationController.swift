//
//  JackACrasherNavigationController.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 5/18/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit
import SpriteKit

class JackACrasherNavigationController: UINavigationController {
    
    override func viewDidLoad() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector:
            #selector(JackACrasherNavigationController.showAuthenticationViewController), name:
            GameCenterManagerViewController, object: nil)
        
        GameCenterManager.sharedInstance.authenticateLocalPlayer()
        super.viewDidLoad()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func showAuthenticationViewController() {
        let gameKitHelper = GameCenterManager.sharedInstance
        
        if let authenticationViewController = gameKitHelper.authenticationViewController {
            
            if let view = self.topViewController?.view as? SKView {
                if let scene = view.scene as? GameScene {
                    scene.pauseGame(true)
                }
            }
            
            topViewController?.presentViewController(authenticationViewController, animated: true,
                completion: nil)
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}
