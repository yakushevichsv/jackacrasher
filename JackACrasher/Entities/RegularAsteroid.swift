//
//  RegularAsteroid.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 4/21/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit
import SpriteKit


let digitAppearanceSpeed = M_PI_4
let duration = (M_PI*2)/digitAppearanceSpeed


@objc protocol ItemDestructable {
    func tryToDestroyWithForce(forceValue:ForceType) -> Bool
     var health:ForceType {get set}
}

@objc protocol ItemDamaging {
    var damageForce:ForceType {get}
    func destroyItem(item:ItemDestructable) -> Bool
}


class RegularAsteroid: SKNode, ItemDestructable ,ItemDamaging {
    private let digitNode:DigitNode!
    private let cropNode:ProgressTimerCropNode!
    private let maxLife:ForceType
    private let displayAction = "displayAction"
    private let asterSize:RegularAsteroidSize
    private let bgImageNode:SKSpriteNode! = SKSpriteNode()
    
    
    
    internal var mainSprite:SKSpriteNode! {
        return bgImageNode
    }
    
    internal var size:CGSize {
        return bgImageNode != nil ? bgImageNode.size : CGSizeZero
    }
    
    internal var health:ForceType {
        get { return self.digitNode.digit }
        set { self.digitNode.digit = newValue}
    }
    
    internal var asteroidSize:RegularAsteroidSize {
        return asterSize
    }
    
    init(asteroid:RegularAsteroidSize,maxLife:ForceType, needToAnimate:Bool) {
        var nodeName:String! = "asteroid-"
        var partName:String! = ""
        
        var w_R:CGFloat
        var w_r:CGFloat
        var f_size:CGFloat
        
        var isLittle:Bool = false
        var multiplicator:CGFloat = 1.0
        switch (asteroid) {
        case .Medium:
            partName = "medium"
            
            w_R = 10
            w_r = 5
            f_size = 30
            
            break
        case .Small:
            partName = "small"
            
            w_R = 5
            w_r = 2
            f_size = 10
            isLittle = true
            break
        case .Big:
            partName = "large"
            multiplicator = 0.5
            w_R = 20
            w_r = 14
            f_size = 100
            
            break
        default:
            break
        }
        if (!partName.isEmpty) {
            nodeName = nodeName.stringByAppendingString(partName)
        }
        
        self.maxLife = maxLife
        let texture = SKTexture(imageNamed: nodeName!)
        var size = texture.size()
        size.width *= multiplicator
        size.height *= multiplicator
        
        self.digitNode = DigitNode(size: size, digit: maxLife,params:[w_R,w_r,f_size])
        self.cropNode = ProgressTimerCropNode(size: size)
        self.asterSize = asteroid
        
        super.init()
        
        self.bgImageNode.texture = texture
        self.bgImageNode.size = size
        
        self.addChild(bgImageNode)
        
        if (!isLittle) {
            self.cropNode.addChild(self.digitNode)
            addChild(self.cropNode)
        }
        
        let physBody = SKPhysicsBody(texture: texture, size: size)
        physBody.categoryBitMask = EntityCategory.RegularAsteroid
        physBody.contactTestBitMask = EntityCategory.Player | EntityCategory.PlayerLaser
        physBody.collisionBitMask = 0
        //physBody.fieldBitMask = EntityCategory.BlakHoleField
        
        self.physicsBody = physBody
        //self.physicsBody!.fieldBitMask = 0
        
        self.appendRadialGravityToAsteroid()
        
        if (needToAnimate) {
            self.startRotation()
        }
    }
    
    internal func removeField() {
        if let field = self.childNodeWithName("field") as? SKFieldNode {
            field.enabled = false
            field.removeFromParent()
        }
    }
    
    override func removeFromParent() {
        self.removeField()
        self.physicsBody = nil
        super.removeFromParent()
    }
    
    private func appendRadialGravityToAsteroid() {
        
        return
        
        let field = SKFieldNode.radialGravityField()
        
        let mRadius = round(0.5*min(self.bgImageNode.texture!.size().width,self.bgImageNode.texture!.size().height))
        
        field.name = "field"
        //field.physicsBody  = SKPhysicsBody(circleOfRadius: mRadius)
        field.categoryBitMask = EntityCategory.RadialField
        
        var falloff:Float = 0
        var animSpeed:Float = 0
        
        var region:SKRegion! = nil
        
        switch (self.asterSize) {
            case .Big:
                falloff = 0.8
                animSpeed = 0.4
                
                region = SKRegion(radius: Float(mRadius)*1.5)
                
                break
            case .Medium:
                falloff = 0.4
                animSpeed = 0.6
                region = SKRegion(radius: Float(mRadius)*1.8)
                break
            case .Small:
            fallthrough
            default:
                falloff = 0.2
                animSpeed = 1
                region = SKRegion(radius: Float(mRadius)*2.0)
                break
        }
        
        
        field.falloff = falloff
        field.animationSpeed = animSpeed
        field.region = region
        
        //self.bgImageNode.addChild(field)
        
        self.insertChild(field, atIndex: 0)
        
        //lself.bgImageNode.addChild(field)
    }
    
    private func startRotation() {
        let rotate = SKAction.rotateByAngle(CGFloat(M_PI_2), duration: Double(1))
        let rotateAlways = SKAction.repeatActionForever(rotate)
        runAction(rotateAlways)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    internal func setProgress(progress:CGFloat) {
        self.cropNode.setProgress(min(1,max(0,progress)))
    }
    
    
    internal func startAnimation() {
        
        let blockAction = SKAction.customActionWithDuration(duration){ (node, time) -> Void in
            self.setProgress(time/CGFloat(duration))
            
            if self.cropNode.currentProgress == 0.0 {
                self.startRotation()
            }
            
            if (time == CGFloat(duration)) {
              self.cropNode.runAction(SKAction.sequence([ SKAction.waitForDuration(1), SKAction.removeFromParent()]))
            }
        }
        runAction(blockAction, withKey: self.displayAction)
        
    }
    
    internal func tryToDestroyWithForce(forceValue:ForceType) -> Bool  {
    
        if (actionForKey(self.displayAction) != nil) {
            self.removeActionForKey(self.displayAction)
        }
        
        var result = self.health - forceValue
        
        if (result < 0) {
            result = 0
        }
        self.health = result
        
        return result == 0
    }
    
    //MARK: ItemDamaging protocol
    
    internal var damageForce:ForceType {
        return self.asteroidSize == .Big ? 5 : 4
    }

    func destroyItem(item:ItemDestructable) ->Bool {
        return item.tryToDestroyWithForce(self.damageForce)
    }
}

class SmallRegularAsteroid:RegularAsteroid, AssetsContainer {
    
    private static let sFireEmitterNode = "FireEmitterNode"
    
    private static var sContext:dispatch_once_t = 0
    private static var sFireEmitter:SKEmitterNode!
    private var firing = false
    
    internal var isFiring:Bool {
        return firing
    }
    
    override internal var damageForce:ForceType {
        return ForceType(1.0)
    }
    
    internal static func loadAssets() {
        
        dispatch_once(&sContext, { () -> Void in
            self.sFireEmitter = SKEmitterNode(fileNamed: "Fire.sks")
            self.sFireEmitter.name = self.sFireEmitterNode
        })
    }
    
    init(maxLife: ForceType, needToAnimate: Bool) {
        super.init(asteroid: .Small, maxLife: maxLife, needToAnimate: needToAnimate)
        setupPhysicsBody()
    }
    
    private func setupPhysicsBody(){
        let texture = self.mainSprite.texture
        
        let physBody = SKPhysicsBody(texture: texture, size: texture!.size())
        physBody.categoryBitMask = EntityCategory.RegularAsteroid
        physBody.contactTestBitMask = EntityCategory.Player | EntityCategory.PlayerLaser
        physBody.fieldBitMask = 0
        
        physBody.collisionBitMask = 0
        
        
        self.physicsBody = physBody
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func startAnimation() {
        return
    }
    
    //MARK: Fire Node
    internal func startFiringAtDirection(direction:CGVector, point:CGPoint) {
        
        let len = point.length()
        let angle = point.angle + π
        
        let x  = len * cos(angle)
        let y  = len * sin(angle)
        
        let p1 = CGPointMake(x, y)
        
        let fireEmitter = SmallRegularAsteroid.sFireEmitter.copy() as! SKEmitterNode
        
        fireEmitter.position = p1
        fireEmitter.targetNode = self.scene
        fireEmitter.particleRotation = shortestAngleBetween(self.zRotation, direction.angle)
        fireEmitter.zPosition = 2
        
        addChild(fireEmitter)
        
        self.firing = true
        
    }
}

class RegularAsteroids {
    
    internal class func loadAssets() {
        
        SmallRegularAsteroid.loadAssets()
        
    }
}
