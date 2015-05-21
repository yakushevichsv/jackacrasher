//
//  GameOverViewController.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 5/9/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit
import SpriteKit

class GameOverViewController: UIViewController, GameOverSceneDelegate {

    @IBOutlet weak var containerView:UIView!
    @IBOutlet weak var btnReplay:UIButton!
    @IBOutlet weak var bntShop:UIButton!
    @IBOutlet weak var btnMainMenu:UIButton!
    
    var didWin:Bool = false {
        didSet {
            if let scene  = self.skView?.scene as? GameOverScene {
                scene.didWin = didWin
            }
        }
    }
    
    private var skView:SKView! {
        get { return self.view as! SKView}
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.containerView.hidden = true
        
        if let scene = GameOverScene.unarchiveFromFile("GameOverScene") as? GameOverScene {
            
            skView.showsFPS = true
            skView.showsNodeCount = true
            /* Sprite Kit applies additional optimizations to improve rendering performance */
            skView.ignoresSiblingOrder = false
            
            /* Set the scale mode to scale to fit the window */
            scene.scaleMode = .AspectFill
            scene.gameOverDelegate = self
            scene.userInteractionEnabled = false
            self.skView.presentScene(scene)
            
            self.containerView.superview?.bringSubviewToFront(self.containerView)
            
            self.btnMainMenu.superview?.bringSubviewToFront(self.btnMainMenu)
            
            self.btnReplay.superview?.bringSubviewToFront(self.btnReplay)
            self.bntShop.superview?.bringSubviewToFront(self.bntShop)
        }
    }
    
    
    internal func displayGameOverContainerView(scenePosition:CGPoint) {
        
        let dScale = self.traitCollection.displayScale
        let sceneY = CGFloat(ceil(scenePosition.y / dScale))
        let xPos = CGRectGetWidth(self.view.bounds) * 0.5 //CGFloat(ceil(scenePosition.x / dScale))
        let yPos = CGRectGetHeight(self.view.bounds) - sceneY
        
        self.containerView.hidden = false;
        self.containerView.center = CGPointMake(xPos, self.containerView.center.y /*yPos*/)
    }
    
    func gameOverScene(scene:GameOverScene, didDisplayLabelWithFrame frame:CGRect)
    {
        let xMid = CGRectGetMidX(frame)
        let yMid = CGRectGetMidY(frame)
        
        displayGameOverContainerView(CGPointMake(xMid, yMid))
    }
    
    
    @IBAction func btnPressed(sender: UIButton) {
        if (sender == self.btnMainMenu){
          //TODO: write here logic for selecting what to replay
            
            self.navigationController?.popToRootViewControllerAnimated(false)
            if let vc = self.navigationController?.topViewController as? GameMainViewController {
                vc.needToDisplayAnimation = true
            }
        }
        
    }
}