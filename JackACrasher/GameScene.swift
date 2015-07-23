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
    func gameScenePlayerDied(scene:GameScene,totalScore:UInt64,currentScore:Int64,playedTime:NSTimeInterval,needToContinue:Bool)
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

class GameScene: SKScene, AsteroidGeneratorDelegate,EnemiesGeneratorDelegate, SKPhysicsContactDelegate {
    
    var asteroidManager:AsteroidManager!
    var asteroidGenerator:AsteroidGenerator!
    var enemyGenerator:EnemiesGenerator!
    
    weak var gameSceneDelegate:GameSceneDelegate?
    var prevPlayerPosition:CGPoint = CGPointZero
    
     var currentGameScore:Int64 = 0
    private var totalGameScore:UInt64 = 0 {
        didSet {
           self.setTotalScoreLabelValue()
        }
    }

    
    private var needToReflect:Bool = false
    
    let asterName:String! = "TestAster"
    let bgStarsName:String! = "bgStars"
    let bgZPosition:CGFloat = 1
    let fgZPosition:CGFloat = 5
    
    private var lastProjectileExp:(date:NSTimeInterval,position:CGPoint) = (0,CGPointZero)
    private var lifeWidth:CGFloat = 0
    private var  hudNode:HUDNode!
    
    var trashAsteroidsCount:Int = 0
    private var player:Player!
    
    var healthRatio:Float {
        get { return Float(self.player.health % 100) }
    }
    
    private var enableCuttingRope:Bool = false
    private var startPoint:CGPoint = CGPointZero
    private var movedPoint:CGPoint = CGPointZero
    private var endPoint:CGPoint = CGPointZero
    private var moving:Bool = false
    
    private let scoreLabel = SKLabelNode(fontNamed: "gamerobot")
    
    private var playableArea:CGRect = CGRectZero
    private var gameScoreNode:ScoreNode!
    
    private var startPlayTime:NSTimeInterval = 0
    var playedTime:NSTimeInterval = 0
    
    private static var sProjectileEmitter:SKEmitterNode!
    
    internal class func loadAssets() {
    
        let projectileEmitter = SKEmitterNode(fileNamed: "ProjectileSplat")
        projectileEmitter.name = "ProjectileSplat"
        GameScene.sProjectileEmitter = projectileEmitter
        
        //TODO: Move into loadAssets  methods
        Player.loadAssets()
        RegularAsteroids.loadAssets()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        
        self.physicsWorld.gravity = CGVectorMake(0.0, 0.0)
        self.physicsWorld.contactDelegate = self
        
        self.asteroidManager = AsteroidManager(scene: self)
        
    }
    
    internal func setTotalScore(totalScore:UInt64) {
        self.totalGameScore = totalScore + UInt64(self.currentGameScore);
    }
    
    internal func updatePlayerLives(extraLives numberOfLives:Int) {
        
        self.hudNode.life = numberOfLives
        self.player.updateNumberOfLives(extraLives: numberOfLives)
    }
    
    internal func pauseGame(pause:Bool = true) {
        if (!pause) {
            self.startPlayTime = NSDate.timeIntervalSinceReferenceDate()
            SoundManager.sharedInstance.playBGMusic()
            self.paused = false
        }
        else {
            let diff = NSDate.timeIntervalSinceReferenceDate() - self.startPlayTime
            self.playedTime += diff
            
            self.startPlayTime = 0
            SoundManager.sharedInstance.pauseBGMusic()
            self.paused = true
        }
    }
    
    
    
    internal func defineHUD(height:CGFloat,alpha:CGFloat) {
        
        if (childNodeWithName("HUD") != nil) {
            return
        }
    
        let inSize = CGSizeMake(CGFloat(round(self.playableArea.size.width/6.0)), height)
        println("IN size \(inSize)")
        
        
        let hudNode = HUDNode(inSize: inSize)
        hudNode.life = HUDNode.sLifeOne
        hudNode.name = "HUD"
        hudNode.position = CGPointMake(CGRectGetWidth(self.playableArea) - inSize.width - 10, CGRectGetMaxY(self.playableArea) /*+ CGRectGetMinY(self.playableArea)*/ - inSize.height)
        hudNode.alpha = alpha
        hudNode.zPosition = self.fgZPosition + 1
        addChild(hudNode)
        self.hudNode = hudNode
        println("HUD node position \(hudNode.position)")
        
        
        GameLogicManager.sharedInstance.accessSurvivalGameScores{
            [unowned self]
            info in
            
            if let gameInfo = info {
                
                dispatch_async(dispatch_get_main_queue()) {
                    [unowned self] in
                    
                    self.playedTime += gameInfo.playedTime
                    self.currentGameScore += gameInfo.currentScore
                    
                    self.setTotalScore(self.totalGameScore)
                    self.updatePlayerLives(extraLives: gameInfo.numberOfLives)
                    self.hudNode.setLifePercentUsingRatio(gameInfo.ratio)
                    
                }
            }
        }
        
    }
    
    
    func definePlayableRect() {
        
        assert(self.scaleMode == .AspectFill, "Not aspect fill mode")
        
        if let presentView = self.view {
            
            
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
    
    func createEnemiesGenerator() {
        self.enemyGenerator = EnemiesGenerator(playableRect: self.playableArea, andDelegate: self)
        self.enemyGenerator.start()
    }
    
    func findNewInitialPositionForPlayer() -> CGPoint {
        
        var position =  self.playableArea.center
        
        for node in self.nodesAtPoint(position) {
            
            if node.categoryBitMask == EntityCategory.BlackHole {
                let blackHole = node as! BlackHole
                
                let size = blackHole.size
                
                let blackHoleRect = size.rectAtPoint(blackHole.position)
                
                var playerRect = Player.backgroundPlayerSprite.size.rectAtPoint(position)
                
                if CGRectIntersectsRect(playerRect, blackHoleRect) {
                    let intersect = CGRectIntersection(playerRect, blackHoleRect)
                    
                    let pOX = CGRectGetMinX(playerRect)
                    let pOY = CGRectGetMinY(playerRect)
                    
                    let hOX = CGRectGetMinX(blackHoleRect)
                    let hOY = CGRectGetMinY(blackHoleRect)
                    
                    var dx:CGFloat = intersect.width
                    var dy:CGFloat = intersect.height
                    
                    if (pOX < hOX) {
                        dx *= -1
                    }
                    
                    if (pOY < hOY) {
                        dy *= -1
                    }
                    
                    playerRect = CGRectOffset(playerRect, dx, dy)
                    position = playerRect.center
                
                }
                break
            }
        }
        return position
    }
    
    func createPlayer() {
        let player = Player(position: self.findNewInitialPositionForPlayer())
        player.alpha = 0.0
        self.prevPlayerPosition = player.position
        
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
        //MARK: ee Why fade in stopped working...
        player.alpha = 1.0
        println("Z rotation \(self.player.zRotation)")
        self.player.hidden = false
    }

    
    override func didMoveToView(view: SKView) {
        SoundManager.sharedInstance.prepareToPlayBGMusic()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "willTerminateApp", name: UIApplicationWillTerminateNotification, object: UIApplication.sharedApplication())
        
        self.startPlayTime = NSDate.timeIntervalSinceReferenceDate()
        SoundManager.sharedInstance.playBGMusic()
        self.playedTime = 0
        
        self.definePlayableRect()
        
        self.defineHUD(30, alpha: 0.7)
        self.fillInBackgroundLayer()
        self.createPlayer()
        self.createAsteroidGenerator()
        self.createEnemiesGenerator()
        
        self.gameScoreNode = ScoreNode(point: CGPointMake(CGRectGetMinX(self.playableArea) + 40, CGRectGetMaxY(self.playableArea) - 30 ), score: self.totalGameScore)
        self.gameScoreNode.zPosition = self.fgZPosition
        addChild(self.gameScoreNode)
        
        self.setTotalScoreLabelValue()
        
    }
    
    func willTerminateApp() {
        terminateGame(needToContinue:false)
    }
    
    private func terminateGame(needToContinue:Bool = true) {
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillTerminateNotification, object: UIApplication.sharedApplication())
        
        let playedTime = self.calculateGameTime()
        assert(self.totalGameScore >= UInt64(self.currentGameScore))
        
        self.gameSceneDelegate?.gameScenePlayerDied(self,totalScore: self.totalGameScore,currentScore: self.currentGameScore, playedTime: playedTime, needToContinue: needToContinue)
    }
    
    private func setTotalScoreLabelValue() {
        self.gameScoreNode?.setScore(self.totalGameScore)
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
        let touch = (touches.first as! UITouch)
        let point = touch.locationInNode(self)
        
        if self.canCutRope(touches) {
            self.startPoint = point
        }
    }
    
    override  func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
        
        if self.canCutRope(touches) {
            
            if let touch = touches.first as? UITouch {
            
                let position = touch.locationInNode(self)
                let prevPosition = touch.previousLocationInNode(self)
                
                if (touchIntersectAsteroid(touch)){
                    let emitterNode = self.createSparks(position, needToRemove:false)
                    self.moving = false
                    
                    
                    let p = (prevPosition - position).normalized()
                    
                    let pBody = SKPhysicsBody(rectangleOfSize: emitterNode.particleTexture!.size())
                    emitterNode.physicsBody = pBody
                    
                    emitterNode.physicsBody!.applyImpulse(CGVectorMake(p.x * 100, -p.y * 100), atPoint: position)
                    emitterNode.physicsBody!.contactTestBitMask = 0
                    emitterNode.physicsBody!.categoryBitMask = 0
                    
                    let particleTime1 = 2 * NSTimeInterval(emitterNode.particleLifetime + emitterNode.particleLifetimeRange)
                    emitterNode.runAction(SKAction.sequence([SKAction.group([SKAction.waitForDuration(particleTime1),SKAction.scaleTo(0.5, duration: particleTime1)]),SKAction.removeFromParent()]))
                    
                    addChild(emitterNode)
                    
                }
                else {
                    self.createSparks(position)
                    self.moving = true
                }
            }
        }
    }
    
    override func touchesCancelled(touches: Set<NSObject>!, withEvent event: UIEvent!) {
        self.moving = false
        self.needToReflect = false
    }
    
    private func touchIntersectAsteroid(touch:UITouch) -> Bool  {
        
        if (self.needToReflect) {
            return false
        }
        
        let point = touch.locationInNode(self)
        let prevPoint = touch.previousLocationInNode(self)
        
        for curNode in self.scene!.nodesAtPoint(point) as! [SKNode] {
            
            if (curNode is RegularAsteroid ||
                curNode is SmallRegularAsteroid) {
                
                self.needToReflect = true
                
                return true
            }
        }
        return false
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
    
    
    private func tryToDestroyPlayer(damageForce:ForceType) -> Bool {
        
        let prevNumberOfLives = self.hudNode.life
        
        self.hudNode.reduceCurrentLifePercent(forceType: damageForce)
        let curNumberOfLives = self.hudNode.life
        
        let destroyed = self.player.tryToDestroyWithForce(damageForce)
        println("!!! Destroyed \(destroyed) prevNumberOfLives \(prevNumberOfLives) curNumberOfLives \(curNumberOfLives)")
        if (prevNumberOfLives != curNumberOfLives) {
            
            let info = SurvivalGameInfo()
            info.numberOfLives = destroyed ? 0 :curNumberOfLives
            info.ratio = destroyed ? 0 : self.healthRatio
            info.currentScore = self.currentGameScore
            info.playedTime = self.playedTime
            
            GameLogicManager.sharedInstance.updateCurrentSurvivalGameInfo(info) {
                updated in
                println("UPdated \(updated)")
            }
        }
    
        return destroyed
    }
    
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        
        if (self.needToReflect) {
            self.needToReflect = false
            return
        }
        
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
        
        let isPlayerVisible = !self.player.hidden
        
        for touch: AnyObject in touches {
            let location = touch.locationInNode(self)
            
            //MARK: HACK life decrease....
            
            if (isPlayerVisible && self.player.containsPoint(location)) {
                
                let damageForce = ForceType(10)
                
                if self.tryToDestroyPlayer(damageForce) {
                    
                    terminateGame()
                    return
                }
            }
            
            
            if (isPlayerVisible && self.player.canThrowProjectile()) {
                self.player.throwProjectileToLocation(location)
            } else if (isPlayerVisible && self.player.parent == self.player.scene) {
                if (!self.needToIgnore(location)) {
                    self.prevPlayerPosition = self.player.position
                    self.player.moveToPoint(location)
                }
            } else  if (!isPlayerVisible) {
                
                self.physicsWorld.enumerateBodiesAtPoint(location, usingBlock: { (body, pointer) -> Void in
                    
                    if let regAster = body.node as? RegularAsteroid {

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
                                    
                                    self.displayScoreAdditionLabel(location, scoreAddition: 20)
                                }
                                else {
                                    self.shakeCamera(regAster, duration: 0.8)
                                }
                            pointer.memory = true
                        }
                })
            }
        }
    }
    
    private func calculateGameTime() -> NSTimeInterval {
        
        if (self.startPlayTime != 0) {
            let spentTime = NSDate.timeIntervalSinceReferenceDate() - self.startPlayTime
            
            return spentTime + self.playedTime
        }
        
        return self.playedTime
    }
    
    func createSparks(point:CGPoint, needToRemove:Bool = true) -> SKEmitterNode {
        let emitter = SKEmitterNode(fileNamed: "Sparky")
        emitter.position = point
        emitter.name = "PARTICLE"
        
        if (needToRemove) {
            let particleTime = NSTimeInterval(emitter.particleLifetime + emitter.particleLifetimeRange)
            emitter.runAction(SKAction.sequence([SKAction.waitForDuration(particleTime),SKAction.removeFromParent()]))
            
            addChild(emitter)
        }
        
        return emitter
    }
    
    func createRocksExplosion(point:CGPoint,scale:CGFloat) {
        
        let  emitter = SKEmitterNode(fileNamed: "Explosion")
        emitter!.zPosition = self.fgZPosition
        emitter!.position = point
        emitter!.targetNode = self
        emitter.particleScale = scale
        addChild(emitter!)
    }
    
    
    func shakeCamera(fakePlayerParent:RegularAsteroid, duration:NSTimeInterval) {
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
        fakePlayerParent.runAction(actionSeq);
    }
   
    override func update(currentTime: CFTimeInterval) {
    }
    
    func returnPlayerToScene(sprite:SKNode) -> Bool {
        
        if self.player.hidden {
            
            self.player.position  = convertNodePosition(sprite, toScene: self)
            self.removePlayerFromRegularAsteroidToScene()
            sprite.removeFromParent()
            
            return true
        }
        return false
    }
    
    func removePlayerFromRegularAsteroidToScene() {
        self.player.physicsBody!.contactTestBitMask &= ~EntityCategory.Player
        self.player.zRotation = 0
        self.player.zPosition = self.fgZPosition
            
        if (self.player.position.x <= CGRectGetMinX(self.playableArea) ) {
            self.player.position.x = CGFloat(self.player.size.width*0.5)
        }
            
        if (self.player.position.y <= CGRectGetMinY(self.playableArea) ){
            self.player.position.y = CGFloat(self.player.size.height*0.5)
        }
        
        if (self.player.position.y >= CGRectGetHeight(self.playableArea)) {
            self.player.position.y = CGRectGetHeight(self.playableArea) - CGFloat(self.player.size.height*0.5)
        }
        
        if (self.player.position.x >= CGRectGetWidth(self.playableArea)) {
            self.player.position.x = CGRectGetWidth(self.playableArea) - CGFloat(self.player.size.width*0.5)
        }
        
        self.player.hidden = false
        
        let delayTime = dispatch_time(DISPATCH_TIME_NOW,
            Int64(2 * Double(NSEC_PER_SEC)))
        
        dispatch_after(delayTime, dispatch_get_main_queue()){
            [unowned self] in
            if (self.view != nil) {
                self.player?.enableGravityReceptivity()
            }
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
                self.enemyGenerator.paused = false
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
            
            println("Asteroid position \(node.position)")
            println("Scene size \(self.size)")
        }
        generator.paused = true
        
        
        switch (type) {
        case .Trash:
            self.enemyGenerator.paused = true
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
    
    func emulateImpulse(forAsteroid asteroid:RegularAsteroid!,direction:CGVector)  {
        
        let vector = vectorFromPoint(asteroid.position, usingDirection: direction, inRect: self.playableArea)
        
        let speed = 1.5 * AsteroidGenerator.regularAsteroidSpeed
        
        let duration = NSTimeInterval(vector.length()/speed)
        
        let moveToAction = SKAction.moveByX(vector.dx, y: vector.dy, duration: duration)
        
        let durMin = min(duration+0.2,2.0)
        
        let seg2 = SKAction.sequence([SKAction.waitForDuration(durMin),SKAction.runBlock({ () -> Void in
            if (asteroid.parent != nil && asteroid.physicsBody != nil) {
                asteroid.physicsBody!.categoryBitMask = EntityCategory.RegularAsteroid
                asteroid.physicsBody!.contactTestBitMask = UInt32.max
                asteroid.physicsBody!.fieldBitMask = EntityCategory.BlakHoleField
                
            }
        })])
        
        let seg1 = SKAction.sequence([moveToAction,SKAction.removeFromParent()])
        
        let group = SKAction.group([seg1,seg2])
        
        asteroid.runAction(group)
    }
    
    //MARK: Enemies Generator's methods
    func enemiesGenerator(generator: EnemiesGenerator, didProduceItems: [SKNode!], type: EnemyType) {
        
        for node in didProduceItems {
            node.zPosition = self.bgZPosition + 1
            addChild(node)
            
            generator.signalItemAppearance(node, type: type)
            //assert(CGRectGetHeight(self.playableArea) > CGRectGetHeight(node.frame) && CGRectGetHeight(node.frame) > CGRectGetMinY(self.playableArea), "Doesn't contain frame!")
            
            println("Enemy position \(node.position)")
            println("Scene size \(self.size)")
        }
        generator.paused = true
        
    }
    
    func didDissappearItemForEnemiesGenerator(generator: EnemiesGenerator, item: SKNode!, type: EnemyType) {
        generator.paused = false
        item.removeFromParent()
    }
    
    //MARK: Contact methods
    
    func playerContactingWithSmallRegulaAsteroid(regAsteroid:RegularAsteroid!,contact: SKPhysicsContact) -> Bool {
        
        if let asteroid = regAsteroid as? SmallRegularAsteroid {
            
            if (asteroid.isFiring) {
                
                let damageForce = asteroid.damageForce
                
                if (self.tryToDestroyPlayer(damageForce)) {
                    terminateGame()
                }
                else {
                    createRocksExplosion(asteroid.position, scale: 1.0)
                
                    asteroid.removeFromParent()
                }
                
                return true
            }
            
            asteroid.removeAllActions()
            asteroid.physicsBody!.categoryBitMask = 0
            asteroid.physicsBody!.contactTestBitMask = 0 //UInt32.max // contacts with all objects...
            asteroid.physicsBody!.fieldBitMask = EntityCategory.BlakHoleField
            var impulse = contact.contactNormal
            
            if (CGPointEqualToPoint(self.prevPlayerPosition, self.player.position)) {
                emulateImpulse(forAsteroid: asteroid, direction: impulse)
            } else {
                let posNormalized = (self.player.position - self.prevPlayerPosition)
                self.player.placeAtPoint(contact.contactPoint)
                emulateImpulse(forAsteroid: asteroid, direction: CGVector(dx: posNormalized.x, dy: posNormalized.y))
            }
            
            //asteroid.physicsBody!.applyImpulse(impulse, atPoint: contact.contactPoint)
        
            asteroid.startFiringAtDirection(impulse, point: self.convertPoint(contact.contactPoint, toNode: asteroid))
            
            
            self.didMoveOutAsteroidForGenerator(self.asteroidGenerator, asteroid: asteroid, withType: .Regular)
            
            return true
        }
        
        return false
    }
    
    
    func didSmallAsteroidCollidedWithRegulaOne(secondNode:SKNode?) -> Bool {
     
        if (!((secondNode is RegularAsteroid) || (secondNode is SmallRegularAsteroid))) {
            return false
        }
        
        let regAster = secondNode as! RegularAsteroid
        
            
            if (regAster.tryToDestroyWithForce(self.player.punchForce * 2)) {
                
                let location  = regAster.position
                
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
                
                self.displayScoreAdditionLabel(location, scoreAddition: 20)
            }
            else {
                self.shakeCamera(regAster, duration: 0.8)
            }
        
        return true
        
    }
    
    
    func didEntityContactWithRegularAsteroid(contact: SKPhysicsContact) -> Bool
    {
        let bodyA = contact.bodyA
        let bodyB = contact.bodyB
        
        var asteroidBody:SKPhysicsBody? = nil
        var entityBody:SKPhysicsBody? = nil
        
        if (bodyA.categoryBitMask == EntityCategory.RegularAsteroid) {
            asteroidBody = bodyA
            entityBody = bodyB
        } else if (bodyB.categoryBitMask == EntityCategory.RegularAsteroid) {
            asteroidBody = bodyB
            entityBody = bodyA
        }

        if let regularBody = asteroidBody  {
            
            let pNode = regularBody.node as! RegularAsteroid
            let secondNode = entityBody?.node
            
            if ((secondNode is Player) &&  playerContactingWithSmallRegulaAsteroid(pNode, contact :contact)) {
                return true
            } else if (pNode is SmallRegularAsteroid) {
                let smallAster = pNode as! SmallRegularAsteroid
                
                createRocksExplosion(smallAster.position, scale: 2)
                displayScoreAdditionLabel(smallAster.position, scoreAddition: 10)
                
                smallAster.removeFromParent()
                
                if (didSmallAsteroidCollidedWithRegulaOne(secondNode)) {
                    return true
                }
                
                //TODO: if second item is not regular asteroid - recalculate....
                return true
            }
            
            //TODO: consider player here... Not a player is bad!!!
            var normal = contact.contactNormal
            //normal.dx *= CGFloat(-1.0)
            //normal.dy *= CGFloat(-1.0)
            
            println("Normal dx \(normal.dx),Normal dyØ \(normal.dy) . Angle \(normal.angle)")
            
            /*let arrow = SKSpriteNode(imageNamed: "debug_arrow")
            arrow.zRotation = π/2 -  normal.angle
            arrow.zPosition = self.player.zPosition
            let curNode = regularBody.node!
            let nPoint = curNode.convertPoint(contact.contactPoint, fromNode: self)
            arrow.position = nPoint
            curNode.addChild(arrow)*/
            //regularBody.node?.removeAllActions()
            
            let playerNode:SKSpriteNode! = SKSpriteNode(imageNamed: "player")
            
            let angle = self.player.zRotation
            playerNode.zRotation = angle
            
            let angel2 =  3*π/2 - normal.angle
        
            
            println("Player's z (before) rotation \(angle.degree), Angle \(angel2.degree)")
            //let delta = shortestAngleBetween(angle, angel2)
            playerNode.zRotation = angel2 //+= delta
            
            println("Player's z (after) rotation \(playerNode.zRotation.degree)")
            
            let pointInternal = self.convertPoint(contact.contactPoint, toNode: pNode)
            
            playerNode.position = pointInternal
            
            println("placing player at position \(pointInternal)")
            self.player.disableGravityReceptivity()
            self.player.hidden = true
            
            regularBody.contactTestBitMask &= ~EntityCategory.Player
            regularBody.categoryBitMask = 0
            
            if let bNode = regularBody.node as? RegularAsteroid {
                bNode.removeField()
            }
            
            pNode.addChild(playerNode)
            
            Player.displayHammerForSprite(playerNode)
            
            return true
        }
        
        return false
    }
    
    func didContachHasBlackHole(contact:SKPhysicsContact) -> Bool
    {
        let bodyA = contact.bodyA
        let bodyB = contact.bodyB
        
        var blackHoleNode:BlackHole!
        var secondNode:SKNode!
        
        if (bodyA.categoryBitMask == EntityCategory.BlackHole) {
            blackHoleNode = bodyA.node as? BlackHole
            secondNode = bodyB.node
        } else if (bodyB.categoryBitMask == EntityCategory.BlackHole) {
            blackHoleNode = bodyB.node as? BlackHole
            secondNode = bodyA.node
        } else {
            blackHoleNode = nil
            secondNode = nil
        }
        
        if (blackHoleNode == nil || secondNode == nil) {
            return false
        }
        
        secondNode.physicsBody!.contactTestBitMask &= ~EntityCategory.BlackHole
    
        
        //self.tryToDestroyDestructableItem(blackHoleNode, secondNode: secondNode)
        println("blackHoleNode")
        let durationToWait = blackHoleNode.moveItemToCenterOfField(secondNode)
        
        let delayTime = dispatch_time(DISPATCH_TIME_NOW,
            Int64(durationToWait * Double(NSEC_PER_SEC)))
        
        dispatch_after(delayTime, dispatch_get_main_queue()){
            [unowned self] in 
            self.tryToDestroyDestructableItem(blackHoleNode, secondNode: secondNode)
        }
        
        return true
    }
    
    private func tryToDestroyDestructableItem(blackHoleNode:BlackHole, secondNode:SKNode!) {
        
        if let destNode = secondNode as? ItemDestructable {
            let damage = blackHoleNode.damageForce
            if secondNode == self.player {
                
                if self.tryToDestroyPlayer(damage) {
                    self.terminateGame()
                }
                else {
                    self.player.removeFromParent()
                    self.createPlayer()
                }
                return
            }
            
            if destNode.tryToDestroyWithForce(damage) {
                
                secondNode.removeFromParent()
            }
        }
    }
    
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
        }
        
        if (didEntityContactWithRegularAsteroid(contact) || didContachHasBlackHole(contact)) {
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
            
            trashAster!.node?.removeFromParent()
            laser?.node?.removeAllActions()
            
            if 0 == self.trashAsteroidsCount {
                createExplosion(expType, position: scenePoint,withScore: 10)

                let timeInterval = NSDate.timeIntervalSinceReferenceDate()
                self.lastProjectileExp = (timeInterval,scenePoint)
            }
            else {
                createExplosion(expType, position: scenePoint)
                
                if let lNode = laser?.node  {
                    
                    let emitterNode =  GameScene.sProjectileEmitter.copy() as! SKEmitterNode
                    emitterNode.position = lNode.position
                    addChild(emitterNode)
                    emitterNode.zPosition = self.fgZPosition + 1
                    
                    runOneShortEmitter(emitterNode, 0.15)
                }
            }
            laser?.node?.removeFromParent()
        }
        
        
        
    }
    
    func createExplosion(explosionType:ExplosionType, position:CGPoint, withScore scoreAddition:Int64 = 0) {
        
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
            
            break;
        }
        
    }
    
    func displayScoreAdditionLabel(position:CGPoint,scoreAddition:Int64) {
        scoreLabel.alpha = 1.0
        scoreLabel.text = (scoreAddition > 0) ? "+\(scoreAddition)" : "-\(scoreAddition)"
        scoreLabel.fontSize = 30.0
        scoreLabel.fontColor = SKColor.greenColor()
        scoreLabel.horizontalAlignmentMode = .Center
        scoreLabel.position = position
        
        self.currentGameScore += scoreAddition
        self.totalGameScore += UInt64(scoreAddition)
        
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
}
 