//
//  GameScene.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 4/9/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    var asteroidManager:AsteroidManager!
    var playerName:String!
    let asterName:String! = "TestAster"
    let bgStarsName:String! = "bgStars"
    let bgZPosition:CGFloat = 1
    let fgZPosition:CGFloat = 5
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.createPlayer()
        self.fillInBackgroundLayer()
    }
    
    func fillInBackgroundLayer() {
        
        let emitterNode = SKEmitterNode(fileNamed: "BGStarts.sks")
        let sceneSize = self.size
        emitterNode.position = CGPointMake(self.size.width, 0.5*self.size.height)
        
        emitterNode.name = self.bgStarsName
        emitterNode.zPosition = bgZPosition
        emitterNode.targetNode = nil
        
        addChild(emitterNode)
    }
    
    func createPlayer() {
        let player = Player(position: CGPointMake(500, 500))
        self.playerName = player.name
        player.zPosition = fgZPosition
        self.addChild(player)
    }
    
    override func didMoveToView(view: SKView) {
        
        /* Setup your scene here */
        /*let myLabel = SKLabelNode(fontNamed:"Chalkduster")
        myLabel.text = "Hello, World!";
        myLabel.fontSize = 65;
        myLabel.position = CGPoint(x:CGRectGetMidX(self.frame), y:CGRectGetMidY(self.frame));
        self.addChild(myLabel)*/
        self.physicsWorld.gravity = CGVectorMake(0.0, 0.0)
        self.asteroidManager = AsteroidManager(scene: self)
        
        let texture1 = SKTexture(imageNamed: "Asteroid1_Part1")
        let size1 = texture1.size()
        
        let aInfo = AsteroidInfo()
        aInfo.itemType = AsteroidItemType.TextureName(texture: texture1)
        aInfo.position = CGPointMake(size1.width*0.5,size1.height*0.5)
        
        
        let texture2 = SKTexture(imageNamed: "Asteroid1_Part2")
        let size2 = texture2.size()
        
        let aInfo2 = AsteroidInfo()
        aInfo2.itemType = AsteroidItemType.TextureName(texture: texture2)
        aInfo2.position = CGPointMake(aInfo.position.x + size1.width*0.5, size2.height*0.5)
        
        
        let jointInfo = JointInfo(type: JointType.Fixed, position: CGPointMake(300 + size1.width*0.5, 200))
        
        if let node = self.asteroidManager.createCompositeAsteroid(atPosition: CGPointMake(300,200 - max(size1.height,size2.height)*0.5), usingAsteroidsInfo: [aInfo,aInfo2], andJointsInfo: [jointInfo]) {
            node.name  = asterName
            
        }
        
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        /* Called when a touch begins */
        
        for touch: AnyObject in touches {
            let location = touch.locationInNode(self)
        
            /*for nodeAny in self.nodesAtPoint(location) {
                let node = nodeAny as SKNode
                
                if (node.name != nil && node.name! == self.asterName) {
                    self.asteroidManager.influenceAtPoint(location)
                }
            }*/
            
            /*if let playerNode = self.childNodeWithName(self.playerName) as? Player {
                
               let moveAct =  SKAction.moveTo(location, duration: 1.0)
               
                let eEngine = SKAction.runBlock({ () -> Void in
                    playerNode.enableEngine()
                })
                
                let sEngine = SKAction.runBlock({ () -> Void in
                    playerNode.disableEngine()
                })
        
                let seg = SKAction.sequence([eEngine,moveAct,sEngine])
                
                playerNode.runAction(seg)
                
            }*/
        }
    }
    
    override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        for touch: AnyObject in touches {
            let location = touch.locationInNode(self)
            
            /*for nodeAny in self.nodesAtPoint(location) {
            let node = nodeAny as SKNode
            
            if (node.name != nil && node.name! == self.asterName) {
            self.asteroidManager.influenceAtPoint(location)
            }
            }*/
            
            if let playerNode = self.childNodeWithName(self.playerName) as? Player {
                
                let moveAct =  SKAction.moveTo(location, duration: 1.0)
                
                let eEngine = SKAction.runBlock({ () -> Void in
                    playerNode.enableEngine()
                })
                
                let sEngine = SKAction.runBlock({ () -> Void in
                    playerNode.disableEngine()
                })
                
                let seg = SKAction.sequence([eEngine,moveAct,sEngine])
                
                playerNode.runAction(seg)
                
            }
        }
    }
   
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }
}
