//
//  Explosion.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 4/19/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit
import SpriteKit

enum ExplosionType {
    case Small
    case Large
    
    static let allValues = [Small, Large]
}

//3333 process here...... Exposion...


class Explosion: SKSpriteNode {
    private static var textures:[SKTexture] = []
    internal let explosionType:ExplosionType
    
    override class func initialize() {
        super.initialize()
        
        for i in 1...3 {
            let texture = SKTexture(imageNamed: "explosion000\(i)")
            assert(texture != nil, "Texture is nil")
            Explosion.textures.append(texture)
        }
    }
    
    init(explosionType type:ExplosionType) {
        self.explosionType = type
        super.init(texture: Explosion.textures.first!,color:SKColor.whiteColor(),size:Explosion.textures.first!.size())
        
        let animation = SKAction.animateWithTextures(Explosion.textures, timePerFrame: 0.2)
        
        runAction(SKAction.sequence([
            SKAction.group([
                animation,
                SKAction.scaleTo(0.5, duration: 0.3)
                ]),
            SKAction.group([
                SKAction.fadeAlphaTo(0, duration: 0.2),
                SKAction.scaleTo(0, duration: 0.2)
                ]),
            SKAction.removeFromParent()
            ]))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
