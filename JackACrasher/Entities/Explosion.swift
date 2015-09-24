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


class Explosion: SKSpriteNode, AssetsContainer {
    private static var textures:[SKTexture] = []
    private static var  animation:SKAction! = nil
    private static var sContext:dispatch_once_t = 0
    internal var explosionType:ExplosionType = .Small
    
    
    internal static func loadAssets() {
        self.prepare()
    }
    
    class func getExplostionForType(type:ExplosionType) -> Explosion {
        
        var exp:Explosion!
        switch type {
         case .Large:
            exp = Explosion(explosionType: .Large)
            break
        case .Small:
            exp = Explosion(explosionType: .Small)
            break
        }
        return exp
    }
    
    private class func prepare() {
        //void for textures initialization...
        
        dispatch_once(&Explosion.sContext) {
        
            var curTextures :[SKTexture] = []
            for i in 1...3 {
                let texture = SKTexture(imageNamed: "explosion000\(i)")
                curTextures.append(texture)
            
            }
            
            SKTexture.preloadTextures(curTextures) { () -> Void in
                self.textures = curTextures
                self.animation = SKAction.animateWithTextures(curTextures, timePerFrame: 0.2)
            }
        }
    }
    
    override init(texture: SKTexture!, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
    }
    
    init(explosionType type:ExplosionType) {
        self.explosionType = type
        super.init(texture: Explosion.textures.first!,color:SKColor.whiteColor(),size:Explosion.textures.first!.size())
        
        
        let sAction = type == .Small ? SoundManager.explosionSmall : SoundManager.explosionLarge
        
        runAction(SKAction.sequence([sAction,
            SKAction.group([
                Explosion.animation,
                SKAction.scaleTo(0.5, duration: 0.3),
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
