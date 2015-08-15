//
//  EnemySpaceShip.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 8/8/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit
import SpriteKit

@objc protocol Attacker {
    func updateWithTimeSinceLastUpdate(interval:NSTimeInterval);
}

class EnemySpaceShip: SKSpriteNode,Attacker, AssetsContainer, ItemDamaging, ItemDestructable {
   
    internal weak var target:Player? {
        didSet {
            if let targetPrivate = self.target {
                onUpdateTarget()
            }
        }
    }
    
    func onUpdateTarget(){
        let range = SKRange(lowerLimit:20)
        let constr = SKConstraint.distance(range, toNode: self.target!)
        self.constraints = [constr]
    }
    
    
    internal struct Constants {
        static let speed:CGFloat = 150
        static let name = "Bomb"
        static let laserSpeed:CGFloat = speed * 2
    }
    
    
    private let chaseRadius:CGFloat = 300
    private let maxAlertRadius:CGFloat = EnemySpaceShip.enemyAlertRadius * 2.0
    private static let enemyAlertRadius:CGFloat = 50 * 40.0
    
    private static var sOnce:dispatch_once_t = 0
    private static var sPlayerTexture:SKTexture! = nil
    private static var sEnemyBulltet:SKSpriteNode! = nil
    
    private var timer:NSTimer!
    internal var canAtack:Bool = true
    
    override init(texture: SKTexture!, color: UIColor!, size: CGSize) {
        let texture = EnemySpaceShip.sPlayerTexture
        super.init(texture: texture, color: SKColor.blackColor(), size: texture.size())
        
        createPhysicsBody()
        self.name = Constants.name
        self.allowsAttackAction()
    }
    
    private func createPhysicsBody() {
        let body = SKPhysicsBody(texture: self.texture, size: texture!.size())
        body.categoryBitMask = EntityCategory.EnemySpaceShip
        body.collisionBitMask = EntityCategory.EnemySpaceShip | EntityCategory.EnemySpaceShipLaser
        body.contactTestBitMask = EntityCategory.Player | EntityCategory.PlayerLaser
        body.fieldBitMask = 0
        
        self.physicsBody = body
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: Attacker protocol
    func updateWithTimeSinceLastUpdate(interval: NSTimeInterval) {
        
        if self.target == nil {
            return
        }
        
        var heroDistance = CGFloat.max
        
        if let scene = self.scene as? GameScene {
            
            for hero in scene.heroes {
                
                let position = self.positionOfNodeRelativeToOurParent(hero)
                
                let distance = distanceBetweenPoints(position,self.position)
                
                if (distance < EnemySpaceShip.enemyAlertRadius && distance < heroDistance) {
                    heroDistance = distance
                    self.target = hero
                }
            }
        }
        
        let chaseRadius = self.chaseRadius
        let heroPosition = self.positionOfNodeRelativeToOurParent(self.target!)
        
        
        if (heroDistance > self.maxAlertRadius) {
            self.target = nil
        } else if (heroDistance > chaseRadius) {
            if arc4random() % 2 == 1 {
                performAttackAction()
            }
            else {
                moveTowards(heroPosition, withTimeInterval: interval)
            }
        } else if (heroDistance < chaseRadius) {
            //self.zRotation = faceTo(heroPosition)
            moveTowards(heroPosition, withTimeInterval: interval)
            performAttackAction()
            
        }
    }
    
    private func positionOfNodeRelativeToOurParent(node:SKNode) -> CGPoint {
        
        var position = node.position
        
        if (node.parent != self.parent) {
            position = node.parent!.convertPoint(position, toNode: self.parent!)
        }
        
        return position
    }
    
    internal func moveTowards(position:CGPoint, withTimeInterval timeInterval: NSTimeInterval) {
        
        let dist = distanceBetweenPoints(self.position, position)
        let moveAction = SKAction.moveTo(position, duration: NSTimeInterval(dist/Bomb.Constants.speed))
        
        self.runAction(moveAction)
    }
    
    internal var attackInterval:NSTimeInterval {
        get {return 2}
    }
    
    internal func performAttackAction() {
        
        if !canAtack {
            return
        }
        
        let bullet = EnemySpaceShip.sEnemyBulltet.copy() as! SKSpriteNode
        
        let sPoint = self.parent!.convertPoint(self.position, toNode:self.scene!)
        let tPoint = self.target!.parent!.convertPoint(self.target!.position, toNode: self.scene!)
        
        let diff = tPoint - sPoint
        
        let extraY = abs(diff.x) >= 1 ? tPoint.x * tan(diff.angle) : tPoint.y
        
        let extraLen = abs(diff.x) >= 1 ? tPoint.x/cos(diff.angle) : abs(extraY)
        
        
        let duration = (distanceBetweenPoints(sPoint, tPoint) + extraLen)/EnemySpaceShip.Constants.laserSpeed
        
        let tPoint2 = CGPointMake(0, tPoint.y - extraY)
        
        let moveToAction = SKAction.moveTo(tPoint2, duration: NSTimeInterval(duration))
        let rotateAction = SKAction.rotateToAngle(radiansBetweenPoints(sPoint,tPoint), duration: NSTimeInterval(min(duration,0.2)))
        let removeAction = SKAction.removeFromParent()
        bullet.position = sPoint
        
        println("Bullet from point \(sPoint) to point: \(tPoint)")
        
        //bullet.zRotation =
        self.scene?.addChild(bullet)
        bullet.runAction(SKAction.sequence([SKAction.group([moveToAction,rotateAction]),removeAction]))
        
        self.timer = NSTimer.scheduledTimerWithTimeInterval(self.attackInterval, target: self, selector: "allowsAttackAction", userInfo: nil, repeats: false)
        
        self.canAtack = false
    }
    
    func allowsAttackAction() {
        self.canAtack = true
        if self.timer != nil {
            self.timer.invalidate()
        }
        self.timer = nil
    }
    
    //AssetsContainer
    static func loadAssets() {
        dispatch_once(&sOnce) {
            let texture = SKTexture(imageNamed: "enemy-bullet")
            let node = SKSpriteNode(texture: texture)
            let body = SKPhysicsBody(texture: texture, size: texture.size())
            body.categoryBitMask = EntityCategory.EnemySpaceShipLaser
            body.collisionBitMask = EntityCategory.EnemySpaceShip | EntityCategory.EnemySpaceShipLaser
            body.contactTestBitMask = EntityCategory.Player | EntityCategory.PlayerLaser
            body.fieldBitMask = 0
            node.physicsBody = body
            node.userData = ["damageForce":ForceType(10)]
            self.sEnemyBulltet = node
            
            self.sPlayerTexture = SKTexture(imageNamed: "enemyShip")
        }
    }
    
    //MARK : Damaging Item 
    
    var damageForce:ForceType {
        get { return 10 }
    }
    
    func destroyItem(item:ItemDestructable) -> Bool {
        return item.tryToDestroyWithForce(min(self.damageForce,item.health))
    }
    
    // MARK: Item Destructable
    func tryToDestroyWithForce(forceValue:ForceType) -> Bool {
        
        self.health -= forceValue
        let minVal = ForceType(0)
        
        if (self.health < minVal) {
            self.health = minVal
        }
        
        return self.health == minVal
    }
    
    var health:ForceType = Player.laserForce * 2
}