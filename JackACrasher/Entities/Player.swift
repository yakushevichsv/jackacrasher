//
//  Player.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 4/12/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit
import SpriteKit


class Player: SKSpriteNode {
    private let engineNodeName = "engineEmitter"
    
    init(position:CGPoint) {
        let texture = SKTexture(imageNamed: "player")
        
        super.init(texture: texture,color:SKColor.whiteColor(), size:texture.size())
        
        self.name = "Player"
        
        createEngine()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createEngine() {
        
        let engineEmitter = SKEmitterNode(fileNamed: "Engine.sks")
        
        let size = self.texture!.size()
        
        engineEmitter.position = CGPoint(x: size.width * -0.5, y: size.height * -0.3)
        engineEmitter.name = engineNodeName
        addChild(engineEmitter)
        
        engineEmitter.targetNode = scene
        
        engineEmitter.hidden = true
    }
    
    //MARK: Public methods
    func enableEngine() {
        self.defineEngineState(false)
    }
    
    func disableEngine() {
        self.defineEngineState(true)
    }
    
    func defineEngineState(enabled:Bool) {
        
        if let engineNode = self.childNodeWithName(engineNodeName) {
            engineNode.hidden = enabled
        }
    }
    
}
