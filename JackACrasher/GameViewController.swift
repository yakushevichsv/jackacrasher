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
    private var logicManager:GameLogicManager! = GameLogicManager.sharedInstance
    private lazy var returnPauseTransDelegate = ReturnPauseTransitionDelegate()
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
    
    internal var skView:SKView! {
        get { return self.view as! SKView}
    }
    
    
    @IBAction func btnPressed(sender: UIButton) {
        
        sender.selected = !sender.selected
        
        if let scene = skView.scene as? GameScene {
            scene.pauseGame(pause: !sender.selected)
        }
    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String?, sender: AnyObject?) -> Bool {
        
        if identifier == Optional("selectAction") {
            
            return !self.btnPlay.selected
        }
        
        return super.shouldPerformSegueWithIdentifier(identifier, sender: sender)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        restartGame()
    }
    
    //MARK: - Public function
    func restartGame(isNew:Bool = true) {
        
        // Configure the view.
        let skView = self.view as! SKView
        let scene = GameScene(size: skView.bounds.size)
        
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
            skView.presentScene(scene, transition: SKTransition.doorsCloseHorizontalWithDuration(1))
        }
        
        
        btnPlay.superview?.bringSubviewToFront(btnPlay)
        btnPlay.selected = true
        
        waitUntilNotLoadedItem()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        /*NSNotificationCenter.defaultCenter().addObserver(self, selector: "didMoveToBG:", name: UIApplicationDidEnterBackgroundNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "willMoveToFG:", name: UIApplicationWillEnterForegroundNotification, object: nil)*/
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didMoveToBG:", name: UIApplicationWillResignActiveNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "willMoveToFG:", name: UIApplicationDidBecomeActiveNotification, object: nil)
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func didMoveToBG(aNotification:NSNotification) {
        
        let scene = self.skView.scene as! GameScene
        scene.pauseGame(pause: true)
    }
    
    func willMoveToFG(aNotification:NSNotification) {
        var paused = false
        if self.presentedViewController == nil {
            paused = !self.btnPlay.selected
        }
        else {
            paused = true
        }
        
        let scene = self.skView.scene as! GameScene
        scene.pauseGame(pause: paused)
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
                SoundManager.sharedInstance.cancelPlayingBGMusic()
                let dVC = segue.destinationViewController as! GameOverViewController
                let sVC = segue.sourceViewController as! GameViewController
               dVC.didWin = false
                
            } else if identifier == "selectAction" {
                
                let dVC = segue.destinationViewController as! PauseReturnViewController
                
                
                let transDelegate = self.returnPauseTransDelegate
                transDelegate.rect = self.view.bounds
                transDelegate.isPortrait = CGRectGetHeight(self.view.frame) > CGRectGetWidth(self.view.frame)
                
                dVC.modalPresentationStyle = .Custom
                dVC.transitioningDelegate = transDelegate
            }
        }
    }
    
    //MARK : GameScene delegate 
    
    private func segueToGameOverSrceen(needToContinue:Bool) {
        
        if (needToContinue && self.view.window != nil) {
            dispatch_async(dispatch_get_main_queue()){
                [unowned self] in
                self.skView.scene?.paused = true
                self.performSegueWithIdentifier("gameOver", sender: self)
            }
        }
    }
    
    func gameScenePlayerDied(scene:GameScene,totalScore:UInt64,currentScore:Int64, playedTime:NSTimeInterval,needToContinue:Bool) {
        
        
        let needToReport = playedTime != 0  && currentScore != 0
        
         if !needToReport {
            segueToGameOverSrceen(needToContinue)
            return
        }
        
        if self.logicManager.appendSurvivalGameValuesToDefaults(currentScore, time: playedTime) {
        
            self.logicManager.submitSurvivalGameValues{
                [unowned self]
                isError in
            }
        }
    
        self.logicManager.storeSurvivalScores([UInt64(currentScore),totalScore, UInt64(playedTime)]){
            [unowned self]
            success, error in
            self.segueToGameOverSrceen(needToContinue)
        }
    }
    
    //MARK: Unwind to replay
    @IBAction func unwindToReplay(sender: UIStoryboardSegue) {
        
        if sender.identifier == Optional("selectAction") {
            
            self.btnPlay.selected = false
            btnPressed(self.btnPlay)
                
            return
        }
        
        
        if let vc = sender.destinationViewController as? GameViewController {
            vc.restartGame(isNew: false)
        }
    }
}
