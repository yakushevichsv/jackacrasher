//
//  ProgressHDViewController.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 2/28/16.
//  Copyright © 2016 Siarhei Yakushevich. All rights reserved.
//

import UIKit

class ProgressHDViewController: UIViewController {

    weak var containerView: UIView!
    weak var activityIndicator:UIActivityIndicatorView!
    weak var backgroundView: UIView!
    
    static var appearanceDuration:NSTimeInterval = 0.5
    static var dissapperanceDuration:NSTimeInterval = 0.2
    
    var hasBackgroundView:Bool = false {
        didSet{
            if let ai = self.activityIndicator {
                if (ai.isAnimating()){
                    appendBGView()
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
      
        self.containerView?.removeFromSuperview()
        self.backgroundView?.removeFromSuperview()
        self.activityIndicator?.removeFromSuperview()
        
        self.containerView = nil
        self.backgroundView = nil
        self.activityIndicator = nil
    }
    
    private func appendViewsOnNeed() {
     
        if self.containerView == nil {
            appendProgressContainerView()
        }
        
        if (activityIndicator == nil) {
            appendActivityIndicator()
        }
        
        if (hasBackgroundView) {
            appendBGView()
        }
    }
    
    private func appendBGView() {
        
        let view1 = UIView(frame: self.view.bounds)
        
        view1.backgroundColor = UIColor.clearColor()
        view1.userInteractionEnabled = false
        view1.translatesAutoresizingMaskIntoConstraints = false
        
        
        self.view.insertSubview(view1, aboveSubview: self.containerView)
        self.backgroundView = view1
        
        
        if (!view1.translatesAutoresizingMaskIntoConstraints) {
            let con1 = NSLayoutConstraint(item: self.view, attribute: .Leading, relatedBy: .Equal, toItem: view1, attribute: .Leading, multiplier: 1.0, constant: 0)
            con1.active = true
            
            let con2 = NSLayoutConstraint(item: self.view, attribute: .Trailing, relatedBy: .Equal, toItem: view1, attribute: .Trailing, multiplier: 1.0, constant: 0)
            con2.active = true
            
            let con3 = NSLayoutConstraint(item: self.view, attribute: .Bottom, relatedBy: .Equal, toItem: view1, attribute: .Bottom, multiplier: 1.0, constant: 0)
            con3.active = true
            
            let con4 = NSLayoutConstraint(item: self.view, attribute: .Top, relatedBy: .Equal, toItem: view1, attribute: .Top, multiplier: 1.0, constant: 0)
            con4.active = true
        
            view1.superview?.setNeedsLayout()
        }
        else {
            
            view1.autoresizingMask = UIViewAutoresizing(rawValue: UIViewAutoresizing.FlexibleWidth.rawValue | UIViewAutoresizing.FlexibleHeight.rawValue )
        }
        
        
    }
    
    private func appendProgressContainerView() {
        
        let size = CGSize(width: 60, height: 60)
        
        let frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        
        let view1 = UIView(frame:frame)
        view1.backgroundColor = UIColor.blackColor()
        view1.alpha = 0.8
        view1.layer.cornerRadius = 10
        view1.layer.masksToBounds = true
        assert(!CGRectEqualToRect(self.view.bounds, CGRectZero))
        view1.center = self.view.bounds.center
        view1.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(view1)
        self.containerView = view1
        
        if (!view1.translatesAutoresizingMaskIntoConstraints) {
            let const1 = view1.centerXAnchor.constraintEqualToAnchor(self.view.centerXAnchor)
        
            let const2 = view1.centerYAnchor.constraintEqualToAnchor(self.view.centerYAnchor)
        
            let const3 = view1.widthAnchor.constraintEqualToConstant(size.width)
            
            let const4 = view1.heightAnchor.constraintEqualToConstant(size.height)
            
            NSLayoutConstraint.activateConstraints([const1,const2,const3,const4])
            
            
        }
        else {
            view1.autoresizingMask = UIViewAutoresizing(rawValue: UIViewAutoresizing.FlexibleLeftMargin.rawValue | UIViewAutoresizing.FlexibleRightMargin.rawValue |
                UIViewAutoresizing.FlexibleTopMargin.rawValue | UIViewAutoresizing.FlexibleBottomMargin.rawValue )
        }
        
    }
    
    
    private func appendActivityIndicator() {
        
        assert(self.containerView != nil)
        let view1 = UIActivityIndicatorView(activityIndicatorStyle: .White)
        view1.translatesAutoresizingMaskIntoConstraints = false
        
        view1.hidesWhenStopped = true
        
        view1.backgroundColor = UIColor.blackColor()
        view1.alpha = 0.8
        view1.layer.cornerRadius = 10
        view1.layer.masksToBounds = true
        view1.center = self.containerView.bounds.center
        assert(!CGRectEqualToRect(self.containerView.frame, CGRectZero))
        
        self.containerView.addSubview(view1)
        self.activityIndicator = view1
        
        
        if (!view1.translatesAutoresizingMaskIntoConstraints) {
            let const1 = view1.centerXAnchor.constraintEqualToAnchor(self.containerView.centerXAnchor)
            
            let const2 = view1.centerYAnchor.constraintEqualToAnchor(self.containerView.centerYAnchor)
            
            NSLayoutConstraint.activateConstraints([const1,const2])
            
            self.containerView.layoutIfNeeded()
        }
        else {
            view1.autoresizingMask = UIViewAutoresizing(rawValue: UIViewAutoresizing.FlexibleLeftMargin.rawValue | UIViewAutoresizing.FlexibleRightMargin.rawValue |
                UIViewAutoresizing.FlexibleTopMargin.rawValue | UIViewAutoresizing.FlexibleBottomMargin.rawValue )
        }
        
        
        
    }
    

    func displayProgress(animated:Bool = false) {
        
        print("displayProgress")
        self.appendViewsOnNeed()
        
        self.containerView.hidden = true
        
        self.backgroundView?.hidden = true
        
        
        if (animated) {
            UIView.animateWithDuration(ProgressHDViewController.appearanceDuration, animations: { [weak self] () -> Void in
                self?.containerView?.hidden = false
                self?.backgroundView?.hidden = false
                
                }, completion: { [weak self] (finished) -> Void in
                    self?.activityIndicator?.startAnimating()
            })
        }
        else {
            self.containerView.hidden = false
            self.activityIndicator.startAnimating()
            
            self.backgroundView?.hidden = false
        }
    }
    
    func hideProgress(animated:Bool = false ) {
        
        return
        
        if self.containerView == nil || self.containerView.hidden == true {
            return
        }
    
        print("hideProgress")
        
        if (animated) {
            UIView.animateWithDuration(ProgressHDViewController.dissapperanceDuration, animations: { [weak self] () -> Void in
                self?.containerView?.hidden = true
                self?.backgroundView?.hidden = true
                
                }, completion: { [weak self] (finished) -> Void in
                    self?.activityIndicator?.stopAnimating()
                })
        }
        else {
            self.containerView.hidden = true
            self.activityIndicator.stopAnimating()
            
            self.backgroundView?.hidden = true
        }
        
    }
    
}
