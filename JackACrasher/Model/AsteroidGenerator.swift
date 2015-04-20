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
    func asteroidGenerator(generator:AsteroidGenerator, didProduceAsteroids:[SKSpriteNode], type:AsteroidType)
    func didMoveOutAsteroidForGenerator(generator:AsteroidGenerator, asteroid:SKSpriteNode, withType type:AsteroidType)
}

class AsteroidGenerator: NSObject {
    
    private let sceneSize:CGSize
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
    
    init(sceneSize size:CGSize, andDelegate delegate:AsteroidGeneratorDelegate) {
        self.sceneSize = size
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

    private func produceRegularAsteroid(size:RegularAsteroidSize) {
        //HACK:
        var imageName = "asteroid-medium"
        switch (size) {
        case .Medium:
            break
        default:
            break
        }
        
        produceRegularAsteroid(imageName)
    }
    
    private func produceRegularAsteroid(imageName:String) {
        
        let texture = self.spriteAtlas.textureNamed(imageName)
        let asteroidSpeed:CGFloat = 30
        
        let body = SKPhysicsBody(texture: texture, size: texture.size())
        
        body.categoryBitMask = EntityCategory.RegularAsteroid
        body.collisionBitMask = 0
        body.contactTestBitMask = EntityCategory.Player | EntityCategory.PlayerLaser
        
        let sprite = SKSpriteNode(texture: texture, size: texture.size())
        sprite.physicsBody = body
        
        let yMargin = round(0.5 * max(sprite.size.width,sprite.size.height))
        
        let duration = NSTimeInterval(sceneSize.width/asteroidSpeed)
        
        let divisor = UInt32(sceneSize.height - yMargin)
        
        let yPos = CGFloat(arc4random() % divisor) + yMargin
        
        let xMargin = sprite.zRotation != 0 ? sprite.size.height : sprite.size.width
        
        sprite.position = CGPointMake(sceneSize.width + xMargin, yPos)
        
        let moveOutAct = SKAction.moveToX(-xMargin, duration: duration)
        let sequence = SKAction.sequence([moveOutAct,SKAction.runBlock({ () -> Void in
            self.delegate.didMoveOutAsteroidForGenerator(self, asteroid: sprite, withType: .Regular)
        }),SKAction.removeFromParent()])
        sprite.runAction(sequence)
        
        self.delegate.asteroidGenerator(self, didProduceAsteroids: [sprite], type: .Regular)
        
        println("Y position \(yPos) and  Scene height \(sceneSize.height) Sprite size \(sprite.size)")
        
        
    }
    
    private func produceBombSprite() {
        let bombSpeed:CGFloat = 200
        let bombTexture = self.spriteAtlas.textureNamed("cartoon-bomb")
        
        let sprite = SKSpriteNode(texture: bombTexture)
        sprite.zRotation = CGFloat(M_PI*0.5)
        
        sprite.xScale = 0.25
        
        let yMargin = round(0.5 * max(sprite.size.width,sprite.size.height))
        let divisor = UInt32(sceneSize.height - yMargin)
        
        let yPos = CGFloat(arc4random() % divisor) + yMargin
        
        let xMargin = sprite.zRotation != 0 ? sprite.size.height : sprite.size.width
        
        sprite.position = CGPointMake(sceneSize.width + xMargin, yPos)
        
        sprite.physicsBody = SKPhysicsBody(texture: bombTexture, size: sprite.size)
        sprite.physicsBody!.collisionBitMask = 0
        sprite.physicsBody!.contactTestBitMask = EntityCategory.Player | EntityCategory.PlayerLaser
        sprite.physicsBody!.categoryBitMask = EntityCategory.Bomb
        sprite.userData = ["radius":50]
        
        let duration = NSTimeInterval(sceneSize.width/bombSpeed)
        
        let moveOutAct = SKAction.moveToX(-xMargin, duration: duration)
        let sequence = SKAction.sequence([moveOutAct,SKAction.runBlock({ () -> Void in
            self.delegate.didMoveOutAsteroidForGenerator(self, asteroid: sprite, withType: .Trash)
        }),SKAction.removeFromParent()])
        sprite.runAction(sequence)
        
        self.delegate.asteroidGenerator(self, didProduceAsteroids: [sprite], type: .Bomb)
        
        println("Y position \(yPos) and  Scene height \(sceneSize.height) Sprite size \(sprite.size)")
    }
    
    private func produceTrashSprites() {
        
        var minSpeed:CGFloat = CGFloat.max
        var minIndex = 0
        var sprites:[SKSpriteNode] = [SKSpriteNode]()
        let actName:String = "moveDelAction"
        
        for index in 1...3 {
            
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
            
            let time:NSTimeInterval = NSTimeInterval(self.sceneSize.width/speed)
            
            let moveAct = SKAction.moveToX(-sprite.size.width*0.5, duration: time)
            
            let rotate = SKAction.rotateByAngle(CGFloat(M_1_PI*0.5), duration: Double(1))
            let rotateAlways = SKAction.repeatActionForever(rotate)
            
            let blinkIn = SKAction.colorizeWithColor(UIColor.redColor(), colorBlendFactor: 0.4, duration: min(1,time*0.5))
            let blinkOut = blinkIn.reversedAction()
            
            let blinkInOut = SKAction.repeatActionForever(SKAction.sequence([blinkIn,blinkOut]))
            
            let moveDelAction = SKAction.group([SKAction.sequence([moveAct,SKAction.runBlock({ () -> Void in
                self.delegate.didMoveOutAsteroidForGenerator(self, asteroid: sprite, withType: .Trash)
            }),SKAction.removeFromParent()]), rotateAlways,blinkInOut])
            sprite.runAction(moveDelAction,withKey: actName )
            
            let position:Int32 = Int32(arc4random() % 4) * (arc4random()%2 == 1 ? 1 : -1 )
            
            let width = self.sceneSize.width*0.2
            var yPos = width * CGFloat(position) + self.sceneSize.height * 0.5
            
            if (yPos <= sprite.size.height) {
                yPos = sprite.size.height + 50
            }
            
            if (yPos > self.sceneSize.height) {
                yPos = CGFloat(round(self.sceneSize.height * 0.8 - sprite.size.height))
            }
            
            yPos = min(max(yPos,200),800)
            
            sprite.position = CGPointMake(self.sceneSize.width + sprite.size.width*0.5, yPos)
            sprite.name = textName
            sprite.physicsBody = SKPhysicsBody(texture: texture!, size: texture!.size())
            sprite.physicsBody!.categoryBitMask = EntityCategory.TrashAsteroid
            sprite.physicsBody!.contactTestBitMask = EntityCategory.Player | EntityCategory.PlayerLaser
            sprite.physicsBody!.collisionBitMask = EntityCategory.TrashAsteroid | EntityCategory.Asteroid
            
            sprites.append(sprite)
        }
        
        assert(sprites.count == 3, "Sprites are not 3 items")
        
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
            
        case .Bomb:
            self.produceBombSprite()
            break
        case .Regular:
            
            let randValue = arc4random()%3
            var regSize:RegularAsteroidSize
            
            if (randValue == 2) {
                regSize = RegularAsteroidSize.Big
            } else if (randValue == 1) {
                regSize = RegularAsteroidSize.Small
            } else {
                regSize = RegularAsteroidSize.Medium
            }
            
            self.produceRegularAsteroid(regSize)
        default:
            break
        }
        
    }
}
