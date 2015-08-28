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
    
    
    override func updateWithTimeSinceLastUpdate(interval: NSTimeInterval) {
        
        if self.target == nil {
            return
        }
        
        if self.allowAttack {
            performAttackAction()
        }
    }

}