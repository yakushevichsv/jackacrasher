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
    static var Asteroid: UInt32  = 1 << 0
    static var Player : UInt32  = 1 << 1
    static var PlayerLaser: UInt32 = 1 << 2
    static var Boss : UInt32 = 1 << 3
    static var TrashAsteroid:UInt32 = 1 << 4
    static var Bomb : UInt32 = 1 << 5
    static var RegularAsteroid:UInt32 = 1 << 6
    static var Rope:UInt32 = 1 << 7
    static var RadialField:UInt32 = 1 << 8
}

typealias ForceType = CGFloat

enum PlayerMovement {
    case Fly
    case Teleport
}

enum PlayerMode {
    case Idle
    case CanFire
}

enum PlayerFlyDistance {
    case None
    case Short
    case Middle
    case Long
}

private let playerBGNodeName = "playerBGNode"
private let playerImageName = "player"

private let hammerImageName = "throw_hammer"
private let hammerNodeName = "throwHammer"

private let damageEmitterNode = "Damage"
private let damageEmitterNodeName = "damageNode"

private let playerNode = "playerNode"

class Player: SKNode, ItemDestructable {
    private let engineNodeName = "engineEmitter"
    private let projectileNodeName = "projectileNode"
    private var numberOfThrownProjectiles = 0
    private var movementStyle:PlayerMovement = .Fly
    private var playerMode:PlayerMode = .Idle
    
    private var hammerSprite:SKSpriteNode! = nil
    
    private static var sBGSprite:SKSpriteNode!
    private static var sHammerSprite:SKSpriteNode!
    private static var sDamageEmitter:SKEmitterNode!
    
    private static var sContext:dispatch_once_t = 0
    
    var health: ForceType = 100
    
    private var playerBGSprite:SKSpriteNode! {
        return self.childNodeWithName(playerBGNodeName) as! SKSpriteNode
    }
    
    internal var size :CGSize {
        return Player.sBGSprite.size
    }
    
    internal class func loadAssets() {
       
        dispatch_once(&sContext) { () -> Void in
           let playerSprite = SKSpriteNode(imageNamed: playerImageName)
            playerSprite.name = playerBGNodeName
            Player.sBGSprite = playerSprite
            
            let hammerSprite = SKSpriteNode(imageNamed: hammerImageName)
            hammerSprite.name = hammerNodeName
            Player.sHammerSprite = hammerSprite
            
            let emitter = SKEmitterNode(fileNamed: damageEmitterNode)
            emitter.name = damageEmitterNodeName
            Player.sDamageEmitter = emitter
        }
    }
    
    //TODO: add methods for loading textures....
    
    internal var punchForce:ForceType = 1
    
    private typealias playerDistFlyMapType = Dictionary<PlayerFlyDistance,(distance:CGFloat,eParticleLifeTime:CGFloat)>
    
    
    private var playerDistFlyMap: playerDistFlyMapType!
    
    
    var projectileSpeed : Float = 600
    
    var flyDurationSpeed : Float = 400
    var teleportDuration : NSTimeInterval = 0.3
    
    
    init(position:CGPoint) {
        super.init()
        
        let bgSprite = Player.sBGSprite.copy() as! SKNode
        bgSprite.position = CGPointZero
        
        addChild(bgSprite)
        
        
        self.name = playerNode
        self.position = position
        
        self.playerDistFlyMap = createEngine()
        
        createPhysicsBody()
        createProjectileGun()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createPhysicsBody() {
    
        let aPhysBody = SKPhysicsBody(rectangleOfSize: self.size)
        aPhysBody.categoryBitMask = EntityCategory.Player
        aPhysBody.contactTestBitMask = 0
        aPhysBody.collisionBitMask = 0
        enableGravityReceptivity()
        self.physicsBody = aPhysBody
    }
    
    //MARK:Player's gravity receptivity
    internal func disableGravityReceptivity() {
        setGravityReceptivity(false)
    }
    
    internal func enableGravityReceptivity() {
        setGravityReceptivity(true)
    }
    
    private func setGravityReceptivity(enabled:Bool) {
        self.physicsBody?.fieldBitMask = enabled ? EntityCategory.RadialField : 0
    }
    
    //MARK: Hammer  methods
    internal func displayHammer() {
        
        self.hammerSprite = Player.displayHammerForSprite(self,size:self.size)
    }
    
    internal class func displayHammerForSprite(sprite:SKSpriteNode!) -> SKSpriteNode! {
        return displayHammerForSprite(sprite, size: sprite.size)
    }

    internal class func displayHammerForSprite(sprite:SKNode!,size:CGSize) -> SKSpriteNode! {
        
        var hammerSprite:SKSpriteNode!
        
        if (sprite.childNodeWithName(Player.sHammerSprite.name!) == nil) {
            
            hammerSprite = Player.sHammerSprite.copy() as! SKSpriteNode
            hammerSprite.anchorPoint = CGPointZero
            sprite.addChild(hammerSprite)
        }
        
        let angle = (sprite.xScale > 0 ? -1.0 : 1.0 ) * CGFloat(M_PI_4)
        hammerSprite.zRotation = angle
        hammerSprite.hidden = false
        
        var xOffset : CGFloat = -CGFloat(round(size.width * 0.5))
        if (angle > 0) {
            xOffset *= -1
        }
        hammerSprite.position = CGPointMake(xOffset, -CGFloat(round(hammerSprite.size.height * 0.0)))
        
        return hammerSprite
    }
    
    //MARK: Engine methods
    
    private func createEngine() -> playerDistFlyMapType {
        
        let engineEmitter = SKEmitterNode(fileNamed: "Engine.sks")
        
        let size = self.size
        
        engineEmitter.position = CGPoint(x: size.width * -0.5, y: size.height * -0.3)
        engineEmitter.name = engineNodeName
        addChild(engineEmitter)
        
        engineEmitter.targetNode = scene
        
        var dic = playerDistFlyMapType()
        
        let distance = max(self.size.width,self.size.height)*sqrt(2)
        let eMax = engineEmitter.particleLifetime
        dic[.Long] = (distance,eMax)
        dic[.Middle] = (distance/1.2,eMax*0.5)
        dic[.Short] = (distance/2,eMax*0.1)
        
        
        engineEmitter.hidden = true
        
        return dic
    }

    func defineEngineStateUsingDistance(dist:CGFloat) {
        
        var playerDist: PlayerFlyDistance
        if (dist == 0) {
            playerDist = .None
        }
        else {
        
            let sDist = self.playerDistFlyMap[.Short]!.distance;
            let mDist = self.playerDistFlyMap[.Middle]!.distance;
            
            if (sDist >= dist) {
                playerDist = .Short
            } else if (mDist >= dist) {
                playerDist = .Middle
            } else {
                playerDist = .Long
            }
        }
        
        self.defineEngineState(playerDist)
    }
    
    func disableEngine() {
        self.defineEngineStateUsingDistance(0)
    }
    
    func defineEngineState(flyDistance:PlayerFlyDistance) {
        
        if let engineNode = self.childNodeWithName(engineNodeName) as? SKEmitterNode {
            
            if (.None == flyDistance) {
                engineNode.hidden = true
            }
            else {
                engineNode.hidden = false
                engineNode.particleLifetime = self.playerDistFlyMap[flyDistance]!.eParticleLifeTime
            }
        }
    }
    
    //MARK: Movement methods
    
    internal func placeAtPoint(point:CGPoint) {
        if self.actionForKey("flyToPoint") != nil {
            self.removeActionForKey("flyToPoint")
        }
        self.position = point
        disableEngine()
    }
    
    private func flyToPoint(point:CGPoint) {
        
        
        if self.actionForKey("flyToPoint") != nil {
            self.removeActionForKey("flyToPoint")
        }
        
        let xDiff = point.x - self.position.x
        let yDiff = point.y - self.position.y
        
        let dist = sqrt(pow(xDiff,2) + pow(yDiff,2))

        if (xDiff > 0 ) {
            self.xScale = 1.0
        } else if (xDiff != 0){
            self.xScale = -1.0
        }
        
        
        let duration = NSTimeInterval(dist/CGFloat(self.flyDurationSpeed))
        
        let moveAct =  SKAction.moveTo(point, duration: NSTimeInterval(dist/CGFloat(self.flyDurationSpeed)))
        
        
        let eEngine = SKAction.runBlock({ () -> Void in
            self.defineEngineStateUsingDistance(dist)
        })
        
        let sEngine = SKAction.runBlock({ () -> Void in
            self.disableEngine()
        })
        
        let seg = SKAction.sequence([eEngine,moveAct,sEngine])
        
        self.runAction(seg ,withKey:"flyToPoint")
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
    
        let texuteProjectile = SKTexture(imageNamed: "projectile")
        var size = texuteProjectile.size()
        
        size.width *= 0.8
        size.height *= 0.8
        
        let miniProjectile = SKSpriteNode(texture: texuteProjectile, size: size)
        miniProjectile.anchorPoint = CGPointMake(0.5, 0.5)
        miniProjectile.name = projectileNodeName
        miniProjectile.hidden = true
        
        let point = CGPointMake(size.width*0.5, size.height*0.5)
        miniProjectile.position = point
        
        addChild(miniProjectile)
    }
    
    internal func canThrowProjectile() -> Bool {
        return self.playerMode == .CanFire
    }
    
    internal func enableProjectileGun() {
        defineProjectileGunState(false)
    }
    
    internal func disableProjectileGun() {
        defineProjectileGunState(true)
    }
    
    private func defineProjectileGunState(hidden:Bool) {
        if let node = self.childNodeWithName(projectileNodeName) {
            node.hidden = hidden
            self.numberOfThrownProjectiles = 0
            
            if (hidden) {
                self.playerMode = .Idle
            } else {
                self.playerMode = .CanFire
            }
        }
    }
    
    internal func updateNumberOfLives(extraLives numberOfLives:Int) {
        
        self.health += ForceType(numberOfLives * 100)
    }
    
    
    func throwProjectileToLocation(location:CGPoint) -> SKNode! {
        let xDiff = location.x - self.position.x
        let yDiff = location.y - self.position.y
        
        let len = sqrt(pow(xDiff, 2) + pow(yDiff, 2))
        
        return throwProjectileAtDirection(CGVectorMake((xDiff != 0 ? xDiff/len : 0) , (yDiff != 0 ? yDiff/len :0)))
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
        
        self.xScale = isLeft ? -1 : 1
        
        let positionFinal = CGPointMake(position.x + xDiff, position.y + yDiff)
        let length = Double(sqrt(pow(xDiff, 2) + pow(yDiff, 2)))
        
        
        let fadeIn = SKAction.fadeInWithDuration(0.2)
        let moveTo = SKAction.moveTo(positionFinal, duration: length/Double(self.projectileSpeed))
        
        projectile.runAction(SKAction.sequence([fadeIn,moveTo,SKAction.removeFromParent()]))
        projectile.position = position
        projectile.physicsBody = SKPhysicsBody(rectangleOfSize: projectile.size)
        projectile.name = "projectile_\(++self.numberOfThrownProjectiles)"
        projectile.physicsBody!.collisionBitMask = 0
        
        projectile.physicsBody!.categoryBitMask  = EntityCategory.PlayerLaser
        projectile.physicsBody!.contactTestBitMask =  EntityCategory.Asteroid
        projectile.userData = ["owner":"p"]
        
        projectile.zPosition = self.zPosition
        self.parent!.addChild(projectile)
        
        return projectile
    }
    
    func tryToDestroyWithForce(forceValue: ForceType) -> Bool {
        self.health -= forceValue
        
        if (self.health > 0) {
            
            let damage = Player.sDamageEmitter.copy() as! SKEmitterNode
            damage.position = self.position
            damage.zPosition = self.zPosition + 1
            self.scene?.addChild(damage)
            
            runOneShortEmitter(damage, 0.2)
            
            return false
        }
        else {
            
            //TODO: Perform death action....
            
            return true
        }
    }
}
