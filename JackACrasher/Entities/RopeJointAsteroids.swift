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
    private let asteroid1:RegularAsteroid!
    private let asteroid2:RegularAsteroid!
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
        
    }
    
    internal var asteroids:[RegularAsteroid!] {
        get  {return [asteroid1,asteroid2]}
    }
    
    internal func prepare() {
        if let ropeValue = rope {
            ropeValue.createRopeRings()
        }
    }

    
    
    
}