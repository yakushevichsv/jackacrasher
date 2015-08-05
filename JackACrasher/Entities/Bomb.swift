//
//  Bomb.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 7/30/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit
import SpriteKit

class Bomb: SKSpriteNode, AssetsContainer {
    
    internal weak var target:Player?
    
    internal struct Constants {
        static let speed:CGFloat = 200
        static let name = "Bomb"
    }
    
    
    private static var sBombTexture:SKTexture! = nil
    private static var sOnce:dispatch_once_t = 0
    
    static func loadAssets() {
        dispatch_once(&Bomb.sOnce) {
            Bomb.sBombTexture = SKTexture(imageNamed: "cartoon-bomb")
        }
    }
    
    init(){
        super.init(texture: Bomb.sBombTexture, color: UIColor.blackColor(), size: Bomb.sBombTexture.size())
        
        self.xScale = 0.25
        self.zRotation = π * 0.5
        let body = SKPhysicsBody(texture: self.texture!, size: self.size)
        
        body.collisionBitMask = 0
        body.contactTestBitMask = EntityCategory.Player | EntityCategory.PlayerLaser
        body.categoryBitMask = EntityCategory.Bomb
        
        self.userData = ["radius":50]
        self.physicsBody = body
        self.name = Bomb.Constants.name
        //sprite.physicsBody!.fieldBitMask = EntityCategory.BlakHoleField
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: Abstract Method
    func updateWithTimeSinceLastUpdate(interval:NSTimeInterval) {
        
    }
    
    
    var canAttack:Bool {
        get {return false}
    }
}
