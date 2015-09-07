//
//  GameViewController.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 4/9/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit
import SpriteKit
import iAd

class GameViewController: UIViewController,GameSceneDelegate,ADInterstitialAdDelegate {
    @IBOutlet weak var btnPlay: UIButton!
    private var logicManager:GameLogicManager! = GameLogicManager.sharedInstance
    private lazy var returnPauseTransDelegate = ReturnPauseTransitionDelegate()
    private var myContext = 0
    private var adWillBeDisplayed:Bool = false
    private var interstitial:ADInterstitialAd!
    private var needToRestartGame:Bool = false
    private weak var adContainerView:UIView! = nil
    private weak var activityIndicatorView:UIActivityIndicatorView! = nil
    private weak var btnClose:UIButton! = nil
    
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
        
        var name:String! = nil
        if sender.selected {
            name = "player_btn_pause_down"
        } else {
            name = "player_btn_play_down"
        }
        
        let img = UIImage(named: name)
        sender.setImage(img, forState: UIControlState.Highlighted)
        
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
        if !GameLogicManager.sharedInstance.isAdvDisabled {
            cycleInterstitial()
            self.btnPlay.hidden = true
        }
        else {
            restartGame()
        }
    }
    
    //MARK: - Public function
    func restartGame(isNew:Bool = true) {
        
        isDisabledAdv()
        activityIndicatorView?.stopAnimating()
        adContainerView?.hidden = true
        btnClose?.hidden = true
        
        interstitial?.cancelAction()
        interstitial?.delegate = nil
        interstitial = nil
    

        self.btnPlay.hidden = false
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
            skView.presentScene(scene, transition: SKTransition.doorwayWithDuration(1))
        }
        
        
        btnPlay.superview?.bringSubviewToFront(btnPlay)
        btnPlay.selected = true
        
        waitUntilNotLoadedItem()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.adWillBeDisplayed {
            self.adWillBeDisplayed = false
            willMoveToFGPrivate()
        }
        
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
        
        let scene = self.skView.scene as? GameScene
        scene?.pauseGame(pause: true)
    }
    
    func willMoveToFG(aNotification:NSNotification) {
        willMoveToFGPrivate()
    }
    
    private func willMoveToFGPrivate() {
        var paused = false
        if self.presentedViewController == nil {
            paused = !self.btnPlay.selected
        }
        else {
            paused = true
        }
        
        if let scene = self.skView.scene as? GameScene {
            scene.pauseGame(pause: paused)
        } else {
            restartGame()
        }
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
            
            if (!GameLogicManager.sharedInstance.isAdvDisabled) {
                self.needToRestartGame = true
                self.presentInterlude()
            }
            else {
                vc.restartGame(isNew: false)
            }
        }
    }
    //MARK:Interstitial Management
    
    private func isDisabledAdv() -> Bool {
        
        if GameLogicManager.sharedInstance.isAdvDisabled{
            self.adContainerView?.removeFromSuperview()
            return true
        }
        return false
    }
    
    private func cycleInterstitial() {
        
        interstitial?.cancelAction()
        interstitial?.delegate = nil
        interstitial = nil
        
        if isDisabledAdv(){
            return
        }
        
        let ad = ADInterstitialAd()
        ad.delegate = self
        interstitial = ad
        self.interstitialPresentationPolicy = .Manual
        //UIViewController.prepareInterstitialAds()
        
        if (self.adContainerView == nil) {
            
            let containerView = UIView(frame: self.view.bounds)
            containerView.frame.origin = CGPointZero
            self.view.addSubview(containerView)
            self.adContainerView = containerView
            
            let indicator = UIActivityIndicatorView()
            indicator.hidesWhenStopped = true
            containerView.addSubview(indicator)
            
            self.activityIndicatorView = indicator
            
            
            let constLeft = NSLayoutConstraint(item: containerView, attribute: .Left, relatedBy: .Equal, toItem: self.view, attribute: .Left, multiplier: 1.0, constant: 0)
            
            let constRight = NSLayoutConstraint(item: containerView, attribute: .Right, relatedBy: .Equal, toItem: self.view, attribute: .Right, multiplier: 1.0, constant: 0)
            
            let constTop = NSLayoutConstraint(item: containerView, attribute: .Top, relatedBy: .Equal, toItem: self.view, attribute: .Top, multiplier: 1.0, constant: 0)
            
            let constBottom = NSLayoutConstraint(item: containerView, attribute: .Bottom, relatedBy: .Equal, toItem: self.view, attribute: .Bottom, multiplier: 1.0, constant: 0)
            
            self.view.addConstraints([constLeft,constRight,constTop,constBottom])
            
            
            let constrYInd = NSLayoutConstraint(item: indicator, attribute: .CenterY, relatedBy: .Equal, toItem: containerView, attribute: .CenterY, multiplier: 1.0, constant: 0)
            let constrXInd = NSLayoutConstraint(item: indicator, attribute: .CenterX, relatedBy: .Equal, toItem: containerView, attribute: .CenterX, multiplier: 1.0, constant: 0)
            
            
            containerView.addConstraints([constrXInd,constrYInd])
            
            indicator.center = CGPointMake(self.view.frame.midX, self.view.frame.midY)
            
            containerView.setTranslatesAutoresizingMaskIntoConstraints(false)
            
            indicator.startAnimating()
        }
        //TODO: Move to GameOver Screen. add timer for several seconds...
    }
    
    private func presentInterlude() {
        if let loaded = interstitial?.loaded {
            if !GameLogicManager.sharedInstance.isAdvDisabled{
                
                if let result = interstitial?.presentInView(self.adContainerView) {
                    
                    
                    if result {
                        
                            if self.btnClose == nil {
                                
                                let btn = UIButton()
                                btn.setImage(UIImage(named: "close"), forState: .Normal)
                                btn.addTarget(self, action: "closePressed:", forControlEvents: UIControlEvents.TouchUpInside)
                                let btnCenter = CGPointMake(CGRectGetWidth(self.view.bounds) * 0.9, CGRectGetHeight(self.view.bounds)*0.1)
                                btn.center = btnCenter
                                btn.bounds = CGRectMake(0, 0, btn.imageForState(.Normal)!.size.width, btn.imageForState(.Normal)!.size.height)
                                self.view.insertSubview(btn, belowSubview: self.adContainerView)
                                self.view.addSubview(btn)
                                self.view.bringSubviewToFront(btn)
                                self.btnClose = btn
                            }
                            activityIndicatorView?.stopAnimating()
                    }
                    
                    self.needToRestartGame = !result
                }
            } else {
                self.needToRestartGame = true
            }
        }
        else {
            self.needToRestartGame = true
        }
            
        if self.needToRestartGame {
            self.needToRestartGame = false
            restartGame(isNew: false)
        }
    }
    
    func closePressed(sender:UIButton!) {
        sender.removeFromSuperview()
        interstitial?.cancelAction()
        interstitialAdActionDidFinish(interstitial)
        self.activityIndicatorView?.stopAnimating()
    }
    
    //MARK: ADInterstitialAdDelegate
    
    func interstitialAd(interstitialAd: ADInterstitialAd!, didFailWithError error: NSError!) {
        println("Error interstitialAd \(error)")
        let domainFault = error.domain == ADErrorDomain
        let codeFault = error.code == ADError.InventoryUnavailable.rawValue
        
        activityIndicatorView?.stopAnimating()
        btnClose?.hidden = true
        
        if !(domainFault && codeFault) {
            cycleInterstitial()
        }
        
        self.willMoveToFGPrivate()
    }
    
    func interstitialAdDidUnload(interstitialAd: ADInterstitialAd!) {
        
        cycleInterstitial()
        
        self.willMoveToFGPrivate()
    }
    
    func interstitialAdDidLoad(interstitialAd: ADInterstitialAd!) {
        println("Did load interstitialAdDidLoad")
        
        if interstitialAd.loaded {
            presentInterlude()
        }
    }
    
    override var shouldPresentInterstitialAd:Bool {
        get { return !GameLogicManager.sharedInstance.isAdvDisabled}
    }
    
    func interstitialAdActionDidFinish(interstitialAd: ADInterstitialAd!) {
        self.willMoveToFGPrivate()
    }
}
