//
//  AsteroidGenerator.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 4/16/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit
import SpriteKit

enum AsteroidType {
    case None
    case Trash
    case Bomb
    case Joint
    case RopeBased
    case Regular
    case Health
}

enum RegularAsteroidSize {
    case Small
    case Medium
    case Big
}


protocol AsteroidGeneratorDelegate:NSObjectProtocol {
    func asteroidGenerator(generator:AsteroidGenerator, didProduceAsteroids:[SKNode], type:AsteroidType)
    func didMoveOutAsteroidForGenerator(generator:AsteroidGenerator, asteroid:SKNode, withType type:AsteroidType)
}

class AsteroidGenerator: NSObject {
    
    private let playableRect:CGRect
    private weak var delegate:AsteroidGeneratorDelegate!
    private var timer:NSTimer!
    private var prevAsteroidType: AsteroidType = .None
    private var curAsteroidType: AsteroidType = .None
    private var trashAtlas:SKTextureAtlas! = SKTextureAtlas(named: "trash")
    private var spriteAtlas:SKTextureAtlas! = SKTextureAtlas(named: "sprites")
    private let trashAvg:CGFloat   = 80.0
    private let trashRange:CGFloat = 10.0

    private var healthUnitProdTime:NSTimeInterval =  NSDate.timeIntervalSinceReferenceDate()
    
    internal var paused:Bool = false {
        didSet {
            let didChange = (paused != oldValue)
            if (paused) {
                if (didChange) {
                    self.stop()
                }
            }
            else {
                if (didChange || !paused) {
                    self.start()
                }
            }
        }
    }
    
    private var canFire:Bool = true
    
    init(playableRect rect:CGRect, andDelegate delegate:AsteroidGeneratorDelegate) {
        self.playableRect = rect
        self.delegate = delegate
        super.init()
        
        redifineTimer()
        stop()
    }
    
    internal func start() {
        canFire = true
        if !self.timer.valid {
            redifineTimer()
        }
        //generateItem()
    }
    
    internal func stop() {
        
        if (self.timer.valid) {
            self.timer.invalidate()
        }
        canFire = false
    }
    
    private func redifineTimer() {
        
        self.timer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: "generateItem", userInfo: nil, repeats: true)
    }
    
    internal func produceSeqActionToAsteroid(asteroid:RegularAsteroid,asteroidSpeed:CGFloat = 30.0) -> SKAction! {
        
        let xMargin = CGFloat(0.5*asteroid.size.width)
        let duration = NSTimeInterval((asteroid.position.x + xMargin)/asteroidSpeed)
        
        let moveOutAct = SKAction.moveToX(-xMargin, duration: duration)
        let sequence = SKAction.sequence([moveOutAct,SKAction.runBlock({ () -> Void in
            self.delegate.didMoveOutAsteroidForGenerator(self, asteroid: asteroid, withType: .Regular)
        }),SKAction.removeFromParent()])
        return sequence
    }
    
    internal class func damageForce(type:AsteroidType) -> ForceType {
        var force = ForceType(0)
        switch (type){
        case .Bomb:
            force = 20
            break
        default:
            assert(false, "False")
            break
        }
        return force
    }
    
    internal class var regularAsteroidSpeed:CGFloat {
        get { return 60  }
    }
    
    private func produceRegularAsteroidPrivate(size:RegularAsteroidSize,initialAnimation:Bool) -> (asteroid:RegularAsteroid,actions:SKAction)  {
        
        let asteroidSpeed = AsteroidGenerator.regularAsteroidSpeed
        
        let sprite = size == .Small ? SmallRegularAsteroid(maxLife: 2, needToAnimate: initialAnimation) : RegularAsteroid(asteroid: size, maxLife: size == .Big ? 5: 3,needToAnimate:initialAnimation)
        
        let param = sprite.size.halfMaxSizeParam()
        
        let yMargin = round(param) + 10
        
        let duration = NSTimeInterval(CGRectGetWidth(self.playableRect)/asteroidSpeed)
        
        let divisor = UInt32(max(CGRectGetHeight(self.playableRect) - 2*yMargin, yMargin))
        
        let yPos = randomUntil(CGFloat(divisor), withOffset: CGFloat(yMargin))
        
        let xMargin = sprite.zRotation != 0 ? sprite.size.height : sprite.size.width
        
        
        sprite.position = CGPointMake(CGRectGetMaxX(self.playableRect) + xMargin, yPos)
        
        let sequence =  produceSeqActionToAsteroid(sprite, asteroidSpeed: asteroidSpeed)
        
        println("Y position \(yPos) and  Scene height \(CGRectGetHeight(self.playableRect)) Sprite size \(sprite.size). Asteroid Size \(size)")
        
        return (asteroid:sprite,actions:sequence)
    }

    private func produceRegularAsteroid(size:RegularAsteroidSize) {
        
        let (sprite,sequence) = self.produceRegularAsteroidPrivate(size,initialAnimation:true)
        
        sprite.runAction(sequence)
        sprite.startAnimation()
        
        self.delegate.asteroidGenerator(self, didProduceAsteroids: [sprite], type: .Regular)
        
    }
    
    private func produceHealthUnit() {
        
        let health = SKSpriteNode(imageNamed: "health")
        
        let body = SKPhysicsBody(rectangleOfSize: health.size)
        body.contactTestBitMask = EntityCategory.Player
        body.categoryBitMask = EntityCategory.HealthUnit
        body.collisionBitMask = 0
        
        health.userData = ["healing": ForceType(5)]
        health.physicsBody = body
        health.name = "health"
        
        let margin = health.size.halfMaxSizeParam()
        
        let yMargin = round(margin) + 10
        
        let divisor = UInt32(max(CGRectGetHeight(self.playableRect) - 2*yMargin, yMargin))
        
        let yPos = CGFloat(arc4random() % divisor) + yMargin
        
        let xMargin = health.zRotation != 0 ? health.size.height : health.size.width
        
        let divisor2 = UInt32(max(CGRectGetWidth(self.playableRect) - 2*xMargin, xMargin))
        
        let xPos = CGFloat(arc4random() % divisor2) + xMargin
        
        health.position = CGPointMake(xPos, yPos)
        health.alpha = 0.3
        
        let sequence = SKAction.sequence([SKAction.fadeInWithDuration(1),
            SKAction.waitForDuration(4),
            SKAction.fadeOutWithDuration(1),
            SKAction.removeFromParent()])
        
        health.runAction(sequence)
        self.delegate.asteroidGenerator(self, didProduceAsteroids: [health], type: .Health)
    }
    
    private func produceBomb() {
        
        let isAIBomb = arc4random() % 2 == 0
        let bomb = !isAIBomb ? Bomb() : AIBomb()
        
        let param = bomb.size.halfMaxSizeParam()
        
        let yMargin = round(param) + 10
        
        var duration = NSTimeInterval(CGRectGetWidth(self.playableRect)/Bomb.Constants.speed)
        
        duration *= isAIBomb ? 2 : 1
        
        let divisor = UInt32(max(CGRectGetHeight(self.playableRect) - 2*yMargin, yMargin))
        
        let yPos = CGFloat(arc4random() % divisor) + yMargin
        
        let xMargin = bomb.zRotation != 0 ? bomb.size.height : bomb.size.width
        
        bomb.position = CGPointMake(CGRectGetMaxX(self.playableRect) + xMargin, yPos)
        
        let moveOutAct = SKAction.moveToX(-xMargin, duration: duration)
        let sequence = SKAction.sequence([moveOutAct,SKAction.runBlock(){ [unowned self] in
            self.delegate.didMoveOutAsteroidForGenerator(self, asteroid: bomb, withType: .Bomb)
        },SKAction.removeFromParent()])
        bomb.runAction(sequence)
        
        self.delegate.asteroidGenerator(self, didProduceAsteroids: [bomb], type: .Bomb)
        
        println("Y position \(yPos) and  Scene height \(CGRectGetHeight(self.playableRect)) Sprite size \(bomb.size)")
    }
    
    private func produceRopeJointAsteroids() {
        var (asteroid1, _) = self.produceRegularAsteroidPrivate(AsteroidGenerator.generateRegularAsteroidSize(),initialAnimation:false)
        
        var (asteroid2, _) = self.produceRegularAsteroidPrivate(AsteroidGenerator.generateRegularAsteroidSize(),initialAnimation:false)
     
        let hRand = CGFloat(arc4random()%200 + 10) + (asteroid1.size.width + asteroid2.size.width)*0.5
        
        
        asteroid2.position.x = asteroid1.position.x + hRand
       
        
        let vRand = CGFloat(arc4random()%200 + 10) + (asteroid1.size.height + asteroid2.size.height)*0.5

        asteroid2.position.y = asteroid1.position.y
        
        
        let center = (asteroid2.position + asteroid1.position)*0.5
        
        let aster1Pos = asteroid1.position - center
        let aster2Pos = asteroid2.position - center
        println("Asteroid 1 position \(aster1Pos). Asteroid 2 position \(aster2Pos)")
        
        let isDirect = true
        var ropePtr:Rope? = nil
        
            let asteroids = RopeJointAsteroids(asteroids: [asteroid1,asteroid2])
        
            if (isDirect) {
                
                let rope = DirectRope(connection1: RopeConnection(position: asteroid1.position,node:asteroid1), connection2: RopeConnection(position: asteroid2.position,node:asteroid2))
                asteroids.rope = rope
            }
        
            let speed:CGFloat = 40.0
            
            let time:NSTimeInterval = NSTimeInterval(CGRectGetWidth(self.playableRect)/speed)
            
            var minXAsteroid:RegularAsteroid!
            var maxXAsteroid:RegularAsteroid!
        
            if (asteroid1.position.x < asteroid2.position.x) {
                minXAsteroid = asteroid1
                maxXAsteroid = asteroid2
            } else {
                minXAsteroid = asteroid2
                maxXAsteroid = asteroid1
            }
        
        
            var minYAsteroid:RegularAsteroid!
            var maxYAsteroid:RegularAsteroid!
        
            if (asteroid1.position.y < asteroid2.position.y) {
                minYAsteroid = asteroid1
                maxYAsteroid = asteroid2
            } else {
                minYAsteroid = asteroid2
                maxYAsteroid = asteroid1
            }
        
        
            let xMin = minXAsteroid.position.x - minXAsteroid.size.width*0.5
            let xMax = maxXAsteroid.position.x + maxXAsteroid.size.width*0.5
        
            let yMax = maxYAsteroid.position.y + maxYAsteroid.size.height*0.5
            let yMin = minYAsteroid.position.y - minYAsteroid.size.height*0.5
        
            let rect = CGRectMake(xMin, yMin, xMax - xMin, yMax - yMin)
       
        asteroids.position =  CGPointMake(CGRectGetMaxX(rect), CGRectGetMidY(rect))
        
        asteroid2.position = aster2Pos
        asteroid1.position = aster1Pos
        
        println("Asteroid position \(asteroids.position)")

            let moveAct = SKAction.moveToX(CGRectGetMinX(rect) - CGRectGetMaxX(rect), duration: time)
            
            let rotate = SKAction.rotateByAngle(CGFloat(M_1_PI*0.5), duration: Double(1))
            let rotateAlways = SKAction.repeatActionForever(rotate)
        
            let moveDelAction = SKAction.group([SKAction.sequence([moveAct,SKAction.runBlock({ () -> Void in
                self.delegate.didMoveOutAsteroidForGenerator(self, asteroid: asteroids, withType: .RopeBased)
            }),SKAction.removeFromParent()]), rotateAlways])

            asteroids.runAction(moveDelAction, withKey: "moveDelAction")
        
            self.delegate.asteroidGenerator(self, didProduceAsteroids:[asteroids], type: .RopeBased)
        
    }
    
    
    private func produceTrashSprites() {
        
        var minSpeed:CGFloat = CGFloat.max
        var minIndex = 0
        var sprites:[SKSpriteNode] = [SKSpriteNode]()
        let actName:String = "moveDelAction"
        
        println("Scene rect \(self.playableRect)")
        
        let count = 3
        
        var spriteFrames:[CGRect] = []
        
        for index in 1...count {
            
            let textName = "trash_asteroid_\(index)"
            
            let texture = trashAtlas?.textureNamed(textName)
            
            let sprite = SKSpriteNode(texture: texture)
            sprite.size = texture!.size()
            
            var speed = self.trashAvg
            if (arc4random()%3 == 1) {
                speed = self.trashAvg + self.trashRange * 0.5
            }
            else if (arc4random()%2 == 1 ) {
                speed -= self.trashRange
            }
            else {
                speed += self.trashRange
            }
            
            if (minSpeed < speed) {
                minSpeed = speed
                minIndex = index - 1
            }
            
            let time:NSTimeInterval = NSTimeInterval(CGRectGetWidth(self.playableRect)/speed)
            
            let moveAct = SKAction.moveToX(-sprite.size.width*0.5, duration: time)
            
            let rotate = SKAction.rotateByAngle(CGFloat(M_1_PI*0.5), duration: Double(1))
            let rotateAlways = SKAction.repeatActionForever(rotate)
            
            let blinkIn   = SKAction.colorizeWithColor(UIColor.redColor(), colorBlendFactor: 1.0, duration: 0.0)
            let blinkWait = SKAction.waitForDuration(0.25)
            let blinkOut  = SKAction.colorizeWithColorBlendFactor(0.0, duration: 0.1)
            
            
            let blinkInOut = SKAction.repeatActionForever(SKAction.sequence([blinkIn, blinkWait ,blinkOut]))
            
            let moveDelAction = SKAction.group([SKAction.sequence([moveAct,SKAction.runBlock({ () -> Void in
                self.delegate.didMoveOutAsteroidForGenerator(self, asteroid: sprite, withType: .Trash)
            }),SKAction.removeFromParent()]), rotateAlways,blinkInOut])
            sprite.runAction(moveDelAction,withKey: actName )
            
            let yMargin = round(1.2*max(sprite.size.width,sprite.size.height)) + 10
            let divisor = UInt32(CGRectGetHeight(self.playableRect) - 2*yMargin)
            
            var yPos  = CGFloat(arc4random() % divisor) + yMargin
            let xMargin = sprite.zRotation != 0 ? sprite.size.height : sprite.size.width
            
            var curFrame = CGRectMake(xMargin - sprite.size.width * 0.5, yPos - sprite.size.height * 0.5, sprite.size.width, sprite.size.height)
            
            for var i = 0 ; i < spriteFrames.count; i++ {
                
                let prevFrame = spriteFrames[i];
                
                var wasInside = false
                
                while (CGRectIntersectsRect(prevFrame, curFrame)) {
                    yPos =  CGFloat(arc4random() % divisor) + yMargin
                    curFrame = CGRectMake(xMargin - sprite.size.width * 0.5, yPos - sprite.size.height * 0.5, sprite.size.width, sprite.size.height)
                    wasInside = true
                }
                
                if (wasInside) {
                    i = -1
                }
            }
            
            spriteFrames.append(curFrame)
            
            sprite.anchorPoint = CGPointMake(0.5, 0.5)
            sprite.position = CGPointMake(CGRectGetWidth(self.playableRect) + xMargin, yPos)
            
            println("Trash # \(index) sprite: \(sprite)")
            
            sprite.name = textName
            sprite.physicsBody = SKPhysicsBody(texture: texture!, size: texture!.size())
            //sprite.physicsBody!.fieldBitMask = EntityCategory.BlakHoleField
            sprite.physicsBody!.categoryBitMask = EntityCategory.TrashAsteroid
            sprite.physicsBody!.contactTestBitMask = EntityCategory.Player | EntityCategory.PlayerLaser
            sprite.physicsBody!.collisionBitMask = EntityCategory.TrashAsteroid
            
            sprites.append(sprite)
        }
        
        
        assert(sprites.count == count, "Sprites are not \(spriteFrames.count) items")
        
        if (EnabledDisplayDebugLabel) {
        
            var ySum:CGFloat = 0
        
            for sprite in sprites {
                ySum += sprite.position.y
            }
            
            ySum /= CGFloat(sprites.count)
            
            
            appendDebugLabels(sprites.last!)
        }
        
        self.delegate.asteroidGenerator(self, didProduceAsteroids: sprites, type: .Trash)
    }
    
    private func appendDebugLabels(node:SKSpriteNode!) {
        
        
        let label = NORLabelNode(fontNamed: "gamerobot")
        label.text = "Can't move\n Attack trash asteroids"
        label.fontColor = SKColor.redColor()
        label.fontSize = 40
        label.lineSpacing = 2
        label.position = CGPointMake(node.size.width+50, node.size.halfHeight())
        label.zRotation = CGFloat(-M_PI_2)
        node.addChild(label)
    }

    
    internal func generateItem() {
        
        if paused || !canFire {
            return
        }
        canFire = false
        
        var currentAstType:AsteroidType = .None
        do {
        
            let randValue = arc4random()%12
        
            if (randValue < 2) {
                currentAstType = .Trash
            } else if (randValue < 4) {
                currentAstType = .Bomb
            } else if (randValue < 6) {
                currentAstType = .RopeBased
            }else if (randValue < 8) {
                currentAstType = .Regular
            } else if (randValue < 10) {
                currentAstType = .Health
                
                let curTime = NSDate.timeIntervalSinceReferenceDate()
                if curTime - self.healthUnitProdTime >= 10 {
                    self.healthUnitProdTime = curTime
                }
                else {
                    currentAstType = .None
                }
        
            } else {
                currentAstType = .Regular
            }
        
            
        } while (currentAstType == self.prevAsteroidType || currentAstType == .None)
        
        //HACK
        currentAstType = .RopeBased
        
        self.prevAsteroidType = self.curAsteroidType
        self.curAsteroidType = currentAstType
        
        
        println("=== Produced current type \(self.curAsteroidType) === ")
        
        switch currentAstType {
        case .Trash:
            println("=== Produced current type .Trash === ")
            self.produceTrashSprites()
            break
        case .RopeBased:
            println("=== Produced current type .RopeBased === ")
            self.produceRopeJointAsteroids()
            break
        case .Bomb:
            println("=== Produced current type .Bomb === ")
            self.produceBomb()
            break
        case .Regular:
            println("=== Produced current type .Regular === ")
            let regSize = AsteroidGenerator.generateRegularAsteroidSize()
            self.produceRegularAsteroid(regSize)
            break
        case .Health:
            println("=== Produced current type .Health === ")
            self.produceHealthUnit()
            break
        default:
            println("=== Produced current type .Default ===  \(currentAstType) ")
            
            break
        }
        
    }
    
    private class func generateRegularAsteroidSize() -> RegularAsteroidSize
    {
        let randValue = arc4random()%3
        var regSize:RegularAsteroidSize
        
        if (randValue == 2) {
            regSize = RegularAsteroidSize.Big
        } else if (randValue == 1) {
            regSize = RegularAsteroidSize.Small
        } else {
            regSize = RegularAsteroidSize.Medium
        }
        
        return regSize
    }
}
