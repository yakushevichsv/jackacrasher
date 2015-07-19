//
//  Utils.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 4/20/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import Foundation
import CoreGraphics
import SpriteKit

func runOneShortEmitter(emitter:SKEmitterNode, duration:NSTimeInterval) {
    
   emitter.runAction(SKAction.sequence([SKAction.waitForDuration(duration), SKAction.runBlock { () -> Void in
        emitter.particleBirthRate = 0 }, SKAction.waitForDuration(NSTimeInterval(emitter.particleLifetime + emitter.particleLifetimeRange)), SKAction.removeFromParent()]))
}

func convertNodePosition(node:SKNode!,toScene scene:SKScene!) -> CGPoint {
    
    if (node.parent == nil && scene == node.parent!) {
        return node.position
    }
    
    return node.parent!.convertPoint(node.position, toNode: scene)
}

func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func += (inout left: CGPoint, right: CGPoint) {
    left = left + right
}

func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func -= (inout left: CGPoint, right: CGPoint) {
    left = left - right
}

func * (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x * right.x, y: left.y * right.y)
}

func *= (inout left: CGPoint, right: CGPoint) {
    left = left * right
}

func * (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func *= (inout point: CGPoint, scalar: CGFloat) {
    point = point * scalar
}

func / (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x / right.x, y: left.y / right.y)
}

func /= (inout left: CGPoint, right: CGPoint) {
    left = left / right
}

func / (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

func /= (inout point: CGPoint, scalar: CGFloat) {
    point = point / scalar
}

#if !(arch(x86_64) || arch(arm64))
    func atan2(y: CGFloat, x: CGFloat) -> CGFloat {
        return CGFloat(atan2f(Float(y), Float(x)))
    }
    
    func sqrt(a: CGFloat) -> CGFloat {
        return CGFloat(sqrtf(Float(a)))
    }
#endif


extension CGFloat {
    
    var degree:CGFloat {
        return self * CGFloat(180.0 * M_1_PI)
    }
    
    func sign() -> CGFloat {
        return (self >= 0.0) ? 1.0 : -1.0
    }
    
    var radians:CGFloat {
        return self * CGFloat(M_PI/180.0)
    }
}

extension CGPoint {
    
    func length() -> CGFloat {
        return sqrt(x*x + y*y)
    }
    
    func normalized() -> CGPoint {
        return self / length()
    }
    
    var angle: CGFloat {
        return atan2(y, x)
    }
}


let π = CGFloat(M_PI)

func shortestAngleBetween(angle1: CGFloat,
    angle2: CGFloat) -> CGFloat {
        let twoπ = π * 2.0
        var angle = (angle2 - angle1) % twoπ
        if (angle >= π) {
            angle = angle - twoπ
        }
        if (angle <= -π) {
            angle = angle + twoπ
        }
        return angle
}


func vectorFromPoint(point:CGPoint, usingDirection direction:CGVector, inRect rect:CGRect) -> CGVector {
    
        let pointOne = point
        
        let isU = direction.dy > 0
        let isR = direction.dx > 0
        var angle = CGVector(dx: fabs(direction.dx), dy: fabs(direction.dy)).angle
    
        /*let pHalf =  π * 0.5
    
        if (angle > pHalf) {
            angle -= pHalf
        } else if (angle < -pHalf) {
            angle += pHalf
        } else if (angle >= 0 && angle < pHalf){
            angle = pHalf - angle
        } else if (angle < 0 && angle > -pHalf) {
            angle = angle + pHalf
        }*/
    
        var yPosDist = isU ? (CGRectGetHeight(rect) + CGRectGetMinY(rect) - pointOne.y) : (pointOne.y)
        
        var xPosDist = isR ? (CGRectGetWidth(rect) - pointOne.x) : (pointOne.x)
        
        let aAngle = fabs(angle)
        
        if (aAngle != π * 0.5) {
            
            let tanVal = tan(aAngle)
            
            let xPosDist2 = yPosDist * tanVal
            
            let xPosDistMin = min(xPosDist2,xPosDist)
            
            xPosDist = xPosDistMin
            
            if (tanVal != 0) {
                yPosDist = xPosDist/tanVal
            }
            
        } else {
            yPosDist = 0
            
        }
    
    if (!isU && yPosDist >= 0) {
        //assert(yPosDist >= 0 , "yPostDist")
        
        yPosDist *= -1
    }
    
    if (!isR && xPosDist >= 0) {
        //assert(xPosDist>=0, "xPostDist")
        xPosDist *= -1
    }
    
    println("Result vector x:\(xPosDist) y:\(yPosDist). Initial Position \(point). Direction \(direction)")
    return CGVector(dx: xPosDist, dy: yPosDist)
}

