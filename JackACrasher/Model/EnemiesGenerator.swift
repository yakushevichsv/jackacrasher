//
//  EnemiesGenerator.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 7/22/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit
import SpriteKit

/*
 Class used for generating black hole & animies ..
*/

enum EnemyType {
    case BlackHole
    case SpaceShip
}

protocol EnemiesGeneratorDelegate:NSObjectProtocol {
    func enemiesGenerator(generator:EnemiesGenerator, didProduceItems:[SKNode], type:EnemyType)
    func didDissappearItemForEnemiesGenerator(generator:EnemiesGenerator, item:SKNode, type:EnemyType)
}

class EnemiesGenerator: NSObject {
    
    private let playableRect:CGRect
    private var canFire:Bool = true
    private var timer:NSTimer!
    weak var delegate:EnemiesGeneratorDelegate?
    
    init(playableRect rect:CGRect, andDelegate delegate:EnemiesGeneratorDelegate?) {
        self.playableRect = rect
        self.delegate = delegate
        super.init()
        self.redifineTimer()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    internal var paused:Bool = false {
        didSet {
            let didChange = (paused != oldValue)
            if (paused) {
                if (didChange) {
                    self.stop()
                }
            }
            else {
                if (didChange || !paused) {
                    self.start()
                }
            }
        }
    }

    
    internal func start() {
        canFire = true
        if !self.timer.valid {
            redifineTimer()
        }
    }
    
    internal func stop() {
        
        if (self.timer.valid) {
            self.timer.invalidate()
        }
        canFire = false
    }
    
    private func redifineTimer() {
        if let lTimer = timer {
            if lTimer.valid {
                lTimer.invalidate()
            }
        }
        timer = NSTimer.scheduledTimerWithTimeInterval(3, target: self, selector: "generateItem", userInfo: nil, repeats: true)
    }
    
    internal func generateItem() {
        
        if (self.paused || !self.canFire) {
            return
        }
        
        self.canFire = false
        
        let isBlackHole = true //arc4random()%2 == 1 //MARK: TODO add support of spaceships
        
        var node:SKNode!
        
        if (isBlackHole) {
            node = produceBlackHoleItem()
        }
        else {
            node = nil
        }
        
        self.delegate?.enemiesGenerator(self, didProduceItems: [node], type: .BlackHole)
    }
    
    
    private func produceBlackHoleItem() -> SKNode! {
        
        let hole = BlackHole()
        
        let r = CGFloat(roundf(Float(0.5*max(hole.frame.size.width,hole.frame.size.height))))
        let nRect = CGRectInset(self.playableRect, r, r)
        
        let x = arc4random() % UInt32(CGRectGetWidth(nRect))
        let y = arc4random() % UInt32(CGRectGetHeight(nRect))
        
        let position = CGPointMake(CGFloat(x), CGFloat(y))
        hole.position = position
        
        return hole
    }
    
    internal func signalItemAppearance(node:SKNode!, type:EnemyType) {
        
        if (type == .BlackHole) {
            
            if let hole = node as? BlackHole {
            
                hole.signalAppearance(){
                    [unowned self] in
                    let seq = SKAction.sequence([SKAction.waitForDuration(4),SKAction.runBlock(){
                        self.delegate?.didDissappearItemForEnemiesGenerator(self,item:hole,type:.BlackHole)
                        },SKAction.removeFromParent()])
                    hole.runAction(seq)
                }
                
            }
        }
    }
    
    
}
