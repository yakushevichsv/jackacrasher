//
//  BlackHole.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 7/22/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit
import SpriteKit

 let blackHoleName = "blackhole"

class BlackHole: SKSpriteNode {
    private static let gravityNodeName = "gravityNode"
    private weak var springField:SKFieldNode!
    private var radius:CGFloat = 0
    private var animAction:SKAction! = nil
    
    init(){
    //override init() {
        //super.init()
        
        let textureAtlas = SKTextureAtlas(named: blackHoleName)
        let texture0 = textureAtlas.textureNamed("BlackHole0")
        
        super.init(texture:texture0 , color: UIColor.whiteColor(), size: texture0.size())
        
        self.defineActions(blackHoleName)
        self.definePhysBody()
        self.appendGravity()
        
        self.springField.enabled = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private func definePhysBody() {
        
        let body = SKPhysicsBody(circleOfRadius: self.radius)
        body.dynamic = false
        body.categoryBitMask = EntityCategory.BlackHole
        body.contactTestBitMask = 0
        body.collisionBitMask = 0
        body.fieldBitMask = 0
        self.physicsBody = body
        self.name = blackHoleName
    }
    
    private func appendGravity() {
        let field = SKFieldNode.springField()
        field.categoryBitMask = EntityCategory.BlakHoleField
        field.falloff = 0.5
        field.region = SKRegion(radius: round(Float(self.radius * 2.0)))
        field.exclusive = true
        addChild(field)
        self.springField = field
    }
    
    private func defineActions(textureAtlasName:String!) {
        
        var frames = [SKTexture]()
        
        let textureAtlas = SKTextureAtlas(named: textureAtlasName)
        
        for i in 0...4 {
            let frame = textureAtlas.textureNamed("BlackHole".stringByAppendingString("\(i)"))
            frames.append(frame)
            
            let r = round(max(frame.size().height,frame.size().width) * 0.5)
            
            if (r > self.radius) {
                self.radius = r
            }
        }
        
        let animateAction = SKAction.repeatActionForever(SKAction.animateWithTextures(frames, timePerFrame: NSTimeInterval(0.2)))
        self.animAction = animateAction
        //runAction(animateAction)
    }
    
    override func removeFromParent() {
        
        self.springField.enabled = false
        self.springField.removeFromParent()
        
        super.removeFromParent()
    }
    
    internal func signalAppearance(completion:(()->Void)!) {
        
        self.springField.enabled = false
        
        let fadeIn = SKAction.fadeInWithDuration(2)
        let fadeOut = SKAction.fadeOutWithDuration(1)
        
        let sequence = SKAction.sequence([fadeOut,fadeIn])
        let seqRep = SKAction.repeatAction(sequence, count: 4)
        
        var seqArray = [seqRep,SKAction.runBlock(){
            [unowned self] in
                self.springField.enabled = true
            },self.animAction]
        
        let fSequence = SKAction.sequence(seqArray)
        
        runAction(fSequence, completion: completion)
        
    }
}
