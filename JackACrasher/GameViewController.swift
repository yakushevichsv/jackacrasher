//
//  GameViewController.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 4/9/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit
import SpriteKit
#if os(iOS)
import ReplayKit
#endif

class GameViewController: UIViewController,GameSceneDelegate {
    @IBOutlet weak var btnPlay: UIButton!
    @IBOutlet weak var btnRecord: UIButton!
    
    private var logicManager:GameLogicManager! = GameLogicManager.sharedInstance
    private lazy var returnPauseTransDelegate = ReturnPauseTransitionDelegate()
    
    private var myContext = 0
    
    private var previewVC : RPPreviewViewController! = nil
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        logicManager.addObserver(self, forKeyPath: "isLoading", options: .New, context: &myContext)
        RPScreenRecorder.sharedRecorder().available
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
    
    @IBAction func recordingPressed(sender : UIButton) {
       sender.selected = !sender.selected
        
        if (sender.selected) {
            sender.enabled = false
            NSObject.cancelPreviousPerformRequestsWithTarget(self, selector: "hideScreenRecording", object: nil)
            
            startScreenRecording { [unowned self] () -> Void in
                self.btnRecord.enabled = true
                self.performSelector("terminateRecording", withObject: nil, afterDelay: 60)
            }
        }
        else {
            NSObject.cancelPreviousPerformRequestsWithTarget(self, selector: "terminateRecording", object: nil)
            terminateRecording()
        }
    }

    func terminateRecording() {
        stopScreenRecordingWithHandler { [unowned self]   () -> Void in
            self.btnRecord.hidden = true
            self.btnRecord.selected = false
            
            //TODO: add logic here for displaying preview action... Discard, or store....
        }
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
        
        let recorder = RPScreenRecorder.sharedRecorder()
        recorder.delegate = self
        self.screenRecorderDidChangeAvailability(recorder)
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
        
        restartGame()
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
            self.logicManager.setScreenRecordingValue(0)
        }
    }
    
    //MARK: GameSceneDelegate
    
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
    
    func gameSceneHasScore(scene: GameScene, totalScore: UInt64) {
        
        guard RPScreenRecorder.sharedRecorder().available else {
            return
        }
        
        if !self.btnRecord.hidden {
            return
        }
        
        let scoreDiff = totalScore - self.logicManager.oldScreenRecordingValue
        
        if scoreDiff > 1000 {
            
            if self.btnRecord.hidden {
                self.btnRecord.hidden = false
                self.btnRecord.selected = false
                
                self.performSelector("hideScreenRecording", withObject:  nil, afterDelay: 60*2)
            }
            
            self.logicManager.setScreenRecordingValue(totalScore)
        }
    }
    
    func hideScreenRecording() {
        self.btnRecord.hidden = true
        if let scene = self.skView.scene as? GameScene {
            self.logicManager.setScreenRecordingValue(scene.totalGameScore)
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

//MARK: Replay Kit
extension GameViewController : RPScreenRecorderDelegate, RPPreviewViewControllerDelegate {
    
    func startScreenRecording(handler:(() -> Void)) {
        // Do nothing if screen recording hasn't been enabled.
        guard RPScreenRecorder.sharedRecorder().available else { return }
        
        let sharedRecorder = RPScreenRecorder.sharedRecorder()
        
        // Register as the recorder's delegate to handle errors.
        sharedRecorder.delegate = self
        
        sharedRecorder.startRecordingWithMicrophoneEnabled(true) { error in
            if let error = error {
                self.alertWithTitle("Error", message: error.localizedDescription)
            }
            else {
                handler()
            }
        }
    }
    
    
    func stopScreenRecordingWithHandler(handler:(() -> Void)) {
        let sharedRecorder = RPScreenRecorder.sharedRecorder()
        
        sharedRecorder.stopRecordingWithHandler { (previewViewController: RPPreviewViewController?, error: NSError?) in
            if let error = error {
                // If an error has occurred, display an alert to the user.
                self.alertWithTitle("Error", message: error.localizedDescription)
                return
            }
            
            if let previewViewController = previewViewController {
                // Set delegate to handle view controller dismissal.
                previewViewController.previewControllerDelegate = self
                
                /*
                Keep a reference to the `previewViewController` to
                present when the user presses on preview button.
                */
                self.previewVC = previewViewController
            }
            
            handler()
        }
    }
    
    func discardRecording() {
        // When we no longer need the `previewViewController`, tell `ReplayKit` to discard the recording and nil out our reference
        RPScreenRecorder.sharedRecorder().discardRecordingWithHandler {
            self.previewVC = nil
        }
    }
    
    func displayRecordedContent() {
        guard let previewViewController = self.previewVC else { fatalError("The user requested playback, but a valid preview controller does not exist.") }
        
        // `RPPreviewViewController` only supports full screen modal presentation.
        previewViewController.modalPresentationStyle = UIModalPresentationStyle.FullScreen
        
        self.presentViewController(previewViewController, animated: true, completion:nil)
    }
    
    // MARK: RPScreenRecorderDelegate
    
    func screenRecorder(screenRecorder: RPScreenRecorder, didStopRecordingWithError error: NSError, previewViewController: RPPreviewViewController?) {
        
        // Display the error the user to alert them that the recording failed.
        self.alertWithTitle("Error", message: error.localizedDescription)
        
        
        /// Hold onto a reference of the `previewViewController` if not nil.
        if previewViewController != nil {
            self.previewVC = previewViewController
        }
    }
    
    func screenRecorderDidChangeAvailability(screenRecorder: RPScreenRecorder) {
        
        if !screenRecorder.available {
            self.btnRecord.hidden = true
            self.btnRecord.selected = false
        }
    }
    
    // MARK: RPPreviewViewControllerDelegate
    
    func previewControllerDidFinish(previewController: RPPreviewViewController) {
        self.previewVC?.dismissViewControllerAnimated(true, completion: nil)
    }
}


