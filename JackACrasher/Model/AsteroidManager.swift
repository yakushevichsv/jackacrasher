//
//  AsteroidManager.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 4/9/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit
import SpriteKit

enum JointType {
    case Fixed
}

enum AsteroidItemType {
    case ImageName(name:String!)
    case TextureName(texture:SKTexture!)
}

struct JointInfo {
    var type:JointType
    var position:CGPoint
}

enum BodyType {
    case Circle(radius:Float)
    case Rect(size:CGSize)
    case Path(path:CGPath!)
}


class AsteroidInfo: NSObject {
    
    var itemType:AsteroidItemType? = nil
    var position:CGPoint = CGPointZero
    var bodyType:BodyType? = nil
    private var _body:SKPhysicsBody? = nil
    
    var body:SKPhysicsBody? {
        get {
            
            if _body != nil {
                return _body!
            }
            
            if let bodyType = self.bodyType {
                switch (bodyType)
                {
                case .Circle(radius: let r):
                        _body = SKPhysicsBody(circleOfRadius: CGFloat(r))
                break
                    
                case .Rect(size: let size):
                    _body =  SKPhysicsBody(rectangleOfSize: size)
                break
                    
                case .Path(path: let path):
                    _body = SKPhysicsBody(polygonFromPath: path)
                    break
                    
                }
            }
            
            return _body
        }
    }
    
    func defineBody(body:SKPhysicsBody!) {
        _body = body
    }
}

private let JointMaxResistance:Float = 2.0
private let JointResistanceThreshold:Float = 1e-3

class JointState:NSObject {
    
    var resistance:Float = JointMaxResistance
    
    var threshold:Float = JointResistanceThreshold
    let joint:SKPhysicsJoint!
    weak var node:SKShapeNode!
    
    init(joint:SKPhysicsJoint!, node:SKShapeNode!, resistance:Float = JointMaxResistance) {
        self.node = node
        self.resistance = resistance
        self.joint = joint
        super.init()
    }
    
    func recalculateResistance(touchPoint:CGPoint, jointPoint:CGPoint) -> Void {
        
        let dx = Float(touchPoint.x - jointPoint.x)
        let dy = Float(touchPoint.y - jointPoint.y)
        
        let dist:Float = (sqrt(pow(dx, 2) + pow(dy, 2))+0)
        
        self.resistance -= (JointMaxResistance/min(max(1,dist),5))
        
        if self.needToDelete() {
            
            let bodyA = self.joint.bodyA
            let bodyB = self.joint.bodyB
            
            bodyA.node?.scene?.physicsWorld.removeJoint(self.joint)
            
            
            let pointA = bodyA.node?.convertPoint(jointPoint, fromNode: bodyA.node!.scene!)
            let pointB = bodyB.node?.convertPoint(jointPoint, fromNode: bodyB.node!.scene!)
            
            
            if (pointA != nil && pointB != nil) {
                bodyA.applyImpulse(CGVectorMake(rand()%10 < 5 ? -10 : 10 , rand()%10 < 5 ? -10 : 10), atPoint: pointA!)
                bodyB.applyImpulse(CGVectorMake(rand()%10 < 5 ? -10 : 10 , rand()%10 < 5 ? -10 : 10), atPoint: pointB!)
            }
            
            
        }
     }
    
    func needToDelete() -> Bool {
        return self.resistance <= threshold
    }
    
    deinit{
        self.node.removeFromParent()
    }
}

class AsteroidManager : NSObject {
    
    var jointsArray:[NSValue:JointState] = Dictionary<NSValue,JointState>()
    
    var scene:SKScene! {
        didSet {
            if (oldValue != self.scene) {
                self.jointsArray.removeAll(keepCapacity:false)
            }
        }
    }
    
    init(scene:SKScene) {
        super.init()
        self.scene = scene
    }
    
    
    //MARK: Public Methods
    
    func createAsteroid(info:AsteroidInfo) ->SKSpriteNode?{
        
        var sprite:SKSpriteNode? = nil
        
        let itemType = info.itemType
        
        if itemType != nil {
        
        switch(itemType!) {
            case .ImageName(name: let name):
                sprite =  SKSpriteNode(imageNamed: name)
                break
            case .TextureName(texture: let texture):
                sprite = SKSpriteNode(texture: texture)
                sprite!.size = texture.size()
                break
            }
        }
        
        sprite?.physicsBody = info.body
        sprite?.anchorPoint = CGPointMake(0.5, 0.5)
        var body:SKPhysicsBody? = info.body
        
        if (body == nil) {
            
            let itemType = info.itemType
            
            if itemType != nil {
                
                switch(itemType!) {
                    
                case .ImageName(name: let name):
                    let texture =  SKTexture(imageNamed: name)
                    body = SKPhysicsBody(texture: texture, size: texture.size())
                    
                    break;
                case .TextureName(texture: let texture):
                    body = SKPhysicsBody(texture: texture, size: texture.size())
                    break;
                }
            }
            
            sprite?.physicsBody = body
        }
        
        sprite?.position = info.position
        print("Sprite position: \(info.position)")
        return sprite
    }
    
    func influenceAtPoint(point:CGPoint) {
        
        var array:[NSValue!] = []
        
        for (key, value) in self.jointsArray {
            
            value.recalculateResistance(point, jointPoint: key.CGPointValue())
            
            if value.needToDelete() {
                array.append(key)
            }
        }
        for key in array {
            self.jointsArray.removeValueForKey(key)
        }
        
    }
    
    func createCompositeAsteroid(atPosition position:CGPoint, usingAsteroidsInfo asteroidsInfo:[AsteroidInfo], andJointsInfo jointsInto:[JointInfo]) -> SKNode? {
        
        var finalNode:SKNode? = nil
        var aBodies:[SKPhysicsBody] = []
        
        for aInfo in asteroidsInfo {
            if let sprite = self.createAsteroid(aInfo) {
                
                var blue = false
                if finalNode == nil {
                    finalNode = SKNode()
                    finalNode!.position = position
                    print("Final node position \(position)")
                    self.scene.addChild(finalNode!)
                    blue = true
                }
                
                finalNode!.addChild(sprite)
                
                let border = SKShapeNode(rectOfSize: sprite.size)
                border.strokeColor =  blue ? UIColor.blueColor() : UIColor.greenColor()
                border.position = sprite.position
                sprite.parent?.addChild(border)
                
                aBodies.append(sprite.physicsBody!)
                
            }
        }
        
        if (aBodies.count != 0) {
            finalNode!.physicsBody = SKPhysicsBody(bodies: aBodies) //SKPhysicsBody(bodies: aBodies)
            finalNode!.position = position
            
            var index:Int = 0
            let bodiesCount = asteroidsInfo.count
            
            for jointInfo in jointsInto {
                
                switch jointInfo.type {
                    case .Fixed:
                        
                        let bodyA:SKPhysicsBody? = index < bodiesCount ? aBodies[index] : nil
                        let bodyB:SKPhysicsBody? = index + 1 < bodiesCount ? aBodies[index+1] : nil
                    
                        if (bodyA != nil  && bodyB != nil ) {
                            let joint = SKPhysicsJointFixed.jointWithBodyA(bodyA!, bodyB: bodyB!, anchor: jointInfo.position)
                            
                            print("Joint position \(jointInfo.position)")
                            
                            scene.physicsWorld.addJoint(joint)
                            
                            let shapeNode = SKShapeNode(circleOfRadius: 5.0)
                            shapeNode.position = jointInfo.position
                            shapeNode.strokeColor = UIColor.redColor()
                            scene.addChild(shapeNode)
                            
                            let value =  NSValue(CGPoint: jointInfo.position)
                            
                            self.jointsArray[value] = JointState(joint: joint,node: shapeNode)
                            
                        }
                        break;
                }
                
                
                
                index+=2
            }
        }
        
        return finalNode
    }
}
