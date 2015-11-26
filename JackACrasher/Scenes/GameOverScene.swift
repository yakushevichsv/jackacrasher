//
//  GameOverScene.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 5/9/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit
import SpriteKit

@objc protocol GameOverSceneDelegate {
    func gameOverScene(scene:GameOverScene, didDisplayLabelWithFrame:CGRect)
}

extension GameOverScene {
    class func unarchiveFromFile(file : NSString) -> SKNode? {
        if let path = NSBundle.mainBundle().pathForResource(file as String, ofType: "sks") {
            
            do {
               let sceneData = try  NSData(contentsOfFile: path, options: .DataReadingMappedIfSafe)
                
                let archiver = NSKeyedUnarchiver(forReadingWithData: sceneData)
                
                archiver.setClass(self.classForKeyedUnarchiver(), forClassName: "SKScene")
                let scene = archiver.decodeObjectForKey(NSKeyedArchiveRootObjectKey) as! GameOverScene
                archiver.finishDecoding()
                return scene
            }
            catch {
                return nil
            }
            
        } else {
            return nil
        }
    }
}

class GameOverScene: SKScene,SKPhysicsContactDelegate {
   
    private struct Constants {
        static var GameOverLabel:String = "lblGameOver"
        static var GameOverMoveDuration:NSTimeInterval = 2
        static var GameOverFadeInDuration:NSTimeInterval = Constants.GameOverMoveDuration
        static var GameOverActGroup = "GameOverActGroup"
        static var EnemyShip1Name  = "enemy1"
        static var EnemyShip2Name = "enemy2"
        static var EnemyShip3Name = "enemy3"
        static var EnemyShip4Name = "enemy4"
        static var PlayerName     = "astronaut"
        static var bulletName     = "bullet"
    }
    
    
    @IBOutlet weak var enemyShip1:SKSpriteNode!
    @IBOutlet weak var enemyShip2:SKSpriteNode!
    @IBOutlet weak var enemyShip3:SKSpriteNode!
    @IBOutlet weak var enemyShip4:SKSpriteNode!
    @IBOutlet weak var player:SKSpriteNode!
    
    private var playableArea:CGRect = CGRectZero
    
    weak var gameOverDelegate: GameOverSceneDelegate?
    
    private var gameOverLabel:SKLabelNode!
    private var attackCount:UInt = 0
    private var playerHealthCount:UInt = 10
    
    private var canAttackPlayer:Bool = true
    
    private var canShoot:Bool = false
    private var timer:NSTimer!
    
    var didWin:Bool = false {
        didSet {
            if (didWin != oldValue) {
                // TODO : display label...
                if (!didWin) {
                    displayGameOver()
                }
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.size = UIScreen.mainScreen().bounds.size
        
        self.gameOverLabel = childNodeWithName(Constants.GameOverLabel) as! SKLabelNode
        self.gameOverLabel.hidden = true
        
        self.enemyShip1 = self.childNodeWithName(Constants.EnemyShip1Name) as! SKSpriteNode!
        self.enemyShip2 = self.childNodeWithName(Constants.EnemyShip2Name) as! SKSpriteNode!
        self.enemyShip3 = self.childNodeWithName(Constants.EnemyShip3Name) as! SKSpriteNode!
        self.enemyShip4 = self.childNodeWithName(Constants.EnemyShip4Name) as! SKSpriteNode!
        self.player     = self.childNodeWithName(Constants.PlayerName) as! SKSpriteNode!
        
    }

    override func didMoveToView(view: SKView) {
        super.didMoveToView(view)
        
        self.definePlayableRect()
        
        if (!didWin) {
            displayGameOver()
            attackPlayer()
        }
        
        correctLabelText(self)
    }
    
    private func attackPlayer() {
        
        self.physicsWorld.contactDelegate = self
        
        self.player.position = CGPointMake(self.size.halfWidth(), self.size.halfHeight())
        self.player.physicsBody?.contactTestBitMask = 2
        self.enemyShip1.position = CGPointMake(CGRectGetMinX(self.playableArea), CGRectGetMinY(self.playableArea))
        self.enemyShip2.position = CGPointMake(CGRectGetMinX(self.playableArea), CGRectGetMaxY(self.playableArea))
        self.enemyShip3.position = CGPointMake(CGRectGetMaxX(self.playableArea), CGRectGetMaxY(self.playableArea))
        self.enemyShip4.position = CGPointMake(CGRectGetMaxX(self.playableArea), CGRectGetMinY(self.playableArea))
        
        for attacker in [self.enemyShip1,self.enemyShip2,self.enemyShip3,self.enemyShip4] {
            createMoveActionForEnemy(attacker)
        }
        
        self.timer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "produceEnemyBullets", userInfo: nil, repeats: true)
    }
    
    private func createMoveActionForEnemy(attacker:SKSpriteNode!) {
        
        let playerPos = self.player.position
        let distDiff = (attacker.position - playerPos)
        
        let distance = distDiff.length()
        
        if distDiff.x > 0 {
            attacker.xScale = 1.0
        }
        else {
            attacker.xScale = -1.0
        }
        
        let act = SKAction.moveTo(playerPos, duration: NSTimeInterval(distance/EnemySpaceShip.Constants.speed))
        attacker.runAction(act)
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        
        //TODO: add contact here....
        
        var playerNode:SKSpriteNode! = nil
        var attackerBullet:SKSpriteNode! = nil
        
        if let node1 = contact.bodyA.node as? SKSpriteNode {
            if self.player != nil && node1 == self.player {
                playerNode = node1
                attackerBullet = contact.bodyB.node as? SKSpriteNode
            }
        } else if let node1 = contact.bodyB.node as? SKSpriteNode {
            if self.player != nil && node1 == self.player {
                playerNode = node1
                attackerBullet = contact.bodyA.node as? SKSpriteNode
            }
        }
        
        if playerNode != nil  {
            // In contact player is used...
            
            let damage = Player.sDamageEmitter.copy() as! SKEmitterNode
            
            damage.position = self.player.position
            damage.zPosition = self.zPosition + 1
            addChild(damage)
            
            runOneShortEmitter(damage, duration: 0.4)
            attackerBullet?.removeFromParent()
            
            if self.playerHealthCount > 0 {
                self.playerHealthCount--
            }
            
            if self.playerHealthCount == 0 {
                self.timer.invalidate()
                var interval:NSTimeInterval = 0.2
                for attacker in [self.enemyShip1,self.enemyShip2,self.enemyShip3,self.enemyShip4] {
                    attacker.removeAllActions()
                    attacker.physicsBody?.contactTestBitMask = 0
                    
                    attacker.runAction(SKAction.sequence([SKAction.waitForDuration(interval),SKAction.removeFromParent()]))
                    interval += 0.1
                }
                
                for node in self.children {
                    if node.name != nil && node.name! == Constants.bulletName {
                        node.removeFromParent()
                    }
                }
                
                self.player.physicsBody?.contactTestBitMask = 0
                self.player.runAction(SKAction.sequence([SKAction.waitForDuration(0.1),SKAction.removeFromParent()]))
            }
        }
    }
    
    internal func produceEnemyBullets() {
        for curNode in [self.enemyShip1,self.enemyShip2,self.enemyShip3,self.enemyShip4] {
            produceEnemyBullet(curNode)
        }
    }
    
    override func didEvaluateActions() {
        
        if self.canShoot {
            
            self.canShoot = false
            
            for attacker in [self.enemyShip1,self.enemyShip2,self.enemyShip3,self.enemyShip4] {
                
            let bullet = EnemySpaceShip.sEnemyBulltet.copy() as! SKSpriteNode
            let sPoint = attacker.position
            let tPoint = self.player.position
            
            let diff = tPoint - sPoint
            let extraY = abs(diff.x) >= 1 ? tPoint.x * tan(diff.angle) : tPoint.y
            
            let extraLen = abs(abs(diff.x) >= 1 ? tPoint.x/cos(diff.angle) : extraY)
            
            let length = diff.length()
            
        
            let duration = (distanceBetweenPoints(sPoint, point2: tPoint) + extraLen)/(EnemySpaceShip.Constants.laserSpeed * 5)
        
            print("Attacker \(attacker)\n Lenght \(length) Duration \(duration)")
                
                
            let moveToAction = SKAction.moveTo(tPoint, duration: NSTimeInterval(duration))
            let removeAction = SKAction.removeFromParent()
            bullet.position = sPoint
            
            print("Bullet from point \(sPoint) to point: \(tPoint)")
            
            addChild(bullet)
            bullet.runAction(SKAction.sequence([moveToAction,removeAction]))
            bullet.zRotation = diff.angle
            bullet.name = Constants.bulletName
                
            }
            
        }
    }
    
    private func produceEnemyBullet(attacker:SKSpriteNode!) {
        
        if canAttackPlayer {
            
            self.attackCount++
            
            if self.attackCount == 4 {
                canAttackPlayer = false
                self.canShoot = true
            }
        }
        else {
            self.attackCount--
            
            if self.attackCount == 0 {
                canAttackPlayer = true
                self.canShoot = false
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
    
    private func displayGameOver() {
        
        let gameOverActGroup = Constants.GameOverActGroup
        
        if (self.gameOverLabel.actionForKey(gameOverActGroup) != nil) {
            return
        }
        
        let h = CGRectGetHeight(self.gameOverLabel.frame)*0.5
        
        
        self.gameOverLabel.position = CGPoint(x: CGRectGetMidX(self.playableArea), y: -h)
        self.gameOverLabel.hidden = false
        self.gameOverLabel.alpha = 0.0
        
        if (isPhone4s() || isPhone5s()) {
            self.gameOverLabel.fontSize = self.gameOverLabel.fontSize - 15
        }
        
        
        let moveAct = SKAction.moveToY(CGRectGetMidY(self.playableArea), duration: Constants.GameOverMoveDuration)
        
        let fadeIn = SKAction.fadeInWithDuration(Constants.GameOverFadeInDuration)
        
        let group = SKAction.group([moveAct,fadeIn])
        
        let seq = SKAction.sequence([group,SKAction.runBlock({ () -> Void in
            self.gameOverDelegate?.gameOverScene(self, didDisplayLabelWithFrame: self.gameOverLabel.frame)
        }),SoundManager.gameOverAction])
        
        self.gameOverLabel.runAction(seq, withKey: gameOverActGroup)
    }
    
}
