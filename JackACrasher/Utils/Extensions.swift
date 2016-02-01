//
//  CGVector+Extensions.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 4/19/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit

extension CGVector{
    
/**
* Returns the length (magnitude) of the vector described by the CGVector.
*/
func length() -> CGFloat {
    return  hypot(dx, dy)
}
    
/**

* length() == 1
*/
    
    func normalize() -> CGVector {
        
        let length = self.length()
        
        return length > CGFloat.min ? CGVectorMake(dx/length, dy/length) : CGVector.zero
        
    }
    
    
    var angle: CGFloat {
        return self.dx != 0 ? atan2(dy, dx) : 0
    }
    
}


extension UIView {
    
    @IBInspectable var cornerRadius:CGFloat {
        get {
            return self.layer.cornerRadius
        }
        set {
            self.layer.cornerRadius = newValue
            self.layer.masksToBounds = newValue > 0
            
            if self.cornerRadius != newValue {
                setNeedsDisplay()
            }
        }
    }
    
    @IBInspectable  var borderWidth:CGFloat {
        get {
            return self.layer.borderWidth
        }
        set {
            self.layer.borderWidth = newValue
            
            if self.borderWidth != newValue {
                setNeedsDisplay()
            }
        }
        
    }
    
    @IBInspectable var borderColor:UIColor! {
        get {
            return UIColor(CGColor: self.layer.borderColor!)
        }
        set {
            self.layer.borderColor = newValue.CGColor
            
            if self.borderColor != newValue {
                setNeedsDisplay()
            }
        }
    }
}

extension UIApplication {
    class func topViewController(base: UIViewController? = UIApplication.sharedApplication().keyWindow?.rootViewController) -> UIViewController? {
        
        if let nav = base as? UINavigationController {
            return topViewController(nav.visibleViewController)
        }
        
        if let tab = base as? UITabBarController {
            let moreNavigationController = tab.moreNavigationController
            
            if let top = moreNavigationController.topViewController where top.view.window != nil {
                return topViewController(top)
            } else if let selected = tab.selectedViewController {
                return topViewController(selected)
            }
        }
        
        if let presented = base?.presentedViewController {
            return topViewController(presented)
        }
        
        return base
    }
}

