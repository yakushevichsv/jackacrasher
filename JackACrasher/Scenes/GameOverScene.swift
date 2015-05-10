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
            var sceneData = NSData(contentsOfFile: path, options: .DataReadingMappedIfSafe, error: nil)!
            var archiver = NSKeyedUnarchiver(forReadingWithData: sceneData)
            
            archiver.setClass(self.classForKeyedUnarchiver(), forClassName: "SKScene")
            let scene = archiver.decodeObjectForKey(NSKeyedArchiveRootObjectKey) as! GameOverScene
            archiver.finishDecoding()
            return scene
        } else {
            return nil
        }
    }
}

class GameOverScene: SKScene {
   
    private struct Constants {
        static var GameOverLabel:String = "lblGameOver"
        static var GameOverMoveDuration:NSTimeInterval = 2
        static var GameOverFadeInDuration:NSTimeInterval = Constants.GameOverMoveDuration
        static var GameOverActGroup = "GameOverActGroup"
    }
    
    weak var gameOverDelegate: GameOverSceneDelegate?
    
    private var gameOverLabel:SKLabelNode!
    
    
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
        
        self.gameOverLabel = childNodeWithName(Constants.GameOverLabel) as! SKLabelNode
        self.gameOverLabel.hidden = true
        self.gameOverLabel.fontName = "Game_Robot.ttf"
    }

    override func didMoveToView(view: SKView) {
        super.didMoveToView(view)
        
        if (!didWin) {
            displayGameOver()
        }
        
    }
    
    private func displayGameOver() {
        
        let gameOverActGroup = Constants.GameOverActGroup
        
        if (self.gameOverLabel.actionForKey(gameOverActGroup) != nil) {
            return
        }
        
        let h = CGRectGetHeight(self.gameOverLabel.frame)*0.5
        
        
        self.gameOverLabel.position = CGPoint(x: self.size.width * 0.5, y: -h)
        self.gameOverLabel.hidden = false
        self.gameOverLabel.alpha = 0.0
        
        let moveAct = SKAction.moveToY(self.size.height*0.5, duration: Constants.GameOverMoveDuration)
        
        let fadeIn = SKAction.fadeInWithDuration(Constants.GameOverFadeInDuration)
        
        let group = SKAction.group([moveAct,fadeIn])
        
        let seq = SKAction.sequence([group,SKAction.runBlock({ () -> Void in
            self.gameOverDelegate?.gameOverScene(self, didDisplayLabelWithFrame: self.gameOverLabel.frame)
        }),SKAction.playSoundFileNamed("lose.wav", waitForCompletion: false)])
        
        self.gameOverLabel.runAction(seq, withKey: gameOverActGroup)
    }
    
}
