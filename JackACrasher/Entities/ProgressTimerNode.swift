//
//  ProgressTimerNode.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 4/21/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit
import SpriteKit

class ProgressTimerCropNode: SKCropNode {
    private let maskShapeNode:SKShapeNode! = SKShapeNode()
    private let radius:CGFloat
    private let size:CGSize
    private var progress:CGFloat = 0
    
    internal var currentProgress:CGFloat {
        return self.progress
    }
    
    init(size:CGSize){
        
        self.radius = min(size.width,size.height) * 0.5
        self.size = size
        super.init()
        
        self.refineMaskNode()
        
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func refineMaskNode() {
        self.maskShapeNode.antialiased = false
        self.maskShapeNode.lineWidth = self.size.width
        self.maskNode = self.maskShapeNode
    }
    
    internal func setProgress(progress:CGFloat) {
        
        let prog = progress
        
        self.progress = 1 - prog
        
        let startAngle = CGFloat(M_PI_2)
        
        let endAngle = startAngle + prog * CGFloat(2.0 * M_PI)
        
        let path = UIBezierPath(arcCenter: CGPointZero, radius: self.radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        
        self.maskShapeNode.path = path.CGPath
    }
    
}
