//
//  GameMainViewController.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 5/10/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit
import GameKit

class GameMainViewController: UIViewController {

    internal var needToDisplayAnimation:Bool = false
    private let gcManager = GameCenterManager.sharedInstance
    private var needToAuthGC:Bool = true
    
    @IBOutlet weak var btnCompany:UIButton!
    @IBOutlet weak var btnStrategy:UIButton!
    @IBOutlet weak var btnHelp:UIButton!
    @IBOutlet weak var btnGameCenter:UIButton!

    
    
    private func shiftOutButtons() {
        
        shiftXButton(self.btnCompany, isLeft: true)
        shiftXButton(self.btnStrategy, isLeft: false)
        shiftYButton(self.btnHelp, isUp: false)
        shiftYButton(self.btnGameCenter, isUp: true)
    }
    
    private func shiftInButtons() {
        
        shiftXButton(self.btnCompany, isLeft: false)
        shiftXButton(self.btnStrategy, isLeft: true)
        shiftYButton(self.btnHelp, isUp: true)
        shiftYButton(self.btnGameCenter, isUp: false)
    }
    
    private func shiftXButton(button:UIButton!, isLeft:Bool) {
        
        button.frame = CGRectOffset(button.frame, (isLeft ? -1 : 1 ) *  CGRectGetWidth(button.frame), 0)
    }
    
    private func shiftYButton(button:UIButton!, isUp:Bool) {
        
        button.frame = CGRectOffset(button.frame, 0, (isUp ? 1 : -1) * CGRectGetHeight(button.frame) )
    }
    
    private func disableButtons() {
        setButtonsState(false)
    }
    
    private func enableButtons() {
        setButtonsState(true)
        self.correctGameCenterButtonState()
    }
    
    private func correctGameCenterButtonState() {
        if (self.btnGameCenter == nil) { return }
        self.btnGameCenter.enabled = self.gcManager.isLocalUserAuthentificated
    }
    
    private func setButtonsState(enabled:Bool) {
        for btn in [self.btnCompany,self.btnStrategy,self.btnHelp,self.btnGameCenter] {
            btn.enabled = enabled
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        authDidChange(nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "authDidChange:", name: GKPlayerAuthenticationDidChangeNotificationName, object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.correctGameCenterButtonState()
        
        if (!self.needToDisplayAnimation) {
            self.scheduleAnimation()
            self.needToDisplayAnimation = true
        }
        
        if (!self.gcManager.isLocalUserAuthentificated) {
            
            if let error = self.gcManager.lastError {
                
                if error.domain == GKErrorDomain  && error.code == GKErrorCode.UserDenied.rawValue {
                    needToAuthPlayer()
                }
            }
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "needToAuthPlayer", name: kGameCenterManagerNeedToAuthPlayer, object: self.gcManager)
        
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: kGameCenterManagerNeedToAuthPlayer, object: self.gcManager)
    }
    
    //MARK: Authefication's related methods
    func authDidChange(notification:NSNotification!) {
        self.needToAuthGC = !self.gcManager.isLocalUserAuthentificated
        self.correctGameCenterButtonState()
    }
    
    func needToAuthPlayer() {
        if self.gcManager.isLocalUserAuthentificated {
            return
        }
        else if (self.needToAuthGC){
            self.needToAuthGC = false
            let alertVC = UIAlertController(title: "Game Center is disabled", message: "To participate in Leaderboard\nPlease enable it", preferredStyle: .Alert)
            
            self.presentViewController(alertVC, animated: true, completion: nil)
            
            let delayTime = dispatch_time(DISPATCH_TIME_NOW,
                Int64(3 * Double(NSEC_PER_SEC)))
            
            dispatch_after(delayTime, dispatch_get_main_queue(), { () -> Void in
                alertVC.dismissViewControllerAnimated(true, completion: nil)
            })
        }
    }
    
    //MARK: -
    private func scheduleAnimation() {
        
        shiftOutButtons()
        disableButtons()
        var didLoadAssets:Bool = false
        var didAnimated:Bool = false
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), { () -> Void in
           GameScene.loadAssets()
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if (didAnimated) {
                    self.enableButtons()
                }
                else {
                    didLoadAssets = true
                }
            });
        });
        
        UIView.animateWithDuration(2, delay: 0.0, usingSpringWithDamping: 0.7, initialSpringVelocity: 8, options: .CurveEaseOut, animations: { () -> Void  in
                self.shiftInButtons()
            }, completion: { (finished) -> Void in
                if (didLoadAssets) {
                    self.enableButtons()
                }
                else {
                    didAnimated = true
                }
        })
    }
    
    //MARK: eee  Why it is not called?
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier {
            if (identifier == "startSurvival") {
                GameLogicManager.sharedInstance.selectSurvival()
            }
        }
    }
    
    
    @IBAction func btnPressed(sender: UIButton) {
        if sender == self.btnStrategy {
            playBtnPressedSound()
            self.performSegueWithIdentifier("startSurvival", sender: self)
            sender.enabled = true
        } else if (sender == self.btnGameCenter) {
            playBtnPressedSound()
            GameCenterManager.sharedInstance.showGKGameCenterViewController(self)
        }
    }
    
    func playBtnPressedSound() {
        SoundManager.sharedInstance.playSoundEffect("button_press.wav")
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
}
