//
//  Player.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 4/12/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit
import SpriteKit

struct EntityCategory {
    static var Asteroid: UInt32  = 1<<0
    static var Player : UInt32  = 1 << 1
    static var Boss : UInt32 = 1 << 3
    static var PlayerLaser: UInt32 = 1 << 2
}

enum PlayerMovement {
    case Fly
    case Teleport
}

enum PlayerMode {
    case Idle
    case Firing
}

class Player: SKSpriteNode {
    private let engineNodeName = "engineEmitter"
    private let projectileNodeName = "projectileNode"
    private var numberOfThrownProjectiles = 0
    private var movementStyle:PlayerMovement = .Fly
    private var playerMode:PlayerMode = .Idle
    
    var projectileSpeed : Float = 40
    
    var flyDuration : NSTimeInterval  = 2.0
    var teleportDuration : NSTimeInterval = 0.3
    
    init(position:CGPoint) {
        let texture = SKTexture(imageNamed: "player")
        
        super.init(texture: texture,color:SKColor.whiteColor(), size:texture.size())
        
        self.name = "Player"
        
        createEngine()
        createProjectileGun()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: Engine methods
    
    private func createEngine() {
        
        let engineEmitter = SKEmitterNode(fileNamed: "Engine.sks")
        
        let size = self.texture!.size()
        
        engineEmitter.position = CGPoint(x: size.width * -0.5, y: size.height * -0.3)
        engineEmitter.name = engineNodeName
        addChild(engineEmitter)
        
        engineEmitter.targetNode = scene
        
        engineEmitter.hidden = true
    }

    func enableEngine() {
        self.defineEngineState(false)
    }
    
    func disableEngine() {
        self.defineEngineState(true)
    }
    
    func defineEngineState(enabled:Bool) {
        
        if let engineNode = self.childNodeWithName(engineNodeName) {
            engineNode.hidden = enabled
        }
    }
    
    //MARK: Movement methods
    
    private func flyToPoint(point:CGPoint) {
        
        let moveAct =  SKAction.moveTo(point, duration: self.flyDuration)
        
        let eEngine = SKAction.runBlock({ () -> Void in
            self.enableEngine()
        })
        
        let sEngine = SKAction.runBlock({ () -> Void in
            self.disableEngine()
        })
        
        let seg = SKAction.sequence([eEngine,moveAct,sEngine])
        
        self.runAction(seg)
    }
    
    private func teleportToPoint(point:CGPoint) {
        
        let time1 = self.teleportDuration/10;
        let scale1 = SKAction.scaleBy(1.2, duration: time1)
        let waitAction1 = SKAction.waitForDuration(time1)
        
        
        let time2 = time1
        
        let oldW = self.size.width
        
        let scaleToSmall = SKAction.resizeToWidth(0, duration:time2)
        
        let fadeOut = SKAction.fadeOutWithDuration(time2)
        
        let waitAction = SKAction.waitForDuration(time2)
        
        let moveAction = SKAction.runBlock { () -> Void in
            self.position = point
        }
        
        let fadeIn = SKAction.fadeInWithDuration(time2)
        
        let scaleToNormal = SKAction.resizeToWidth(oldW, duration: time2)
        
        let seq1 = SKAction.sequence([scale1,waitAction1,SKAction.group([scaleToSmall,fadeOut]),SKAction.group([scaleToSmall,fadeOut])])
        
        self.runAction(seq1)
    }
    
    func moveToPoint(point:CGPoint) {
        
        if self.movementStyle == PlayerMovement.Fly {
            self.flyToPoint(point)
        } else if self.movementStyle == PlayerMovement.Teleport {
            self.teleportToPoint(point)
        }
    }
    
    //MARK: Projectile (Shooting) methods
    
    private func createProjectileGun() {
    
        let texute = SKTexture(imageNamed: "projectile")
        var size = texture?.size()
        
        size?.width *= 0.8
        size?.height *= 0.8
        
        let miniProjectile = SKSpriteNode(texture: texture, size: size!)
        miniProjectile.name = projectileNodeName
        miniProjectile.hidden = true
        
        let point = CGPointMake(size!.width*0.5, size!.height*0.5)
        miniProjectile.position = point
        
        addChild(miniProjectile)
    }
    
    func enableProjectileGun() {
        defineProjectileGunState(false)
    }
    
    func disableProjectileGun() {
        defineProjectileGunState(true)
    }
    
    private func defineProjectileGunState(hidden:Bool) {
        if let node = self.childNodeWithName(projectileNodeName) {
            node.hidden = hidden
            self.numberOfThrownProjectiles = 0
        }
    }
    
    
    func throwProjectileToLocation(location:CGPoint) -> SKNode! {
        let xDiff = location.x - self.position.x
        let yDiff = location.y - self.position.y
        
        let len = sqrt(pow(xDiff, 2) + pow(yDiff, 2))
        
        return throwProjectileAtDirection(CGVectorMake(xDiff/len, yDiff/len))
    }
    
    
    private func throwProjectileAtDirection(vector:CGVector) -> SKNode! {
        
        let projectile = SKSpriteNode(imageNamed: "projectile")
        
        let isLeft = vector.dx < 0
        let isUp  = vector.dy > 0
        let signX:CGFloat = isLeft ? -1 : 1
        let signY:CGFloat = isUp ? 1 : -1
        let xPos = self.position.x + CGFloat(signX * (self.size.width*0.5+10))
        
        let position = CGPointMake(xPos, self.position.y)
        projectile.alpha = 0.0
        
        var yDiff:CGFloat = 0.0
        
        if (isUp) {
            yDiff = self.scene!.size.height + projectile.size.height*0.5 - position.y
        }
        else if (vector.dy != 0){
            yDiff =  -(position.y + projectile.size.height * 0.5)
        }
        
        var xDiff:CGFloat = 0.0
        
        if (yDiff != 0 ) {
            xDiff = vector.dx/vector.dy * yDiff
        } else if (isLeft) {
            xDiff = -(position.x + projectile.size.width * 0.5)
        } else {
            xDiff = self.scene!.size.width + projectile.size.width * 0.5 - position.x
        }
        
        let positionFinal = CGPointMake(position.x + xDiff, position.y + yDiff)
        let length = Double(sqrt(pow(xDiff, 2) + pow(yDiff, 2)))
        
        
        let fadeIn = SKAction.fadeInWithDuration(0.2)
        let moveTo = SKAction.moveTo(positionFinal, duration: length/Double(self.projectileSpeed))
        
        projectile.runAction(SKAction.sequence([fadeIn,moveTo,SKAction.removeFromParent()]))
        projectile.position = position
        projectile.name = "projectile_\(++self.numberOfThrownProjectiles)"
        projectile.physicsBody?.collisionBitMask = 0
        projectile.physicsBody?.contactTestBitMask = EntityCategory.Asteroid
        
        projectile.userData = ["owner":"p"]
        
        
        self.parent!.addChild(projectile)
        
        return projectile
    }
    
    
}
