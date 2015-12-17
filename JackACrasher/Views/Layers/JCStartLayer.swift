//
//  JCStartLayer.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 12/16/15.
//  Copyright © 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit

class JCStartLayer: CALayer {
    private let animationDuration: CFTimeInterval = 1.2
    private let midRect:CGRect
    private var animCompletionCount = 0
    private var completionBlock:dispatch_block_t! = nil
    
    private struct Constants {
        static let shrink = "shrink"
        static let scale =  "scale"
        static let position = "position"
        static let shrinkZero = "shrinkZero"
        static let rotation = "rotation"
    }
    
    init(midRect:CGRect) {
        self.midRect = midRect
        super.init()
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func shrinkToMidRect()  {
        
        let repeatCount:NSTimeInterval = 2
        
        let posAnim = CABasicAnimation(keyPath: "position")//"transform.scale")
        posAnim.duration = animationDuration * repeatCount
        //shrinkAnim.fromValue = 0
        if let pLayer = self.presentationLayer() as? CALayer {
            posAnim.fromValue = NSValue(CGPoint:pLayer.position)
        }
        
        let x = self.midRect.center.x
        let y = self.midRect.center.y
        
        posAnim.toValue = NSValue(CGPoint:CGPointMake(x, y))
        //shrinkAnim.beginTime = beginTime
        posAnim.removedOnCompletion = false
        posAnim.fillMode = kCAFillModeForwards
        
        
        let scaleAnim = CABasicAnimation(keyPath: "transform.scale")
        scaleAnim.duration = posAnim.duration
        //shrinkAnim.fromValue = 0
        let param = max(CGRectGetWidth(self.midRect)/CGRectGetWidth(self.frame), CGRectGetHeight(self.midRect)/CGRectGetHeight(self.frame))
        scaleAnim.toValue =   param
        //shrinkAnim.beginTime = beginTime
        scaleAnim.removedOnCompletion = false
        scaleAnim.fillMode = kCAFillModeForwards
        
        let angle = CGFloat(M_PI/2)
        let rotationLAnimation: CABasicAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotationLAnimation.fromValue = self.valueForKeyPath("transform.rotation.z")
        rotationLAnimation.toValue = angle
        rotationLAnimation.duration = animationDuration/4
        rotationLAnimation.removedOnCompletion = false
        rotationLAnimation.repeatCount = 1
        rotationLAnimation.additive = true
        rotationLAnimation.autoreverses = true
        
        let rotationRAnimation: CABasicAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotationRAnimation.toValue = -angle
        rotationRAnimation.duration = rotationLAnimation.duration
        rotationLAnimation.repeatCount = 1
        rotationRAnimation.removedOnCompletion = false
        rotationRAnimation.beginTime = rotationLAnimation.beginTime + rotationLAnimation.duration * (rotationLAnimation.autoreverses ? 2 : 1)
        rotationRAnimation.autoreverses = true
        rotationRAnimation.additive = true
        
        let animationGroup: CAAnimationGroup = CAAnimationGroup()
        animationGroup.animations = [rotationLAnimation,rotationRAnimation]
        animationGroup.duration = animationDuration
        animationGroup.removedOnCompletion = false
        animationGroup.repeatCount = Float(repeatCount)
        
        
        animationGroup.delegate = self
        addAnimation(animationGroup, forKey: Constants.shrink)
        
        posAnim.delegate = self
        addAnimation(posAnim, forKey: Constants.position)
        
        scaleAnim.delegate = self
        addAnimation(scaleAnim, forKey: Constants.scale)
    }
    
    private func shrinkToZero() {
        
        //addAnimation(shrinkAnim, forKey: "shrinkAnim")
        let scaleAnim = CABasicAnimation(keyPath: "transform.scale")
        scaleAnim.duration = animationDuration
        scaleAnim.fromValue = max(CGRectGetWidth(self.midRect)/CGRectGetWidth(self.frame), CGRectGetHeight(self.midRect)/CGRectGetHeight(self.frame))
        //shrinkAnim.fromValue = 0
        scaleAnim.toValue = 0
        //shrinkAnim.beginTime = beginTime
        scaleAnim.removedOnCompletion = false
        scaleAnim.fillMode = kCAFillModeForwards
        
        
        let rotationRAnimation: CABasicAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotationRAnimation.toValue = CGFloat(M_PI * 2)
        rotationRAnimation.duration = animationDuration/2
        rotationRAnimation.removedOnCompletion = false
        rotationRAnimation.additive = true
        rotationRAnimation.autoreverses = true
        rotationRAnimation.repeatCount = 1
        //rotationRAnimation.beginTime = beginTime
        
        //addAnimation(rotationRAnimation, forKey: "rotationRAnimation")
        
        scaleAnim.delegate = self
        addAnimation(scaleAnim, forKey: Constants.scale)
        
        addAnimation(rotationRAnimation, forKey: Constants.rotation)
    }

    
    //MARK: CA Delegate methods...
    
    override func animationDidStart(anim: CAAnimation) {
        
        if (self.animationForKey(Constants.shrink) == anim ||
            self.animationForKey(Constants.shrinkZero) == anim ||
                self.animationForKey(Constants.position) == anim  ||
                self.animationForKey(Constants.scale) == anim) {
                    animCompletionCount++
        }
    }
    
    override func animationDidStop(anim: CAAnimation, finished flag: Bool) {
        
        if (!flag) {
            return
        }
        
        if (self.animationForKey(Constants.shrink) == anim ||
            self.animationForKey(Constants.shrinkZero) == anim ||
            self.animationForKey(Constants.position) == anim  ||
            self.animationForKey(Constants.scale) == anim) {
                animCompletionCount--
        }
        
        if (animCompletionCount == 0) {
            shrinkToZero()
            animCompletionCount--
        }
        else if (animCompletionCount < 0) {
            self.completionBlock()
            self.completionBlock = nil
            self.animCompletionCount = 0
        }
    }
    
    
    //MARK: Public interface
    func animate(completion:dispatch_block_t) -> Bool {
        
        if (self.animCompletionCount != 0) {
            return false
        }
        
        self.completionBlock = completion
        animCompletionCount = 0
        shrinkToMidRect()
        
        
        return true
    }
    
}