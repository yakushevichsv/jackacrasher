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
    static var Player : UInt32  = 1 << 1
    static var PlayerLaser: UInt32 = 1 << 2
    static var Boss : UInt32 = 1 << 3
    static var TrashAsteroid:UInt32 = 1 << 4
    static var Bomb : UInt32 = 1 << 5
    static var RegularAsteroid:UInt32 = 1 << 6
    static var Rope:UInt32 = 1 << 7
    static var RadialField:UInt32 = 1 << 8
    static var BlakHoleField:UInt32 = 1 << 8
    static var BlackHole:UInt32 = 1 << 10
    static var EnemySpaceShip:UInt32 = 1 << 11
    static var EnemySpaceShipLaser:UInt32 = 1 << 12
    static var LeftEdgeBorder:UInt32 = 1 << 13
    static var RightEdgeBorder:UInt32 = 1 << 14
    static var HealthUnit:UInt32 = 1 << 15
    static var Blade:UInt32 = 1 << 16
}

typealias ForceType = CGFloat

enum PlayerMovement {
    case Fly
    case Teleport
}

enum PlayerMode {
    case Idle
    case CanFire
    case CanFireAndMove
}

enum PlayerFlyDistance {
    case None
    case Short
    case Middle
    case Long
}

private let playerBGNodeName = "playerBGNode"
private let playerImageName = "astronaut2"

private let damageEmitterNode = "Damage"
private let damageEmitterNodeName = "damageNode"

private let playerNode = "playerNode"

class Player: SKSpriteNode, ItemDestructable, AssetsContainer {
    private let engineNodeName = "engineEmitter"
    private var numberOfThrownProjectiles = 0
    private var movementStyle:PlayerMovement = .Fly
    private var playerMode:PlayerMode = .Idle
    
    private weak var timeLeftLabel:SKLabelNode! = nil
    
    private static var sBGSpriteTexture:SKTexture!
    internal static var sDamageEmitter:SKEmitterNode!
    private static var sProjectileTexture:SKTexture!
    private static var hammerAttackAction:SKAction!
    private static var displayShowGunAction:SKAction!
    private static var spritesAtlas:SKTextureAtlas!
    
    private static var sContext:dispatch_once_t = 0    
    var health: ForceType = 100
    
    private var prevTimeInterval:NSTimeInterval = 0
    
    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
    }
    
    internal var isCaptured:Bool {
        get {return self.parent != self.scene }
    }
    
    internal static func loadAssets() {
       
        dispatch_once(&sContext) { () -> Void in
            
            if let emitter = SKEmitterNode(fileNamed: damageEmitterNode) {
                emitter.name = damageEmitterNodeName
            
                Player.sDamageEmitter = emitter
                
                
                var textures:[SKTexture] = []
                
                var totalTime:NSTimeInterval = 0.0
                let timePerFrame:NSTimeInterval = 0.1
                
                self.spritesAtlas = SKTextureAtlas(named: "player")
                
                for var index = 0 ; index < 6; index++ {
                    print("Player textures \(self.spritesAtlas.textureNames)")
                    let texture = self.spritesAtlas.textureNamed("astr\(index+1)")
                    textures.append(texture)
                    totalTime += timePerFrame
                }
                
                let texturesAct = SKAction.animateWithTextures(textures, timePerFrame: timePerFrame)
                
                self.hammerAttackAction = texturesAct
                
                let playerSprite = self.spritesAtlas.textureNamed(playerImageName)
                Player.sBGSpriteTexture = playerSprite
                
                
                var flyTextures:[SKTexture] = []
                totalTime = 0
                    let texture1 = self.spritesAtlas.textureNamed("astronaut1")
                    flyTextures.append(texture1)
                    totalTime += timePerFrame
                
                
                let texture2 = self.spritesAtlas.textureNamed("astronaut")
                flyTextures.append(texture2)
                totalTime += timePerFrame
                
                let flyAct = SKAction.animateWithTextures(flyTextures, timePerFrame: timePerFrame)
                self.displayShowGunAction = flyAct
            }
            
            let atlas = SKTextureAtlas(named: "player_extra")
            self.sProjectileTexture =  atlas.textureNamed("projectile")
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
        let texture = Player.sBGSpriteTexture
        
        super.init(texture: texture, color: UIColor.redColor(), size: texture.size())
        
        self.name = playerNode
        self.position = position
        
        self.playerDistFlyMap = createEngine()
        
        createPhysicsBody()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createPhysicsBody() {
    
       let size = CGSizeMake(40, 64);
        let center = CGPointMake(-8, self.texture!.size().halfHeight()*0.05)
        
        var origin = center
        origin.x -= size.halfWidth()
        origin.y -= size.halfHeight()
        
        let path = UIBezierPath(ovalInRect: CGRect(origin: origin, size: size))
        
        let aPhysBody =  SKPhysicsBody(polygonFromPath: path.CGPath)
        
        aPhysBody.categoryBitMask = EntityCategory.Player
        aPhysBody.contactTestBitMask =  0
        aPhysBody.collisionBitMask = 0
        enableGravityReceptivity()
        self.physicsBody = aPhysBody
        
        if (EnabledDisplayDebugLabel) {
            let shapeNode = SKShapeNode(path: path.CGPath)
            shapeNode.position = center
            shapeNode.strokeColor = UIColor.redColor()
            addChild(shapeNode)
        }
    }
    
    //MARK:Player's gravity receptivity
    internal func disableGravityReceptivity() {
        setGravityReceptivity(false)
    }
    
    internal func enableGravityReceptivity() {
        setGravityReceptivity(true)
    }
    
    private func setGravityReceptivity(enabled:Bool) {
        self.physicsBody?.fieldBitMask = enabled ? (EntityCategory.RadialField & EntityCategory.BlakHoleField)  : EntityCategory.BlakHoleField
    }
    
    
    private func redifineEngineEmitter() -> SKEmitterNode? {
        self.childNodeWithName(engineNodeName)?.removeFromParent()
        return createEngineEmitterNode()
    }
    
    func animeAsteroidHammerAttack(runBlock:dispatch_block_t) {
        
        if self.actionForKey("attackHammer") != nil {
            self.runAction(SKAction.runBlock(runBlock))
        }
        else {
            self.runAction(SKAction.sequence([Player.hammerAttackAction,SKAction.waitForDuration(0.1), SKAction.animateWithTextures([Player.sBGSpriteTexture], timePerFrame: 1e-2),SKAction.runBlock(runBlock)]), withKey: "attackHammer")
        }
    }
    
    func hideHammer() {
        
        if self.actionForKey("attackHammer") != nil {
            removeActionForKey("attackHammer")
        }
    }
    
    
    private func  createEngineEmitterNode() -> SKEmitterNode? {
    
        if let engineEmitter = SKEmitterNode(fileNamed: "Engine.sks") {
            
            let size = self.size
            
            engineEmitter.position = CGPoint(x: size.width * -self.xScale * 0.5, y: size.height * -0.4)
            engineEmitter.name = engineNodeName
            addChild(engineEmitter)
            
            engineEmitter.targetNode = nil
            engineEmitter.hidden = true
            return engineEmitter
        }
        else {
            return nil
        }
    }
    
    //MARK: Engine methods
    
    private func createEngine() -> playerDistFlyMapType {
        
        var dic = playerDistFlyMapType()
        
        if let engineEmitter = createEngineEmitterNode() {
            
            let distance = max(self.size.width,self.size.height)*sqrt(2)
            let eMax = engineEmitter.particleLifetime
            dic[.Long] = (distance,eMax)
            dic[.Middle] = (distance/1.2,eMax*0.5)
            dic[.Short] = (distance/2,eMax*0.1)
            
        }
        
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
                engineNode.paused = true
                /*if let engine = redifineEngineEmitter() {
                    engine.hidden = true
                    engine.paused = true
                }*/
                
            }
            else {
                engineNode.hidden = false
                engineNode.paused = false
                engineNode.alpha = 1.0
                engineNode.resetSimulation()
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
        
        let dist = distanceBetweenPoints(point, point2: self.position)

        if (xDiff > 0 ) {
            self.xScale = 1.0
        } else if (xDiff != 0){
            self.xScale = -1.0
        }
        
        
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
        
        
        let scaleToSmall = SKAction.resizeToWidth(0, duration:time2)
        
        let fadeOut = SKAction.fadeOutWithDuration(time2)
        
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
    
    internal func canThrowProjectile() -> Bool {
        return self.playerMode == .CanFire 
    }
    
    internal func forceEnableProjectileGunDuringMove() {
        enableProjectileGun()
        self.playerMode = .CanFireAndMove
    }
    
    internal func enableProjectileGunDuringMove() {
        if (self.playerMode == .CanFire) {
            return
        }
        self.forceEnableProjectileGunDuringMove()
    }
    
    internal func enableProjectileGun() {
        defineProjectileGunState(false)
        self.timeLeftLabel?.hidden = true
    }
    
    internal func disableProjectileGun() {
        defineProjectileGunState(true)
    }
    
    internal func disableProjectileGunDuringMove() {
        if self.playerMode == .CanFireAndMove {
            disableProjectileGun()
            self.prevTimeInterval = 0
            self.timeLeftLabel.hidden = true
        }
    }
    
    private func defineProjectileGunState(hidden:Bool) {
        
            if (hidden) {
                if self.actionForKey("displayShowGunAction") != nil {
                    self.removeActionForKey("displayShowGunAction")
                }
                
                let texture = Player.sBGSpriteTexture
                
                self.texture = texture
                self.size = texture.size()
                
                self.playerMode = .Idle
            } else {
                if self.playerMode == .CanFireAndMove {
                    return
                }
                
                self.playerMode = .CanFire
                
                if self.actionForKey("displayShowGunAction") == nil {
                    self.runAction(SKAction.sequence([Player.displayShowGunAction]), withKey:"displayShowGunAction")
                }
            }
        
    }
    
    internal func updateNumberOfLives(extraLives numberOfLives:Int) {
        
        self.health += ForceType(numberOfLives * 100)
    }
    
    
    func throwProjectileToLocation(location:CGPoint) -> SKNode? {
       
        print("Throw location \(location)")
        
        let sPosition = convertNodePositionToScene(self)
        
        let xDiff = location.x - sPosition.x
        let yDiff = location.y - sPosition.y
        
        let len = distanceBetweenPoints(location, point2: sPosition)
        
        return throwProjectileAtDirection(CGVectorMake((xDiff != 0 ? xDiff/len : 0) , (yDiff != 0 ? yDiff/len :0)),sPosition:sPosition)
    }
    
    private func throwProjectileAtDirection(vector:CGVector,sPosition:CGPoint) -> SKNode? {
        
        if self.scene == nil {
            return nil
        }
        
        let texture = Player.sProjectileTexture
        let projectile = SKSpriteNode(texture: texture)
        
        let isLeft = vector.dx < 0
        let isUp  = vector.dy > 0

        let xPos = sPosition.x +  CGFloat(self.size.width * 0.2)
        
        let position = CGPointMake(xPos, sPosition.y)
        projectile.alpha = 0.0
        
        var yDiff:CGFloat = 0.0
        
        if (isUp) {
            yDiff = self.scene!.size.height + projectile.size.halfHeight() - position.y
        }
        else if (vector.dy != 0){
            yDiff =  -(position.y + projectile.size.halfHeight())
        }
        
        var xDiff:CGFloat = 0.0
        
        if (yDiff != 0 ) {
            xDiff = vector.dx/vector.dy * yDiff
        } else if (isLeft) {
            xDiff = -(position.x + projectile.size.halfWidth())
        } else {
            xDiff = self.scene!.size.width + projectile.size.halfWidth() - position.x
        }
        
        self.xScale = isLeft ? -1 : 1
        
        let positionFinal = CGPointMake(position.x + xDiff, position.y + yDiff)
        let length =  Double(hypot(xDiff, yDiff))
        
        let fadeIn = SKAction.fadeInWithDuration(0.2)
        let moveTo = SKAction.moveTo(positionFinal, duration: length/Double(self.projectileSpeed))
        
        projectile.zRotation = vector.angle

        if vector.angle >= π/6 || vector.angle <= -π/6 {
            
            var defPoint = projectile.anchorPoint
            let pointX =  ((vector.angle/π + 1/6) + 1) * 0.5
            defPoint.x = pointX
            
            projectile.anchorPoint = defPoint
        }

        

        //more than 30 degrees throw... less than -30 degree than also throw....
        //more than 110 values....

        print("Projectile value \(projectile.zRotation) \nVector value \(vector.angle * 180.0/π)\n Anchor Point \(projectile.anchorPoint)")
        
        projectile.runAction(SKAction.sequence([fadeIn,moveTo,SKAction.removeFromParent()]))
        projectile.position = position
        projectile.physicsBody = SKPhysicsBody(rectangleOfSize: projectile.size)
        projectile.name = "projectile_\(++self.numberOfThrownProjectiles)"
        projectile.physicsBody!.collisionBitMask = 0
        
        projectile.physicsBody!.categoryBitMask  = EntityCategory.PlayerLaser
        projectile.physicsBody!.contactTestBitMask =  EntityCategory.RegularAsteroid
        projectile.userData = ["owner":"p"]
        
        projectile.zPosition = self.zPosition
        self.scene!.addChild(projectile)
        
        return projectile
    }
    
    func willBeDestroyedWithFore(forceValue: ForceType) -> Bool {
        return self.health - forceValue <= 0
    }
    
    
    func tryToDestroyWithForce(forceValue: ForceType) -> Bool {
        self.health -= forceValue
        
        if (self.health > 0) {
        
            let damage = Player.sDamageEmitter.copy() as! SKEmitterNode
            if (forceValue < 0) {
                damage.particleColor = UIColor.greenColor()
            }
            damage.position = self.position
            damage.zPosition = self.zPosition + 1
            self.parent?.addChild(damage)
            
            runOneShortEmitter(damage, duration: 0.4)
            
            return false
        }
        else {
            
            //TODO: Perform death action....
            
            return true
        }
    }
    
    internal func updateWithTimeSinceLastUpdate(interval:NSTimeInterval,location:CGPoint) {
        
        if self.playerMode != .CanFireAndMove {
            return
        }
        
        
        let xDiff = location.x - self.position.x
        
        var xScale:CGFloat = 0
        
        if (xDiff > 0 ) {
            xScale = 1.0
        } else if (xDiff != 0){
            xScale = -1.0
        }
        
        if let lblNode = self.timeLeftLabel {
            lblNode.xScale = 1.0
        }
        
        
        let now = NSDate.timeIntervalSinceReferenceDate()
        
        if self.prevTimeInterval == 0 {
            self.prevTimeInterval = now
            
            if self.timeLeftLabel == nil {
                let node = SKLabelNode()
                node.fontSize = 15
                node.position = CGPointMake(self.size.halfWidth() * 0.6, self.size.halfHeight())
                self.timeLeftLabel = node
                //node.colorBlendFactor = 1.0
                self.addChild(node)
            }
            else {
                self.timeLeftLabel.hidden = false
            }
            
            self.timeLeftLabel.fontColor = !self.isCaptured ? SKColor.whiteColor() : SKColor.blackColor()
            //self.timeLeftLabel.color = self.timeLeftLabel.fontColor
        }
        
        if xScale != 0 {
            self.xScale = xScale
        }
        
        let margin = now - self.prevTimeInterval
        let upperBorder:Double = 3
        
        if margin >= upperBorder {
            self.prevTimeInterval = now
                throwProjectileToLocation(location)
            
            self.timeLeftLabel.hidden = true
        }
        else {
            self.timeLeftLabel.text = "\(UInt(upperBorder - margin + 1))"
        }
        
    }
    
    //MARK: Black Hole affection 
    
    func influencedByBlackHole() {
        self.physicsBody?.categoryBitMask = 0
    }
    
    func isUnderBlackHole()-> Bool {
        return self.physicsBody?.categoryBitMask == Optional<UInt32>(0)
    }
    
    
    //MARK: Laser force 
    class var laserForce : ForceType {
        get { return 30 }
    }
}
