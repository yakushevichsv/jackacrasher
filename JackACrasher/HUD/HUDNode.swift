//
//  HUDNode.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 5/7/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit
import SpriteKit

class HUDNode: SKNode {
    
    typealias lifeType = Int
    
    private let lifeCurPercentNode = SKShapeNode()
    private let lifeLabelNode = SKLabelNode(fontNamed: "gamerobot")
    private let bgNode = SKShapeNode()
    
    private static let sLifePercentMax = lifeType(100)
    private static let sLifePercentMin = lifeType(0)
    
    //internal static let sLifeOne = lifeType(1)
    
    private let size:CGSize
    private let animDuration:NSTimeInterval
    
    internal var life:lifeType = HUDNode.sLifePercentMin {
        didSet {
            self.updateLifeNode()
        }
    }
    
    internal var curLifePercent: lifeType = sLifePercentMax
    
    init(inSize:CGSize,life:lifeType = HUDNode.sLifePercentMin, duration:NSTimeInterval = 3 ) {
        self.life = life
        self.animDuration = duration
        self.size = inSize
        
        super.init()
    
        createBGBorder()
        createOtherNodes()
        
        updateLifeCurPercentNode(true)
        updateLifeNode()
    }
    
    private func updateLifeNode() {
        
        if (self.life != HUDNode.sLifePercentMin) {
            
            
            self.lifeLabelNode.text = "\(Int(life))"
            
            self.lifeLabelNode.hidden = false
        } else {
            self.lifeLabelNode.hidden = true
        }
    }
    
    private func updateLifeCurPercentNode(animated:Bool = true, prevValue:lifeType = HUDNode.sLifePercentMin) {

         let w =  CGFloat(Double(self.size.width) * Double(self.curLifePercent)/Double(HUDNode.sLifePercentMax))
        
        if (!animated) {
            updateLifeCurPercentNodeWithValue(self.curLifePercent,width:w)
        }
        else {
        
            let newDuration = fabs(self.animDuration * Double(self.curLifePercent - prevValue)/Double(HUDNode.sLifePercentMax -  HUDNode.sLifePercentMin))
            
        let b = CGFloat(Double(self.size.width) * Double(prevValue)/Double(HUDNode.sLifePercentMax))
        let b1 = CGFloat(prevValue)
        
        let k = w - b
        let k1 = CGFloat(self.curLifePercent) - b1
            
            let blockAction = SKAction.customActionWithDuration(newDuration){ (node, time) -> Void in
                
                
                let x = newDuration != 0 ? time/CGFloat(newDuration) : CGFloat(0)
                
                let width = k * x + b
                let value = k1 * x + b1
                
                self.updateLifeCurPercentNodeWithValue(max(lifeType(0),lifeType(value)), width: width)
                //print("Current value \(value)")
            }
            
            
            if (self.actionForKey("scaleAction") != nil) {
                self.removeActionForKey("scaleAction")
            }
            self.runAction(blockAction, withKey: "scaleAction")
        }
    }
    
    private func updateLifeCurPercentNodeWithValue(value:lifeType,width w:CGFloat) {
        
        var color:SKColor? = nil
        
        if (value > lifeType(75)) {
            color = SKColor.greenColor()
        } else if (value > lifeType(25)) {
            color = SKColor.yellowColor()
        } else if (value > HUDNode.sLifePercentMin) {
            color = SKColor.redColor()
        } else {
            color = SKColor.clearColor()
        }
        
        if let colorVal = color {
            
            self.lifeCurPercentNode.fillColor = colorVal
            
            let path = UIBezierPath(roundedRect: CGRectMake(0, 0, w, self.size.height), cornerRadius: 5)
                
            self.lifeCurPercentNode.path = path.CGPath
        }
    }
    
    private func createBGBorder() {
        
        let path = UIBezierPath(roundedRect: CGRectMake(0, 0, self.size.width, self.size.height), cornerRadius: 5)
        path.lineWidth = 2
        
        bgNode.path = path.CGPath
        bgNode.strokeColor = SKColor.blackColor()
        bgNode.fillColor = SKColor.lightGrayColor()
        
        addChild(bgNode)
    }
    
    private func createOtherNodes() {
        
        
        
        addChild(lifeCurPercentNode)
        
        let midX = CGFloat(round(self.size.width  * 0.5))
        let midY = CGFloat(round(self.size.height * 0.5))
        
        lifeLabelNode.position = CGPointMake(midX, midY)
        lifeLabelNode.fontColor = SKColor.blackColor()
        lifeLabelNode.fontSize = 20
        
        addChild(lifeLabelNode)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func decreaseLife() -> lifeType {
        if (self.life > HUDNode.sLifePercentMin) {
            self.life = self.life - lifeType(1)
        }
        else {
            self.life = HUDNode.sLifePercentMin
        }
        
        updateLifeNode()
        
        return self.life
    }
    
    internal func reduceCurrentLifePercent(forceType lifeDamage:ForceType) {
        
        let damage:HUDNode.lifeType = lifeDamage > ForceType(HUDNode.sLifePercentMax) ? HUDNode.sLifePercentMax : HUDNode.lifeType(lifeDamage)
        
        reduceCurrentLifePercent(damage)
    }
    
    //MARK: Internal methods
    internal func reduceCurrentLifePercent(lifeDamage:lifeType) {
        
        var prevLifePercent = self.curLifePercent
        
        self.curLifePercent -= lifeDamage
        
        
        if (self.curLifePercent <= HUDNode.sLifePercentMin) {
            self.curLifePercent = HUDNode.sLifePercentMin
            
            if (self.decreaseLife() != HUDNode.sLifePercentMin) {
                self.curLifePercent = HUDNode.sLifePercentMax
                prevLifePercent = HUDNode.sLifePercentMin
            }
            else {
                updateLifeCurPercentNode(false, prevValue: self.curLifePercent)
                return
            }
        }
        
        if (self.curLifePercent > HUDNode.sLifePercentMax) {
            self.curLifePercent = HUDNode.sLifePercentMax
        }
        
        updateLifeCurPercentNode(true, prevValue: prevLifePercent)
    }
    
    internal func setLifePercentUsingRatio(var ratio:Float){
        
        if (ratio > 1) {
            ratio = ratio/100.0
        }
        
        assert(ratio >= 0 && ratio <= 1)
        
        let prevValue = self.curLifePercent
        
        self.curLifePercent += lifeType(ratio*100)
        
        if (self.curLifePercent > HUDNode.sLifePercentMax) {
            self.curLifePercent = HUDNode.sLifePercentMax
        }
        if (prevValue != self.curLifePercent) {
            updateLifeCurPercentNode(true, prevValue: prevValue)
        }
    }
}
