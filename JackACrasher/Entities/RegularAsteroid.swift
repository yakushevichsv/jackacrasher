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

extension SKScene {
    
    func correctLabelText(node:SKNode!) {
    
        for child in node.children {
            
            if let labelNode = child as? SKLabelNode {
                let fontName = NSLocalizedString("FontName", comment: "FontName")
                labelNode.fontName = fontName
                if let text = labelNode.text {
                    labelNode.text = NSLocalizedString(text, comment: text)
                }
            }
            else {
                correctLabelText(child)
            }
        }
    }
}

extension SKNode {
    
    private var syScoreLabel:SKLabelNode! {
        get {
            
            let label = SKLabelNode(fontNamed: NSLocalizedString("FontName",comment:""))
            label.alpha = 1.0
            label.text = ""
            label.fontSize = 30.0
            label.fontColor = SKColor.greenColor()
            label.horizontalAlignmentMode = .Center
            label.position = CGPointZero
            label.zPosition = self.zPosition + CGFloat(1.0)
            label.hidden = false
            
            
            return label
        }
    }
    
    func syDisplayScore(rect playableArea:CGRect, scoreAddition:Int64) {
        syDisplayScore(CGPointZero, rect:playableArea, scoreAddition: scoreAddition)
    }
    
    func syDisplayScore(position:CGPoint, rect playableArea:CGRect, scoreAddition:Int64) {
        let label = self.syScoreLabel
        
        let numFormatter = NSNumberFormatter()
        numFormatter.numberStyle = .DecimalStyle
        let numAsString = numFormatter.stringFromNumber(NSNumber(longLong:scoreAddition))
        
        label.text = numAsString
        
        let sPosition = self.parent != nil ? self.scene!.convertPoint(self.position, fromNode: self.parent!) : self.position
        
        label.position = sPosition + position
        
        self.scene?.addChild(label)
        
        var yDiff:CGFloat = 30
        var sign:CGFloat
        
        
        if (yDiff + sPosition.y > CGRectGetMaxY(playableArea)) {
            sign = -1.0
        }
        else {
            sign = 1.0
        }
        
        yDiff *= sign
        
        label.runAction(SKAction.sequence([
            SKAction.moveByX(0, y: yDiff, duration: 1.0),
            SKAction.fadeOutWithDuration(1.0),
            SKAction.removeFromParent()
            ]))
        
        if let gameScoreScene = self.scene as? GameScoreItem {
            gameScoreScene.currentGameScore += scoreAddition
            gameScoreScene.totalGameScore += UInt64(scoreAddition)
        }
    }
}

class RegularAsteroid: SKSpriteNode, ItemDestructable ,ItemDamaging {
    private let digitNode:DigitNode!
    private let cropNode:ProgressTimerCropNode!
    var maxLife:ForceType {
        didSet {
            self.digitNode?.digit = maxLife
        }
    }
    private let displayAction = "displayAction"
    private let asterSize:RegularAsteroidSize
    
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
        case .Small:
            partName = "small"
            multiplicator = 1.2
            w_R = 5
            w_r = 2
            f_size = 10
            isLittle = true
            
            break
        case .Medium:
            partName = "medium"
            w_R = 8
            w_r = 4
            f_size = 30
            
            break
        case .Big:
            multiplicator = 1.0
            partName = "large"
            w_R = 8
            w_r = 4
            f_size = 30
            
            break
        }
        if (!partName.isEmpty) {
            nodeName = nodeName.stringByAppendingString(partName)
        }
        
        self.maxLife = maxLife
        let texture = SKTexture(imageNamed: nodeName!)
        var size = texture.size()
        
        if (multiplicator != 1.0) {
            size.width *= multiplicator
            size.height *= multiplicator
        
            w_R *= multiplicator
            w_r *= multiplicator
            f_size *= multiplicator
            f_size = round(f_size)
            w_r = round(w_r)
            w_R = round(w_R)
        }
        
        self.digitNode = DigitNode(size: size, digit: maxLife,params:[w_R,w_r,f_size])
        self.cropNode = ProgressTimerCropNode(size: size)
        self.asterSize = asteroid
        
        super.init(texture: texture, color: UIColor.blueColor(), size: size)
        
        
        
        let center = CGPointMake(0.0, 0)
        
        var origin = center
        origin.x -= size.halfWidth()
        origin.y -= size.halfHeight()
        
        //let path = UIBezierPath(ovalInRect: CGRect(origin: origin, size: size))
        
        let physBody =  SKPhysicsBody(texture: texture, size: size) //SKPhysicsBody(polygonFromPath: path.CGPath)

        physBody.categoryBitMask = EntityCategory.RegularAsteroid
        physBody.contactTestBitMask = EntityCategory.Player | EntityCategory.PlayerLaser
        physBody.collisionBitMask = 0
        //physBody.fieldBitMask = EntityCategory.BlakHoleField
        
        self.physicsBody = physBody
        //self.physicsBody!.fieldBitMask = 0
        
        if (EnabledDisplayDebugLabel) {
            let path = UIBezierPath(ovalInRect: CGRect(origin: origin, size: size))
            let shapeNode = SKShapeNode(path: path.CGPath)
            shapeNode.strokeColor = UIColor.redColor()
            shapeNode.position = center
            addChild(shapeNode)
        }
        
        if (!isLittle) {
            self.cropNode.addChild(self.digitNode)
            addChild(self.cropNode)
        }

        
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
        
        
        if (result == 0 && maxLife > 1){
            maxLife -= 1
            result = maxLife
        }
        else {
            maxLife = result
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
        self.health = self.damageForce
    }
    
    private func setupPhysicsBody(){
        let texture = self.texture
        
        let physBody = SKPhysicsBody(texture: texture!, size: texture!.size())
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
        fireEmitter.targetNode = nil
        fireEmitter.particleRotation = shortestAngleBetween(self.zRotation, angle2: direction.angle)
        fireEmitter.zPosition = 2
        
        addChild(fireEmitter)
        
        self.firing = true
        
    }
    
    override func tryToDestroyWithForce(forceValue: ForceType) -> Bool {
        self.maxLife = 1.0
        return super.tryToDestroyWithForce(forceValue)
    }
}

class RegularAsteroids {
    
    internal class func loadAssets() {
        
        SmallRegularAsteroid.loadAssets()
        
    }
}
