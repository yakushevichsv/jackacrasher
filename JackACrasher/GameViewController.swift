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

    private var startLayer:JCStartLayer? = nil
    private var displStartLayerAnim = false
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        logicManager.addObserver(self, forKeyPath: "isLoading", options: .New, context: &myContext)
    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        
        if context == &myContext {
            if let obj = change?[NSKeyValueChangeNewKey] {
            
                let isLoading:Bool = obj.boolValue
            
                if (!isLoading) {
                    self.waitUntilNotLoadedItem()
                }
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
        
        var name:String! = nil
        if sender.selected {
            name = "player_btn_pause_down"
        } else {
            name = "player_btn_play_down"
        }
        
        let img = UIImage(named: name)
        sender.setImage(img, forState: UIControlState.Highlighted)
        
        if let scene = skView.scene as? GameScene {
            scene.pauseGame(!sender.selected)
        }
    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        
        if identifier == "selectAction" {
            
            return !self.btnPlay.selected
        }
        
        return super.shouldPerformSegueWithIdentifier(identifier, sender: sender)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //restartGame()
        
        correctFontOfChildViews(self.view)

    }
    
    //MARK: - Public function
    func restartGame(isNew:Bool = true) {
        
        self.btnPlay.hidden = false
        // Configure the view.
        let skView = self.skView
        let scene = GameScene(size: skView.bounds.size)
        
        skView.showsFPS = false
        skView.showsNodeCount = false
        /* Sprite Kit applies additional optimizations to improve rendering performance */
        skView.ignoresSiblingOrder = false
        
        /* Set the scale mode to scale to fit the window */
        scene.scaleMode = .AspectFill
        
        scene.gameSceneDelegate = self
        if (isNew) {
            skView.presentScene(scene)
        }
        else {
            skView.presentScene(scene, transition: SKTransition.doorwayWithDuration(1))
        }
        
        
        btnPlay.superview?.bringSubviewToFront(btnPlay)
        btnPlay.selected = true
        
        waitUntilNotLoadedItem()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didMoveToBG:", name: UIApplicationWillResignActiveNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "willMoveToFG:", name: UIApplicationDidBecomeActiveNotification, object: nil)
        
        performStartLayerAnimation()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
        
    }
    
    func didMoveToBG(aNotification:NSNotification) {
        
        didMoveToBGPrivate()
    }
    
    func didMoveToBGPrivate() {
        let scene = self.skView.scene as? GameScene
        scene?.pauseGame(true)
    }
    
    func willMoveToFG(aNotification:NSNotification) {
        willMoveToFGPrivate()
    }
    
    private func willMoveToFGPrivate() {
        
        self.btnPlay.hidden = false
        
        let paused = !self.btnPlay.selected
        
        if let scene = self.skView.scene as? GameScene {
            scene.pauseGame(paused)
            
        } else {
            restartGame()
        }
    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Landscape
    }

    

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if let identifier = segue.identifier {
            if identifier == "gameOver" {
                SoundManager.sharedInstance.cancelPlayingBGMusic()
                let dVC = segue.destinationViewController as! GameOverViewController
                 dVC.didWin = false
                
            } else if identifier == "selectAction" {
                
                let dVC = segue.destinationViewController as! PauseReturnViewController
                
                dVC.exitCompletion = {
                    [unowned self]
                    ()->Void in
                    
                    if let scene = self.skView.scene as? GameScene {
                        scene.willTerminateApp()
                    }
                }
                
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
        
        if sender.identifier == Optional("selectActionUnwindToReplay") {
            
            self.btnPlay.selected = false
            btnPressed(self.btnPlay)
                
            return
        }
        
        
        if let vc = sender.destinationViewController as? GameViewController {
            
            vc.restartGame(false)
            
        }
    }
}

//MARK: CA Start Layer methods
extension GameViewController {
    
    private func performStartLayerAnimation() {
        
        if (!self.displStartLayerAnim)
        {
            let boxSize:CGFloat = 200
            
            let center = self.view.frame.center
            let rect = CGRect(origin: center - CGPointMake(boxSize, boxSize)*0.5, size: CGSizeMake(boxSize, boxSize))
            
            self.startLayer = JCStartLayer(midRect:rect)
            //self.startLayer?.fillColor = self.view.layer.backgroundColor
            self.startLayer?.frame = self.view.layer.bounds
            
            print("Mid rect \(rect)\n Frame \(self.startLayer!.frame)")
            
            self.view.layer.addSublayer(self.startLayer!)
            
            if let duration = self.startLayer?.animate()
            {
                print("PerformStartLayerAnimation Duration \(duration)")
                NSTimer.scheduledTimerWithTimeInterval(duration, target: self,
                    selector: "removeStartLayer",
                    userInfo: nil, repeats: false)
            }
            self.displStartLayerAnim = true
        }
    }
    
    func removeStartLayer() {
        self.startLayer?.removeAllAnimations()
        self.startLayer?.removeFromSuperlayer()
        self.startLayer = nil
        
        restartGame()
    }
}

