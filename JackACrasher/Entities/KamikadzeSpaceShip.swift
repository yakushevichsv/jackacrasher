//
//  KamikadzeBomb.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 8/26/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit
import SpriteKit

@objc protocol EnemySpaceShipDelegate {
    
    func enemySpaceShip(ship:EnemySpaceShip!, needToCreateExplosionWithEmitter:SKEmitterNode!)
}

class KamikadzeSpaceShip: EnemySpaceShip  {

    private static var context:dispatch_once_t = 0
    private static var sEnemyDeathEmitter:SKEmitterNode! = nil
    var explosionXPosition:CGFloat = 0
    
    weak var delegate:EnemySpaceShipDelegate?
    
    override init(texture: SKTexture!, color: UIColor!, size: CGSize) {
        super.init(texture:texture,color:color,size:size)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
        setup()
    }
    
    private func setup() {
        self.color = SKColor.orangeColor()
        self.colorBlendFactor = 0.2
    }
    
    //MARK : Attacker 
    override func updateWithTimeSinceLastUpdate(interval:NSTimeInterval) {
        
        if self.target == nil {
            return
        }
        
        if explosionXPosition >= self.position.x {
            
            let deathEmitter = KamikadzeSpaceShip.sEnemyDeathEmitter.copy() as! SKEmitterNode
            deathEmitter.position = self.position
            deathEmitter.resetSimulation()
            self.delegate?.enemySpaceShip(self, needToCreateExplosionWithEmitter:deathEmitter)
            
            if self.delegate == nil {
                self.removeFromParent()
            }
        }
        else {
            horizontalMoveToPlayer(self.target!.position,interval: interval)
        }
    }
    
    private func horizontalMoveToPlayer(pos:CGPoint,interval:NSTimeInterval) {
        
        
        self.performAttackAction()
        
        let maxX = max(explosionXPosition,pos.x)
        
        let distance = maxX - self.position.x
        
        let duration = min(NSTimeInterval(abs(distance)/Bomb.Constants.speed),interval)
        
        self.position.x =  CGFloat(NSTimeInterval(self.position.x) - duration * NSTimeInterval(Bomb.Constants.speed))
    }
    
    
    var canAttack:Bool {
        get { return true }
    }
    
    //MARK: Assets container
    override class func loadAssets() {
        super.loadAssets()
        
        dispatch_once(&context) {
            self.sEnemyDeathEmitter = SKEmitterNode(fileNamed: "enemyDeath.sks")
        }
    }
    
    class func damageForceForDistance() -> ForceType {
        return ForceType(20)
    }
}
