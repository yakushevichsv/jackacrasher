//
//  RegularAsteroid.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 4/21/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit
import SpriteKit


let digitAppearanceSpeed = M_PI_4
let duration = (M_PI*2)/digitAppearanceSpeed

class RegularAsteroid: SKSpriteNode {
    private let digitNode:DigitNode!
    private let cropNode:ProgressTimerCropNode!
    private let maxLife:Int
    private let displayAction = "displayAction"
    private let asterSize:RegularAsteroidSize
    
    internal var healthState:Int {
        return self.digitNode.digit
    }
    
    internal var asteroidSize:RegularAsteroidSize {
        return asterSize
    }
    
    convenience init(asteroid:RegularAsteroidSize, maxLife:Int) {
        self.init(asteroid:asteroid,maxLife:maxLife, needToAnimate:true)
    }
    
    init(asteroid:RegularAsteroidSize,maxLife:Int, needToAnimate:Bool) {
        var nodeName:String! = "asteroid-"
        var partName:String! = ""
        
        var w_R:CGFloat
        var w_r:CGFloat
        var f_size:CGFloat
        
        switch (asteroid) {
        case .Medium:
            partName = "medium"
            
            w_R = 10
            w_r = 5
            f_size = 30
            
            break
        case .Small:
            partName = "small"
            
            w_R = 5
            w_r = 2
            f_size = 10
            
            break
        case .Big:
            partName = "large"
            
            w_R = 20
            w_r = 14
            f_size = 100
            
            break
        default:
            break
        }
        if (!partName.isEmpty) {
            nodeName = nodeName.stringByAppendingString(partName)
        }
        
        self.maxLife = maxLife
        let texture = SKTexture(imageNamed: nodeName!)
        
        self.digitNode = DigitNode(size: texture.size(), digit: maxLife,params:[w_R,w_r,f_size])
        self.cropNode = ProgressTimerCropNode(size: texture.size())
        self.asterSize = asteroid
        
        super.init(texture: texture, color: UIColor.clearColor(), size: texture.size())
        
        self.cropNode.addChild(self.digitNode)
        addChild(self.cropNode)
        
        let physBody = SKPhysicsBody(texture: texture, size: texture.size())
        physBody.categoryBitMask = EntityCategory.RegularAsteroid
        physBody.contactTestBitMask = EntityCategory.Player | EntityCategory.PlayerLaser
        
        physBody.collisionBitMask = 0
        
        self.physicsBody = physBody
        
        
        if (needToAnimate) {
            self.startRotation()
        }
    }
    
    private func startRotation() {
        let rotate = SKAction.rotateByAngle(CGFloat(M_PI_2), duration: Double(1))
        let rotateAlways = SKAction.repeatActionForever(rotate)
        runAction(rotateAlways)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    internal func setProgress(progress:CGFloat) {
        self.cropNode.setProgress(min(1,max(0,progress)))
    }
    
    internal func startAnimation() {
        
        let blockAction = SKAction.customActionWithDuration(duration){ (node, time) -> Void in
            self.setProgress(time/CGFloat(duration))
            
            if self.cropNode.currentProgress == 0.0 {
                self.startRotation()
            }
        }
        runAction(blockAction, withKey: self.displayAction)
        
    }
    
    internal func tryToDestroyWithForce(forceValue:ForceType) -> Bool  {
    
        if (actionForKey(self.displayAction) != nil) {
            self.removeActionForKey(self.displayAction)
        }
        
        var result = self.digitNode.digit - forceValue
        
        if (result < 0) {
            result = 0
        }
        self.digitNode.digit = result
        
        return result == 0
    }
    
    
}
