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
    }
    
}
