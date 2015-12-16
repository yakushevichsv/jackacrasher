//
//  JCStartLayer.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 12/16/15.
//  Copyright © 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit

class JCStartLayer: CAShapeLayer {
    private let animationDuration: CFTimeInterval = 1.2
    private let midRect:CGRect
    
    init(midRect:CGRect) {
        self.midRect = midRect
        super.init()
        fillColor = UIColor.lightGrayColor().CGColor
        borderColor = UIColor.blackColor().CGColor
        borderWidth = 2.0
    }
    
    override var frame: CGRect {
        get {
            return super.frame
        }
        set {
            super.frame = newValue
            path = rectPathLarge.CGPath
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var rectPathLarge:UIBezierPath {
        return UIBezierPath(rect: CGRect(origin: CGPointZero,size:self.bounds.size))
    }
    
    private var rectPathMedium:UIBezierPath {
        return UIBezierPath(rect: self.midRect)
    }
    
    private var rectPathMediumZero:UIBezierPath {
        return UIBezierPath(rect:CGRect(origin: self.midRect.center, size: CGSizeZero))
    }
    
    private func shrinkToMidRect() -> CFTimeInterval {
        let shrinkAnim = CABasicAnimation(keyPath: "path")
        shrinkAnim.duration = animationDuration * 2
        shrinkAnim.fromValue = self.path
        shrinkAnim.toValue = self.rectPathMedium.CGPath
        shrinkAnim.removedOnCompletion = false
        shrinkAnim.fillMode = kCAFillModeForwards
        shrinkAnim.additive = true
        addAnimation(shrinkAnim, forKey: "shrinkAnim")
        
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
        animationGroup.repeatCount = Float(shrinkAnim.duration/animationDuration)
        
        
        addAnimation(animationGroup, forKey: "shrinkToMidRect")
        
        return animationGroup.duration * CFTimeInterval(animationGroup.repeatCount) + animationGroup.beginTime
    }
    
    private func shrinkToMidPoint(beginTime:CFTimeInterval) -> CFTimeInterval {
        let shrinkAnim = CABasicAnimation(keyPath: "path")
        shrinkAnim.duration = animationDuration
        shrinkAnim.fromValue = self.path
        shrinkAnim.toValue = self.rectPathMediumZero.CGPath
        //shrinkAnim.beginTime = beginTime
        shrinkAnim.removedOnCompletion = false
        shrinkAnim.fillMode = kCAFillModeForwards
        
        //addAnimation(shrinkAnim, forKey: "shrinkAnim")
        

        
        let rotationRAnimation: CABasicAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotationRAnimation.toValue = CGFloat(M_PI * 2)
        rotationRAnimation.duration = animationDuration/2
        rotationRAnimation.removedOnCompletion = false
        rotationRAnimation.additive = true
        rotationRAnimation.autoreverses = true
        rotationRAnimation.repeatCount = 1
        //rotationRAnimation.beginTime = beginTime
        
        //addAnimation(rotationRAnimation, forKey: "rotationRAnimation")
        
        let animationGroup: CAAnimationGroup = CAAnimationGroup()
        animationGroup.animations = [rotationRAnimation,shrinkAnim]
        animationGroup.duration = animationDuration
        animationGroup.repeatCount = 1
        animationGroup.beginTime = beginTime
        animationGroup.removedOnCompletion = false
        addAnimation(animationGroup, forKey: "shrinkToMidPoint2")
        
        
        
        return animationDuration //animationGroup.duration * CFTimeInterval(animationGroup.repeatCount) + animationGroup.beginTime
    }

    
    //MARK: Public interface
    func animate() -> CFTimeInterval {
        
        //let durationPart = shrinkToMidRect()
        let durationTotal = shrinkToMidPoint(0)
        
        return durationTotal
    }
    
    
}