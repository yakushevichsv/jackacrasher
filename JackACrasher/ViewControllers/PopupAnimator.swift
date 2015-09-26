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
    
    init(rect:CGRect, portrait isPortrait:Bool, isPresenting:Bool = false) {
        self.isPresenting = isPresenting
        self.isPortrait = isPortrait
        self.rect = rect
        super.init()
    }
    
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return NSTimeInterval(1)
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
    
        let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)
        
        let toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)
        
        if (!isPresenting) {
        
            if let fromViewInternal = fromVC?.view {
                
                fromVC?.view.userInteractionEnabled = false
                
                transitionContext.containerView()!.addSubview(fromViewInternal)
                
                UIView.animateWithDuration(self.transitionDuration(transitionContext), animations: { () -> Void in
                    fromViewInternal.transform = CGAffineTransformMakeScale(1e-1, 1e-1)
                    
                    }) { (flag) -> Void in
                        transitionContext.completeTransition(true)
                        fromViewInternal.removeFromSuperview()
                        toVC?.view.userInteractionEnabled = true
                }
                
            }
            
            return
        }
        
        
        print("From VC Initial \(transitionContext.initialFrameForViewController(fromVC!)) Final \(transitionContext.finalFrameForViewController(fromVC!)) \n From VC Final \(transitionContext.initialFrameForViewController(toVC!)) Final \(transitionContext.finalFrameForViewController(toVC!))")
        
        
        if let toViewInternal = toVC?.view {
            transitionContext.containerView()!.addSubview(toViewInternal)
            
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
            toViewInternal.transform = CGAffineTransformMakeScale(1e-1, 1e-1)
            
            
            UIView.animateWithDuration(self.transitionDuration(transitionContext), animations: { () -> Void in
                toViewInternal.transform = CGAffineTransformIdentity
                }) { (flag) -> Void in
                    transitionContext.completeTransition(true)
            }
        }
        
        
    }
}
