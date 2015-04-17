//
//  GameScene.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 4/9/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import SpriteKit

class GameScene: SKScene, AsteroidGeneratorDelegate,SKPhysicsContactDelegate {
    
    var asteroidManager:AsteroidManager!
    var asteroidGenerator:AsteroidGenerator!
    
    let asterName:String! = "TestAster"
    let bgStarsName:String! = "bgStars"
    let bgZPosition:CGFloat = 1
    let fgZPosition:CGFloat = 5
    var trashAsteroidsCount:Int = 0
    
    private var player:Player!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.createPlayer()
        self.fillInBackgroundLayer()
        self.createAsteroidGenerator()
        
        self.physicsWorld.contactDelegate = self
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
    
    func createAsteroidGenerator() {
        
        self.asteroidGenerator = AsteroidGenerator(sceneSize: self.size, andDelegate: self)
        self.asteroidGenerator.start()
    }
    
    func createPlayer() {
        let player = Player(position: CGPointMake(500, 500))
        player.zPosition = fgZPosition
        self.addChild(player)
        self.player = player
        self.player.hidden = false
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
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
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
    
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        for touch: AnyObject in touches {
            let location = touch.locationInNode(self)
            
            if (self.player.canThrowProjectile()) {
                self.player.throwProjectileToLocation(location)
            } else {
                self.player.moveToPoint(location)
            }
        }
    }
   
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }
    
    //MARK: Asteroid Generator's delegate methods
    func didMoveOutAsteroidForGenerator(generator: AsteroidGenerator, asteroid: SKSpriteNode, withType type: AsteroidType) {
        
        switch (type) {
        case .Trash:
            if (self.trashAsteroidsCount != 0 && asteroid.parent != nil) {
                self.trashAsteroidsCount--
            }
            
            if (self.trashAsteroidsCount == 0) {
                self.player.disableProjectileGun()
                generator.paused = self.trashAsteroidsCount != 0
            }
            
            println("Trash asteroids count \(self.trashAsteroidsCount) after removing" )
            
            break;
        default:
            break;
        }
    }
    
    func asteroidGenerator(generator: AsteroidGenerator, didProduceAsteroids: [SKSpriteNode], type: AsteroidType) {
        
        for node in didProduceAsteroids {
            node.zPosition = self.fgZPosition
            self.addChild(node)

        }
        generator.paused = true
        
        
        switch (type) {
        case .Trash:
            self.player.removeAllActions()
            self.player.disableEngine()
            self.trashAsteroidsCount += didProduceAsteroids.count
            
            println("Trash asteroids count \(self.trashAsteroidsCount) addition" )
            self.player.enableProjectileGun()
            
            //eee Move up if there is a contact...
            break;
        default:
            break;
        }
    }
    
    //MARK: Contact methods
    
    func didBeginContact(contact: SKPhysicsContact)
    {
        let bodyA = contact.bodyA
        let bodyB = contact.bodyB
        
        var trashAster:SKPhysicsBody? = nil
        
        if (bodyA.categoryBitMask == EntityCategory.TrashAsteroid ) {
            trashAster = bodyA
        }
        else if (bodyB.categoryBitMask == EntityCategory.TrashAsteroid) {
            trashAster = bodyB
        }
        else {
            return
        }
        
        
        var laser:SKPhysicsBody? = nil
            
        if (trashAster! == bodyA &&  bodyB.categoryBitMask == EntityCategory.PlayerLaser ) {
            laser = bodyB
        }
        else if (trashAster! == bodyB &&  bodyA.categoryBitMask == EntityCategory.PlayerLaser ) {
            laser = bodyA
        }
        else {
            return
        }
        
        self.didMoveOutAsteroidForGenerator(self.asteroidGenerator, asteroid: trashAster!.node as! SKSpriteNode, withType: AsteroidType.Trash)
        
        trashAster!.node?.removeFromParent()
        laser!.node?.removeFromParent()
        
        //TODO: Play sound here....
        //TODO: present explosion here....
        
    }
}
