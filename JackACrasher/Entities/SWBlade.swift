//
//  SWBlade.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 9/8/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import SpriteKit

class SWBlade: SKNode {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init(position:CGPoint, target:SKNode, color:UIColor) {
        super.init()
        
        self.name = "skblade"
        self.position = position
        
        let tip:SKSpriteNode = SKSpriteNode(color: color, size: CGSizeMake(25, 25))
        tip.zRotation = 0.785398163
        tip.zPosition = 10
        self.addChild(tip)
        
        let emitter:SKEmitterNode = emitterNodeWithColor(color)
        emitter.targetNode = target
        emitter.zPosition = 0
        tip.addChild(emitter)
        
        self.setScale(0.6)
    }
    
    func enablePhysics(categoryBitMask:UInt32, contactTestBitmask:UInt32, collisionBitmask:UInt32) {
        self.physicsBody = SKPhysicsBody(circleOfRadius: 16)
        self.physicsBody?.categoryBitMask = categoryBitMask
        self.physicsBody?.contactTestBitMask = contactTestBitmask
        self.physicsBody?.collisionBitMask = collisionBitmask
        self.physicsBody?.dynamic = false
    }
    
    func emitterNodeWithColor(color:UIColor)->SKEmitterNode {
        var emitterNode:SKEmitterNode = SKEmitterNode()
        emitterNode.particleTexture = SKTexture(imageNamed: "spark.png")
        emitterNode.particleBirthRate = 3000
        
        emitterNode.particleLifetime = 0.2
        emitterNode.particleLifetimeRange = 0
        
        emitterNode.particlePositionRange = CGVectorMake(0.0, 0.0)
        
        emitterNode.particleSpeed = 0.0
        emitterNode.particleSpeedRange = 0.0
        
        emitterNode.particleAlpha = 0.8
        emitterNode.particleAlphaRange = 0.2
        emitterNode.particleAlphaSpeed = -0.45
        
        emitterNode.particleScale = 0.5
        emitterNode.particleScaleRange = 0.001
        emitterNode.particleScaleSpeed = -1
        
        emitterNode.particleRotation = 0
        emitterNode.particleRotationRange = 0
        emitterNode.particleRotationSpeed = 0
        
        emitterNode.particleColorBlendFactor = 1
        emitterNode.particleColorBlendFactorRange = 0
        emitterNode.particleColorBlendFactorSpeed = 0
        
        emitterNode.particleColor = color
        emitterNode.particleBlendMode = SKBlendMode.Add
        
        return emitterNode
    }
}
