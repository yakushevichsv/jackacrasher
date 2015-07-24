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

class BlackHole: SKSpriteNode,ItemDamaging {
    private static let gravityNodeName = "gravityNode"
    private weak var springField:SKFieldNode!
    
    private static var radius:CGFloat = 0
    private static var animAction:SKAction! = nil
    private static var sTextures:[SKTexture]!
    private static var sContext:dispatch_once_t = 0
    
    init(){
       let texture0 = BlackHole.sTextures[0]
        super.init(texture:texture0 , color: UIColor.whiteColor(), size: texture0.size())
        
        self.definePhysBody()
        self.appendGravity()
        
        setFieldState(false)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private func definePhysBody() {
        
        let body = SKPhysicsBody(circleOfRadius: BlackHole.radius)
        body.dynamic = false
        body.categoryBitMask = 0
        body.contactTestBitMask = 0
        body.collisionBitMask = 0
        body.fieldBitMask = 0
        self.physicsBody = body
        self.name = blackHoleName
    }
    
    private func appendGravity() {
        let field = SKFieldNode.springField()
        field.categoryBitMask = EntityCategory.BlakHoleField
        field.region = SKRegion(radius: round(Float(BlackHole.radius * 2.0)))
        field.exclusive = true
        addChild(field)
        self.springField = field
    }
    
    private func setFieldState(enabled:Bool) {
        self.springField.enabled = enabled
        if let pBody = self.physicsBody {
            pBody.categoryBitMask = enabled ? EntityCategory.BlackHole : 0
        }
    }
    
    override func removeFromParent() {
        
        self.setFieldState(false)
        self.springField.removeFromParent()
        
        super.removeFromParent()
    }
    
    internal class func  loadAssets() {
    
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
            
            let animateAction = SKAction.repeatActionForever(SKAction.animateWithTextures(frames, timePerFrame: NSTimeInterval(0.2)))
            self.animAction = animateAction
            
        }
    }
    
    internal func presentHole(completion:(()->Void)!) {
        
        self.setFieldState(false)
        
        let fadeIn = SKAction.fadeInWithDuration(2)
        let fadeOut = SKAction.fadeOutWithDuration(1)
        
        let sequence = SKAction.sequence([fadeOut,fadeIn])
        let seqRep = SKAction.repeatAction(sequence, count: 3)
        
        var seqArray = [seqRep,SKAction.runBlock(){
            [unowned self] in
            
            self.setFieldState(true)
            
            let delayTime = dispatch_time(DISPATCH_TIME_NOW,
                Int64(4 * Double(NSEC_PER_SEC)))
            
            dispatch_after(delayTime, dispatch_get_main_queue()){
                completion()
            }
            
            },BlackHole.animAction]
        
        runAction(SKAction.sequence(seqArray))
    }
    
    internal func moveItemToCenterOfField(item:SKNode!) -> NSTimeInterval {
        
        let duration = NSTimeInterval(2)
        
        let rotate = SKAction.repeatActionForever(SKAction.rotateByAngle(π, duration: duration/2))
        let move = SKAction.moveTo(self.position, duration: duration)
        let shrink = SKAction.scaleTo(0.2, duration: duration)
        
        
        item.runAction(SKAction.group([rotate,move,shrink]))
        
        return duration
    }
    
    //MARK: Item damaging
    var damageForce:ForceType {
        return ForceType.max
    }
    
    func destroyItem(item:ItemDestructable) -> Bool {
        return item.tryToDestroyWithForce(min(self.damageForce,item.health))
    }
}
