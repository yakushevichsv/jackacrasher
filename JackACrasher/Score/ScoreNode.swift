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
    
    init(point:CGPoint,score:UInt64 = 0) {
        super.init()
        
        label.fontColor = SKColor.blackColor()
        label.fontSize =  isPhone4s() ? 36 : isPhone5s() ? 38 : 40
        label.horizontalAlignmentMode = .Left
        label.position = point
        addChild(label)
        
        setScore(score: score)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    internal func setScore(score scoreInner:UInt64) {
        var score = scoreInner
        if (score < 0) {
            score = 0
        }
        let scoreText = NSLocalizedString("Score", comment: "Score")
        
        let numFormatter = NSNumberFormatter()
        numFormatter.numberStyle = .DecimalStyle
        let numAsString = numFormatter.stringFromNumber(NSNumber(unsignedLongLong: score))
        
        var scoreTextFinal = "\(scoreText) : "
        scoreTextFinal = scoreTextFinal.stringByAppendingString(numAsString!)
        
        label.text = scoreTextFinal
    }
    
}
