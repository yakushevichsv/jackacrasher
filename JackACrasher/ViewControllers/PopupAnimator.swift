	//
//  PopupAnimator.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 6/12/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit

class PopupAnimator: NSObject, UIViewControllerAnimatedTransitioning {
   
    internal let isPresenting:Bool
    internal let isPortrait:Bool
    internal let rect:CGRect
    
    var initialFrame:CGRect = CGRectZero
    
    init(rect:CGRect, portrait isPortrait:Bool, isPresenting:Bool = false) {
        self.isPresenting = isPresenting
        self.isPortrait = isPortrait
        self.rect = rect
        super.init()
    }
    
    var isInitialFrameSet:Bool {
        return !CGRectEqualToRect(CGRectZero, self.initialFrame)
    }
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning) -> NSTimeInterval {
        return NSTimeInterval(1)
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
    
        let offsetSign:CGFloat = self.isPresenting ? 1 : -1
        let value:CGFloat = !self.isPortrait ? CGRectGetHeight(rect) : CGRectGetWidth(rect)
        
        let fromView = transitionContext.viewForKey(UITransitionContextFromViewKey)
        let toView = transitionContext.viewForKey(UITransitionContextToViewKey)
        
        let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)
        
        let toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)
        
        if (!isPresenting) {
        
            if let fromViewInternal = fromVC?.view {
                
                fromVC?.view.userInteractionEnabled = false
                
                transitionContext.containerView().addSubview(fromViewInternal)
                
                var transform:CGAffineTransform
                
                if isInitialFrameSet {
                    
                    let toViewFrame = self.initialFrame
                    
                    let scale = CGAffineTransformMakeScale(CGRectGetWidth(toViewFrame)/CGRectGetWidth(fromViewInternal.frame), CGRectGetHeight(toViewFrame)/CGRectGetHeight(fromViewInternal.frame))
                    
                    let translation = CGAffineTransformMakeTranslation(toViewFrame.origin.x - fromViewInternal.frame.origin.x, toViewFrame.origin.y - fromViewInternal.frame.origin.y)
                    
                    transform = CGAffineTransformConcat(scale, translation)
                }
                else {
                    transform = CGAffineTransformMakeScale(1e-1, 1e-1)
                }

                
                
                UIView.animateWithDuration(self.transitionDuration(transitionContext), animations: { () -> Void in
                    fromViewInternal.transform = transform
                    
                    }) { (flag) -> Void in
                        transitionContext.completeTransition(true)
                        fromViewInternal.removeFromSuperview()
                        toVC?.view.userInteractionEnabled = true
                }
                
            }
            
            return
        }
        
        
        let fFrame = transitionContext.finalFrameForViewController(toVC!)
        
        let sFrame = transitionContext.initialFrameForViewController(fromVC!)
        
        println("From VC Initial \(transitionContext.initialFrameForViewController(fromVC!)) Final \(transitionContext.finalFrameForViewController(fromVC!)) \n From VC Final \(transitionContext.initialFrameForViewController(toVC!)) Final \(transitionContext.finalFrameForViewController(toVC!))")
        
        
        if let toViewInternal = toVC?.view {
            transitionContext.containerView().addSubview(toViewInternal)
            
            fromVC?.view.userInteractionEnabled = false
            
            let tW = self.isPortrait ? CGRectGetHeight(rect) : CGRectGetWidth(rect)
            let tH =  !self.isPortrait ? CGRectGetHeight(rect) : CGRectGetWidth(rect)
            
            let w  = round(0.6*tW)
            let h  = round(0.75*tH)
            let oX = round(0.2*tW)
            let oY = round(0.2*tH)
            
            var toViewFrame:CGRect
            
            if (self.isPortrait) {
                toViewFrame = CGRectMake(oY, oX, h, w)
            }
            else {
                toViewFrame = CGRectMake(oX, oY, w, h)
            }
            
            toViewInternal.frame = toViewFrame
            
            var transform:CGAffineTransform
            
            
            let scale = CGAffineTransformMakeScale(CGRectGetWidth(toViewFrame)/CGRectGetWidth(self.initialFrame), CGRectGetHeight(toViewFrame)/CGRectGetHeight(self.initialFrame))
            
            if isInitialFrameSet {
                toViewInternal.frame = self.initialFrame
                //toViewInternal.frame.origin = self.initialFrame.origin
                toViewInternal.setNeedsLayout()
                /*let translation = CGAffineTransformMakeTranslation(toViewFrame.origin.x - self.initialFrame.origin.x, toViewFrame.origin.y - self.initialFrame.origin.y)
                
                transform = CGAffineTransformConcat(scale, translation)*/
                
                //toViewInternal.transform = scale
            }
            else {
                transform = CGAffineTransformMakeScale(1e-1, 1e-1)
            }
            
            UIView.animateWithDuration(self.transitionDuration(transitionContext), animations: { () -> Void in
                    //toViewInternal.transform = transform
                    //toViewInternal.frame = toViewFrame
                    toViewInternal.frame = toViewFrame
                    toViewInternal.transform = CGAffineTransformIdentity
                
                }) { (flag) -> Void in
                    
                    transitionContext.completeTransition(true)
                    toViewInternal.setNeedsLayout()
            }
        }
        
        
    }
}
