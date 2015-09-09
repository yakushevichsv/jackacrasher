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
        
        return length > CGFloat.min ? CGVectorMake(dx/length, dy/length) : CGVector.zeroVector
        
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
            return UIColor(CGColor: self.layer.borderColor)
        }
        set {
            self.layer.borderColor = newValue.CGColor
            
            if self.borderColor != newValue {
                setNeedsDisplay()
            }
        }
    }
}
