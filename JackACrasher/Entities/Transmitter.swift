//
//  Transmitter.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 8/4/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import Foundation
import SpriteKit

class Transmitter:SKNode {
    
    enum State {
        case Capturing
        case Transferring
        case Constraining
    }
    
    private  struct Constants {
        static let bgSpriteName = "bgSpriteName"
        static let movingSpeed:CGFloat = 100.0
        static let beamSpeed:CGFloat = 60.0
    }
    
    private weak var basementNode:SKShapeNode! = nil
    private weak var rayNode:SKShapeNode! = nil
    
    private let size:CGSize
    private let beamHeight:CGFloat
    
    init(transmitterSize size:CGSize,beamHeight:CGFloat) {
        self.size = size
        self.beamHeight = beamHeight
        
        super.init()
        self.createBasement(size)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createBasement(size:CGSize) {
        
        let node = SKShapeNode(rectOfSize: size)
        node.fillColor = UIColor.redColor()
        node.name = Transmitter.Constants.bgSpriteName
        self.addChild(node)
        self.basementNode = node
        
        
        let shape = SKShapeNode()
        shape.fillColor = UIColor(white: 1, alpha: 0.7)
        self.addChild(shape)
        self.rayNode = shape
    }

    
    internal func transmitAnItem(item node:SKNode!,itemSize:CGSize, toPosition destPosition:CGPoint, completion:(()->Void)!) {
        
        var array = [SKAction]()
        let position = node.position
        if (self.position.x != position.x) {
            let moveAction = SKAction.moveToX(position.x, duration: NSTimeInterval(fabs(position.x - self.position.x)/Transmitter.Constants.movingSpeed))
            array.append(moveAction)
        }
        
        let yDiff = fabs(self.position.y - position.y - itemSize.halfHeight())
        
        let duration = NSTimeInterval(yDiff/Transmitter.Constants.beamSpeed)
        
        let custAction = SKAction.customActionWithDuration(duration) {
            [unowned self]
            node, time in
            
            let ratio = time/CGFloat(duration)
            
            let h = ratio * yDiff
            
            self.rayNode.path = UIBezierPath(rect: CGRectMake(-self.size.halfWidth(), 0, self.size.width, -h)).CGPath
        }
        array.append(custAction)

        let moveOwnership = SKAction.runBlock(){
            [unowned self] in
            let location = node.parent!.convertPoint(node.position, toNode: self)
            node.removeFromParent()
            node.position = location
        
            self.addChild(node)
        }
        
        array.append(moveOwnership)
        
        let moveAction = SKAction.moveToX(destPosition.x, duration: NSTimeInterval(fabs(position.x - destPosition.x)/Transmitter.Constants.movingSpeed) )
        array.append(moveAction)
        
        
        let yDiff2 = fabs(yDiff -  self.beamHeight)
        
        let duration2 = NSTimeInterval(yDiff2/Transmitter.Constants.beamSpeed)
        
        let expandBeamAction = SKAction.customActionWithDuration(duration2) {
            [unowned self]
            node, time in
            
            let ratio = time/CGFloat(duration2)
            
            let h = ratio * yDiff2 + yDiff
            
            self.rayNode.path = UIBezierPath(rect: CGRectMake(-self.size.halfWidth(), 0, self.size.width, -h)).CGPath
        }
        array.append(expandBeamAction)
        
        self.runAction(SKAction.sequence(array), completion: completion)
    }
    
}