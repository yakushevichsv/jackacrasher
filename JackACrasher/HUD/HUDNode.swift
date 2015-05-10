//
//  HUDNode.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 5/7/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit
import SpriteKit

class HUDNode: SKCropNode {
    private let progressNode:SKSpriteNode!
    private let maxLife:Int
    private var life:Int = 0
    private let duration:NSTimeInterval
    private let maskShape:SKShapeNode! = SKShapeNode()
    
    init(inSize:CGSize, maxLife:Int,duration:NSTimeInterval = 0.5) {
        
        self.maxLife = maxLife
        self.duration = duration
        self.progressNode = SKSpriteNode(color: SKColor.greenColor(), size: inSize)
    
        super.init()
     
        self.maskShape.antialiased = false
        self.maskShape.lineWidth = inSize.width
        //self.maskShape.fillColor = UIColor.whiteColor()
        self.maskShape.path = UIBezierPath(roundedRect: CGRectMake(0, 0, progressNode.size.width, progressNode.size.height), cornerRadius: 2).CGPath
        
        maskNode = self.maskShape
        
    
        
        addChild(progressNode)
        
        setLife(maxLife)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var normalizedLife:Float {
        get {return self.maxLife != 0 ? Float(life)/Float(self.maxLife) : 0.0 }
    }
    
    internal func isDead() -> Bool {
        return self.life == 0
    }
    
    internal func decreaseLife() -> Int {
        if (self.life > 0) {
            setLife(self.life - 1)
        }
        else {
            self.life = 0
        }
        return self.life
    }
    
    internal func setLife(life:Int) {
        assert(life <= self.maxLife, "Life shouldn't be bigger than maxLife")
        if (life == self.life) {
            return
        }
        
        let oldLife = self.life
        self.life = life
        
        let normLife = self.normalizedLife
        
        assert(normLife <= 1 && normLife >= 0, "Normalized life is not in range")
        
        if (self.maskShape?.actionForKey("scaleAction") != nil) {
            self.maskShape?.removeActionForKey("scaleAction")
        }
        
        let corLife = CGFloat(max(0,min(1,normLife)))
        
        let b = self.progressNode.size.width * CGFloat(oldLife)/CGFloat(self.maxLife)
        let k = self.progressNode.size.width * CGFloat(normLife) - b
        
        let newDuration = NSTimeInterval(self.duration*Double(self.life)/Double(self.maxLife))
        
        if newDuration == 0 {
            progressNode.color = SKColor.grayColor()
            self.maskShape.path = UIBezierPath(roundedRect: CGRectMake(0, 0, self.progressNode.size.width, self.progressNode.size.height), cornerRadius: 2).CGPath
            self.maskShape.lineWidth = self.progressNode.size.width
            self.maskShape.lineCap = kCGLineCapRound
            return
        }
        
        let blockAction = SKAction.customActionWithDuration(newDuration){ (node, time) -> Void in
            
            let x = time/CGFloat(newDuration)
            
            let width:CGFloat = k * x + b
            
            let rect = CGRectMake(0, 0, width, self.progressNode.size.height)
            println("New rect: \(rect)")
            
            //let bezier = UIBezierPath(roundedRect: rect, cornerRadius: 2)
            
            //self.maskNode = SKShapeNode(rectOfSize: rect.size)
            
            self.maskShape.path = UIBezierPath(roundedRect: rect, cornerRadius: 2).CGPath
            
            self.maskShape.lineWidth = width*0.5
        }
        
        
        
        self.maskShape.runAction(blockAction, withKey: "scaleAction")
        
        var color: SKColor!
        
        if (corLife <= 0.25) {
            color = SKColor.redColor()
        } else if (corLife <= 0.75){
            color = SKColor.yellowColor()
        } else {
            color = SKColor.greenColor()
        }
        
        progressNode.color = color
    }
}
