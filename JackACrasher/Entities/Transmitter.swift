//
//  Transmitter.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 8/4/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import Foundation
import SpriteKit

protocol AssetsContainer
{
    static func loadAssets()
}

class Transmitter:SKNode,AssetsContainer {
    
    enum State {
        case Capturing
        case Transferring
        case Constraining
    }
    
    internal static let  NodeName = "Transmitter"
    
    private  struct Constants {
        static let bgSpriteName = "bgSpriteName"
        static let movingSpeed:CGFloat = 100.0
        static let beamSpeed:CGFloat = 60.0
        static let transmitterLaserName = "TransmitterLaser"
    }
    
    private weak var basementNode:SKShapeNode! = nil
    private weak var rayNode:SKShapeNode! = nil
    private weak var laserNode:SKEmitterNode! = nil
    private weak var transmitNode:Player! = nil
    
    private static var sLaserEmitter:SKEmitterNode!
    private static var sOne:dispatch_once_t = 0
    
    private let size:CGSize
    private let beamHeight:CGFloat
    
    static func loadAssets() {
        dispatch_once(&sOne) {
            let laser = SKEmitterNode(fileNamed: Transmitter.Constants.transmitterLaserName)
            laser.name = self.Constants.transmitterLaserName
            self.sLaserEmitter = laser
        }
    }
    
    internal var transmitterSize:CGSize {
        get {return self.size}
    }
    
    
    init(transmitterSize size:CGSize,beamHeight:CGFloat) {
        self.size = size
        self.beamHeight = beamHeight
        
        super.init()
        self.createItems(size)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createItems(size:CGSize) {
        
        let node = SKShapeNode(rectOfSize: size)
        node.fillColor = UIColor.redColor()
        node.name = Transmitter.Constants.bgSpriteName
        addChild(node)
        self.basementNode = node
    
        let shape = SKShapeNode()
        shape.fillColor = UIColor(white: 1, alpha: 0.7)
        addChild(shape)
        let hPos = -round(CGRectGetMaxY(self.basementNode.frame)*0.9)
        shape.position = CGPointMake(0, hPos)
        self.rayNode = shape
        
        let laserNode = Transmitter.sLaserEmitter.copy() as! SKEmitterNode
        laserNode.position = self.rayNode.position
        laserNode.particlePositionRange = CGVector(dx: round(size.width * 0.8), dy: 0)
        addChild(laserNode)
        self.laserNode = laserNode
        
        self.name = Transmitter.NodeName
    }

    private func correctRayPath(time:CGFloat,duration:NSTimeInterval,yDiff:CGFloat,yOffset:CGFloat) {
        
        let ratio = time/CGFloat(duration)
        let h = ratio * yDiff + yOffset
        
        let half = self.laserNode.particleSpeedRange * 0.5
        let lifeTimeMin = h / (self.laserNode.particleSpeed + half)
        let lifeTimeMax = h / (self.laserNode.particleSpeed - half)
        
        self.laserNode.particleLifetimeRange = lifeTimeMax - lifeTimeMin
        self.laserNode.particleLifetime = 0.5 * (lifeTimeMin + lifeTimeMax )
        self.laserNode.particleBirthRate = 100
        self.rayNode.path = UIBezierPath(rect: CGRectMake(-self.size.halfWidth(), 0, self.size.width, -h)).CGPath
    }
    
    internal func moveToPosition(toPosition destPosition:CGPoint) -> Bool {
        
        if self.position.x != destPosition.x {
            let action = SKAction.moveToX(destPosition.x, duration: NSTimeInterval(fabs(destPosition.x - self.position.x)/Transmitter.Constants.movingSpeed))
            self.runAction(action)
            return true
        }
        else {
            return false
        }
        
    }
    
    internal func underRayBeam(positon itemPosition:CGPoint) -> Bool {
        
        let maxX = self.position.x + size.halfWidth()
        let minX = self.position.x - size.halfWidth()
        
        let isUnder = minX <= itemPosition.x && maxX >= itemPosition.x
        
        if (isUnder){
            println("Under value!")
        }
        return isUnder
    }
    
    internal func transmitAnItem(item node:Player!,itemSize:CGSize, toPosition destPosition:CGPoint, completion:(()->Void)!) {
        
        if self.userInteractionEnabled {
            return
        }
        
        var array = [SKAction]()
        let position = node.position
        self.userInteractionEnabled = true
        self.removeAllActions()
        
        if (self.position.x != position.x) {
            let moveAction = SKAction.moveToX(position.x, duration: NSTimeInterval(fabs(position.x - self.position.x)/Transmitter.Constants.movingSpeed))
            array.append(moveAction)
        }

        
        self.transmitNode = node
        
        let yDiff = fabs(self.position.y - position.y + itemSize.halfHeight())
        
        let duration = NSTimeInterval(yDiff/Transmitter.Constants.beamSpeed)
       
        
        let custAction = SKAction.customActionWithDuration(duration) {
            [unowned self]
            node, time in
            
            if (!self.underRayBeam(positon: node.position)) {
                self.userInteractionEnabled = false
                self.removeAllActions()
                completion()
                return
            }
            
            
            self.correctRayPath(time, duration: duration, yDiff: yDiff, yOffset:0)
        }
        array.append(custAction)

        let moveOwnership = SKAction.runBlock(){
            [unowned self] in
            
            if (!self.underRayBeam(positon: node.position)) {
                self.userInteractionEnabled = false
                self.removeAllActions()
                completion()
                return
            }
            
            let location = node.parent!.convertPoint(node.position, toNode: self)
            node.removeFromParent()
            node.position = location
        
            self.addChild(node)
        }
        
        array.append(moveOwnership)
        
        let moveAction = SKAction.moveToX(destPosition.x, duration: NSTimeInterval(fabs(position.x - destPosition.x)/Transmitter.Constants.movingSpeed) )
        array.append(moveAction)
        
        
        let yDiff2 = fabs(yDiff -  0 * self.beamHeight)
        
        let duration2 = NSTimeInterval(yDiff2/Transmitter.Constants.beamSpeed)
        
        let expandBeamAction = SKAction.customActionWithDuration(duration2) {
            [unowned self]
            node, time in
            
            if (!self.underRayBeam(positon: node.position)) {
                self.userInteractionEnabled = false
                self.removeAllActions()
                completion()
                return
            }
            
            self.correctRayPath(time, duration: duration, yDiff: yDiff2,yOffset:yDiff)
        }
        array.append(expandBeamAction)
        
        self.runAction(SKAction.sequence(array), completion: completion)
    }
    
    private func pointInsideBeam(location:CGPoint) -> Bool {
        return self.rayNode.containsPoint(location)
    }
    
    // MARK: Touches 
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        
        let touch = (touches.first as! UITouch)
        let point = touch.locationInNode(self)
        
        if CGPathContainsPoint(self.rayNode.path, nil, point, false) {
            self.transmitNode.moveToPoint(point)
        }
    }
}