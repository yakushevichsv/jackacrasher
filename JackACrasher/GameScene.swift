//
//  GameScene.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 4/9/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import SpriteKit

@objc protocol GameSceneDelegate
{
    func gameScenePlayerDied(scene:GameScene)
}

extension GameScene {
    class func unarchiveFromFile(file : NSString) -> SKNode? {
        if let path = NSBundle.mainBundle().pathForResource(file as String, ofType: "sks") {
            var sceneData = NSData(contentsOfFile: path, options: .DataReadingMappedIfSafe, error: nil)!
            var archiver = NSKeyedUnarchiver(forReadingWithData: sceneData)
            
            archiver.setClass(self.classForKeyedUnarchiver(), forClassName: "SKScene")
            let scene = archiver.decodeObjectForKey(NSKeyedArchiveRootObjectKey) as! GameScene
            archiver.finishDecoding()
            return scene
        } else {
            return nil
        }
    }
}

class GameScene: SKScene, AsteroidGeneratorDelegate,SKPhysicsContactDelegate,AnalogControlPositionChange {
    
    var asteroidManager:AsteroidManager!
    var asteroidGenerator:AsteroidGenerator!
    weak var gameSceneDelegate:GameSceneDelegate?
    
    let asterName:String! = "TestAster"
    let bgStarsName:String! = "bgStars"
    let bgZPosition:CGFloat = 1
    let fgZPosition:CGFloat = 5
    
    private var lastProjectileExp:(date:NSTimeInterval,position:CGPoint) = (0,CGPointZero)
    private let maxLifesCount:Int = 5
    private var lifeWidth:CGFloat = 0
    private var  hudNode:HUDNode!
    
    var trashAsteroidsCount:Int = 0
    private var player:Player!
    
    private var enableCuttingRope:Bool = false
    private var startPoint:CGPoint = CGPointZero
    private var movedPoint:CGPoint = CGPointZero
    private var endPoint:CGPoint = CGPointZero
    private var moving:Bool = false
    
    private let scoreLabel = SKLabelNode(fontNamed: "gamerobot")
    
    private var playableArea:CGRect = CGRectZero
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        
        self.fillInBackgroundLayer()
        
        //self.defineStartingRect(CGRectMake(0, 0, 20, 50), alpha: 0.7)
        
        

        
        self.physicsWorld.gravity = CGVectorMake(0.0, 0.0)
        self.physicsWorld.contactDelegate = self
        
        self.asteroidManager = AsteroidManager(scene: self)
        
    }
    
    internal func defineStartingRect(rect:CGRect,alpha:CGFloat) {
        
        if (childNodeWithName("HUD") != nil) {
            return
        }
        
        
        let height = CGRectGetHeight(rect)
        
        let inSize = CGSizeMake(CGFloat(round(self.playableArea.size.width/6.0)), height)
        
        println("IN size \(inSize)")
        
        let hudNode = HUDNode(inSize: inSize, maxLife: self.maxLifesCount)
        hudNode.name = "HUD"
        hudNode.position = CGPointMake(CGRectGetMaxX(self.playableArea) - inSize.width*0.5 - 10, CGRectGetMaxY(self.playableArea) - inSize.height*0.5 - 100.0)
        hudNode.alpha = alpha
        hudNode.zPosition = self.fgZPosition + 1
        addChild(hudNode)
        self.hudNode = hudNode
        println("HUD node position \(hudNode.position)")
        
    }
    
    
    func definePlayableRect() {
        
        assert(self.scaleMode == .AspectFill, "Not aspect fill mode")
        
        if let presentView = self.view {
            
            /*let vH = CGRectGetHeight(presentView.bounds)
            let vW = CGRectGetWidth(presentView.bounds)
            
            let hRatio = vH/self.size.height
            let wRatio = vW/self.size.width
            
            let ratio = min(hRatio,wRatio)
            
            let h = self.size.height * ratio
            let w = self.size.width * ratio
            
            
            let yDiff = 0.5*( max(h,vH) - min(h,vH))
            let xDiff = 0.5*( max(w,vW) - min(w,vW))
            
            self.playableArea = CGRectMake(xDiff/ratio, yDiff/ratio, vW/ratio, vH/ratio)*/
            
            let maxAspectRatio:CGFloat = 16.0/9.0 // 1
            let playableHeight = size.width / maxAspectRatio // 2
            let playableMargin = (size.height-playableHeight)/2.0 // 3
            playableArea = CGRect(x: 0, y: playableMargin,
                width: size.width,
                height: playableHeight) // 4
            println("Area \(self.playableArea)")
        }
    }
    
    
    func fillInBackgroundLayer() {
        
        let emitterNode = SKEmitterNode(fileNamed: "BGStarts.sks")
        emitterNode.position = CGPointMake(CGRectGetWidth(self.playableArea), CGRectGetMidY(self.playableArea))
        
        emitterNode.name = self.bgStarsName
        emitterNode.zPosition = bgZPosition
        emitterNode.targetNode = nil
        
        emitterNode.particlePositionRange = CGVectorMake(0, CGRectGetHeight(self.playableArea))
        
        let timeInterval = CGRectGetWidth(self.playableArea)/emitterNode.particleSpeed
        
        emitterNode.particleLifetime = timeInterval
        
        addChild(emitterNode)
    }
    
    func createAsteroidGenerator() {
        
        self.asteroidGenerator = AsteroidGenerator(playableRect: self.playableArea, andDelegate: self)
        self.asteroidGenerator.start()
    }
    
    func createPlayer() {
        let player = Player(position: CGPointMake(CGRectGetMidX(self.playableArea), CGRectGetMidY(self.playableArea)))
        player.alpha = 0.0
        
        player.zPosition = fgZPosition
        self.addChild(player)
        self.player = player
        
        let sparkEmitter = SKEmitterNode(fileNamed: "Spawn")
        sparkEmitter.zPosition = player.zPosition
        sparkEmitter.position = player.position
        addChild(sparkEmitter)
        runOneShortEmitter(sparkEmitter, 0.15)
        player.runAction(SKAction.fadeInWithDuration(2.0))
        
        //self.player.anchorPoint = CGPointZero
        //self.player.zRotation = CGFloat(140).radians
        println("Z rotation \(self.player.zRotation)")
        self.player.hidden = false
    }
    
    override func didMoveToView(view: SKView) {
        
        self.definePlayableRect()
        self.createPlayer()
        self.createAsteroidGenerator()
        
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
    
    private func canCutRope(touches: Set<NSObject>) -> Bool {
        return touches.count == 1 && self.enableCuttingRope
    }
    
    private func transferAsteroidsToScene(rope:Rope) {
        
        if let ropeJointsAster = rope.parent  as? RopeJointAsteroids {
            
            for regAster:RegularAsteroid in ropeJointsAster.asteroids {
                let position = ropeJointsAster.convertPoint(regAster.position, toNode: self)
                regAster.removeFromParent()
                regAster.position = position
                asteroidGenerator(self.asteroidGenerator, didProduceAsteroids: [regAster], type: .Regular)
                
                let action = self.asteroidGenerator.produceSeqActionToAsteroid(regAster)
                regAster.runAction(action)
            }
        }
    }
    
    //MARK: Touch system
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        /* Called when a touch begins */
        self.moving = false
        
        if self.canCutRope(touches) {
            self.startPoint = (touches.first as! UITouch).locationInNode(self)
        }
        
    }
    
    override  func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
        
        if self.canCutRope(touches) {
            
            if let touch = touches.first as? UITouch {
            
                let position = touch.locationInNode(self)
                self.createSparks(position)
                
                self.moving = true
            }
        }
    }
    
    
    func needToIgnore(location:CGPoint) ->Bool {
        
        let date = self.lastProjectileExp.date
        
        if NSDate.timeIntervalSinceReferenceDate() - date <= 1 {
           
           let diff1 = location - self.player.position
           let diff2 = self.lastProjectileExp.position - self.player.position
            
            if (diff1.length() == 0 || diff2.length() == 0) {
                return false
            }
            
            let v1 = CGVector(dx: diff1.x, dy: diff1.y)
            let v2 = CGVector(dx: diff2.x, dy: diff2.y)
            let len1 = v1.length()
            let len2 = v2.length()
            
            let cosAngle = (v1.dx*v2.dx+v1.dy*v2.dy)/(len1*len2)
            
           return cosAngle >= 0 && cosAngle < 1
        }
        return false
    }
    
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        
        //MARK: eee Test is here...
        /*self.hudNode.decreaseLife()
        
        if (self.hudNode.isDead()) {
            
            self.gameSceneDelegate?.gameScenePlayerDied(self)
            
            return
        }*/
        
        if self.canCutRope(touches) &&  self.moving {
            
            let touch = touches.first as! UITouch
            let location = touch.locationInNode(self)
            self.endPoint = location
            
            if (!CGPointEqualToPoint(self.startPoint, self.endPoint)){
                
                if let  body = self.physicsWorld.bodyAlongRayStart(self.startPoint, end: self.endPoint) {
                    
                    if body.categoryBitMask == EntityCategory.Rope {
                        
                        if !body.joints.isEmpty {
                            
                            for var i = 0; i < body.joints.endIndex;i++ {
                                let joint: AnyObject = body.joints[i]
                                
                                let skJoint = unsafeBitCast(joint, SKPhysicsJoint.self)
                                
                                physicsWorld.removeJoint(skJoint)
                            }
                           
                            if let bNode = body.node {
                                
                                let bNodeParent = bNode.parent!
                                
                                let position = bNodeParent.convertPoint(bNode.position, toNode: self.scene!)
                                
                                bNode.removeFromParent()
                            
                                bNodeParent.runAction(SKAction.sequence([SKAction.waitForDuration(1.5),SKAction.fadeOutWithDuration(0.5),SKAction.runBlock({ () -> Void in
                                    self.displayScoreAdditionLabel(position, scoreAddition: 20)
                                })]))
                                
                                self.enableCuttingRope = false
                                
                            }
                            
                            
                        }
                        
                    }
                }
            }
            
            self.moving = false
            return
        }
        
        for touch: AnyObject in touches {
            let location = touch.locationInNode(self)
            
            if (self.player.canThrowProjectile()) {
                self.player.throwProjectileToLocation(location)
            } else if (self.player.parent == self.player.scene) {
                if (!self.needToIgnore(location)) {
                    self.player.moveToPoint(location)
                }
            } else  if (self.player.parent!.isKindOfClass(RegularAsteroid)) {
                
                
                
                self.physicsWorld.enumerateBodiesAtPoint(location, usingBlock: { (body, pointer) -> Void in
                    
                    if let regAster = body.node as? RegularAsteroid {

                            if regAster == self.player.parent! {
                                
                                if (regAster.tryToDestroyWithForce(self.player.punchForce)) {
                                    
                                    
                                    self.didMoveOutAsteroidForGenerator(self.asteroidGenerator, asteroid: regAster, withType: .Regular)
                                    
                                    var scale:CGFloat
                                    
                                    switch (regAster.asteroidSize){
                                    case .Big:
                                        scale = 4.0
                                        break;
                                    case .Medium:
                                        scale = 2.0
                                        break;
                                    case .Small:
                                        scale = 1.0
                                        break;
                                    default:
                                        scale = 1.0
                                        break;
                                    }
                                    
                                    //MARK: Continue here, create crystal, with score addition.
                                    
                                    self.createRocksExplosion(location,scale:scale)
                                }
                                self.shakeCamera(0.8)
                            
                            pointer.memory = true
                        }
                    }
                })

                
                
            }
        }
    }

    override func touchesCancelled(touches: Set<NSObject>!, withEvent event: UIEvent!) {
        self.moving = false
    }
    
    func createSparks(point:CGPoint) {
        
        let particlePath = NSBundle.mainBundle().pathForResource("Sparky", ofType:"sks")
        var sparky = NSKeyedUnarchiver.unarchiveObjectWithFile(particlePath!) as! SKNode
        
        sparky.position = point
        sparky.name = "PARTICLE"
        addChild(sparky)
    }
    
    func createRocksExplosion(point:CGPoint,scale:CGFloat) {
        
        let  emitter = SKEmitterNode(fileNamed: "Explosion")
        emitter!.zPosition = self.fgZPosition
        emitter!.position = point
        emitter!.targetNode = self
        emitter.particleScale = scale
        addChild(emitter!)
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
    
    func returnPlayerToScene(sprite:SKNode) -> Bool {
        
        if let playerParent = self.player.parent {
            
            if playerParent == sprite {
                playerParent.physicsBody!.categoryBitMask = EntityCategory.RegularAsteroid
                
                self.player.position  = convertNodePosition(self.player, toScene: self)
                
                self.removePlayerFromRegularAsteroidToScene()
                return true
            }
        }
        return false
    }
    
    func removePlayerFromRegularAsteroidToScene() {
        if let regularAsteroid = self.player.parent as? RegularAsteroid {
            self.player.anchorPoint = CGPointMake(0.5, 0.5)
            self.player.physicsBody!.contactTestBitMask != EntityCategory.Player
            self.player.zRotation = 0
            self.player.zPosition--
            
            if (self.player.position.x <= CGRectGetMinX(self.playableArea) ) {
                self.player.position.x = CGFloat(self.player.size.width*0.5)
            }
            
            if (self.player.position.y <= CGRectGetMinY(self.playableArea) ){
                self.player.position.y = CGFloat(self.player.size.height*0.5)
            }
            
            self.player.removeFromParent()
            regularAsteroid.removeFromParent()
            addChild(self.player)
        }
    }
    
    //MARK: Asteroid Generator's delegate methods
    func didMoveOutAsteroidForGenerator(generator: AsteroidGenerator, asteroid: SKNode, withType type: AsteroidType) {
        
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
        case .RopeBased:
            self.enableCuttingRope = false
            fallthrough
        case .Regular:
            returnPlayerToScene(asteroid)
            fallthrough
        case .Bomb:
            generator.paused = false
            break
        default:
            break
        }
    }
    
    func asteroidGenerator(generator: AsteroidGenerator, didProduceAsteroids: [SKNode], type: AsteroidType) {
        
        for node in didProduceAsteroids {
            node.zPosition = self.fgZPosition
            addChild(node)
            
            //assert(CGRectGetHeight(self.playableArea) > CGRectGetHeight(node.frame) && CGRectGetHeight(node.frame) > CGRectGetMinY(self.playableArea), "Doesn't contain frame!")
        }
        generator.paused = true
        
        
        switch (type) {
        case .Trash:
            self.player.removeAllActions()
            self.player.disableEngine()
            self.trashAsteroidsCount += didProduceAsteroids.count
            
            println("Trash asteroids count \(self.trashAsteroidsCount) addition" )
            Explosion.prepare()
            self.player.enableProjectileGun()
            
            //eee Move up if there is a contact...
            break;
        case .Bomb:
            break
        case .Regular:
            self.player.disableProjectileGun()
            break
        case .RopeBased:
            if let asteroids = didProduceAsteroids.last as? RopeJointAsteroids {
                asteroids.prepare()
                self.enableCuttingRope = true
            }
            break
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
            
            
            let angel2 =  normal.angle
            
            //self.player.anchorPoint = CGPointZero
            
            println("Player's z (before) rotation \(angle.degree), Angle \(angel2.degree)")
            let delta = shortestAngleBetween(angle, angel2)
            self.player.zRotation += delta
            
            println("Player's z (after) rotation \(self.player.zRotation.degree)")
            
            self.player.zPosition += 1
            
            let pointInternal = pNode.convertPoint(contact.contactPoint, fromNode: pNode.scene!)
            
            self.player.position = pointInternal
            
            println("placing player at position \(pointInternal)")
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
            
            if 0 == self.trashAsteroidsCount {

                let timeInterval = NSDate.timeIntervalSinceReferenceDate()
                self.lastProjectileExp = (timeInterval,scenePoint)
            }
        }
        
        
        trashAster!.node?.removeFromParent()
        laser?.node?.removeFromParent()
    }
    
    func createExplosion(explosionType:ExplosionType, position:CGPoint, withScore scoreAddition:CGFloat) {
        
        switch explosionType {
        case .Small:
            var explosion = Explosion.getExplostionForType(.Small)
            explosion.position = position
            explosion.zPosition = self.fgZPosition
            
            addChild(explosion)
            
            break;
        case .Large:
            var explosion = Explosion.getExplostionForType(.Large)
            explosion.zPosition = self.fgZPosition
            explosion.position = position
            
            addChild(explosion)
            
            if (scoreAddition == 0) {
                return
            }
            
            displayScoreAdditionLabel(position,scoreAddition: scoreAddition)
            
            //TODO: add score here....
            break;
        }
        
    }
    
    func displayScoreAdditionLabel(position:CGPoint,scoreAddition:CGFloat) {
        scoreLabel.alpha = 1.0
        scoreLabel.text = "+\(scoreAddition)"
        scoreLabel.fontSize = 30.0
        scoreLabel.fontColor = SKColor.greenColor()
        scoreLabel.horizontalAlignmentMode = .Center
        scoreLabel.position = position
        
        var yDiff:CGFloat = 0.0
        if (30 + position.y > CGRectGetMaxY(self.playableArea)) {
            yDiff = -30
        }
        else {
            yDiff = 30
        }
        
        scoreLabel.runAction(SKAction.sequence([
            SKAction.moveByX(0, y: yDiff, duration: 1.0),
            SKAction.fadeOutWithDuration(1.0),
            SKAction.removeFromParent()
            ]))
        
        if (scoreLabel.parent == nil) {
            addChild(scoreLabel)
        }
    }
    
    //MARK: Processing events 
    
    func analogControlPositionChanged(analogControl: AnalogControl,
        position: CGPoint)  {
            
            
            self.player.physicsBody!.velocity = CGVector(
                dx: position.x * CGFloat(self.player.flyDurationSpeed),
                dy: -position.y * CGFloat(self.player.flyDurationSpeed))
            
            
            
            
    }
}
 