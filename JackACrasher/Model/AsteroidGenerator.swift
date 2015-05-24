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
    private var trashAtlas:SKTextureAtlas! = SKTextureAtlas(named: "trash")
    private var spriteAtlas:SKTextureAtlas! = SKTextureAtlas(named: "sprites")
    private let trashAvg:CGFloat   = 80.0
    private let trashRange:CGFloat = 10.0

    internal var paused:Bool = false {
        didSet {
            let didChange = (paused != oldValue)
            if (paused) {
                if (didChange) {
                    self.stop()
                }
            }
            else {
                if (didChange) {
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
    }
    
    internal func start() {
        canFire = true
        if !self.timer.valid {
            redifineTimer()
        }
    }
    
    internal func stop() {
        
        if (self.timer.valid) {
            self.timer.invalidate()
        }
        canFire = false
    }
    
    private func redifineTimer() {
        
        self.timer = NSTimer.scheduledTimerWithTimeInterval(3, target: self, selector: "generateItem", userInfo: nil, repeats: true)
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
    
    private func produceRegularAsteroidPrivate(size:RegularAsteroidSize,initialAnimation:Bool) -> (asteroid:RegularAsteroid,actions:SKAction)  {
        
        let asteroidSpeed:CGFloat = 30
        
        let sprite = RegularAsteroid(asteroid: size, maxLife: size == .Big ? 5: 3,needToAnimate:initialAnimation)
        
        let yMargin = round(1.2 * max(sprite.size.width,sprite.size.height)) + 10
        
        let duration = NSTimeInterval(CGRectGetWidth(self.playableRect)/asteroidSpeed)
        
        let divisor = UInt32(CGRectGetHeight(self.playableRect) - 2*yMargin)
        
        let yPos = CGFloat(arc4random() % divisor) + yMargin
        
        let xMargin = sprite.zRotation != 0 ? sprite.size.height : sprite.size.width
        
        sprite.position = CGPointMake(CGRectGetMaxX(self.playableRect) + xMargin, yPos)
        
        let sequence =  produceSeqActionToAsteroid(sprite, asteroidSpeed: asteroidSpeed)
        
        println("Y position \(yPos) and  Scene height \(CGRectGetHeight(self.playableRect)) Sprite size \(sprite.size)")
        
        return (asteroid:sprite,actions:sequence)
    }

    private func produceRegularAsteroid(size:RegularAsteroidSize) {
        
        let (sprite,sequence) = self.produceRegularAsteroidPrivate(size,initialAnimation:true)
        
        sprite.runAction(sequence)
        sprite.startAnimation()
        
        self.delegate.asteroidGenerator(self, didProduceAsteroids: [sprite], type: .Regular)
        
    }
    
    private func produceBombSprite() {
        let bombSpeed:CGFloat = 200
        let bombTexture = self.spriteAtlas.textureNamed("cartoon-bomb")
        
        let sprite = SKSpriteNode(texture: bombTexture)
        sprite.zRotation = CGFloat(M_PI*0.5)
        
        sprite.xScale = 0.25
        
        let yMargin = round(1 * max(sprite.size.width,sprite.size.height)) + 10
        
        let duration = NSTimeInterval(CGRectGetWidth(self.playableRect)/bombSpeed)
        
        let divisor = UInt32(CGRectGetHeight(self.playableRect) - 2*yMargin)
        
        let yPos = CGFloat(arc4random() % divisor) + yMargin
        
        let xMargin = sprite.zRotation != 0 ? sprite.size.height : sprite.size.width
    
        sprite.position = CGPointMake(CGRectGetMaxX(self.playableRect) + xMargin, yPos)
        
        sprite.physicsBody = SKPhysicsBody(texture: bombTexture, size: sprite.size)
        sprite.physicsBody!.collisionBitMask = 0
        sprite.physicsBody!.contactTestBitMask = EntityCategory.Player | EntityCategory.PlayerLaser
        sprite.physicsBody!.categoryBitMask = EntityCategory.Bomb
        sprite.userData = ["radius":50]
        
        let moveOutAct = SKAction.moveToX(-xMargin, duration: duration)
        let sequence = SKAction.sequence([moveOutAct,SKAction.runBlock({ () -> Void in
            self.delegate.didMoveOutAsteroidForGenerator(self, asteroid: sprite, withType: .Trash)
        }),SKAction.removeFromParent()])
        sprite.runAction(sequence)
        
        self.delegate.asteroidGenerator(self, didProduceAsteroids: [sprite], type: .Bomb)
        
        println("Y position \(yPos) and  Scene height \(CGRectGetHeight(self.playableRect)) Sprite size \(sprite.size)")
    }
    
    private func produceRopeJointAsteroids() {
        var (asteroid1, _) = self.produceRegularAsteroidPrivate(AsteroidGenerator.generateRegularAsteroidSize(),initialAnimation:false)
        
        var (asteroid2, _) = self.produceRegularAsteroidPrivate(AsteroidGenerator.generateRegularAsteroidSize(),initialAnimation:false)
     
        let isR = true
        let isL = false
        
        let isU = false
        let isD = false
        
        let hRand = CGFloat(arc4random()%200 + 10) + (asteroid1.size.width + asteroid2.size.width)*0.5
        
        if (isR) {
           asteroid2.position.x = asteroid1.position.x + hRand
        } else if (isL) {
            asteroid2.position.x = asteroid1.position.x - hRand
        } else if (!isL && !isR) {
            asteroid1.position.x = asteroid2.position.x
        }
        
        let vRand = CGFloat(arc4random()%200 + 10) + (asteroid1.size.height + asteroid2.size.height)*0.5

        if (isU) {
            asteroid2.position.y = asteroid1.position.y + vRand
        } else if (isD) {
            asteroid2.position.y = asteroid1.position.y - vRand
        } else if (!isD  && !isU) {
            asteroid2.position.y = asteroid1.position.y
        }
        
        let center = (asteroid2.position + asteroid1.position)*0.5
        
        let aster1Pos = asteroid1.position - center
        let aster2Pos = asteroid2.position - center
        println("Asteroid 1 position \(aster1Pos). Asteroid 2 position \(aster2Pos)")
        
        let con1 = RopeConnection(position: aster1Pos, node: asteroid1)
        let con2 = RopeConnection(position: aster2Pos, node: asteroid2)
        
        let isDirect = true
        var ropePtr:Rope? = nil
        
        /*if (isDirect) {
            
            ropePtr = DirectRope(connection1: con1, connection2: con2)
        }*/
        
        //if let rope = ropePtr {
            let asteroids = RopeJointAsteroids(asteroids: [asteroid1,asteroid2])
        
            if (isDirect) {
                
                let rope = DirectRope(connection1: RopeConnection(position: asteroid1.position,node:asteroid1), connection2: RopeConnection(position: asteroid2.position,node:asteroid2))
                //rope.createRopeRings(self.delegate as! SKScene)
                //HACK:
                //rope.position = CGPointMake(500, 500)
                //(self.delegate as! SKNode).addChild(rope)
                //end HACK;
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
            //println("Asteroids \(asteroids). Rope \(asteroids.rope!)")
        
        //MARK: HACK
            println("Asteroid 1 \(asteroid1), Asteroid 2 \(asteroid2)")
            //asteroid2.removeFromParent()
            //asteroid1.removeFromParent()
        
            //asteroid1.runAction(moveDelAction, withKey: "@@")
        
            self.delegate.asteroidGenerator(self, didProduceAsteroids:[asteroids] /*[asteroid1,asteroid2]*/, type: .RopeBased)
        //}
        
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
            
            let blinkIn = SKAction.colorizeWithColor(UIColor.redColor(), colorBlendFactor: 0.4, duration: min(1,time*0.5))
            let blinkOut = SKAction.colorizeWithColor(SKColor.clearColor(), colorBlendFactor: 0.0, duration: blinkIn.duration)
            
            let blinkInOut = SKAction.repeatActionForever(SKAction.sequence([blinkIn,blinkOut]))
            
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
            sprite.physicsBody!.categoryBitMask = EntityCategory.TrashAsteroid
            sprite.physicsBody!.contactTestBitMask = EntityCategory.Player | EntityCategory.PlayerLaser
            sprite.physicsBody!.collisionBitMask = EntityCategory.TrashAsteroid | EntityCategory.Asteroid
            
            sprites.append(sprite)
        }
        
        
        assert(sprites.count == count, "Sprites are not \(spriteFrames.count) items")
        
        self.delegate.asteroidGenerator(self, didProduceAsteroids: sprites, type: .Trash)
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
                currentAstType = .Joint
            }else if (randValue < 8) {
                currentAstType = .Regular
            } else {
                currentAstType = .RopeBased
            }
            
            
        } while (currentAstType == self.prevAsteroidType )
        
        //HACK: warning
        
        self.prevAsteroidType = .None
        currentAstType = .Regular
        
        self.prevAsteroidType = currentAstType
        
        switch currentAstType {
        case .Trash:
            self.produceTrashSprites()
            break
        case .RopeBased:
            self.produceRopeJointAsteroids()
            break
        case .Bomb:
            self.produceBombSprite()
            break
        case .Regular:
            
            let regSize = AsteroidGenerator.generateRegularAsteroidSize()
            
            self.produceRegularAsteroid(regSize)
        default:
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
