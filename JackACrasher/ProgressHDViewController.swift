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
        
        let view = UIView(frame: self.view.bounds)
        
        view.backgroundColor = UIColor.clearColor()
        view.userInteractionEnabled = false
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let con1 = NSLayoutConstraint(item: self.view, attribute: .Leading, relatedBy: .Equal, toItem: view, attribute: .Leading, multiplier: 1.0, constant: 0)
        con1.active = true
        
        let con2 = NSLayoutConstraint(item: self.view, attribute: .Trailing, relatedBy: .Equal, toItem: view, attribute: .Trailing, multiplier: 1.0, constant: 0)
        con2.active = true
        
        let con3 = NSLayoutConstraint(item: self.view, attribute: .Bottom, relatedBy: .Equal, toItem: view, attribute: .Bottom, multiplier: 1.0, constant: 0)
        con3.active = true
        
        let con4 = NSLayoutConstraint(item: self.view, attribute: .Top, relatedBy: .Equal, toItem: view, attribute: .Top, multiplier: 1.0, constant: 0)
        con4.active = true
        
        self.view.insertSubview(view, aboveSubview: self.containerView)
        
        self.view.setNeedsLayout()
        
        self.backgroundView = view
        
    }
    
    private func appendProgressContainerView() {
        
        let size = CGSize(width: 60, height: 60)
        
        let frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        
        let view = UIView(frame:frame)
        view.backgroundColor = UIColor.blackColor()
        view.alpha = 0.8
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        //view.center = self.view.bounds.center
        view.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(view)
        self.containerView = view
        
        let const1 = view.centerXAnchor.constraintEqualToAnchor(self.view.centerXAnchor)
        const1.active = true
        
        let const2 = view.centerYAnchor.constraintEqualToAnchor(self.view.centerYAnchor)
        const2.active = true
        
        NSLayoutConstraint.activateConstraints([const1,const2])
        
        
    }
    
    
    private func appendActivityIndicator() {
        
        assert(self.containerView != nil)
        let view = UIActivityIndicatorView(activityIndicatorStyle: .White)
        view.translatesAutoresizingMaskIntoConstraints = false
        
        view.hidesWhenStopped = true
        
        view.backgroundColor = UIColor.blackColor()
        view.alpha = 0.8
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        //view.center = self.containerView.bounds.center
        
        self.containerView.addSubview(view)
        self.activityIndicator = view
        
        
        let const1 = view.centerXAnchor.constraintEqualToAnchor(self.containerView.centerXAnchor)
        
        let const2 = view.centerYAnchor.constraintEqualToAnchor(self.containerView.centerYAnchor)
        
        NSLayoutConstraint.activateConstraints([const1,const2])
        
        
        
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
