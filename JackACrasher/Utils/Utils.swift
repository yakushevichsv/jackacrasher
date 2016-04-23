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
    
    if (node.parent == nil || scene == node.parent!) {
        return node.position
    }
    
    return node.parent!.convertPoint(node.position, toNode: scene)
}

func synch(lockObj:AnyObject!,closure:()->Void) {
    
    objc_sync_enter(lockObj)
    closure()
    objc_sync_exit(lockObj)
    return
}

func convertNodePositionUntilScene(node:SKNode!) -> CGPoint {
    
    var pos = node.position
    var nodeParent = node.parent
    while (nodeParent != node.scene){
        
        if let posNew = nodeParent?.convertPoint(pos, toNode:(nodeParent?.parent)!) {
            pos = posNew
            nodeParent = nodeParent?.parent
        }
    }
    return pos
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

func *= (inout vector:CGVector,value:CGFloat) {
    vector = vector * value
}

func * (vector:CGVector, value:CGFloat) -> CGVector {
    
    return CGVector(dx: vector.dx * value, dy: vector.dy * value)
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
    
    func toVector() -> CGVector {
        return CGVector(dx: x, dy: y)
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
        let angle = CGVector(dx: fabs(direction.dx), dy: fabs(direction.dy)).angle
    
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
    
    print("Result vector x:\(xPosDist) y:\(yPosDist). Initial Position \(point). Direction \(direction)")
    return CGVector(dx: xPosDist, dy: yPosDist)
}

extension CGRect {
    var center:CGPoint {
        return CGPointMake(CGRectGetMidX(self), CGRectGetMidY(self))
    }
}

extension CGPoint {
    func rectWithSize(size:CGSize) -> CGRect {
        
        let dx = size.halfWidth()
        let dy = size.halfHeight()
        
        let oX = self.x - dx
        let oY = self.y - dy
        
        return CGRectMake(oX, oY, dx*2, dy*2)
    }
    
    func integralPoint() -> CGPoint {
        return CGPoint(x: round(self.x),y: round(self.y))
    }
}



extension CGSize {
    func rectAtPoint(point:CGPoint) -> CGRect {
        return point.rectWithSize(self)
    }
    
    func maxSizeParam() -> CGFloat {
        return max(self.width,self.height)
    }
    
    func halfMaxSizeParam() -> CGFloat {
        return 0.5*maxSizeParam()
    }
    
    func halfWidth() -> CGFloat {
        return width * 0.5
    }
    
    func halfHeight() -> CGFloat {
        return height * 0.5
    }
}

func reflectionAngleFromContact3(contact:SKPhysicsContact!) -> CGFloat {
    
    var normal = contact.contactNormal
    
    print("Before reflection  Normal dx \(normal.dx),Normal dy \(normal.dy) . Angle (degree) \(normal.angle.degree)")
    
    normal.dx *= CGFloat(-1.0)
    normal.dy *= CGFloat(-1.0)
    
    print("After reflection Normal dx \(normal.dx),Normal dy \(normal.dy) . Angle (degree) \(normal.angle.degree)")
    
    var angle:CGFloat = normal.angle
    
    angle += π
    
    return angle
}

func reflectionAngleFromContact2(contact:SKPhysicsContact!) -> CGFloat {
    
    var normal = contact.contactNormal
    
    print("Before reflection  Normal dx \(normal.dx),Normal dy \(normal.dy) . Angle (degree) \(normal.angle.degree)")
    
    normal.dx *= CGFloat(-1.0)
    normal.dy *= CGFloat(-1.0)
    
    print("After reflection Normal dx \(normal.dx),Normal dy \(normal.dy) . Angle (degree) \(normal.angle.degree)")
    
    var angle:CGFloat = normal.angle
    
    if (normal.dx > 0) {
        
        angle -= π*0.5
    }
    else if (normal.dx == 0){
        
        if (normal.dy > 0) {
            angle = 0
        }
        else if (normal.dy == 0) {
            assert(false, "Normal equal to Zero!")
        }
        else {
            angle = π
        }
    }
    else {
        angle += π*0.5
    }
    
    return angle
}

func reflectionAngleFromContact(contact:SKPhysicsContact!) -> CGFloat {
    
    let normal = contact.contactNormal
    
    let point = contact.contactPoint
    
    
    let point2 = point - CGPointMake(normal.dx*10, normal.dy*10)
    
    let extraAngle = shortestAngleBetween(point.angle, angle2: point2.angle)
    
    return extraAngle
}

func distanceBetweenPoints(point1:CGPoint, point2:CGPoint) -> CGFloat {
    return hypot(CGFloat(point2.x - point1.x), CGFloat(point2.y - point1.x))
}

func radiansBetweenPoints(first:CGPoint, second:CGPoint) -> CGFloat {
    let deltaX = second.x - first.x;
    let deltaY = second.y - first.y;
    return CGFloat(atan2f(Float(deltaY), Float(deltaX)))
}


func convertNodePositionToScene(node:SKNode!) -> CGPoint {
    
    if (node.scene != node.parent && node.parent != nil) {
        return node.parent!.convertPoint(node.position, toNode: node.scene!)
    }
    else {
        return node.position
    }
}

func convertSceneLocationToParentOfNode(location:CGPoint,node:SKNode!) -> CGPoint {
    
    if (node.parent == node.scene) {
        return location
    } else {
        return node.scene!.convertPoint(location, toNode: node.parent!)
    }
}

func randomBetween(y1:CGFloat,y2:CGFloat) -> CGFloat {
    
    let yMax = max(y1,y2)
    let yMin = min(y1,y2)
    
    let yPos = arc4random() % UInt32(yMax-yMin)
    
    return yMin + CGFloat(yPos)
}

func isPhone4s() -> Bool {
    return UIScreen.mainScreen().bounds.size == CGSizeMake(480, 320) && UIScreen.mainScreen().scale == 2.0
}

func isPhone5s() -> Bool {
    return UIScreen.mainScreen().bounds.size == CGSizeMake(568, 320) && UIScreen.mainScreen().scale == 2.0
}

func isPhone6Plus() -> Bool {
    return UIScreen.mainScreen().bounds.size == CGSizeMake(736, 414) && UIScreen.mainScreen().scale == 3.0
}

func randomUntil(y:CGFloat) -> CGFloat {
    return randomBetween(0, y2: y)
}

func randomUntil(y:CGFloat,withOffset offset:CGFloat) -> CGFloat{
    return randomUntil(y) + offset
}

func recursiveConvertPositionToScene(node:SKNode!) -> CGPoint {
    
    var curNode = node
    var parent = curNode.parent!
    var pos = curNode.position

    
    while (parent != node.scene)  {
    
        curNode = parent
        parent = curNode.parent!
        pos = parent.convertPoint(pos, fromNode: curNode)
    }
    
    return pos
}

func isNullOrEmpty(str:String?) -> Bool {
    return str == nil || str!.isEmpty
}

extension String {
    
    func stringByAppendingPathComponent(lastComponent:String?) -> String {
        
        if let lastComponent = lastComponent {
            
            let nsSt = self as NSString
            
            return nsSt.stringByAppendingPathComponent(lastComponent)
        }
        else {
            return self
        }
    }
    
    var  lastPathComponent:String? {
        get {
            
            return (self as NSString).lastPathComponent  
        }
    }
    
}

