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
    
    func gameSceneHasScore(scene:GameScene, totalScore:UInt64)
}

@objc protocol GameScoreItem
{
    var currentGameScore:Int64 {get set}
    var totalGameScore:UInt64 {get set}
}

class GameScene: SKScene, AsteroidGeneratorDelegate,EnemiesGeneratorDelegate, SKPhysicsContactDelegate,AssetsContainer,GameScoreItem {
    
    var asteroidManager:AsteroidManager!
    var asteroidGenerator:AsteroidGenerator!
    var enemyGenerator:EnemiesGenerator!
    
    weak var gameSceneDelegate:GameSceneDelegate?
    private var prevPlayerPosition:CGPoint = CGPointZero
    private var lastUpdateTimeInterval:CFTimeInterval
    
    private var blades:[SWBlade]! = []
    
    private var delta = CGPointZero
    
    private var ropeBasedArray = [RopeJointAsteroids]()
    
    var currentGameScore:Int64 = 0
    var totalGameScore:UInt64 = 0 {
        didSet {
           self.setTotalScoreLabelValue()
            self.gameSceneDelegate?.gameSceneHasScore(self, totalScore: self.totalGameScore)
        }
    }
    
    private struct Constants {
        static let LeftEdge  = "leftEdge"
        static let RightEdge = "rightEdge"
    }
    
    private var bombs = [Bomb]()
    private var enemiesShips = [EnemySpaceShip]()
    
    let asterName:String! = "TestAster"
    let bgStarsName:String! = "bgStars"
    let bgZPosition:CGFloat = 1
    let fgZPosition:CGFloat = 5
    
    private var lastProjectileExp:(date:NSTimeInterval,position:CGPoint) = (0,CGPointZero)
    private var lifeWidth:CGFloat = 0
    private var  hudNode:HUDNode!
    
    var trashAsteroidsCount:Int = 0
    private  var player:Player!
    
    var healthRatio:Float {
        get { return Float(self.player.health % 100) }
    }
    
    private var startPoint:CGPoint = CGPointZero
    private var movedPoint:CGPoint = CGPointZero
    private var endPoint:CGPoint = CGPointZero
    private var removedBlade:Bool = false
    
    private var playableArea:CGRect = CGRectZero
    private var gameScoreNode:ScoreNode!
    
    private var startPlayTime:NSTimeInterval = 0
    var playedTime:NSTimeInterval = 0
    
    private static var sProjectileEmitter:SKEmitterNode!
    
    internal static func loadAssets() {
    
        let projectileEmitter = SKEmitterNode(fileNamed: "ProjectileSplat")!
        projectileEmitter.name = "ProjectileSplat"
        GameScene.sProjectileEmitter = projectileEmitter
        
        //TODO: Move into loadAssets  methods
        SWBlade.loadAssets()
        Player.loadAssets()
        RegularAsteroids.loadAssets()
        Explosion.loadAssets()
        BlackHole.loadAssets()
        Bomb.loadAssets()
        Transmitter.loadAssets()
        KamikadzeSpaceShip.loadAssets()
    }
    
    override init(size:CGSize) {
        self.lastUpdateTimeInterval = 0
        super.init(size: size)
        initPrivate()
    }
    
    
    private func initPrivate() {
        self.physicsWorld.gravity = CGVectorMake(0.0, 0.0)
        self.physicsWorld.contactDelegate = self
        self.backgroundColor = UIColor.lightGrayColor()
        self.asteroidManager = AsteroidManager(scene: self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
            
            self.asteroidGenerator.start()
            self.enemyGenerator.start()
        }
        else {
            let diff = NSDate.timeIntervalSinceReferenceDate() - self.startPlayTime
            self.playedTime += diff
            
            self.asteroidGenerator.stop()
            self.enemyGenerator.stop()
            
            self.startPlayTime = 0
            SoundManager.sharedInstance.pauseBGMusic()
            self.paused = true
        }
        
        /*if !self.enemiesShips.isEmpty {
            
            for enemyShip in self.enemiesShips {
                enemyShip.paused = self.paused
            }
        }
        
        if !self.bombs.isEmpty {
            
            for bomb in self.bombs {
                bomb.paused = self.paused
            }
        }
        
        self.childNodeWithName(Transmitter.NodeName)?.paused = self.paused*/
    }
    
    
    
    internal func defineHUD(height:CGFloat,alpha:CGFloat) {
        
        if (childNodeWithName("HUD") != nil) {
            return
        }
    
        let inSize = CGSizeMake(CGFloat(round(self.playableArea.size.width/4.0)), height)
        print("IN size \(inSize)")
        
        
        let hudNode = HUDNode(inSize: inSize)
        hudNode.name = "HUD"
        hudNode.position = CGPointMake(CGRectGetWidth(self.playableArea) - inSize.width - 10, CGRectGetMaxY(self.playableArea) /*+ CGRectGetMinY(self.playableArea)*/ - inSize.height)
        hudNode.alpha = alpha
        hudNode.zPosition = self.fgZPosition + 1
        addChild(hudNode)
        self.hudNode = hudNode
        print("HUD node position \(hudNode.position)")
        
        
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
        
        if let _ = self.view {
            playableArea = CGRect(x: 0, y: 0,
                width: size.width,
                height: size.height) // 4
            print("Area \(self.playableArea)")
        }
    }
    
    
    func fillInBackgroundLayer() {
        
        let emitterNode = SKEmitterNode(fileNamed: "BGStarts.sks")!
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
            
            if node.physicsBody?.categoryBitMask == EntityCategory.BlackHole {
                let blackHole = node as! BlackHole
                
                let size = blackHole.size
                
                let blackHoleRect = size.rectAtPoint(blackHole.position)
                
                var playerRect = self.player.size.rectAtPoint(position)
                
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
    
    private func storePrevPlayerPosition() {
        
        if self.player.parent != nil && self.player.scene != nil {
            self.prevPlayerPosition = convertNodePositionToScene(self.player)
        }
        else {
            
            let delayTime = dispatch_time(DISPATCH_TIME_NOW,
                Int64(0.1 * Double(NSEC_PER_SEC)))
            
            dispatch_after(delayTime, dispatch_get_main_queue()){
                [unowned self] in
                self.storePrevPlayerPosition()
            }
        }
    }
    
    func createPlayer(needSpark:Bool = true) {
        let player = Player(position: self.findNewInitialPositionForPlayer())
        player.alpha = 0.0
        player.zPosition = self.fgZPosition
        self.addChild(player)
        self.player = player
        
        storePrevPlayerPosition()
        
        if (needSpark) {
        let sparkEmitter = SKEmitterNode(fileNamed: "Spawn")!
            sparkEmitter.zPosition = player.zPosition
            sparkEmitter.position = player.position
            addChild(sparkEmitter)
            runOneShortEmitter(sparkEmitter, duration: 0.15)
            player.runAction(SKAction.fadeInWithDuration(2.0))
        }
        player.anchorPoint = CGPointMake(0.5, 0.5)
        
        //self.player.anchorPoint = CGPointZero
        //self.player.zRotation = CGFloat(140).radians
        //MARK: ee Why fade in stopped working...
        player.alpha = 1.0
        print("Z rotation \(self.player.zRotation)")
        self.player.hidden = false
        
        if let transmitter = self.childNodeWithName(Transmitter.NodeName) as? Transmitter {
            transmitter.transmitNode = self.player
        }
    }

    
    override func didMoveToView(view: SKView) {
        SoundManager.sharedInstance.prepareToPlayBGMusic()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "willTerminateApp", name: UIApplicationWillTerminateNotification, object: UIApplication.sharedApplication())
        
        self.startPlayTime = NSDate.timeIntervalSinceReferenceDate()
        SoundManager.sharedInstance.playBGMusic()
        self.playedTime = 0
        
        self.definePlayableRect()
        
        self.defineHUD(20, alpha: 0.7)
        self.fillInBackgroundLayer()
        self.createPlayer()
        self.createAsteroidGenerator()
        self.createEnemiesGenerator()
        self.createLeftBorderEdge()
        self.createRightBorderEdge()
        
        self.gameScoreNode = ScoreNode(point: CGPointMake(CGRectGetMinX(self.playableArea) + 40, CGRectGetMaxY(self.playableArea) - 30 ), score: self.totalGameScore)
        self.gameScoreNode.zPosition = self.fgZPosition
        addChild(self.gameScoreNode)
        
        self.setTotalScoreLabelValue()
        
        
        correctLabelText(self)
    }
    
    func createLeftBorderEdge() {
        
        let lEdge:SKNode = SKNode()
        let w1 = CGRectGetMinX(self.playableArea) - self.player.size.halfWidth()
        let p1 = CGPointMake(w1, 0)
        let p2 = CGPointMake(w1, CGRectGetHeight(self.playableArea))
        
        lEdge.name = Constants.LeftEdge
        lEdge.physicsBody = SKPhysicsBody(edgeFromPoint: p1, toPoint: p2)
        lEdge.physicsBody!.contactTestBitMask = EntityCategory.Player
        lEdge.physicsBody!.collisionBitMask = EntityCategory.Player
        lEdge.physicsBody!.categoryBitMask = EntityCategory.LeftEdgeBorder
        lEdge.physicsBody!.dynamic = false
        addChild(lEdge)
        
    }
    
    func createRightBorderEdge() {
        let edge:SKNode = SKNode()
        let w1 = CGRectGetWidth(self.playableArea) + min(10,self.player.size.halfWidth())
        let p1 = CGPointMake(w1, 0)
        let p2 = CGPointMake(w1, CGRectGetHeight(self.playableArea))
        
        edge.name = Constants.RightEdge
        edge.physicsBody = SKPhysicsBody(edgeFromPoint: p1, toPoint: p2)
        edge.physicsBody!.contactTestBitMask = EntityCategory.PlayerLaser
        edge.physicsBody!.collisionBitMask = 0
        edge.physicsBody!.categoryBitMask = EntityCategory.RightEdgeBorder
        edge.physicsBody!.dynamic = false
        
        addChild(edge)
    }
    
    func willTerminateApp() {
        if let sPlayer = self.player {
            var fractHealth = sPlayer.health % 100
            if fractHealth == 0  {
               fractHealth = ForceType(100)
            }
            if self.tryToDestroyPlayer(ForceType(fractHealth)) {
                terminateGame(false)
            }
        }
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
        return !(touches.count == 0 || self.ropeBasedArray.isEmpty)
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
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        /* Called when a touch begins */
        self.removedBlade = false
        let touch = touches.first!
        let point = touch.locationInNode(self)
        
        if self.canCutRope(touches) {
            self.startPoint = point
        }
        else {
            self.storePrevPlayerPosition()
        }
        
        print("touchesBegan. Can cut the rope \(self.canCutRope(touches))")
    }
    
    override  func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        print("touchesMoved. Can cut the rope \(self.canCutRope(touches))")
        
        areTouchesMovedForBlade(touches, withEvent: event)
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        
        print("touchesCancelled. Can cut the rope \(self.canCutRope(touches!))")
        removeBlade()
    
    }
    
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        
        if areTouchesEndedForBlade(touches, withEvent: event) {
            return
        }
        
        let isPlayerVisible = !self.player.isCaptured || (self.player.parent as? Transmitter) != nil
        
        print("touchesEnded. Can cut the rope \(self.canCutRope(touches))\n Is player visible \(isPlayerVisible)\n")
        
        
        for touch: AnyObject in touches {
            let location = touch.locationInNode(self)
            
            let transmitterObj = self.childNodeWithName(Transmitter.NodeName) as? Transmitter
            
            if (isPlayerVisible && self.player.canThrowProjectile() && (self.player.parent != self.player.scene || transmitterObj == nil || transmitterObj!.rayCapturingPlayer())) {
                self.player.throwProjectileToLocation(location)
            } else if (isPlayerVisible && self.player.parent == self.player.scene) {
                if (!self.needToIgnore(location)) {
                    
                    let transmitter = childNodeWithName(Transmitter.NodeName) as? Transmitter
                    if (transmitter == nil || transmitter!.userInteractionEnabled == false) {
                        self.player.moveToPoint(location)
                        self.storePrevPlayerPosition()
                    }
                }
            } else  if (!isPlayerVisible) {
                
                print("Is player visible \(isPlayerVisible)\n")
                
                    if let regAster = self.player.parent as? RegularAsteroid {
                        print("Reg asteroid ")
                        let regAsterPos = convertNodePositionUntilScene(regAster)
                        let rect = regAster.size.rectAtPoint(regAsterPos)
                        if CGRectContainsPoint(rect, location) {
                                if (regAster.tryToDestroyWithForce(self.player.punchForce)) {
                                    
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
                                    }
                                    
                                    //MARK: Continue here, create crystal, with score addition.
                                   self.rotatePlayer(location) {
                                        [unowned self] in
                                       
                                        let spritePos = self.player.position
                                        
                                        let diffVector = spritePos.normalized().toVector() * -0.5
                                        self.applyRotationOnNeedToRopeJointAsteroids(diffVector, node: regAster)
                                        
                                        self.createRocksExplosion(location,scale:scale)
                                        
                                        
                                        regAster.syDisplayScore(rect:self.playableArea, scoreAddition: 20)
                                        
                                        if (!self.checkNodeAndDestroyParentOnNeed(regAster, isRope: false)) {
                                            self.didMoveOutAsteroidForGenerator(self.asteroidGenerator, asteroid: regAster, withType: .Regular)
                                        } else {
                                            self.didMoveOutAsteroidForGenerator(self.asteroidGenerator, asteroid: regAster, withType: .RopeBased)
                                        }
                                        
                                    }
                                }
                                else {
                                     self.rotatePlayer(location){
                                        [unowned self] in
                                        self.shakeCamera(regAster, duration: 0.8)
                                    }
                                }
                        }
                }
            }
        }
        
        
        
        let delayTime = dispatch_time(DISPATCH_TIME_NOW,
            Int64(0.5 * Double(NSEC_PER_SEC)))
        
        dispatch_after(delayTime, dispatch_get_main_queue()){
            [unowned self] in
            self.storePrevPlayerPosition()
        }
    }
    
    private func rotatePlayer(location:CGPoint, runBlock:dispatch_block_t) {
        
        let regAster = self.player.parent as! RegularAsteroid
        
        let relLocation = convertPoint(location, toNode: regAster)
        
        
            let difX = relLocation.x - self.player.position.x
            
            //var angle:CGFloat = 0
            var xScale:CGFloat = 1.0
            
            if (difX > 0) {
                //angle = -π * 0.5
                xScale = 1.0
            } else if (difX < 0) {
                //angle = π * 0.5
                xScale = -1.0
            }
            self.player.xScale = xScale
            
            /*let rotateAct = SKAction.rotateByAngle(angle, duration: angle != 0 ? 0.2 : 0 )
            let runBlockAct = SKAction.runBlock(runBlock)
            let rotateBackAct = rotateAct.reversedAction()
            
            let seq = SKAction.sequence([rotateAct,runBlockAct,rotateBackAct])
            self.player.runAction(seq)*/
        
            self.player.animeAsteroidHammerAttack(runBlock)
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
        print("!!! Destroyed \(destroyed) prevNumberOfLives \(prevNumberOfLives) curNumberOfLives \(curNumberOfLives)")
        if (prevNumberOfLives != curNumberOfLives) {
            
            let info = SurvivalGameInfo()
            info.numberOfLives = destroyed ? 0 :curNumberOfLives
            info.ratio = destroyed ? 0 : self.healthRatio
            info.currentScore = self.currentGameScore
            info.playedTime = self.playedTime
            
            GameLogicManager.sharedInstance.updateCurrentSurvivalGameInfo(info) {
                updated in
                print("UPdated \(updated)")
            }
        }
        
        return destroyed
    }
    
    private func calculateGameTime() -> NSTimeInterval {
        
        if (self.startPlayTime != 0) {
            let spentTime = NSDate.timeIntervalSinceReferenceDate() - self.startPlayTime
            
            return spentTime + self.playedTime
        }
        
        return self.playedTime
    }
    
    func createRocksExplosion(point:CGPoint,scale:CGFloat) {
        
        let  emitter = SKEmitterNode(fileNamed: "Explosion")!
        emitter.zPosition = self.fgZPosition
        emitter.position = point
        emitter.targetNode = self
        emitter.particleScale = scale
        addChild(emitter)
        
        let sAction = scale < 2 ? SoundManager.explosionSmall : SoundManager.explosionLarge
        
        emitter.runAction(sAction)
    }
    
    
    func shakeCamera(fakePlayerParent:RegularAsteroid, duration:NSTimeInterval) {
        let amplitudeX:CGFloat = 10;
        let amplitudeY:CGFloat = 6;
        let numberOfShakes = duration / 0.04;
        var actionsArray:[SKAction] = [];
        for _ in 1...Int(numberOfShakes) {
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
        
        if self.paused {
            return
        }
        
        updateForBlade(currentTime)
        
        var timeSinceLast = currentTime - self.lastUpdateTimeInterval
        self.lastUpdateTimeInterval = currentTime;
        if (timeSinceLast > 1) { // more than a second since last update
            timeSinceLast = CFTimeInterval(1/60)
        }
        
        for bomb in self.bombs {
            player.updateWithTimeSinceLastUpdate(timeSinceLast,location: bomb.position)
            bomb.updateWithTimeSinceLastUpdate(timeSinceLast)
        }
        
        for enemyShip in self.enemiesShips {
            enemyShip.updateWithTimeSinceLastUpdate(timeSinceLast)
        }
        
        if !self.player.isCaptured && self.player.zRotation != 0 {
            self.player.zRotation = 0.0
        }
    }
    
    private func didEvaluateActionPrivate() {
        
            if let transmitter = self.childNodeWithName(Transmitter.NodeName) as? Transmitter {
             
                if self.player.isCaptured {
                    
                    if let parent = self.player!.parent  {
                        if parent == transmitter {
                            return
                        }
                        else {
                            
                            if self.player.isUnderBlackHole() {
                                return
                            }
                            
                            if (transmitter.underRayBeam(self.player!) && self.player.isCaptured) {
                                let returned = returnPlayerToScene(parent, removeAsteroid: false,usePlayerPostion:true,needToExplode: true)
                                
                                if returned {
                                    return
                                }
                            }
                        }
                        
                        
                    }
                }
                
                //let playerPos = self.player.parent!.convertPoint(self.player, toNode: transmitter)
                if !self.player.isCaptured && transmitter.underRayBeam(self.player)  {
                    transmitter.transmitAnItem(item: self.player, itemSize: self.player.size, toPosition: CGPointMake(CGRectGetMinX(self.playableArea) + max(self.player.size.halfWidth(),transmitter.transmitterSize.halfWidth()) , self.player.position.y)) {
                        [unowned self] in
                        self.enemyGenerator.paused = false
                        //#if DEBUG
                           //self.enemyGenerator.appendToSceneBlackHoleAtPosition(self.player.parent!.convertPoint(self.player.position, toNode: self))
                        //#endif
                        }
                }
            }
    }

    
    override func didApplyConstraints() {
        
        if !self.enemiesShips.isEmpty {
            for enemyShip in self.enemiesShips {
                if enemyShip is MotionlessEnemySpaceShip {
                    let castEnemy = enemyShip as! MotionlessEnemySpaceShip
                    
                    if !castEnemy.allowAttack {
                        castEnemy.allowAttack = true
                    }
                }
            }
        }
    }
    
    override func didEvaluateActions() {
        super.didEvaluateActions()
        didEvaluateActionPrivate()
    }
    
    
    private func applyImpulseToNode(sprite:SKNode!,vector:CGVector) {
        
        var affectedNode:SKNode! = sprite
        if sprite.parent != self {
            affectedNode = affectedNode.parent
        }
        
        affectedNode?.physicsBody?.applyImpulse(vector)
    }
    
    private func applyBackImpulseToNode(sprite:SKNode!) {
        
        applyImpulseToNode(sprite, vector: CGVector(dx: -40, dy: 0.0))
    }
    
    func returnPlayerToScene(sprite:SKNode,removeAsteroid:Bool = true,usePlayerPostion:Bool = false, needToExplode:Bool = false) -> Bool {
        
        if self.player.isCaptured {
            
            let position = convertNodePosition(sprite, toScene: self)
            self.removePlayerFromRegularAsteroidToScene(position)
            
            if needToExplode {
                createRocksExplosion(position, scale: 2.0)
                self.didMoveOutAsteroidForGenerator(self.asteroidGenerator, asteroid: sprite, withType: .Regular)
            }
            else if usePlayerPostion {
                applyBackImpulseToNode(sprite)
            }
            
            if let transmitter = self.childNodeWithName(Transmitter.NodeName) as? Transmitter {
                if transmitter.underRayBeam(self.player) && !self.player.isCaptured {
                    transmitter.transmitAnItem(item: self.player, itemSize: self.player.size, toPosition: CGPointMake(CGRectGetMinX(self.playableArea) + max(self.player.size.halfWidth(),transmitter.transmitterSize.halfWidth()) , self.player.position.y)) {
                        [unowned self] in
                        self.enemyGenerator.paused = false
                    }
                }
            }
            
            if removeAsteroid {
                sprite.physicsBody = nil
                sprite.removeFromParent()
            }
            else {
                sprite.physicsBody?.contactTestBitMask = EntityCategory.PlayerLaser
            }
            return true
        }
        return false
    }
    
    internal var heroes:[Player] {
        get {
            return [self.player]
        }
    }
    
    func removePlayerFromRegularAsteroidToScene(pos:CGPoint) {
        
        let pPos:CGPoint = pos
        
        if let asteroid = self.player.parent as? RegularAsteroid {
            asteroid.physicsBody?.contactTestBitMask &= ~EntityCategory.Player
            
            
            asteroid.runAction(SKAction.sequence([SKAction.waitForDuration(1),SKAction.runBlock(){
                    asteroid.physicsBody?.contactTestBitMask |= (EntityCategory.Player | EntityCategory.PlayerLaser)
                }]))
            
        }
        else {
            return
        }
        
        self.player.hideHammer()
            
                //let pPos = recursiveConvertPositionToScene(self.player)
        print("Current position \(pPos)")
        
        if self.player.isCaptured {
            //let player = self.player
            self.player.removeFromParent()
            createPlayer(false)
            self.player.health = 0.0
            self.player.updateNumberOfLives(extraLives: self.hudNode.life)
            self.player.health += ForceType(self.hudNode.curLifePercent)
            //self.addChild(player)
            //self.player = player
        }
        
        self.player.removeAllActions();
        self.player.position = pPos
        self.player.zRotation = 0.0
        self.player.zPosition = self.fgZPosition
        
        var x:CGFloat = 0
        var y:CGFloat = 0
        
        
        
        if pPos.x <= CGRectGetMinX(self.playableArea) {
            x = CGRectGetMinX(self.playableArea)  + self.player.size.halfWidth()
        }
        else if pPos.x >= CGRectGetWidth(self.playableArea) {
            x = CGRectGetWidth(self.playableArea) - self.player.size.halfHeight()
        }
        else {
            x = pPos.x
        }
        
        if pPos.y <= CGRectGetMinY(self.playableArea) {
            y = CGRectGetMinY(self.playableArea) + self.player.size.halfHeight()
        }
        else if pPos.y >= CGRectGetHeight(self.playableArea) {
            y = CGRectGetHeight(self.playableArea) - self.player.size.halfHeight()
        }
        else {
            y = pPos.y
        }
        
        
        
        
        let newPoint = CGPointMake(x, y)
        if (!CGPointEqualToPoint(newPoint, pPos)) {
            //self.player.moveToPoint(CGPointMake(x, y))
            print("Return position \newPoint)")
            self.player.runAction(SKAction.moveTo(newPoint, duration: 0.2))
        }
        
        
        
        let actSeq = SKAction.sequence([SKAction.waitForDuration(2),SKAction.runBlock(){
            [unowned self] in
            if (self.view != nil) {
                self.player?.enableGravityReceptivity()
            }
        }])
        
        self.player.runAction(actSeq)
    }
    
    //MARK: Asteroid Generator's delegate methods
    func didMoveOutAsteroidForGenerator(generator: AsteroidGenerator, asteroid: SKNode, withType type: AsteroidType) {
        
        /*let transmitter = self.childNodeWithName(Transmitter.NodeName) as? Transmitter
        
        var isUnderTransmitter:Bool
        if let value = transmitter?.transmitterKeepsAPlayer() {
            isUnderTransmitter = value
        }
        else {
            isUnderTransmitter = false
        }*/
        
        switch (type) {
        case .Trash:
            if (self.trashAsteroidsCount != 0 && asteroid.parent != nil) {
                self.trashAsteroidsCount--
            }
            
            if (self.trashAsteroidsCount == 0) {
                self.enemyGenerator.paused = false
                if self.childNodeWithName(Transmitter.NodeName) == nil && self.bombs.isEmpty {
                    self.player.disableProjectileGun()
                }
                generator.paused = self.trashAsteroidsCount != 0
            }
            
            print("Trash asteroids count \(self.trashAsteroidsCount) after removing" )
            
            break
        case .RopeBased:
            
            if !self.ropeBasedArray.isEmpty {
                
                for (var i = self.ropeBasedArray.startIndex; i < self.ropeBasedArray.endIndex;i++) {
                    
                    let curAster = self.ropeBasedArray[i]
                    
                    if curAster == asteroid {
                        self.ropeBasedArray.removeAtIndex(i)
                        break
                    }
                }
            }
            generator.paused = false
            if let ropeBased = asteroid as? RopeJointAsteroids {
                for aster in ropeBased.asteroids {
                    if self.player.parent ==  aster  && returnPlayerToScene(aster) {
                        self.player.hideHammer()
                        break;
                    }
                }
                ropeBased.removeFromParent()
            }
            
            break
        case .Regular:
//HACK: #warning "HACK"
            
            if self.player.parent == asteroid && returnPlayerToScene(asteroid) {
                self.player.hideHammer()
            }
            
            generator.paused = false
            if asteroid.parent != nil {
                asteroid.removeFromParent()
            }
            break
        case .Bomb:
            generator.paused = false
            
            let bomb = asteroid as! Bomb
            
            if !self.bombs.isEmpty {
                for index in 0...self.bombs.count - 1 {
                    if self.bombs[index] == bomb {
                        self.bombs.removeAtIndex(index)
                        break
                    }
                }
            }
    
            if CGRectContainsPoint(self.playableArea, bomb.position) {
                if (bomb.parent != nil) {
                    createExplosion(.Small, position: bomb.position)
                    bomb.syDisplayScore(rect: self.playableArea, scoreAddition: 0)
                }
            }
            
            if self.bombs.isEmpty {
                self.player.disableProjectileGunDuringMove()
            }
            
            if self.childNodeWithName(Transmitter.NodeName) != nil {
                self.player.enableProjectileGun()
            }
            break
        default:
            break
        }
    }
    
    func asteroidGenerator(generator: AsteroidGenerator, didProduceAsteroids: [SKNode], type: AsteroidType) {
        
        for node in didProduceAsteroids {
            node.zPosition = self.fgZPosition
            
            if node.parent != Optional<SKNode>(self) {
                addChild(node)
            }
            
            //assert(CGRectGetHeight(self.playableArea) > CGRectGetHeight(node.frame) && CGRectGetHeight(node.frame) > CGRectGetMinY(self.playableArea), "Doesn't contain frame!")
            
            print("Asteroid position \(node.position)")
            print("Scene size \(self.size)")
        }
        generator.paused = true
        
        
        switch (type) {
        case .Trash:
            self.enemyGenerator.paused = true
            self.player.removeAllActions()
            self.player.disableEngine()
            self.trashAsteroidsCount += didProduceAsteroids.count
            
            print("Trash asteroids count \(self.trashAsteroidsCount) addition" )
            self.player.enableProjectileGun()
            
            //eee Move up if there is a contact...
            break;
        case .Bomb:
            
            for curBombObj in didProduceAsteroids {
                if let curBomb = curBombObj as? Bomb {
                    curBomb.target = self.player
                    self.bombs.append(curBomb)
                    if (curBomb.canAttack) {
                        self.player.enableProjectileGunDuringMove()
                    }
                }
            }
            
            break
        case .Health:
            generator.paused = false
            break
        case .Regular:
            
            for node in didProduceAsteroids {
                if node is SmallRegularAsteroid {
                    generator.paused = false
                }
                else if let regAster = node as? RegularAsteroid {
                    if self.player.canThrowProjectile() && regAster.maxLife != 0 {
                        regAster.maxLife = 1.0
                    }
                }
            }
            
            if self.childNodeWithName(Transmitter.NodeName) == nil {
                self.player.disableProjectileGun()
            }
            break
        case .RopeBased:
            for aster in didProduceAsteroids {
                if let asteroids = aster as? RopeJointAsteroids {
                    asteroids.prepare()
                    self.ropeBasedArray.append(asteroids)
                }
            }
            break
        default:
            break;
        }
    }
    
    func emulateImpulse(forAsteroid asteroid:RegularAsteroid!,direction:CGVector) -> NSTimeInterval {
        
        let vector = vectorFromPoint(asteroid.position, usingDirection: direction, inRect: self.playableArea)
        
        let speed = 1.5 * AsteroidGenerator.regularAsteroidSpeed
        
        let duration = NSTimeInterval(vector.length()/speed)
        
        let moveToAction = SKAction.moveByX(vector.dx, y: vector.dy, duration: duration)
        
        let durMin = min(duration+0.2,1.0)
        
        let seg2 = SKAction.sequence([SKAction.waitForDuration(durMin),SKAction.runBlock({ () -> Void in
            if (asteroid.parent != nil && asteroid.physicsBody != nil) {
                asteroid.physicsBody!.categoryBitMask = EntityCategory.RegularAsteroid
                asteroid.physicsBody!.contactTestBitMask = UInt32.max
                //asteroid.physicsBody!.fieldBitMask = EntityCategory.BlakHoleField
                
            }
        })])
        
        let seg1 = SKAction.sequence([moveToAction,SKAction.removeFromParent()])
        
        let group = SKAction.group([seg1,seg2])
        
        asteroid.runAction(group)
        
        return durMin
    }
    
    //MARK: Enemies Generator's methods
    func enemiesGenerator(generator: EnemiesGenerator, didProduceItems: [SKNode!], type: EnemyType) {
        
        let isTransmitter = didProduceItems.count == 1 && type == .Transmitter
        
        for node in didProduceItems {
            let pBody = node.physicsBody
            
            if pBody == nil {
                node.zPosition = self.bgZPosition + 1
            }
            else if pBody!.categoryBitMask == EntityCategory.BlackHole {
                node.zPosition = self.bgZPosition + 1
            }
            else if pBody!.categoryBitMask == EntityCategory.EnemySpaceShip {
                node.zPosition = self.fgZPosition
                let eSpaceShip = node as! EnemySpaceShip
                eSpaceShip.target = self.player
            }
            
            addChild(node)
            
            if type == .SpaceShip {
                self.enemiesShips.append(node as! EnemySpaceShip)
                
                if let node = node as? KamikadzeSpaceShip {
                    node.delegate = self
                    node.dataSource = self
                    let transmitter = self.childNodeWithName(Transmitter.NodeName) as! Transmitter
                    let xPos = CGRectGetMinX(self.playableArea) + transmitter.transmitterSize.width
                    node.explosionXPosition = xPos
                }
            }
            
            generator.signalItemAppearance(node, type: type)
            print("Enemy position \(node.position)")
            print("Scene size \(self.size)")
        }
        generator.paused = type != .BlackHole
        
        if isTransmitter == true {
            self.asteroidGenerator.paused = true
            
            if let transmitter = didProduceItems.last as? Transmitter {
                
                self.player.enableProjectileGun()
                if (!transmitter.moveToPosition(toPosition: CGPointMake(CGRectGetMinX(self.playableArea) + max(self.player.size.halfWidth(),transmitter.transmitterSize.halfWidth()) , self.player.position.y))) {
                    //TODO: Transfer ownership of the player to transmitter
                    self.didEvaluateActionPrivate()
                }
            }
        }
    }
    
    func didDissappearItemForEnemiesGenerator(generator: EnemiesGenerator, item: SKNode!, type: EnemyType) {
        
        var paused:Bool = false
        
        item?.removeFromParent()
        
        if type == .SpaceShip {
            
            if !self.enemiesShips.isEmpty {
                for i in 0...self.enemiesShips.count-1 {
                    if self.enemiesShips[i] == item {
                        self.enemiesShips.removeAtIndex(i)
                        break
                    }
                }
            }
            else {
            
                
                if self.childNodeWithName(Transmitter.NodeName) == nil {
                    if !self.bombs.isEmpty {
                        
                        for bomb in self.bombs {
                            
                            if (bomb.canAttack) {
                                self.player.forceEnableProjectileGunDuringMove()
                                break
                            }
                        }
                    }
                    else {
                        self.player.disableProjectileGun()
                    }
                }
            }
            if self.enemiesShips.isEmpty {
                paused = !generator.didFinishWithCurrentSpaceShipChunk()
            } else {
                paused = true
            }
        }
        
        generator.paused = paused
        
        
        if type == .Transmitter {
            if let trans = self.childNodeWithName(Transmitter.NodeName) as? Transmitter{
                trans.disposeTransmitter()
            }
                if !self.bombs.isEmpty {
                    
                    for bomb in self.bombs {
                        
                        if (bomb.canAttack) {
                            self.player.forceEnableProjectileGunDuringMove()
                            break
                        }
                    }
                }
                else {
                    
                    if !self.enemiesShips.isEmpty {
                        self.player.enableProjectileGun()
                    }
                    else {
                        self.player.disableProjectileGun()
                    }
                }
            self.player.zRotation = 0
            self.player.physicsBody!.contactTestBitMask |= EntityCategory.RegularAsteroid
            self.asteroidGenerator.paused = false
        }
    }
    
    /*
        There is an issue when player with asteroids is moved out. Player is not returned back to the scene.
    */
    
    //MARK: Contact methods
    
    func playerContactingWithSmallRegulaAsteroid(regAsteroid:RegularAsteroid!,contact: SKPhysicsContact) -> Bool {
        
        if let asteroid = regAsteroid as? SmallRegularAsteroid {
            
            if (asteroid.isFiring) {
            
                if let contactTime  = asteroid.userData?.valueForKey("syContactTime") {
                    
                    if NSDate.timeIntervalSinceReferenceDate() - contactTime.doubleValue! < 2 {
                        return true
                    }
                }
                
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
            asteroid.physicsBody!.contactTestBitMask &= ~EntityCategory.Player //UInt32.max // contacts with all objects...
            //asteroid.physicsBody!.fieldBitMask = EntityCategory.BlakHoleField
            

            
            if (checkNodeAndDestroyParentOnNeed(regAsteroid, isRope: false)) {
                self.didMoveOutAsteroidForGenerator(self.asteroidGenerator, asteroid: regAsteroid, withType: .RopeBased)
            }
            
            var impulse = contact.contactNormal
            if (!CGPointEqualToPoint(self.prevPlayerPosition, self.player.position)) {
                let posNormalized = (self.player.position - self.prevPlayerPosition).normalized()
                self.player.placeAtPoint(contact.contactPoint)
                self.player.removeAllActions()
                impulse = CGVector(dx: posNormalized.x, dy: posNormalized.y)
            }
            
            if (contact.collisionImpulse != 0)
            {
                impulse.dx *= contact.collisionImpulse
                impulse.dy *= contact.collisionImpulse
            }
            asteroid.physicsBody?.applyImpulse(impulse)
            
            
            if asteroid.userData == nil {
                asteroid.userData = ["syContactTime":NSDate.timeIntervalSinceReferenceDate()]
            }
            else {
               let mUserData = asteroid.userData!
                mUserData.setObject(NSDate.timeIntervalSinceReferenceDate(), forKey: "syContactTime")
            }
            
            /*if !asteroid.isFiring {
                
                //MARK: HACK remove this!!
                let bomb = self.asteroidGenerator.produceBombInternal()
                    
                bomb.removeAllActions()
                    
                
                var newPos = contact.contactPoint +  CGPointMake(impulse.dx * 1000, impulse.dy * 1000)
                
                newPos.x = max(min(newPos.x,CGRectGetMaxX(self.playableArea)),CGRectGetMinX(self.playableArea))
                
                newPos.y = max(min(newPos.y,CGRectGetMaxY(self.playableArea)),CGRectGetMinY(self.playableArea))
                
                bomb.position = newPos
                bomb.zPosition = self.fgZPosition 

                print(" Bomb new position \(newPos)")
                
                print("Impulse dx \(impulse.dx)\n Impulse dy \(impulse.dx)" )
                
                addChild(bomb)
                
                bomb.physicsBody?.contactTestBitMask = 0xffffffff
                
                assert(bomb.physicsBody != nil)
            }
            */
            let asteroidTime = emulateImpulse(forAsteroid: asteroid, direction: impulse)
            
            let time2 = asteroidTime * 0.1
            
            asteroid.runAction(SKAction.sequence([SKAction.waitForDuration(time2),SKAction.runBlock(){
                    asteroid.physicsBody?.contactTestBitMask = UInt32.max
                }]))
            
            
            asteroid.startFiringAtDirection(impulse, point: self.convertPoint(contact.contactPoint, toNode: asteroid))
            
            
            self.asteroidGenerator.paused = false
            
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
                
                let location  = regAster.parent!.convertPoint(regAster.position, toNode: self)
            
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
                }
                
                //MARK: Continue here, create crystal, with score addition.
                
                self.createRocksExplosion(location,scale:scale)
                
                regAster.syDisplayScore(rect: self.playableArea, scoreAddition: 20)
                
                if (!self.checkNodeAndDestroyParentOnNeed(regAster, isRope: false)) {
                    self.didMoveOutAsteroidForGenerator(self.asteroidGenerator, asteroid: regAster, withType: .Regular)
                }
                else {
                    self.didMoveOutAsteroidForGenerator(self.asteroidGenerator, asteroid: regAster, withType: .RopeBased)
                }
            }
            else {
                self.shakeCamera(regAster, duration: 0.8)
            }
        
        return true
        
    }
    
    func didContactContainTrash(contact:SKPhysicsContact!) -> Bool {
        
        let bodyA = contact.bodyA
        let bodyB = contact.bodyB
        
        var trashAster:SKPhysicsBody? = nil
        var laser:SKPhysicsBody? = nil
        
        //Trash asteroid
        if (bodyA.categoryBitMask == EntityCategory.TrashAsteroid ) {
            trashAster = bodyA
        }
        else if (bodyB.categoryBitMask == EntityCategory.TrashAsteroid) {
            trashAster = bodyB
        }
        else {
            return false
        }
        
        if bodyB.categoryBitMask == EntityCategory.PlayerLaser {
            laser = bodyB
        } else if bodyA.categoryBitMask == EntityCategory.PlayerLaser {
            laser = bodyA
        } else {
            return false
        }
        
        self.didMoveOutAsteroidForGenerator(self.asteroidGenerator, asteroid: trashAster!.node as! SKSpriteNode, withType: AsteroidType.Trash)
        
        
        processContact(trashAster!, andPlayerLaser: laser)
        
        return true
        
    }
    
    func didContactContainBomb(contact:SKPhysicsContact!) -> Bool {
        var bomb:SKPhysicsBody! = nil
        // bomb search
        if (contact.bodyA.categoryBitMask == EntityCategory.Bomb) {
            bomb = contact.bodyA
        } else if (contact.bodyB.categoryBitMask == EntityCategory.Bomb) {
            bomb = contact.bodyB
        }
        
        if let bombBody = bomb {
            
            if (bombBody.node == nil){
                return true
            }
            
            print("One node is bomb!")
            let bombNode = bombBody.node!
            
            let radius = bombNode.userData!["radius"] as! CGFloat
            
            let contactP = contact.contactPoint
            
            let x = contactP.x - radius
            let y = contactP.y - radius
            
            let rect = CGRectMake(x, y, 2*radius, 2*radius)
            
            
            self.physicsWorld.enumerateBodiesInRect(rect, usingBlock: {
                (eBody, retPtr) -> Void in
                
                if (eBody.categoryBitMask == EntityCategory.TrashAsteroid) {
                    
                    self.processContact(eBody, andPlayerLaser: nil)
                    
                } else if (eBody.categoryBitMask == EntityCategory.Player) {
                    let damageForce = AsteroidGenerator.damageForce(.Bomb)
                    if self.tryToDestroyPlayer(damageForce) {
                        self.terminateGame()
                        retPtr.memory = true
                        return
                    }
                }  else if (eBody.categoryBitMask == EntityCategory.PlayerLaser) {
                    if let node = eBody.node {
                        node.physicsBody = nil
                        node.removeFromParent();
                    }
                }
            })
            
            let scenePoint = contact.contactPoint
            createExplosion(ExplosionType.Large, position: scenePoint)
            bombNode.physicsBody = nil
            bombNode.removeFromParent()
            
            self.didMoveOutAsteroidForGenerator(self.asteroidGenerator, asteroid: bombNode as! SKSpriteNode, withType: AsteroidType.Bomb)
            
            
            return true
        }

        return false
    }
    
    func didPlayerLaserContactWithEnemyOrLaser(contact:SKPhysicsContact!) -> Bool {
        
        let bodyA = contact.bodyA
        let bodyB = contact.bodyB
        
        var playerLaser:SKNode? = nil
        var otherNode:SKNode? = nil
        
        if (bodyA.categoryBitMask == EntityCategory.PlayerLaser) {
            playerLaser =  bodyA.node
            otherNode = bodyB.node
        } else if (bodyB.categoryBitMask == EntityCategory.PlayerLaser) {
            playerLaser = bodyB.node
            otherNode = bodyA.node
        }
        
        if let playerLaser = playerLaser,let oNode = otherNode {
            if oNode.physicsBody!.categoryBitMask == EntityCategory.EnemySpaceShip {
                
                let enemyShip = oNode as! ItemDestructable
                
                if enemyShip.tryToDestroyWithForce(Player.laserForce) {
                    createExplosion(.Large, position: oNode.position)
                    oNode.syDisplayScore(rect: self.playableArea, scoreAddition: 10)
                    self.didDissappearItemForEnemiesGenerator(self.enemyGenerator, item: oNode, type: .SpaceShip)
                }
                else {
                    createExplosion(.Small, position: oNode.position)
                    oNode.syDisplayScore(rect: self.playableArea, scoreAddition: 5)
                }
            } else if oNode.physicsBody!.categoryBitMask == EntityCategory.EnemySpaceShipLaser {
                createExplosion(.Small, position: oNode.position)
                oNode.removeFromParent()
            }
            
            playerLaser.removeFromParent()
            return true
        }
        return false
    }
    
    func didEnemyLaserContactWithPlayerOrLaser(contact:SKPhysicsContact!) -> Bool {
        
        let bodyA = contact.bodyA
        let bodyB = contact.bodyB
        
        var enemyLaser:SKNode? = nil
        var otherNode:SKNode? = nil
        
        if (bodyA.categoryBitMask == EntityCategory.EnemySpaceShipLaser) {
            enemyLaser =  bodyA.node
            otherNode = bodyB.node
        } else if (bodyB.categoryBitMask == EntityCategory.EnemySpaceShipLaser) {
            enemyLaser = bodyB.node
            otherNode = bodyA.node
        }
        
        if let enemyLaser = enemyLaser,let oNode = otherNode {
            
            if oNode.physicsBody!.categoryBitMask == EntityCategory.Player {
                
                let damageForce = ForceType(enemyLaser.userData!["damageForce"]!.doubleValue)
                
                if (self.tryToDestroyPlayer(damageForce)) {
                    terminateGame()
                }
                else {

                }
            } else if oNode.physicsBody!.categoryBitMask == EntityCategory.PlayerLaser {
                oNode.removeFromParent()
                createExplosion(.Small, position: enemyLaser.position)
            }
            
            enemyLaser.removeFromParent()
            return true
        }
        return false
    }
    
    func applyRotationOnNeedToRopeJointAsteroids(vector:CGVector,node:SKNode!) -> Bool
    {
        if let ropeJointAsters =  node.parent as? RopeJointAsteroids {
            
            if ropeJointAsters.rope == nil {
                return false
            }
            
            let secondAster = node //(ropeJointAsters.asteroids.last == node ? ropeJointAsters.asteroids.first : ropeJointAsters.asteroids.last)!
            
            //let position = ropeJointAsters.convertPoint(secondAster.position, toNode: self)
            
            let childrenNode = ropeJointAsters.rope?.children
            if let chain = childrenNode?.last {
                
                let curPhysBody = chain.physicsBody!
                
                if !curPhysBody.joints.isEmpty {
                    
                    for var i = curPhysBody.joints.startIndex; i < curPhysBody.joints.endIndex;i++ {
                        let joint: AnyObject = curPhysBody.joints[i]
                        
                        let skJoint = unsafeBitCast(joint, SKPhysicsJoint.self)
                        
                        if let nodeA =  skJoint.bodyA.node {
                            
                            if (secondAster == nodeA) {
                                chain.physicsBody?.applyImpulse(vector) //applyImpulse(vector, atPoint: position)
                                return true
                            }
                        }
                        
                        if let nodeB =  skJoint.bodyB.node {
                            if (secondAster == nodeB) {
                                chain.physicsBody?.applyImpulse(vector)//applyImpulse(vector, atPoint: position)
                                return true
                            }
                        }
                    }
                    
                }
            }
            
            if let chain = childrenNode?.first {
                
                let curPhysBody = chain.physicsBody!
                
                if !curPhysBody.joints.isEmpty {
                    
                    for var i = curPhysBody.joints.startIndex; i < curPhysBody.joints.endIndex;i++ {
                        let joint: AnyObject = curPhysBody.joints[i]
                        
                        let skJoint = unsafeBitCast(joint, SKPhysicsJoint.self)
                        
                        if let nodeA =  skJoint.bodyA.node {
                            
                            if (secondAster == nodeA) {
                                chain.physicsBody?.applyImpulse(vector)//, atPoint: position)
                                return true
                            }
                        }
                        
                        if let nodeB =  skJoint.bodyB.node {
                            if (secondAster == nodeB) {
                                chain.physicsBody?.applyImpulse(vector)//, atPoint: position)
                                return true
                            }
                        }
                    }
                    
                }
            }
            
            //ropeJointAsters.rope?.physicsBody?.applyAngularImpulse(vector.length()*10)
            
            return true
        }
        return false
    }
    
    func checkNodeAndDestroyParentOnNeed(node:SKNode!,isRope rope:Bool) -> Bool {
        
        if let jointsAster = node.parent as? RopeJointAsteroids  {
            
            if rope {
                jointsAster.rope = nil
            }
            else {
                if let last = jointsAster.asteroids.last {
                    if last == node{
                       jointsAster.removeAsteroid(node as? RegularAsteroid)
                       let nPos = jointsAster.convertPoint(node.position, toNode: self)
                       node.position = nPos
                       addChild(node)
                    }
                }
                
                
                if let first = jointsAster.asteroids.first {
                    if first == node {
                        jointsAster.removeAsteroid(node as? RegularAsteroid)
                        let nPos = jointsAster.convertPoint(node.position, toNode: self)
                        node.position = nPos
                        addChild(node)
                    }
                }
            }
            
            let needToRemove = jointsAster.asteroids.isEmpty && jointsAster.rope == nil
            
            if (needToRemove){
                self.returnPlayerToScene(node, removeAsteroid: true, usePlayerPostion: true)
            }
            
            return needToRemove
        }
        return false
    }
    
    func didEntityContactWithFireingSmallAsteroid(contact:SKPhysicsContact) -> Bool
    {
        let bodyA = contact.bodyA
        let bodyB = contact.bodyB
        
        var asteroidBody:SKPhysicsBody? = nil
        var entityBody: SKPhysicsBody? = nil
        var isFireing:Bool = false
        
        if bodyA.categoryBitMask == EntityCategory.RegularAsteroid {
            asteroidBody = bodyA
            entityBody = bodyB
            
            if let smallAster = asteroidBody?.node as? SmallRegularAsteroid {
                isFireing = smallAster.isFiring
            }
        }
        
        if !isFireing && bodyB.categoryBitMask == EntityCategory.RegularAsteroid {
            asteroidBody = bodyB
            entityBody = bodyA
            
            if let smallAster = asteroidBody?.node as? SmallRegularAsteroid {
                isFireing = smallAster.isFiring
            }
        }
        
        if let smallRegAster = asteroidBody?.node as? SmallRegularAsteroid {
            
            if smallRegAster.isFiring {

                if (entityBody?.categoryBitMask != EntityCategory.BlackHole) {
                    
                    if let item = entityBody?.node as? ItemDestructable {
                        
                        if entityBody?.node == self.player {
                            
                            if let contactTime  = smallRegAster.userData?.valueForKey("syContactTime") {
                                
                                let timeDiff = NSDate.timeIntervalSinceReferenceDate() - contactTime.doubleValue!
                                
                                print("Time Diff \(timeDiff)")
                                
                                if timeDiff < 2 {
                                    return false
                                }
                            }
                            
                            if self.tryToDestroyPlayer(smallRegAster.damageForce) {
                                self.terminateGame()
                            }
                            
                        }
                        else if (smallRegAster.destroyItem(item)) {
                            if (entityBody?.categoryBitMask != EntityCategory.Bomb) {
                                self.createExplosion(.Large, position: contact.contactPoint)
                            }
                            if let node = entityBody?.node {
                                node.syDisplayScore(rect: self.playableArea, scoreAddition: 20)
                                self.didMoveOutAsteroidForGenerator(self.asteroidGenerator, asteroid: node, withType: .Regular)
                            }
                        } else {
                            smallRegAster.syDisplayScore(rect: self.playableArea, scoreAddition: 10)
                            self.createExplosion(.Large, position: contact.contactPoint)
                        }
                    }
                }
                
                self.didMoveOutAsteroidForGenerator(self.asteroidGenerator, asteroid: smallRegAster, withType: .Regular)
                
                return true
            }
            
        }
        
        return false
        
    }
    
    func didEntityContactWithRegularAsteroid(contact: SKPhysicsContact) -> Bool
    {
        let bodyA = contact.bodyA
        let bodyB = contact.bodyB
        
        var asteroidBody:SKPhysicsBody? = nil
        var entityBody:SKPhysicsBody? = nil
        
        if (bodyA.categoryBitMask == 0) {
            bodyA.categoryBitMask = EntityCategory.RegularAsteroid
        }
        else if (bodyB.categoryBitMask == 0) {
            bodyB.categoryBitMask = EntityCategory.RegularAsteroid
        }
        
        if (bodyA.categoryBitMask == EntityCategory.RegularAsteroid) {
            asteroidBody = bodyA
            entityBody = bodyB
        } else if (bodyB.categoryBitMask == EntityCategory.RegularAsteroid) {
            asteroidBody = bodyB
            entityBody = bodyA
        }

        if let regularBody = asteroidBody  {
            
            if regularBody.node == nil || (regularBody.node as? RegularAsteroid) == nil {
                regularBody.categoryBitMask = 0
                return true
            }
            
            let pNode = regularBody.node as! RegularAsteroid
            let secondNode = entityBody?.node
            
            if ((secondNode is Player) &&  playerContactingWithSmallRegulaAsteroid(pNode, contact :contact)) {
                return true
            } else if (pNode is SmallRegularAsteroid) {
                let smallAster = pNode as! SmallRegularAsteroid
                let asterPos = smallAster.parent!.convertPoint(smallAster.position,toNode:self)
                createRocksExplosion(asterPos, scale: 2)
                
                smallAster.syDisplayScore(rect: self.playableArea, scoreAddition: 10)
                smallAster.removeFromParent()
                
                if (didSmallAsteroidCollidedWithRegulaOne(secondNode)) {
                    return true
                }
                
                //TODO: if second item is not regular asteroid - recalculate....
                return true
            } else if (entityBody!.categoryBitMask == EntityCategory.PlayerLaser) {
                
                if let regAster = regularBody.node as? RegularAsteroid {
                    
                    if (regAster.tryToDestroyWithForce(Player.laserForce)) {
                        
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
                        }
                        let location = contact.contactPoint
                        
                        let vector = contact.contactNormal * -0.5
                        
                        self.applyRotationOnNeedToRopeJointAsteroids(vector, node: regAster)
                        
                        self.createRocksExplosion(location,scale:scale)
                        
                        regAster.syDisplayScore(rect: self.playableArea, scoreAddition: 20)
                        
                        if (!self.checkNodeAndDestroyParentOnNeed(regAster, isRope: false)) {
                            self.didMoveOutAsteroidForGenerator(self.asteroidGenerator, asteroid: regAster, withType: .Regular)
                        } else {
                            if let parent = regAster.parent as? RopeJointAsteroids {
                                self.didMoveOutAsteroidForGenerator(self.asteroidGenerator, asteroid: parent, withType: .RopeBased)
                            } else {
                                self.didMoveOutAsteroidForGenerator(self.asteroidGenerator, asteroid: regAster, withType: .Regular)
                            }
                        }
                        
                    }
                    else {
                        entityBody?.node?.removeFromParent()
                           self.shakeCamera(regAster, duration: 0.8)
                    }
                }

                return true
            }
            
            
            if ((self.player.parent as? Transmitter) != nil ) {
                if let node = asteroidBody?.node {
                    node.removeAllActions()
                    let action = SKAction.repeatActionForever(SKAction.rotateByAngle(-CGFloat(M_PI), duration: 2))
                    node.runAction(action)
                    
                    
                    let vector = CGVector(dx:100,dy:0)
                    let pos = node.parent!.convertPoint(node.position, toNode: self)
                    let duration = NSTimeInterval((CGRectGetMaxX(self.playableArea) - pos.x)/CGFloat(vector.dx))
                    
                    let action2 = SKAction.sequence([SKAction.waitForDuration(duration),SKAction.removeFromParent()])
                    
                    if node.parent != self {
                    
                        if let ropeJointsAster = asteroidBody?.node?.parent as? RopeJointAsteroids {
                            cutRopeUsingImpulse(ropeJointsAster.rope?.childNodeWithName("Chain"), v: CGVector(dx:1,dy:0))
                            
                            ropeJointsAster.runAction(action2)
                        }
                    }
                    else {
                        node.runAction(action2)
                    }
                    
                    asteroidBody?.applyImpulse(vector)
                    asteroidBody?.contactTestBitMask &= EntityCategory.Player
                    self.asteroidGenerator.paused = false
                }
                return true
            }
            
            print("Is Captured \(self.player.isCaptured)")
            
            if self.player.isCaptured {
                return true
            }
            
            let angle2 = reflectionAngleFromContact3(contact)
        
            //TODO: Move to the Player class
            print("Player's z (before) rotation \(self.player.zRotation.degree), Angle \(angle2.degree)")
            
            let pointInternal = self.convertPoint(contact.contactPoint, toNode: pNode)
            self.player.position = pointInternal
            self.player.zRotation = angle2
            
            pNode.physicsBody!.contactTestBitMask &= ~self.player.physicsBody!.categoryBitMask
            
            print("Player parent \(self.player.parent)\n PNode parent \(pNode.parent)")
            let player = self.player
            self.player.removeAllActions()
            self.player.removeFromParent()
            
            player.anchorPoint = CGPoint.zero
            pNode.addChild(player)
            player.disableEngine()
            self.player = player
            
            print("placing player at position \(pointInternal)")
            self.player.disableGravityReceptivity()
            print("\(self.player.physicsBody!.contactTestBitMask)")
            self.player.zPosition = self.fgZPosition
            self.player.zRotation = 0
            
            
            
            if let bNode = regularBody.node as? RegularAsteroid {
                bNode.removeField()
                self.player.animeAsteroidHammerAttack{
                    [unowned self] in
                    self.shakeCamera(bNode,duration:0.8)
                }
            }
            
            //check the node....
            if needToCorrectRotation(self.player) {
                self.player.zRotation += π
                /*if needToCorrectRotation(playerNode) {
                    playerNode.zRotation += π
                }*/
            }
            return true
        }
        
        return false
    }
    
    
    func needToCorrectRotation(node:Player) -> Bool
    {
        let p2 = node.parent?.convertPoint(CGPointMake(0, node.size.halfHeight()), fromNode: node)
        let p1 = node.parent?.convertPoint(CGPointZero, fromNode: node)
        
        assert(CGPointEqualToPoint(p1!, node.position))
        
        let firstPoint = (p2! - p1!).normalized()
        let lastPoint = (p1! - CGPointZero).normalized()
        
        let productPoint = firstPoint * lastPoint
        
        return (productPoint.x * productPoint.y) < 0
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
        
        if !(secondNode is Player) {
            return true
        }
        
        secondNode.physicsBody!.contactTestBitMask &= ~EntityCategory.BlackHole
    
        
        print("blackHoleNode")

        self.userInteractionEnabled = !(secondNode is Player)
        
        var isTransmitter = false
        var wasAsteroid = false
        
        if !self.userInteractionEnabled {
            
            if secondNode.parent != blackHoleNode.parent {
                assert(self.player == secondNode)
                
                if self.player.isCaptured {
                    
                    if let parent = self.player.parent as? RegularAsteroid {
                        wasAsteroid = true
                        let scaleAction = SKAction.scaleTo(0.2, duration: 0.2)
                        parent.runAction(SKAction.sequence([scaleAction,SKAction.removeFromParent()]))
                    }
                    else {
                        isTransmitter = self.player.parent is Transmitter
                    }
                }
                
                let blackHoleWon = self.player.willBeDestroyedWithFore(blackHoleNode.damageForce)
                
                if (wasAsteroid || blackHoleWon) {
                    let itemPos = contact.contactPoint
                    
                    secondNode.removeFromParent()
                    addChild(secondNode)
                
                    secondNode.removeAllActions()
                    secondNode.position = itemPos
                }
                
                if !blackHoleWon {
                    self.tryToDestroyPlayer(blackHoleNode.damageForce)
                    self.restartGameForPlayer(wasAsteroid,blackHoleNode: blackHoleNode,isTransmitter: isTransmitter)
                    return true
                }
            }
            
            
            if self.player == secondNode {
                self.player.influencedByBlackHole()
            }
            else {
                secondNode.physicsBody?.categoryBitMask = 0
            }
        }
        
        let blackHoleWon = self.player.willBeDestroyedWithFore(blackHoleNode.damageForce)
        
        if !blackHoleWon {
            self.tryToDestroyPlayer(blackHoleNode.damageForce)
            self.restartGameForPlayer(wasAsteroid,blackHoleNode: blackHoleNode,isTransmitter: isTransmitter)
            return true
        }

        let durationToWait = blackHoleNode.moveItemToCenterOfField(secondNode)
        
        if secondNode == self.player {
            self.player.runAction(SKAction.sequence([SKAction.waitForDuration(durationToWait),SKAction.runBlock(){
                [unowned self] in
                    if self.tryToDestroyPlayer(blackHoleNode.damageForce) {
                        self.terminateGame()
                        self.player?.removeFromParent()
                    } else {
                        self.restartGameForPlayer(wasAsteroid,blackHoleNode: blackHoleNode,isTransmitter: isTransmitter)
                    }
                }]))
        }
        else {
        blackHoleNode.runAction(SKAction.sequence([SKAction.waitForDuration(durationToWait),SKAction.runBlock(){
            [unowned self] in
            self.tryToDestroyDestructableItem(blackHoleNode, secondNode: secondNode)
            }]))
        }
        return true
    }
    
    
    private func restartGameForPlayer(wasAsteroid:Bool,blackHoleNode:SKNode!,isTransmitter:Bool) {
        
        self.player?.removeAllActions()
        if self.player.parent == nil {
            
            if (isTransmitter) {
                
                if let transmitter = self.childNodeWithName(Transmitter.NodeName) {
                    
                    let posTrans =  self.player.parent!.convertPoint(self.player.position, toNode: transmitter)
                    
                    self.player.position = CGPointMake(0,posTrans.y)
                    self.player.removeFromParent()
                    transmitter.addChild(self.player)
                }
                
            }
            else {
                self.addChild(self.player)
            }
        }
        
        if wasAsteroid {
            self.player.hideHammer()
        }
        
        self.player.physicsBody?.categoryBitMask = EntityCategory.Player
        self.userInteractionEnabled = true
        
        if self.player.xScale != 1.0 {
            self.player.xScale = 1.0
            self.player.yScale = 1.0
        }
            //TODO: hide hammer if it is not needed.....
            blackHoleNode?.removeAllActions()
            blackHoleNode?.removeFromParent()
    }

    private func tryToDestroyDestructableItem(blackHoleNode:BlackHole, secondNode:SKNode!) {
        
        if let destNode = secondNode as? ItemDestructable {
            let damage = blackHoleNode.damageForce
            if secondNode == self.player {
                
                if self.tryToDestroyPlayer(damage) {
                    self.terminateGame()
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
        print("Contact \(contact)")
        if (didBladeContactWithRope(contact)) {
            return
        }
        
        if (didPlayerContactWithEdge(contact) || didPlayerContactWithHealthUnit(contact) || didPlayerLaserContactWithEdge(contact)) {
            return
        }
        
        if (didContactOutOfRange(contact)) {
            return
        }
        
        if (didEntityContactWithFireingSmallAsteroid(contact) || didContactContainBomb(contact) || didContactContainTrash(contact)) {
            return
        }
        
        if (didEntityContactWithRegularAsteroid(contact) || didContachHasBlackHole(contact)) {
            return
        }
        
        if (didEnemyLaserContactWithPlayerOrLaser(contact) || didPlayerLaserContactWithEnemyOrLaser(contact)) {
            return
        }
        
    }
    
    func didEndContact(contact: SKPhysicsContact) {
        
         print("\(contact)")
    }
    
    
    func didContactOutOfRange(contact:SKPhysicsContact) -> Bool {
        
        var minX = CGRectGetMinX(self.playableArea)
        var maxX = CGRectGetMaxX(self.playableArea)
        
        if let lEdge = self.childNodeWithName(Constants.LeftEdge) {
            minX = min(lEdge.position.x - 10,minX)
        }
        
        if let rEdge = self.childNodeWithName(Constants.RightEdge) {
            maxX = max(rEdge.position.x + 10,maxX)
        }
        
        let rect = CGRectMake(minX, CGRectGetMinY(self.playableArea), maxX - minX, CGRectGetHeight(self.playableArea))
        
        return !CGRectContainsPoint(rect, contact.contactPoint)
    }
    
    func didPlayerContactWithHealthUnit(contact:SKPhysicsContact) -> Bool {
        
        var healthBody:SKPhysicsBody? = nil
        var secondBody:SKPhysicsBody? = nil
        
        if (contact.bodyA.categoryBitMask == EntityCategory.HealthUnit) {
            healthBody = contact.bodyA
            secondBody = contact.bodyB
        } else if (contact.bodyB.categoryBitMask == EntityCategory.HealthUnit){
            healthBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        if secondBody?.categoryBitMask == EntityCategory.Player && healthBody != nil {
            
            let node = healthBody!.node!
            let force = node.userData!["healing"] as! ForceType
            let res = tryToDestroyPlayer(force > 0 ? -force : force)
            assert(res == false)
            let action = SKAction.sequence([SoundManager.lapAction,SKAction.removeFromParent()])
            healthBody?.node?.runAction(action)
            return true
        }
        
        return false
    }
    
    func didPlayerContactWithEdge(contact:SKPhysicsContact) ->  Bool {
        
        if (contact.bodyB.categoryBitMask == EntityCategory.LeftEdgeBorder && contact.bodyA.categoryBitMask == EntityCategory.Player) || (contact.bodyA.categoryBitMask == EntityCategory.LeftEdgeBorder && contact.bodyB.categoryBitMask == EntityCategory.Player)  {
            
            print("Player contacted with left edge")
            
                let bgSpritePos = self.player.parent != nil ? self.player.parent!.convertPoint(self.player.position, toNode:self) : self.player.position
            
                let result = CGRectContainsPoint(self.playableArea, bgSpritePos)
            
                if (result) {
                    return true
                }
                
            
            
            if (self.returnPlayerToScene(self.player.parent!, removeAsteroid: false)) {
                
                let delayTime = dispatch_time(DISPATCH_TIME_NOW,
                    Int64(0.5 * Double(NSEC_PER_SEC)))
                
                self.childNodeWithName(Constants.LeftEdge)?.physicsBody?.contactTestBitMask &= ~EntityCategory.Player
                
                self.player.physicsBody?.contactTestBitMask &= ~EntityCategory.Player
                
                dispatch_after(delayTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)){
                    [unowned self] in
                    self.childNodeWithName(Constants.LeftEdge)?.physicsBody?.contactTestBitMask |= EntityCategory.Player
                }
            }
            return true
        }
        
        return false
        
    }
    
    func didPlayerLaserContactWithEdge(contact:SKPhysicsContact) -> Bool {
        
        if (contact.bodyA.categoryBitMask == EntityCategory.RightEdgeBorder ||
            contact.bodyB.categoryBitMask == EntityCategory.RightEdgeBorder) {
                
                var node:SKNode? = nil
                
                if (contact.bodyB.categoryBitMask == EntityCategory.RightEdgeBorder &&
                    contact.bodyA.categoryBitMask == EntityCategory.PlayerLaser) {
                    node = contact.bodyA.node
                }
                else if (contact.bodyA.categoryBitMask == EntityCategory.RightEdgeBorder &&
                    contact.bodyB.categoryBitMask == EntityCategory.PlayerLaser) {
                        node = contact.bodyB.node
                }
                
                node?.removeFromParent()
                
                return true
        }
        return false
    }
    
    func processContact(trashAster:SKPhysicsBody!, andPlayerLaser laser:SKPhysicsBody?) {
        
        
        let nodePtr:SKNode? =   laser?.node != nil ? laser?.node! : (trashAster.node != nil ? trashAster.node! :nil)
        
        if let node = nodePtr  {
            
            let scenePoint = node.position
            
            let expType = self.trashAsteroidsCount == 0 ? ExplosionType.Large : ExplosionType.Small
            
            laser?.node?.removeAllActions()
            
            if 0 == self.trashAsteroidsCount {
                createExplosion(expType, position: scenePoint)
                trashAster?.node?.syDisplayScore(rect: self.playableArea, scoreAddition: 10)
                
                let timeInterval = NSDate.timeIntervalSinceReferenceDate()
                self.lastProjectileExp = (timeInterval,scenePoint)
                trashAster?.node?.removeFromParent()
            }
            else {
                trashAster?.node?.removeFromParent()
                createExplosion(expType, position: scenePoint)
                
                if let lNode = laser?.node  {
                    
                    let emitterNode =  GameScene.sProjectileEmitter.copy() as! SKEmitterNode
                    emitterNode.position = lNode.position
                    addChild(emitterNode)
                    emitterNode.zPosition = self.fgZPosition + 1
                    
                    runOneShortEmitter(emitterNode, duration: 0.15)
                }
            }
            laser?.node?.removeFromParent()
        }
        
        
        
    }
    
    func createExplosion(explosionType:ExplosionType, position:CGPoint) {
        
        switch explosionType {
        case .Small:
            let explosion = Explosion.getExplostionForType(.Small)
            explosion.position = position
            explosion.zPosition = self.fgZPosition
            
            addChild(explosion)
            
            break;
        case .Large:
            let explosion = Explosion.getExplostionForType(.Large)
            explosion.zPosition = self.fgZPosition
            explosion.position = position
            
            addChild(explosion)
            
            
        }
    }
}

//MARK: EnemySpaceShipDelegate & Data Source
extension GameScene:EnemySpaceShipDelegate , EnemySpaceShipDataSource {
    
    func enemySpaceShip(ship:EnemySpaceShip!, needToCreateExplosionWithEmitter emitter:SKEmitterNode!) {
        
        let maxTime = NSTimeInterval(emitter.particleLifetime +  emitter.particleLifetimeRange * 0.5 )
        let minTime = NSTimeInterval(emitter.particleLifetime -  emitter.particleLifetimeRange * 0.5 )
        
        let maxSpeed = emitter.particleSpeed + emitter.particleSpeedRange*0.5
        
        let maxRadius = maxSpeed * CGFloat(maxTime)
        
        let shipPosition = ship.position
        
        didDissappearItemForEnemiesGenerator(self.enemyGenerator, item: ship, type: .SpaceShip)
        
        let seq = SKAction.sequence([SKAction.waitForDuration(minTime),SKAction.runBlock(){
            [unowned self] in
            
                
                let playerPos = self.player.parent!.convertPoint(self.player.position, toNode: self)
                
                let dist = distanceBetweenPoints(shipPosition, point2: playerPos)
                
                if dist <= maxRadius {
                    emitter.particleBirthRate = 0
                    emitter.removeAllActions()
                    emitter.removeFromParent()
                    let damageForce = KamikadzeSpaceShip.damageForceForDistance()
                    
                    if (self.tryToDestroyPlayer(damageForce)) {
                        self.terminateGame()
                    }
                }
            
            
            },SKAction.waitForDuration(maxTime - minTime),SKAction.runBlock(){
                [unowned self] in
                
                    if emitter.particleBirthRate == 0 {
                        return
                    }
                    
                    let playerPos = self.player.parent!.convertPoint(self.player.position, toNode: self)
                    
                    let dist = distanceBetweenPoints(shipPosition, point2: playerPos)
                    
                    if dist <= maxRadius {
                        emitter.particleBirthRate = 0
                        
                        let damageForce = KamikadzeSpaceShip.damageForceForDistance()
                        
                        if (self.tryToDestroyPlayer(damageForce)) {
                            self.terminateGame()
                        }
                    }
                
                
            }, SKAction.removeFromParent()])
        
        emitter.runAction(seq)
        emitter.targetNode = nil
        addChild(emitter)
    }
    
    //MARK: Data Source
    func detectXExplosionPositionForEnemySpaceShip(ship: EnemySpaceShip!) -> CGFloat {
        
        if let transmitter = self.childNodeWithName(Transmitter.NodeName) as? Transmitter {
            let xPos = transmitter.position.x + transmitter.transmitterSize.halfWidth()
        
            return xPos
        } else {
            return -1
        }
    }
}

//MARK: Blade
extension GameScene {
    
    // This will help us to initialize our blade
    private func presentBladeAtPosition(position:CGPoint) {
        let node = SWBlade(position: position, target: self, color: UIColor.whiteColor())
        node.enablePhysics(EntityCategory.Blade, contactTestBitmask: EntityCategory.Rope, collisionBitmask: EntityCategory.RegularAsteroid)
        self.addChild(node)
        self.removeBladesOnly()
        self.blades.append(node)
        node.position = position
    }
    
    // This will help us to remove our blade and reset the delta value
    private  func removeBlade() {
        delta = CGPointZero
        self.removedBlade = !self.blades.isEmpty
        
        self.removeBladesOnly()
    }
    
    
    private func removeBladesOnly() {
        if !self.blades.isEmpty {
            
            for blade in self.blades {
                blade.removeFromParent()
            }
            self.blades.removeAll()
        }
    }
    
    private func areTouchesMovedForBlade(touches: Set<NSObject>, withEvent event: UIEvent?) -> Bool {
        
        print("touchesMoved. Can cut the rope \(self.canCutRope(touches))")
        
        if self.canCutRope(touches) {
            
            if let touch = touches.first as? UITouch {
                
                let position = touch.locationInNode(self)
                let prevPosition = touch.previousLocationInNode(self)
                
                var removedBlade:Bool = false
                
                self.physicsWorld.enumerateBodiesAtPoint(position) {
                    [unowned self]
                    (curBody, exitPtr) in
                    
                    if curBody.categoryBitMask == EntityCategory.RegularAsteroid {
                        self.removeBlade()
                        removedBlade = true
                        exitPtr.memory = true
                    }
                }
                
                if removedBlade {
                    return true
                }
                
                if self.blades.isEmpty
                {
                    self.presentBladeAtPosition(position)
                }
                
                self.delta = CGPoint(x: position.x - prevPosition.x, y: position.y - prevPosition.y)
            }
            
            return true
        }
        return false
    }
    
    private func areTouchesEndedForBlade(touches: Set<UITouch>, withEvent event: UIEvent?) -> Bool {
        
        print("touchesEnded. Can cut the rope \(self.canCutRope(touches))")
        let flag = self.removedBlade || !self.blades.isEmpty
        removeBlade()
    
        if self.canCutRope(touches) && flag {
            return true
        }
        
        return false
    }
    
    private func updateForBlade(currentTime:CFTimeInterval) {
        if !self.blades.isEmpty {
            // Here you add the delta value to the blade position
            
            var initCount = self.blades.count
            for var index = initCount; index < 3; index++ {
                if let lastCopy = self.blades.last?.copy() as? SWBlade {
                    addChild(lastCopy)
                    self.blades.insert(lastCopy, atIndex:0)
                }
            }
            
            initCount = self.blades.count
            
            for var index = 0; index < initCount; index++ {
                
                let mult = CGFloat(index+1)/CGFloat(initCount)
                let position = self.blades.last!.position  + (delta * mult)
                self.blades[index].position = position
                print("POsition \(position) Mult \(mult)")
            }
            
            // it's important to reset delta at this point,
            // You are telling the blade to only update his position when touchesMoved is called
            delta = CGPointZero
        }
    }
    
    func cutRopeUsingImpulse(bNode:SKNode?,v:CGVector) {
        
        if let bNode = bNode {
            
            var impulseDirection:CGFloat = -1
            var boost:CGFloat = 1.0
            var extraPlus:CGFloat = 0.05
            
            let bNodeParent =  bNode.parent
            
            bNodeParent?.enumerateChildNodesWithName(bNode.name!, usingBlock: { (curNode, retPtr) -> Void in
                
                let bNodeParent = curNode.parent!
                
                let curPhysBody = curNode.physicsBody!
                
                if !curPhysBody.joints.isEmpty {
                    
                    for var i = curPhysBody.joints.startIndex; i < curPhysBody.joints.endIndex;i++ {
                        let joint: AnyObject = curPhysBody.joints[i]
                        
                        let skJoint = unsafeBitCast(joint, SKPhysicsJoint.self)
                        
                        self.physicsWorld.removeJoint(skJoint)
                    }
                }
                
                
                var pos1 = bNodeParent.convertPoint(curNode.position, toNode: self)
                
                if (curNode == bNode) {
                    impulseDirection = 1
                    extraPlus *= -1
                    
                    bNodeParent.runAction(SKAction.sequence([SKAction.waitForDuration(1.0),SKAction.fadeOutWithDuration(0.5),SKAction.runBlock(){
                        [unowned self] in
                        bNode.syDisplayScore(rect: self.playableArea, scoreAddition: 20)
                        }]))
                }
                
                
                curNode.removeFromParent()
                curNode.position = pos1
                self.addChild(curNode)
                
                var v1 = v.normalize()
                v1.dx *= boost * impulseDirection
                v1.dy *= boost * impulseDirection
                boost += extraPlus
                boost = max(1.0,boost)
                
                curPhysBody.categoryBitMask = 0
                curPhysBody.contactTestBitMask = 0
                curPhysBody.collisionBitMask = 0
                
                if (curNode == bNode) {
                    pos1 = bNode.position
                    pos1.x += (CGFloat(Int(arc4random() % 10) * (arc4random() == 1 ? 1 : -1)))
                    pos1.y += (CGFloat(Int(arc4random() % 10) * (arc4random() == 1 ? 1 : -1)))
                }
                else {
                    curPhysBody.applyAngularImpulse(boost/3)
                }
                
                
                
                curPhysBody.applyImpulse(v1, atPoint: pos1)
                
                curNode.runAction(SKAction.sequence([SKAction.waitForDuration(1.0),SKAction.removeFromParent()]))
                
            })
            
            
            self.checkNodeAndDestroyParentOnNeed(bNodeParent, isRope: true)
            
        }
    }

    func didBladeContactWithRope(contact:SKPhysicsContact) -> Bool {
        
        var bladeBody:SKPhysicsBody? = nil
        var ropeBody:SKPhysicsBody? = nil
        
        if (contact.bodyA.categoryBitMask == EntityCategory.Blade) {
            bladeBody = contact.bodyA
        } else if (contact.bodyB.categoryBitMask  == EntityCategory.Blade) {
            bladeBody = contact.bodyB
        }
        
        if (contact.bodyA.categoryBitMask == EntityCategory.Rope) {
            ropeBody = contact.bodyA
        } else if (contact.bodyB.categoryBitMask  == EntityCategory.Rope) {
            ropeBody = contact.bodyB
        }
        
        let isRope = bladeBody != nil && ropeBody != nil
        
        //print("Body category \(body.categoryBitMask)\n Is rope \(isRope)")
        
        if isRope {
            cutRopeUsingImpulse(ropeBody?.node, v: contact.contactNormal)
        }
        
        return isRope
    }

}

 