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
    
    
    @IBOutlet weak var lConstraint:NSLayoutConstraint!
    @IBOutlet weak var rConstraint:NSLayoutConstraint!
    @IBOutlet weak var bConstraint:NSLayoutConstraint!
    @IBOutlet weak var tBConstraint:NSLayoutConstraint!

    
    private var lConstrValue:CGFloat = 0
    private var rConstrValue:CGFloat = 0
    private var bConstrValue:CGFloat = 0
    private var tBConstrValue:CGFloat = 0
    
    
    private var custPushSegue:UIStoryboardSegue!
    
    private func storeConstraints() {
        self.lConstrValue  = self.lConstraint.constant
        self.rConstrValue  = self.rConstraint.constant
        self.bConstrValue  = self.bConstraint.constant
        self.tBConstrValue = self.tBConstraint.constant
    }
    
    private func restoreConstraints() {
        self.lConstraint.constant  = self.lConstrValue
        self.rConstraint.constant  = self.rConstrValue
        self.bConstraint.constant  = self.bConstrValue
        self.tBConstraint.constant = self.tBConstrValue
    }
    
    private func shiftOutButtons() {
        
        shiftXButton(self.btnCompany, isLeft: true)
        shiftXButton(self.btnStrategy, isLeft: false)
        shiftYButton(self.btnHelp, isUp: false)
    }
    
    private func shiftInButtons() {
        
        shiftXButton(self.btnCompany, isLeft: false)
        shiftXButton(self.btnStrategy, isLeft: true)
        shiftYButton(self.btnHelp, isUp: true)
    }
    
    private func shiftXButton(button:UIButton!, isLeft:Bool) {
        
        button.frame = CGRectOffset(button.frame, (isLeft ? -1 : 1 ) *  CGRectGetWidth(button.frame), 0)
        
    }
    
    
    private func shiftYButton(button:UIButton!, isUp:Bool) {
        
        button.frame = CGRectOffset(button.frame, 0, (isUp ? 1 : -1) * CGRectGetHeight(button.frame) )
    }
    
    
    private func moveOutOfScreenButtons() {
        
        self.lConstraint.constant = CGRectGetMidX(self.view.bounds) + CGRectGetWidth(self.btnCompany.bounds)
        self.rConstraint.constant = CGRectGetMidX(self.view.bounds) + CGRectGetWidth(self.btnStrategy.bounds)
        self.bConstraint.constant = -CGRectGetHeight(self.btnHelp.bounds)
        self.tBConstraint.constant = self.bConstrValue + self.tBConstrValue
    }
    
    private func prepareCustomPushSegue() {
        
        let vc = self.storyboard?.instantiateViewControllerWithIdentifier("GameViewControllerID") as? GameViewController
        
        custPushSegue = UIStoryboardSegue(identifier: "startSurvival", source: self, destination: vc!) { () -> Void in
          println("Push view")
          self.navigationController?.pushViewController(self.custPushSegue.destinationViewController as! UIViewController, animated: false)
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
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
        
        UIView.animateWithDuration(4, delay: 0.0, usingSpringWithDamping: 0.7, initialSpringVelocity: 8, options: .CurveEaseOut, animations: { () -> Void  in
                self.shiftInButtons()
            }, completion: { (finished) -> Void in
                
                
                
                //self.custPushSegue.perform()
        })
        
        self.prepareCustomPushSegue()
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier {
            if (identifier == "startSurvival") {
                
            }
        }
    }
    
    
    @IBAction func btnPressed(sender: UIButton) {
        if sender == self.btnStrategy {
            self.custPushSegue.perform()
            sender.enabled = false
        }
    }
    
}
