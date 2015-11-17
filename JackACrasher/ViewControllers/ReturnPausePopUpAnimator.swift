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
    
        let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)
        
        let toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)
        
        if (!isPresenting) {
            
            if let fromViewInternal = fromVC?.view {
                
                fromVC?.view.userInteractionEnabled = false
                
                transitionContext.containerView()!.addSubview(fromViewInternal)
                
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
        
        
        print("From VC Initial \(transitionContext.initialFrameForViewController(fromVC!)) Final \(transitionContext.finalFrameForViewController(fromVC!)) \n From VC Final \(transitionContext.initialFrameForViewController(toVC!)) Final \(transitionContext.finalFrameForViewController(toVC!))")
        
        
        if let toViewInternal = toVC?.view {
            transitionContext.containerView()!.addSubview(toViewInternal)
            
            fromVC?.view.userInteractionEnabled = false
            
            
            let tW = self.isPortrait ? CGRectGetHeight(rect) : CGRectGetWidth(rect)
            let tH =  !self.isPortrait ? CGRectGetHeight(rect) : CGRectGetWidth(rect)
            
            let wScale = CGFloat( isPhone4s() ? 0.6 : (isPhone6Plus() ? 0.4 : 0.5) )
            let hScale = CGFloat( isPhone4s() ? 0.5 : (isPhone6Plus() ? 0.4 : 0.4) )
            let xMargin = (1 - wScale) * 0.5
            let yMargin =  (1 - hScale) * 0.5
            
            let w  = round(wScale * tW)
            let h  = round(hScale * tH)
            let oX = round(xMargin * tW)
            let oY = round(yMargin * tH)
            
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
