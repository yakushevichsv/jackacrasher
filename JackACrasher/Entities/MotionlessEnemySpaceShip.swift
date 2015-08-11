//
//  MotionlessEnemySpaceShip.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 8/10/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import Foundation
import SpriteKit

class MotionlessEnemySpaceShip : EnemySpaceShip {
    
    internal var allowAttack:Bool = false
    
    override init(texture: SKTexture!, color: UIColor!, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func onUpdateTarget() {
        let range = SKRange(lowerLimit:100, upperLimit: 500)
        let constr = SKConstraint.distance(range, toNode: self.target!)
        self.constraints = [constr]
    }
    
    
    /*override func moveTowards(position: CGPoint, withTimeInterval timeInterval: NSTimeInterval) {
        
        let distance =  distanceBetweenPoints(self.position, position)
        var action:SKAction!
        
        if self.position.x < 0 {
            self.physicsBody!.applyImpulse(CGVector(dx: abs(self.position.normalized().x * 10), dy: 0))
        }
        
        if self.position.y < 0 {
            self.physicsBody!.applyImpulse(CGVector(dx: 0, dy: abs(self.position.normalized().y * 10)))
        }
        
        if (position.x != self.position.x) {
            let duration = NSTimeInterval((distance * 2)/(Bomb.Constants.speed))
            
            action = SKAction.moveToX(position.x, duration: duration)
            
        }
        else {
            let duration = NSTimeInterval(distance/(Bomb.Constants.speed))
            action = SKAction.moveToY(position.y, duration: duration)
            self.allowsAttackAction()
        }
        
        self.runAction(action)
        performAttackAction()
    }
    
    override internal var attackInterval:NSTimeInterval {
        get { return NSTimeInterval(super.attackInterval/2) }
    } */
    
    
    
    override func updateWithTimeSinceLastUpdate(interval: NSTimeInterval) {
        
        if self.target == nil {
            return
        }
        
        if self.allowAttack {
            performAttackAction()
        }
    }

}