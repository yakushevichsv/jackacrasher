//
//  SoundManager.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 4/19/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import AVFoundation
import SpriteKit

private let manager = SoundManager()

class SoundManager: NSObject {
   
    internal static let explosionSmall = SKAction.playSoundFileNamed("explosion_small.wav", waitForCompletion: false)
    
    internal static let explosionLarge = SKAction.playSoundFileNamed("explosion_large.wav", waitForCompletion: false)
    
    internal var soundEffectPlayer: AVAudioPlayer?
    
    internal static var sharedInstance:SoundManager!{
        return manager
    }
    
    
    internal func playSoundEffect(filename: String) {
        let url = NSBundle.mainBundle().URLForResource(filename, withExtension: nil)
        if (url == nil) {
            println("Could not find file: \(filename)")
            return
        }
        
        var error: NSError? = nil
        self.soundEffectPlayer = AVAudioPlayer(contentsOfURL: url, error: &error)
        if let player = soundEffectPlayer {
            player.numberOfLoops = 0
            player.prepareToPlay()
            player.play()
        } else {
            println("Could not create audio player: \(error!)")
        }
    }

}
