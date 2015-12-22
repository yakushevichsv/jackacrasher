//
//  EnemiesGenerator.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 7/22/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

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
    private var transmitterTime:NSTimeInterval = 0
    
    private var transmitterDistr:GKRandomDistribution! = nil
    
    private var isTransmitterPresent:Bool {
        return transmitter != nil
    }
    
    private var currentCount:UInt = 0
    private var chunks = [UInt]()
    private weak var transmitter:Transmitter? = nil
    private var transmitterNodesCount:UInt = 0
    
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
        //generateItem()
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
        timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "generateItem", userInfo: nil, repeats: true)
    }
    
    internal func generateItem() {
        
        if (self.paused || !self.canFire) {
            return
        }
        
        self.canFire = false
        
        let isSerieOver = self.isTransmitterSerieOver
        
        
        
        let isBlackHole = !isTransmitterPresent && ( isSerieOver ? arc4random() % 3 <= 2 : arc4random() % 2 == 1 )
        
        if (isSerieOver) {
            self.resetTransmitterItems()
        }
        
        var nodes = [SKNode]()
        var type:EnemyType = .None
        
        if (isBlackHole) {
            nodes.append(produceBlackHoleItem())
            type = .BlackHole
        }
        else if (!isTransmitterPresent) {
            
            if (NSDate.timeIntervalSinceReferenceDate() - self.transmitterTime < 20 ){
                generateItem()
                return
            }
            print("Transmitter was produced")
            nodes.append(produceTransmitter())
            self.setNextTransmittersCount()
            type = .Transmitter
        }
        else if !isSerieOver {
            assert(isTransmitterPresent)
            type = .SpaceShip
            
            let finalCount = self.chuncksCount
            
            var curCount:UInt = 0
            let diff = self.transmitterNodesCount - finalCount
            if diff < self.maxTransmitterChunckCount  && diff > 0 {
                curCount = diff
                
                self.transmitterTime = NSDate.timeIntervalSinceReferenceDate()
            }
            else if (currentCount == finalCount) {
                curCount = UInt(self.transmitterDistribution.nextIntWithUpperBound(Int(self.transmitterDistribution.lowestValue) + Int(self.maxTransmitterChunckCount - 1)) + 1 - self.transmitterDistribution.lowestValue)
            }
            
            print("Number of items to display \(curCount)\n Total number of items final \(finalCount)\n Maximum number \(self.transmitterNodesCount)")
            
            currentCount += curCount
            if (curCount != 0) {
                self.chunks.append(curCount)
            
                let items = produceEnemiesSpaceShips(curCount,last: self.isTransmitterSerieOver)
                for item in items {
                    nodes.append(item)
                }
            }
            else {
                type = .None
            }
            
        } else if (isTransmitterPresent) {
            self.transmitter = nil
            self.delegate?.didDissappearItemForEnemiesGenerator(self, item: nil, type: .Transmitter)
            return
        }
        
        if (type != .None) {
            self.delegate?.enemiesGenerator(self, didProduceItems: nodes, type: type)
        }
    }
    
    func didFinishWithCurrentSpaceShipChunk() -> Bool {
        return didFinishWithSpaceShipChunk(0)
    }
    
    func didFinishWithSpaceShipChunk(count:UInt) -> Bool {
        self.currentCount += count
        
        let isSerieOver = self.isTransmitterSerieOver
        
        let finalCount = self.chuncksCount
        
        
        if (currentCount == finalCount || isSerieOver) {
            if isSerieOver {
                self.delegate?.didDissappearItemForEnemiesGenerator(self, item: nil, type: .Transmitter)
                self.transmitter = nil
            }
            
            return true
        }
        else {
            return false
        }
    }
    
    private func produceEnemiesSpaceShips(count:UInt, last:Bool = false) -> [EnemySpaceShip]! {
        
        var result = [EnemySpaceShip]()
        var curPart:CGFloat = 0
        let allowedPart = CGRectGetHeight(self.playableRect)/CGFloat(count)
        
        if count == 0 {
            return result
        }
        
        for i in 0...count - 1 {
            
            var enemy = last ? MotionlessEnemySpaceShip() : EnemySpaceShip()
            
            if i == count/2 {
                enemy = KamikadzeSpaceShip()
            }
            
            let yPos = randomBetween(curPart, y2: curPart + allowedPart - enemy.size.height)
            
            let xPos = CGRectGetWidth(self.playableRect)
            enemy.position = CGPointMake(xPos, yPos)
            
            result.append(enemy)
            
            curPart += allowedPart
        }
        return result
    }
    
    private func produceTransmitter() -> SKNode! {
        let w = CGRectGetWidth(self.playableRect) * 0.2
        let h = CGRectGetHeight(self.playableRect) * 0.05
        
        let transmitter = Transmitter(transmitterSize: CGSizeMake(w, h), beamHeight: CGRectGetHeight(self.playableRect))
        transmitter.position  = CGPointMake(CGRectGetWidth(self.playableRect), CGRectGetHeight(self.playableRect))
        self.transmitter  = transmitter
        
        self.transmitterTime = NSDate.timeIntervalSinceReferenceDate()
        
        return transmitter
    }
    
    private func produceBlackHoleItem() -> SKNode! {
        
        let hole = BlackHole()
        
        let r = round(hole.size.halfMaxSizeParam())
        
        let nRect = CGRectInset(self.playableRect, r, r)
        
        let x = CGFloat(arc4random() % UInt32(CGRectGetWidth(nRect))) + CGRectGetMinX(nRect)
        let y = CGFloat(arc4random() % UInt32(CGRectGetHeight(nRect))) + CGRectGetMinY(nRect)
        
        let position = CGPointMake(x, y)
        print("!!nRect \(nRect) Position \(position)")
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
    
    //MARK: Debug functions
    
    internal func appendToSceneBlackHoleAtPosition(position:CGPoint) {
    
        let node = produceBlackHoleItem() as! BlackHole
        node.position = position
        if let scene = self.delegate as? GameScene {
            scene.addChild(node)
            node.presentHole() {
                
            }
        }
    }
    
}

//MARK: Generators

extension EnemiesGenerator {
    
    private var transmitterDistribution: GKRandomDistribution! {
        get {
            
            if (self.transmitterDistr == nil) {
                
                
                let source = GKARC4RandomSource()
                
                
                self.transmitterDistr = GKRandomDistribution(randomSource: source, lowestValue: Int(self.maxTransmitterChunckCount*2), highestValue: Int(self.maxTransmitterChunckCount*4))
            }
            return self.transmitterDistr
        }
    }
    
    private var maxTransmitterChunckCount:UInt {
        get {
            return 4
        }
    }
    
    private func setNextTransmittersCount() {
        
        self.transmitterNodesCount =  UInt(self.transmitterDistribution.nextInt())
    }
    
    private var isTransmitterSerieOver:Bool {
        get {
            return self.transmitterNodesCount == self.currentCount && self.transmitterNodesCount != 0
        }
    }
    
    private func resetTransmitterItems() {
        self.chunks.removeAll()
        self.currentCount = 0
    }
    
    
    private var chuncksCount:UInt {
        
        var finalCount:UInt = 0
        for item in self.chunks {
            finalCount += item
        }
        return finalCount
    }
}

