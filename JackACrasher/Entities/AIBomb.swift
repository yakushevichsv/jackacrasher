//
//  AIBomb.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 7/30/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit
import SpriteKit

class AIBomb: Bomb {
   
    private let chaseRadius:CGFloat = 300
    private let maxAlertRadius:CGFloat = AIBomb.enemyAlertRadius * 2.0
    private static let enemyAlertRadius:CGFloat = 50 * 40.0
    
    /*private struct Constants {
        private static let extraMove = "extraMove"
    }*/
    
    override init() {
        super.init()
        self.xScale *= 2
        self.yScale *= 0.5
        
        let action = SKAction.colorizeWithColorBlendFactor(0.7, duration:1)
        let backAction = action.reversedAction()
        let repAction = SKAction.repeatActionForever(SKAction.sequence([action,backAction]))
        
        self.runAction(repAction)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func updateWithTimeSinceLastUpdate(interval:NSTimeInterval) {
        super.updateWithTimeSinceLastUpdate(interval)
    
        if self.target == nil {
            return
        }
        
        var heroDistance = CGFloat.max
        
        if let scene = self.scene as? GameScene {
            
            for hero in scene.heroes {
                
                let distance = distanceBetweenPoints(hero.position,self.position)
                
                if (distance < AIBomb.enemyAlertRadius && distance < heroDistance) {
                    heroDistance = distance
                    self.target = hero
                }
            }
        }
        
        let chaseRadius = self.chaseRadius
        let heroPosition = self.target!.position
        
        if (heroDistance > self.maxAlertRadius) {
            self.target = nil
        } else if (heroDistance > chaseRadius) {
            moveTowards(heroPosition, withTimeInterval: interval)
        } else if (heroDistance < chaseRadius) {
            faceTo(heroPosition)
            moveTowards(heroPosition, withTimeInterval: interval)
            //performAttackAction()
        }
    }
    
    private func moveTowards(position:CGPoint, withTimeInterval timeInterval: NSTimeInterval) {
        
        //let actionKey = AIBomb.Constants.extraMove
        
        /*if self.actionForKey(actionKey) != nil {
            self.removeActionForKey(actionKey)
        }*/
        
        let dist = distanceBetweenPoints(self.position, position)
        let moveAction = SKAction.moveTo(position, duration: NSTimeInterval(dist/Bomb.Constants.speed))
        
        self.runAction(moveAction)
    }
    
    private func performAttackAction() {
        
    }
    
    private func faceTo(position:CGPoint) -> CGFloat {
    
        let ang = radiansBetweenPoints(self.position, position)
        
        //let action = SKAction.rotateToAngle(ang, duration: 0)
        //self.runAction(action)
        self.zRotation = π * 1.5 + ang
        return ang
    }
    
    override var canAttack:Bool {
        get {return true}
    }
    
}
