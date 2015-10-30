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

class BlackHole: SKNode,ItemDamaging,AssetsContainer {
    private static let gravityNodeName = "gravityNode"
    private static var radius:CGFloat = 0
    private static var animAction:SKAction! = nil
    private static var sTextures:[SKTexture]!
    private static var sContext:dispatch_once_t = 0
    
    private let time1 = NSTimeInterval(2)
    private let time2 = NSTimeInterval(1)
    private let count = 3
    private let time3 = NSTimeInterval(4)
    
    private var presentTime:NSTimeInterval = 0
    
    private weak var bgNode:SKSpriteNode!
    
    override init(){
        super.init()
       
        self.definePhysBody()
        self.appendBGSprite()
        
        setFieldState(false)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    internal var size : CGSize {
        return self.bgNode.size
    }
    
    private func appendBGSprite() {
        
        let sprite = SKSpriteNode(texture: BlackHole.sTextures[0])
        
        let animateAction = SKAction.repeatActionForever(SKAction.animateWithTextures(BlackHole.sTextures, timePerFrame: NSTimeInterval(0.2)))
        
        sprite.runAction(animateAction)
        
        self.addChild(sprite)
        
        self.bgNode = sprite
    }
    
    private func definePhysBody() {
        
        let body = SKPhysicsBody(circleOfRadius: BlackHole.radius)
        body.dynamic = false
        body.categoryBitMask = 0
        body.contactTestBitMask = EntityCategory.Player
        body.collisionBitMask = 0
        body.fieldBitMask = 0
        self.physicsBody = body
        self.name = blackHoleName
    }
    
    
    private func setFieldState(enabled:Bool) {
        if let pBody = self.physicsBody {
            pBody.categoryBitMask = enabled ? EntityCategory.BlackHole : 0
        }
    }
    
    internal static func  loadAssets() {
    
        dispatch_once(&BlackHole.sContext) {
            
            var frames = [SKTexture]()
            
            let textureAtlas = SKTextureAtlas(named: blackHoleName)
            
            for i in 0...4 {
                let frame = textureAtlas.textureNamed("BlackHole".stringByAppendingString("\(i)"))
                frames.append(frame)
                
                let r = round(max(frame.size().height,frame.size().width) * 0.5)
                
                if (r > self.radius) {
                    self.radius = r
                }
            }
            
            self.sTextures = frames
        }
    }
    
    internal func presentHole(completion:(()->Void)!) {
        
        self.setFieldState(false)
        
        let fadeIn = SKAction.fadeInWithDuration(time1)
        let fadeOut = SKAction.fadeOutWithDuration(time2)
        
        let sequence = SKAction.sequence([fadeOut,fadeIn])
        let seqRep = SKAction.repeatAction(sequence, count: count)
        
        let seqArray = [seqRep,SKAction.runBlock(){
            [unowned self] in
            
            self.setFieldState(true)
            
            /*let delayTime = dispatch_time(DISPATCH_TIME_NOW,
                Int64(4 * Double(NSEC_PER_SEC)))
            
            dispatch_after(delayTime, dispatch_get_main_queue()){
                completion()
            }*/
            
            },SKAction.waitForDuration(time3),SKAction.runBlock(){
                completion()
            }]
        
        runAction(SKAction.sequence(seqArray))
        
        self.presentTime = NSDate.timeIntervalSinceReferenceDate()
    }
    
    internal func moveItemToCenterOfField(item:SKNode!) -> NSTimeInterval {
        
        let duration = max(0,min(NSTimeInterval(1.5), NSDate.timeIntervalSinceReferenceDate() - self.presentTime))
        
        let rotate = SKAction.repeatActionForever(SKAction.rotateByAngle(π, duration: duration/2))
        let move = SKAction.moveTo(item.parent == Optional<SKNode>(self) ? CGPointZero : self.position, duration: duration)
        let shrink = SKAction.scaleTo(0.2, duration: duration)
        
        
        item.runAction(SKAction.group([rotate,move,shrink]))
        
        return duration
    }
    
    //MARK: Item damaging
    var damageForce:ForceType {
        return ForceType(100)
    }
    
    func destroyItem(item:ItemDestructable) -> Bool {
        return item.tryToDestroyWithForce(min(self.damageForce,item.health))
    }
    
    
    //MARK: Debug label
}
