//
//  Bomb.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 7/30/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit
import SpriteKit

class Bomb: SKSpriteNode, AssetsContainer,Attacker, ItemDestructable {
    
    internal weak var target:Player?
    
    internal struct Constants {
        static var speed:CGFloat = 200
        static let name = "Bomb"
    }
    
    private var _health:ForceType = ForceType(1)
    
    internal static var sBombTexture:SKTexture! = nil
    internal static var sBombTexture2:SKTexture! = nil
    
    private static var sOnce:dispatch_once_t = 0
    
    static func loadAssets() {
        dispatch_once(&Bomb.sOnce) {
            Constants.speed *= (UIDevice.currentDevice().userInterfaceIdiom == .Pad ? 1.5 : 1.2)
            Bomb.sBombTexture = SKTexture(imageNamed: "cartoon-bomb")
            Bomb.sBombTexture2 = SKTexture(imageNamed: "cartoon-bomb2")
        }
    }
    
    init(){
        super.init(texture: Bomb.sBombTexture, color: UIColor.blackColor(), size: Bomb.sBombTexture.size())
        
        setup()
    }
    
    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
        
        setup()
        
    }
    
    private func setup() {
        
        let body = SKPhysicsBody(texture: self.texture!, size: self.size)
        
        body.collisionBitMask = 0
        body.contactTestBitMask = EntityCategory.Player | EntityCategory.PlayerLaser
        body.categoryBitMask = EntityCategory.Bomb
        
        self.userData = ["radius":50]
        self.physicsBody = body
        self.name = Bomb.Constants.name
        
        if EnabledDisplayDebugLabel {
            appendDebugLabels()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    //MARK: Abstract Method
    func updateWithTimeSinceLastUpdate(interval:NSTimeInterval) {
        
    }
    
    private func appendDebugLabels() {
        
        
        let label = NORLabelNode(fontNamed: NSLocalizedString("FontName",comment:""))
        label.text = "When there is a bomb, destroy it \nOr wait until a timer has signaled\nAnd it will be fired automatically".syLocalizedString
        label.fontColor = SKColor.redColor()
        label.fontSize = 25
        label.lineSpacing = 3
        label.position = CGPointMake(-Bomb.sBombTexture.size().halfWidth()+50, Bomb.sBombTexture.size().halfHeight() - 40)
        label.zRotation = CGFloat(0)
        addChild(label)
    }
    
    var canAttack:Bool {
        get {return false}
    }
    
    //MARK: Item Destructable
    
    func tryToDestroyWithForce(forceValue: ForceType) -> Bool {
        
        health -= forceValue
        
        if health < 0 {
            health = 0.0
        }
        let result = health == 0.0
        
        return result
    }
    
    var health:ForceType {
        get {
            return _health
        }
        set {
            _health = newValue
        }
    }
    
}
