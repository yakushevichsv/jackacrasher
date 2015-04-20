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
            } else if (self.player.parent == self.player.scene) {
                self.player.moveToPoint(location)
            } else  {
                //TODO: handle touch...
                
                shakeCamera(0.8)
            }
        }
    }
    
    func shakeCamera(duration:NSTimeInterval) {
        let amplitudeX:CGFloat = 10;
        let amplitudeY:CGFloat = 6;
        let numberOfShakes = duration / 0.04;
        var actionsArray:[SKAction] = [];
        for index in 1...Int(numberOfShakes) {
            // build a new random shake and add it to the list
            let moveX = CGFloat(arc4random_uniform(UInt32(amplitudeX))) - CGFloat(amplitudeX * 0.5)
            let moveY = CGFloat(arc4random_uniform(UInt32(amplitudeY))) - CGFloat(amplitudeY * 0.5)
            let shakeAction = SKAction.moveByX(moveX, y: moveY, duration: 0.02)
            shakeAction.timingMode = SKActionTimingMode.EaseOut;
            actionsArray.append(shakeAction);
            actionsArray.append(shakeAction.reversedAction());
        }
        
        let actionSeq = SKAction.sequence(actionsArray);
        self.player.parent?.runAction(actionSeq);
    }
   
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }
    
    func returnPlayerToScene(sprite:SKSpriteNode) -> Bool {
        
        if let playerParent = self.player.parent {
            
            if playerParent == sprite {
                playerParent.physicsBody!.categoryBitMask = EntityCategory.RegularAsteroid
                self.player.removeFromParent()
                
                addChild(self.player)
                self.player.position = CGPointMake(self.player.size.width, self.player.position.y)
                self.player.anchorPoint = CGPointMake(0.5, 0.5)
                self.player.physicsBody!.contactTestBitMask != EntityCategory.Player
                self.player.zRotation = 0
                self.player.zPosition--
                return true
            }
        }
        return false
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
            
            break
        case .Bomb:
            generator.paused = false
            break
        case .Regular:
            generator.paused = false
            returnPlayerToScene(asteroid)
            break
        default:
            break
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
        case .Bomb:
            break;
        case .Regular:
            self.player.disableProjectileGun()
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
        var bomb:SKPhysicsBody? = nil
        var laser:SKPhysicsBody? = nil
        var regular:SKPhysicsBody? = nil
        
        //Trash asteroid
        if (bodyA.categoryBitMask == EntityCategory.TrashAsteroid ) {
            trashAster = bodyA
        }
        else if (bodyB.categoryBitMask == EntityCategory.TrashAsteroid) {
            trashAster = bodyB
        }
        // bomb search
        else if (bodyA.categoryBitMask == EntityCategory.Bomb) {
            bomb = bodyA
        } else if (bodyB.categoryBitMask == EntityCategory.Bomb) {
            bomb = bodyB
        } else if (bodyA.categoryBitMask == EntityCategory.RegularAsteroid) {
            regular = bodyA
        } else if (bodyB.categoryBitMask == EntityCategory.RegularAsteroid) {
            regular = bodyB
        }
        
        if let regularBody = regular  {
            
            let pNode = regularBody.node!
            
            var normal = contact.contactNormal
            
            normal.dx *= CGFloat(-1.0)
            normal.dy *= CGFloat(-1.0)
            
            let angle = self.player.zRotation
            
            let vector = CGVector(dx: cos(CGFloat(M_PI_2) - angle), dy: sin(CGFloat(M_PI_2) -  angle))
            
            let angel2 =  CGFloat(M_PI_2) - atan(vector.dy/vector.dx) //CGFloat(M_PI_2) -  acos(normal.dx * vector.dx+normal.dy * vector.dy)
            
            self.player.anchorPoint = CGPointZero
            self.player.zRotation = angel2*0
            self.player.zPosition += 1
            
            let pointInternal = pNode.convertPoint(contact.contactPoint, fromNode: self)
            
            self.player.position = CGPointZero// pointInternal
            self.player.removeFromParent()
            regularBody.contactTestBitMask &= ~EntityCategory.Player
            regularBody.categoryBitMask = 0
            pNode.addChild(self.player)
            
            
            return
        }
        
        if let bombBody = bomb {
            println("One node is bomb!")
            let bombNode = bombBody.node!
            
            let radius = bombNode.userData!["radius"] as! CGFloat
        
            let contactP = contact.contactPoint
            
            let x = contactP.x - radius
            let y = contactP.y - radius
            
            let rect = CGRectMake(x, y, 2*radius, 2*radius)
            
            
            let node = bombNode
            let scenePoint = contact.contactPoint
            createExplosion(ExplosionType.Large, position: scenePoint,withScore:0)
            bombNode.removeFromParent()
            
            self.didMoveOutAsteroidForGenerator(self.asteroidGenerator, asteroid: bombNode as! SKSpriteNode, withType: AsteroidType.Bomb)
            
            self.physicsWorld.enumerateBodiesInRect(rect, usingBlock: { (eBody, _) -> Void in
                
                if (eBody.categoryBitMask == EntityCategory.TrashAsteroid) {
                    
                    self.processContact(eBody, andPlayerLaser: nil)
                    
                } else if (eBody.categoryBitMask == EntityCategory.Player) {
                    //TODO: remove live value...
                    //or GameOver...
                }
            })
            
            
            return
        }
        
        if (trashAster == nil) {
            return
        }
            
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
        
        
        processContact(trashAster!, andPlayerLaser: laser)
        
    }
    
    func processContact(trashAster:SKPhysicsBody!, andPlayerLaser laser:SKPhysicsBody?) {
        
        
        var nodePtr:SKNode? =   laser?.node != nil ? laser?.node! : (trashAster.node != nil ? trashAster.node! :nil)
        
        if let node = nodePtr  {
            
            let scenePoint = node.position
            
            let expType = self.trashAsteroidsCount == 0 ? ExplosionType.Large : ExplosionType.Small
            
            createExplosion(expType, position: scenePoint,withScore: 10)
            
        }
        
        
        trashAster!.node?.removeFromParent()
        laser?.node?.removeFromParent()
    }
    
    func createExplosion(explosionType:ExplosionType, position:CGPoint, withScore scoreAddition:CGFloat) {
        
        switch explosionType {
        case .Small:
            var explosion = Explosion(explosionType: .Small)
            explosion.position = position
            explosion.zPosition = self.fgZPosition
            
            addChild(explosion)
            runAction(SoundManager.explosionSmall)
            break;
        case .Large:
            var explosion = Explosion(explosionType: .Large)
            explosion.zPosition = self.fgZPosition
            explosion.position = position
            
            addChild(explosion)
            runAction(SoundManager.explosionLarge)
            
            if (scoreAddition == 0) {
                return
            }
            
            let scoreLabel = SKLabelNode(fontNamed: "Menlo-Regular")
            scoreLabel.text = "+\(scoreAddition)"
            scoreLabel.fontSize = 30.0
            scoreLabel.horizontalAlignmentMode = .Center
            scoreLabel.position = position
            scoreLabel.runAction(SKAction.sequence([
                SKAction.moveByX(0, y: 30, duration: 1.0),
                SKAction.fadeOutWithDuration(1.0),
                SKAction.removeFromParent()
                ]))
            addChild(scoreLabel)
            
            //TODO: add score here....
            break;
        }
        
    }
}
