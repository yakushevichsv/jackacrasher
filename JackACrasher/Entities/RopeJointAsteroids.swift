//
//  RopeJointAsteroids.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 4/26/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit
import SpriteKit


class RopeJointAsteroids: SKNode {
    private weak var asteroid1:RegularAsteroid!
    private weak var asteroid2:RegularAsteroid!
    internal var rope:Rope? {
        didSet {
            if let ropeValue = rope {
                oldValue?.removeFromParent()
                addChild(ropeValue)
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(asteroids:[RegularAsteroid]) {
        self.asteroid1 = asteroids[0]
        self.asteroid2 = asteroids[1]
        super.init()
        
        addChild(self.asteroid1)
        addChild(self.asteroid2)
        
        #if DEBUG
            let dot = SKShapeNode(rectOfSize: CGSizeMake(20, 20))
            dot.fillColor = UIColor.redColor()
        
            dot.position = CGPointZero
        
            addChild(dot)
        #endif
        
    }
    
    
    internal func configureBody() {
        
        let body = SKPhysicsBody(bodies:[self.asteroid1.physicsBody!,self.asteroid2.physicsBody!,self.rope!.physicsBody!])
        body.fieldBitMask = 0
        body.categoryBitMask = 0
        body.contactTestBitMask = 0
        
        self.physicsBody = body
        
    }
    
    internal var asteroids:[RegularAsteroid!] {
        get  {return [asteroid1,asteroid2]}
    }
    
    internal func prepare() {
        if let ropeValue = rope {
            ropeValue.createRopeRings()
            //ropeValue.configureBody()
            //configureBody()
        }
    }
}
