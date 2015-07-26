//
//  ReturnPausePopUpAnimator.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 7/26/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit

class ReturnPausePopUpAnimator: PopupAnimator {
   
    override func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
    
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
                
                let fFrame = CGRectOffset(fromViewInternal.frame, 0, CGRectGetMaxY(fromViewInternal.frame))
                UIView.animateWithDuration(self.transitionDuration(transitionContext), animations: { () -> Void in
                    fromViewInternal.frame = fFrame
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
            
            let w  = round(0.5*tW)
            let h  = round(0.5*tH)
            let oX = round(0.25*tW)
            let oY = round(0.25*tH)
            
            var toViewFrame:CGRect
            
            if (self.isPortrait) {
                toViewFrame = CGRectMake(oY, oX, h, w)
            }
            else {
                toViewFrame = CGRectMake(oX, oY, w, h)
            }
            
            toViewInternal.frame = toViewFrame
            
            
            toViewInternal.frame = CGRectOffset(toViewFrame,0,-CGRectGetMaxY(toViewFrame))
            
            
            UIView.animateWithDuration(self.transitionDuration(transitionContext), animations: { () -> Void in
                toViewInternal.frame = toViewFrame
                }) { (flag) -> Void in
                    transitionContext.completeTransition(true)
            }
        }
    }
}
