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
    case None
    case BlackHole
    case SpaceShip
    case Transmitter
}

protocol EnemiesGeneratorDelegate:NSObjectProtocol {
    func enemiesGenerator(generator:EnemiesGenerator, didProduceItems:[SKNode!], type:EnemyType)
    func didDissappearItemForEnemiesGenerator(generator:EnemiesGenerator, item:SKNode!, type:EnemyType)
}

class EnemiesGenerator: NSObject {
    
    private let playableRect:CGRect
    private var canFire:Bool = true
    private var timer:NSTimer!
    weak var delegate:EnemiesGeneratorDelegate?
    
    private var isTransmitterPresent:Bool = false
    private var currentCount:UInt = 0
    internal static let sTransmitterNodesCount:UInt = 10
    
    init(playableRect rect:CGRect, andDelegate delegate:EnemiesGeneratorDelegate?) {
        self.playableRect = rect
        self.delegate = delegate
        super.init()
        self.redifineTimer()
        self.stop()
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
        
        
        let isBlackHole = !isTransmitterPresent && arc4random()%2 == 1 //MARK: TODO add support of spaceships
        
        var nodes = [SKNode]()
        var type:EnemyType = .None
        
        if (isBlackHole) {
            nodes.append(produceBlackHoleItem())
            type = .BlackHole
        }
        else if (!isTransmitterPresent) {
            nodes.append(produceTransmitter())
            type = .Transmitter
        }
        else if (self.currentCount != EnemiesGenerator.sTransmitterNodesCount){
            assert(isTransmitterPresent)
            type = .SpaceShip
            
            var curCount:UInt = 0
            if (currentCount == 0 ) {
                //generate 2 items..
                curCount = 2
            } else if (currentCount == 2) {
                //generate 3 items...
                curCount = 3
            } else if (currentCount == 5) {
                //generate 3 items...
                curCount = 3
            }else if (currentCount == 8) {
                curCount = 2
                //generate 2 items...
            }
            let items = produceEnemiesSpaceShips(curCount)
            for item in items {
                nodes.append(item)
            }
            
        } else if (isTransmitterPresent) {
            isTransmitterPresent = false
            //TODO: remove transmitter
        }
        
        if (type != .None) {
            self.delegate?.enemiesGenerator(self, didProduceItems: nodes, type: type)
        }
        /*if (isTransmitterPresent && self.currentCount == EnemiesGenerator.sEnemiesInSerieCount) {
            
            self.isTransmitterPresent = false
            //Finished items generation...
            
            //didDissappearItemForEnemiesGenerator
        }*/
    }
    
    func didFinishWithCurrentSpaceShipChunk() -> Bool {
        return didFinishWithSpaceShipChunk(0)
    }
    
    func didFinishWithSpaceShipChunk(count:UInt) -> Bool {
        self.currentCount += count
        
        let isSerieOver = currentCount == EnemiesGenerator.sTransmitterNodesCount
        
        if (currentCount == 2 || currentCount == 5 || currentCount == 8 || isSerieOver) {
            
            if isSerieOver {
                self.delegate?.didDissappearItemForEnemiesGenerator(self, item: nil, type: .Transmitter)
                self.isTransmitterPresent = false
            }
            
            return true
        }
        else {
            return false
        }
    }
    
    private func produceEnemiesSpaceShips(count:UInt) -> [EnemySpaceShip]! {
        
        var result = [EnemySpaceShip]()
        
        for i in 0...count - 1 {
            
            let enemy = EnemySpaceShip()
            
            let yPos = CGFloat( arc4random() % UInt32(CGRectGetHeight(self.playableRect) - enemy.size.height) )
            let xPos = CGRectGetWidth(self.playableRect)
            enemy.position = CGPointMake(xPos, yPos)
            
            result.append(enemy)
        }
        return result
    }
    
    private func produceTransmitter() -> SKNode! {
        self.isTransmitterPresent  = true
        self.currentCount = 0
        let w = CGRectGetWidth(self.playableRect) * 0.2
        let h = CGRectGetHeight(self.playableRect) * 0.05
        
        let transmitter = Transmitter(transmitterSize: CGSizeMake(w, h), beamHeight: CGRectGetHeight(self.playableRect))
        transmitter.position  = CGPointMake(CGRectGetWidth(self.playableRect), CGRectGetHeight(self.playableRect))
        return transmitter
    }
    
    private func produceBlackHoleItem() -> SKNode! {
        
        let hole = BlackHole()
        
        let r = round(hole.size.halfMaxSizeParam())
        
        let nRect = CGRectInset(self.playableRect, r, r)
        
        let x = CGFloat(arc4random() % UInt32(CGRectGetWidth(nRect))) + CGRectGetMinX(nRect)
        let y = CGFloat(arc4random() % UInt32(CGRectGetHeight(nRect))) + CGRectGetMinY(nRect)
        
        let position = CGPointMake(x, y)
        println("!!nRect \(nRect) Position \(position)")
        hole.position = position
        
        return hole
    }
    
    internal func signalItemAppearance(node:SKNode!, type:EnemyType) {
        
        if (type == .BlackHole) {
            
            if let hole = node as? BlackHole {
            
                hole.presentHole(){
                    [unowned self] in
                    self.delegate?.didDissappearItemForEnemiesGenerator(self,item:hole,type:.BlackHole)
                }
                
            }
        }
    }
    
    
}
