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
            
            var toViewFrame:CGRect
            
            if toVC!.traitCollection.userInterfaceIdiom == .Phone {
                let tW = self.isPortrait ? CGRectGetHeight(rect) : CGRectGetWidth(rect)
                let tH =  !self.isPortrait ? CGRectGetHeight(rect) : CGRectGetWidth(rect)
                
                let wScale = CGFloat( isPhone4s() ? 0.8 : (isPhone6Plus() ? 0.6 : 0.6) )
                let hScale = CGFloat( (isPhone4s() || isPhone5s()) ? 0.9 : (isPhone6Plus() ? 0.7 : 0.8) )
                let xMargin = (1 - wScale) * 0.5
                let yMargin =  (1 - hScale) * 0.5
                
                let w  = round(wScale * tW)
                let h  = round(hScale * tH)
                let oX = round(xMargin * tW)
                let oY = round(yMargin * tH)
                
                
                if (self.isPortrait) {
                    toViewFrame = CGRectMake(oY, oX, h, w)
                }
                else {
                    toViewFrame = CGRectMake(oX, oY, w, h)
                }
            }
            else {
                toViewFrame = rect
            }
            
            toViewInternal.frame = toViewFrame
        
        
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
