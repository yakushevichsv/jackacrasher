//
//  PopUpTransitioningDelegate.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 6/10/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit

class PopUpTransitioningDelegate: NSObject,UIViewControllerTransitioningDelegate {

    internal var rect:CGRect = CGRectZero
    internal var isPortrait:Bool = false
    
    internal var backgroundColor:UIColor! = UIColor.clearColor()
    internal var backgroundAlpha:CGFloat = 0.0
    
    override init() {
        super.init()
    }
    
    init(rect:CGRect,portrait isPortrait:Bool) {
        self.rect = rect
        self.isPortrait = isPortrait
        super.init()
    }
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        let presenter = PopupAnimator(rect: self.rect, portrait: self.isPortrait, isPresenting: true)
        return presenter
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        let presenter = PopupAnimator(rect: self.rect, portrait: self.isPortrait, isPresenting: false)
        return presenter
    }
    
    func presentationControllerForPresentedViewController(presented: UIViewController, presentingViewController presenting: UIViewController, sourceViewController source: UIViewController) -> UIPresentationController? {
        
    
        let controller = PopupPresentationController(presentedViewController: presented, presentingViewController: presenting)
        
        controller.backgroundAlpha = self.backgroundAlpha
        controller.backgroundColor = self.backgroundColor
        
        return controller
        
    }
    
}
