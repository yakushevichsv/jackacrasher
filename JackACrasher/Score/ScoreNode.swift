//
//  ScoreNode.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 5/21/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit
import SpriteKit

class ScoreNode: SKNode {
   
    private let label:SKLabelNode! = SKLabelNode()
    //private let border:SKShapeNode! = SKShapeNode()
    
    
    init(point:CGPoint,score:UInt64 = 0) {
        super.init()
        
        label.fontColor = SKColor.blackColor()
        label.fontName = "gamerobot"
        label.fontSize = 40
        label.horizontalAlignmentMode = .Left
        label.position = point
        addChild(label)
        
        setScore(score)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    internal func setScore(var score:UInt64) {
        if (score < 0) {
            score = 0
        }
        label.text = "Score : \(score)"
    }
    
}
