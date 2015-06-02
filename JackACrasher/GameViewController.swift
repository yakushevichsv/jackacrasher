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
    
    private var logicManager:GameLogicManager! = GameLogicManager.sharedInstance
    
    private var myContext = 0
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        logicManager.addObserver(self, forKeyPath: "isLoading", options: .New, context: &myContext)
    }

    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject: AnyObject], context: UnsafeMutablePointer<Void>) {
        if context == &myContext {
            let isLoading:Bool = change[NSKeyValueChangeNewKey]!.boolValue
            
            println("Date changed: \(change[NSKeyValueChangeNewKey])")
            
            if (!isLoading) {
                self.waitUntilNotLoadedItem()
            }
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    deinit {
        logicManager.removeObserver(self, forKeyPath: "isLoading", context: &myContext)
    }
    
    private func waitUntilNotLoadedItem(force:Bool = false)  {
        if (!logicManager.isLoading && self.isViewLoaded()) {
                if let scene = self.skView.scene as? GameScene {
                    if (self.logicManager.isSurvival) {
                        scene.setTotalScore(self.logicManager.survivalTotalScore)
                    }
                }
        }
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
        
        restartGame()
    }
    
    //MARK: - Public function
    func restartGame(isNew:Bool = true) {
        
        if let scene = GameScene.unarchiveFromFile("GameScene") as? GameScene {
            
            // Configure the view.
            let skView = self.view as! SKView
            
            
            skView.showsFPS = true
            skView.showsNodeCount = true
            /* Sprite Kit applies additional optimizations to improve rendering performance */
            skView.ignoresSiblingOrder = false
            
            /* Set the scale mode to scale to fit the window */
            scene.scaleMode = .AspectFill
            
            scene.gameSceneDelegate = self
            if (isNew) {
                skView.presentScene(scene)
            }
            else {
                skView.presentScene(scene, transition: SKTransition.pushWithDirection(.Down, duration: 1))
            }
            
            btnPlay.superview?.bringSubviewToFront(btnPlay)
            
            analogControl.delegate = scene
            analogControl.superview?.bringSubviewToFront(analogControl)
            
            waitUntilNotLoadedItem()
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
                self.skView.scene?.paused = true
               dVC.didWin = false
                
            }
        }
    }
    
    //MARK : GameScene delegate 
    
    func gameScenePlayerDied(scene:GameScene,totalScore:UInt64,currentScore:Int64) {
        
        self.logicManager.storeSurvivalScores([UInt64(currentScore),totalScore], completionHandler: { (success, error) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.skView.scene?.paused = true
                self.performSegueWithIdentifier("gameOver", sender: self)
            })
        })
        
        
    }
    
    //MARK: Unwind to replay
    @IBAction func unwindToReplay(sender: UIStoryboardSegue)
    {
        if let vc = sender.destinationViewController as? GameViewController {
            vc.restartGame(isNew: false)
        }
    }
    
}
