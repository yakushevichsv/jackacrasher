//
//  ReturnPauseTransitionDelegate.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 7/26/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit

class ReturnPauseTransitionDelegate: PopUpTransitioningDelegate {
   
    override func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        return ReturnPausePopUpAnimator(rect: rect,portrait:self.isPortrait,isPresenting:true)
    }
    
    override func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ReturnPausePopUpAnimator(rect: rect,portrait:self.isPortrait,isPresenting:false)
    }
    
    
    
}
