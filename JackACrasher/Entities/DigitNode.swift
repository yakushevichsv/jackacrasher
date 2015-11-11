//
//  DigitNode.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 4/21/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import SpriteKit

class DigitNode: SKNode {
    
    private let size:CGSize
    private let nodeCenter:CGPoint
    private let labelNodeName = "labelNodeName"
    
    private let lineWidth_R:CGFloat
    private let lineWidth_r:CGFloat
    private let labelFont_Size:CGFloat
    
    internal var digit:ForceType {
        didSet {
            if (oldValue != self.digit) {
                updateLabel()
            }
        }
    }
    
    convenience init(size:CGSize,digit:ForceType){
        let array:[CGFloat] = [CGFloat]()
        self.init(size: size,digit:digit,params:array)
    }
    
    init(size:CGSize, digit:ForceType,params:[CGFloat]!) {
        
        self.digit = digit
        self.size = size
        let center = CGPointMake(self.size.width * 0.5, self.size.height * 0.5)
        self.nodeCenter = center
        self.lineWidth_R = !params.isEmpty ? params[0] : 15
        self.lineWidth_r = params.count > 1 ? params[1] : 10
        self.labelFont_Size = params.count > 2 ? params[2] : 30
        super.init()
        
        self.createCircles()
        self.updateLabel()
        
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createCirlce(radius:CGFloat,lineWidth:CGFloat) {
        
        let externalCirclePath = UIBezierPath(arcCenter: CGPointZero, radius: radius, startAngle: 0.0, endAngle: CGFloat(M_PI)*2, clockwise: false)
        externalCirclePath.lineWidth = lineWidth
        externalCirclePath.closePath()
        
        let node = SKShapeNode()
        node.strokeColor = SKColor.whiteColor()
        node.lineWidth = lineWidth
        node.path = externalCirclePath.CGPath
        addChild(node)
    }
    
    func createCircles() {
    
        let R = CGFloat(round(min(self.nodeCenter.x,self.nodeCenter.y) * 0.8))
        
        let r = CGFloat(round(R * 0.6))
        
        createCirlce(R, lineWidth: self.lineWidth_R)
        createCirlce(r, lineWidth: self.lineWidth_r)
    }
    
    
    
    func updateLabel() {
       
        let labelPtr:SKLabelNode? = childNodeWithName(self.labelNodeName) as? SKLabelNode
        var label:SKLabelNode!
        
        if (labelPtr == nil) {
            label = SKLabelNode(fontNamed: "Menlo-Regular")
            label.name = self.labelNodeName
            label.fontColor = SKColor.whiteColor()
            label.fontSize = self.labelFont_Size
            label.verticalAlignmentMode = SKLabelVerticalAlignmentMode.Center
            label.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Center
            addChild(label)
        }
        else {
            label = labelPtr!
        }
        
        let numFormatter = NSNumberFormatter()
        numFormatter.numberStyle = .DecimalStyle
        if let numAsString = numFormatter.stringFromNumber(NSNumber(integer: Int(self.digit))) {
            label.text = numAsString
        }
    }
    
}
