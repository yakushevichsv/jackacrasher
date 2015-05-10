//
//  GameViewController.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 4/9/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController,GameSceneDelegate {

    @IBOutlet weak var btnPlay: UIButton!
    @IBOutlet weak var analogControl: AnalogControl!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    private var skView:SKView! {
        get { return self.view as! SKView}
    }
    
    @IBAction func btnPressed(sender: UIButton) {
        
        sender.selected = !sender.selected
        
            if let scene = skView.scene {
                scene.paused = sender.selected
            }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let scene = GameScene.unarchiveFromFile("GameScene") as? GameScene {
            
            scene.defineStartingRect(self.btnPlay.frame,alpha: self.btnPlay.alpha)
            // Configure the view.
            let skView = self.view as! SKView
            
            
            skView.showsFPS = true
            skView.showsNodeCount = true
            /* Sprite Kit applies additional optimizations to improve rendering performance */
            skView.ignoresSiblingOrder = false
            
            /* Set the scale mode to scale to fit the window */
            scene.scaleMode = .AspectFill
            
            scene.gameSceneDelegate = self
            skView.presentScene(scene)
            
            btnPlay.superview?.bringSubviewToFront(btnPlay)
            
            analogControl.delegate = scene
            analogControl.superview?.bringSubviewToFront(analogControl)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didMoveToBG:", name: UIApplicationDidEnterBackgroundNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "willMoveToFG:", name: UIApplicationWillEnterForegroundNotification, object: nil)
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidEnterBackgroundNotification, object: nil)
    
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillEnterForegroundNotification, object: nil)
    }
    
    func didMoveToBG(aNotification:NSNotification) {
        
        self.btnPlay.selected = false
        
        self.btnPressed(self.btnPlay)
    }
    
    func willMoveToFG(aNotification:NSNotification) {
        
        self.btnPlay.selected = true
        
        self.btnPressed(self.btnPlay)
    }
    

    override func shouldAutorotate() -> Bool {
        return true
    }

    override func supportedInterfaceOrientations() -> Int {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return Int(UIInterfaceOrientationMask.Landscape.rawValue) //Int(UIInterfaceOrientationMask.AllButUpsideDown.rawValue)
        } else {
            return Int(UIInterfaceOrientationMask.All.rawValue)
        }
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if let identifier = segue.identifier {
            if identifier == "gameOver" {
                let dVC = segue.destinationViewController as! GameOverViewController
                let sVC = segue.sourceViewController as! GameViewController
                
               dVC.didWin = false
                
            }
        }
    }
    
    //MARK : GameScene delegate 
    
    func gameScenePlayerDied(scene:GameScene) {
        self.skView.scene?.paused = true
        performSegueWithIdentifier("gameOver", sender: self)
    }
    
}
