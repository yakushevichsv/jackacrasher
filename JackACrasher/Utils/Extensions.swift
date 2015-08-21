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

