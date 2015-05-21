//
//  GameMainViewController.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 5/10/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit

class GameMainViewController: UIViewController {

    internal var needToDisplayAnimation:Bool = false
    
    @IBOutlet weak var btnCompany:UIButton!
    @IBOutlet weak var btnStrategy:UIButton!
    @IBOutlet weak var btnHelp:UIButton!
    @IBOutlet weak var btnGameCenter:UIButton!
    
    private var custPushSegue:UIStoryboardSegue!

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
    
    
    private func prepareCustomPushSegue() {
        
        let vc = self.storyboard?.instantiateViewControllerWithIdentifier("GameViewControllerID") as? GameViewController
        
        custPushSegue = UIStoryboardSegue(identifier: "startSurvival", source: self, destination: vc!) { () -> Void in
          println("Push view")
         GameLogicManager.sharedInstance.selectSurvival()
          self.navigationController?.pushViewController(self.custPushSegue.destinationViewController as! UIViewController, animated: false)
        }
        
    }

    
    private func disableButtons() {
        setButtonsState(false)
    }
    
    private func enableButtons() {
        setButtonsState(true)
    }
    
    private func setButtonsState(enabled:Bool) {
        for btn in [self.btnCompany,self.btnStrategy,self.btnHelp,self.btnGameCenter] {
            btn.enabled = enabled
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if (!self.needToDisplayAnimation) {
            self.scheduleAnimation()
            self.needToDisplayAnimation = true
        }
    }
    
    private func scheduleAnimation() {
        
        shiftOutButtons()
        disableButtons()
        
        UIView.animateWithDuration(2, delay: 0.0, usingSpringWithDamping: 0.7, initialSpringVelocity: 8, options: .CurveEaseOut, animations: { () -> Void  in
                self.shiftInButtons()
            }, completion: { (finished) -> Void in
                self.enableButtons()
        })
        
        self.prepareCustomPushSegue()
        
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
            self.custPushSegue.perform()
            sender.enabled = true
        } else if (sender == self.btnGameCenter) {
            ///eeee Add here logic...
        }
    }
    
}
