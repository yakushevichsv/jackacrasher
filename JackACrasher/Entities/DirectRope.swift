//
//  DirectRope.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 4/26/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit
import SpriteKit

class DirectRope: Rope {
   
    private var direction : CGVector = CGVector.zeroVector
    private var numberOfSteps:Int = 0
    
    internal class func directRope(connection1: RopeConnection, connection2: RopeConnection) ->DirectRope {
        
        let rope = DirectRope(connection1: connection1, connection2: connection2)
        rope.createRopeRings()
        
        return rope
    }
    
    override init(connection1: RopeConnection, connection2: RopeConnection) {
        
        super.init(connection1: connection1, connection2: connection2)
        
        findDirectionVector()
    }

    required init?(coder aDecoder: NSCoder) {
        self.direction = CGVector.zeroVector
        super.init(coder: aDecoder)
    }
    
    func findDirectionVector() {
        if (!CGPointEqualToPoint(self.connectionA.position, self.connectionB.position)) {
            
            var vectDiff = (self.connectionB.position - self.connectionA.position)
            
            var length = vectDiff.length()
            
            if let node1 = self.connectionB.node as? SKSpriteNode {
                length -= node1.size.width * 0.5
            }
            
            if let node2 = self.connectionA.node as? SKSpriteNode {
                length -= node2.size.width * 0.5
            }
            
            self.numberOfSteps = Int(ceilf(Float(length/self.ringLength)))
            vectDiff = vectDiff.normalized()
            
            self.direction = CGVector(dx: vectDiff.x, dy: vectDiff.y)
        }
    }
    
    internal override func createRopeRings() {
        
        let angle = self.direction.angle
        
        let curScene = scene!
        
        var jointPos = self.connectionA.position //self.connectionA.node.parent!.convertPoint(self.connectionA.position, toNode: curScene)
        
        if let nodeA = self.connectionA.node as? SKSpriteNode {
            jointPos += CGPointMake(self.direction.dx * nodeA.size.width*0.5, self.direction.dy * nodeA.size.height*0.5)
        }
        
        var refNode = self.connectionA.node
        let ringDiff = CGPointMake(self.direction.dx * self.ringLength,self.direction.dy * self.ringLength)
        var xPos = -(CGFloat(self.numberOfSteps) - 1 ) * ringDiff.x * 0.5
        
        
        for var i = 0 ; i < self.numberOfSteps; i++ {
           
            let sprite = SKSpriteNode(texture:self.ringTexture)
            let body = SKPhysicsBody(rectangleOfSize: self.ringTexture.size())
            body.collisionBitMask = 0
            body.contactTestBitMask = 0
            body.categoryBitMask = EntityCategory.Rope
            //sprite.zRotation = CGFloat(M_PI_2)
            sprite.physicsBody = body
            sprite.position = CGPointMake(xPos, 0)
            addChild(sprite)
            
            
            let fixedJoint = SKPhysicsJointFixed.jointWithBodyA(refNode.physicsBody!, bodyB: body, anchor: jointPos)
            
            //curScene.addChild(sprite)
            //refNode.removeFromParent()
            //curScene.addChild(refNode)
            
            curScene.physicsWorld.addJoint(fixedJoint)
            
            xPos += ringDiff.x
            refNode = sprite
            jointPos += ringDiff
            
            if (i == self.numberOfSteps - 1) {
                
                var jointPos = self.connectionB.position
                if let nodeB = self.connectionB.node as? SKSpriteNode {
                    jointPos -= CGPointMake(self.direction.dx * nodeB.size.width*0.5, self.direction.dy * nodeB.size.height*0.5)
                }
                
                let fixedJoint = SKPhysicsJointFixed.jointWithBodyA(refNode.physicsBody!, bodyB: self.connectionB.node.physicsBody!, anchor: jointPos)
                
                //curScene.addChild(sprite)
                //refNode.removeFromParent()
                //curScene.addChild(refNode)
                
                curScene.physicsWorld.addJoint(fixedJoint)
            }
        }
        
        self.zRotation = angle
        
    }
}
