//
//  Rope.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 4/25/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit
import SpriteKit

struct RopeConnection:Printable {
    let position:CGPoint
    let node:SKNode!
    
    init(position:CGPoint, node:SKNode!) {
        self.position = position
        self.node = node
    }
    
    var description: String {
        get {
            return "Position: \(self.position) and Node: \(self.node)"
        }
    }
}

private let sRingTexture = SKTexture(imageNamed: "rope_ring")

class Rope: SKNode {
    
    private let con1: RopeConnection
    private let con2: RopeConnection
    private let ancestor:SKNode?
    private var ropeRings:[SKNode]?
    private var rLength:CGFloat = 0.0
    static var onceRingLengthToken: dispatch_once_t = 0
    
    
    init(connection1:RopeConnection,connection2:RopeConnection) {
        let ancestorPtr = Rope.findAncestorforNodes(connection1.node, nodeB: connection2.node)
    
        self.ancestor = ancestorPtr
        
        let arrayPtr =  Rope.findPositionsforConnections(connection1, connection2: connection2,ancestor: ancestorPtr)
            
            if let array = arrayPtr  {
                
                self.con1 = RopeConnection(position: array[0], node: connection1.node)
                
                self.con2 = RopeConnection(position: array[1], node: connection2.node)
            }
            else {
                self.con1 = connection1
                self.con2 = connection2
            }
        
    
        
        super.init()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    //MARK: Class functions
    private class func findPositionsforConnections(connection1:RopeConnection,connection2:RopeConnection, ancestor:SKNode?) ->[CGPoint]? {
        
        var points:[CGPoint]? = nil
        
        if ancestor != nil {
            var pointsInternal = [CGPoint]()
            
            pointsInternal.append(findPositionForConnection(connection1, usingAncestor: ancestor))
            pointsInternal.append(findPositionForConnection(connection2, usingAncestor: ancestor))
            
            points = pointsInternal
        }
        
        return points
    }
    
    private class func findPositionForConnection(connection:RopeConnection, usingAncestor ancestor:SKNode!) -> CGPoint {
        
        var point = connection.position
        
        if (ancestor != connection.node.parent) {
            
            point = connection.node.parent != nil ? connection.node.parent!.convertPoint(connection.position, toNode: ancestor) : CGPoint.zeroPoint
        }
        
        return point
    }

    private class func findAncestorforNodes(nodeA:SKNode!,nodeB:SKNode!) -> SKNode? {
        //assert(nodeA.scene! == nodeB.scene!, "Don't belong to the same scene!")
        
        if let nodeAParent = nodeA.parent {
            if let nodeBParent = nodeB.parent {
                
                if (nodeAParent == nodeBParent) {
                    return nodeAParent
                }
            }
        }
        return nil
    }
    
    //MARK: Internal functions
    internal func createRopeRings() {
       
        assert(false, "Should be overwritten!")
    }
    
    internal var connectionA:RopeConnection {
        get {return con1}
    }
    
    internal var connectionB:RopeConnection {
        get {return con2}
    }
    
    internal var ringLength:CGFloat {
        get {
        
            if (self.rLength == 0) {
                self.rLength =  sqrt(pow(sRingTexture.size().width,2) + pow(sRingTexture.size().height,2))
        }
            
            return self.rLength
        }
    }
    
    internal var ringTexture:SKTexture {
        get {return sRingTexture}
    }

}

