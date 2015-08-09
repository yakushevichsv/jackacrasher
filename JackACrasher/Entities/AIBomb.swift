//
//  AIBomb.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 7/30/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit
import SpriteKit

class AIBomb: Bomb,Attacker {
   
    private let chaseRadius:CGFloat = 300
    private let maxAlertRadius:CGFloat = AIBomb.enemyAlertRadius * 2.0
    private static let enemyAlertRadius:CGFloat = 50 * 40.0
    
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
                
                let position = self.positionOfNodeRelativeToOurParent(hero)
                
                let distance = distanceBetweenPoints(position,self.position)
                
                if (distance < AIBomb.enemyAlertRadius && distance < heroDistance) {
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
            moveTowards(heroPosition, withTimeInterval: interval)
        } else if (heroDistance < chaseRadius) {
            faceTo(heroPosition)
            moveTowards(heroPosition, withTimeInterval: interval)
            //performAttackAction()
        }
    }
    
    private func positionOfNodeRelativeToOurParent(node:SKNode) -> CGPoint {
        
        var position = node.position
        
        if (node.parent != self.parent) {
            position = node.parent!.convertPoint(position, toNode: self.parent!)
        }
        
        return position
    }
    
    private func moveTowards(position:CGPoint, withTimeInterval timeInterval: NSTimeInterval) {
        
        let dist = distanceBetweenPoints(self.position, position)
        let moveAction = SKAction.moveTo(position, duration: NSTimeInterval(dist/Bomb.Constants.speed))
        
        self.runAction(moveAction)
    }
    
    private func performAttackAction() {
        
    }
    
    private func faceTo(position:CGPoint) -> CGFloat {
    
        let ang = radiansBetweenPoints(self.position, position)
        
        self.zRotation = π * 1.5 + ang
        return ang
    }
    
    override var canAttack:Bool {
        get {return true}
    }
    
}
