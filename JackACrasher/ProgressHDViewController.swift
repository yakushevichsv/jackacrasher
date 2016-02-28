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
        
        
        self.view.addConstraint(NSLayoutConstraint(item: self.view, attribute: .Leading, relatedBy: .Equal, toItem: view, attribute: .Leading, multiplier: 1.0, constant: 0))
        
        self.view.addConstraint(NSLayoutConstraint(item: self.view, attribute: .Trailing, relatedBy: .Equal, toItem: view, attribute: .Trailing, multiplier: 1.0, constant: 0))
        
        self.view.addConstraint(NSLayoutConstraint(item: self.view, attribute: .Bottom, relatedBy: .Equal, toItem: view, attribute: .Bottom, multiplier: 1.0, constant: 0))
        
        self.view.addConstraint(NSLayoutConstraint(item: self.view, attribute: .Top, relatedBy: .Equal, toItem: view, attribute: .Top, multiplier: 1.0, constant: 0))
        
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
        view.center = self.view.bounds.center
        
        self.view.addSubview(view)
        
        self.view.addConstraint(NSLayoutConstraint(item: view, attribute: .CenterX, relatedBy: .Equal, toItem: self.view, attribute: .CenterX, multiplier: 0.5, constant: 0))
        
        self.view.addConstraint(NSLayoutConstraint(item: view, attribute: .CenterY, relatedBy: .Equal, toItem: self.view, attribute: .CenterY, multiplier: 0.5, constant: 0))
        
        view.superview!.setNeedsLayout()
        
        self.containerView = view
    }
    
    
    private func appendActivityIndicator() {
        
        
        let view = UIActivityIndicatorView(activityIndicatorStyle: .White)
        view.hidesWhenStopped = true
        
        view.backgroundColor = UIColor.blackColor()
        view.alpha = 0.8
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        view.center = self.containerView.bounds.center
        
        self.containerView.addSubview(view)
        
        
        
        self.containerView.addConstraint(NSLayoutConstraint(item: view, attribute: .CenterX, relatedBy: .Equal, toItem: self.containerView, attribute: .CenterX, multiplier: 0.5, constant: 0))
        
        self.containerView.addConstraint(NSLayoutConstraint(item: view, attribute: .CenterY, relatedBy: .Equal, toItem: self.containerView, attribute: .CenterY, multiplier: 0.5, constant: 0))
        
        view.superview!.setNeedsLayout()
        
        
        self.activityIndicator = view
    }
    

    func displayProgress(animated:Bool = false) {
        
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
