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

class SoundManager: NSObject, AVAudioPlayerDelegate {
   
    typealias completionHandlerType = ((url:NSURL?, successfully:Bool) ->Void)
    
    internal static let explosionSmall = SKAction.playSoundFileNamed("explosion_small.wav", waitForCompletion: false)
    
    internal static let explosionLarge = SKAction.playSoundFileNamed("explosion_large.wav", waitForCompletion: false)
    
    private var completionHandler:completionHandlerType? = nil
    private var noSound:Bool = false
    
    internal var soundEffectPlayer: AVAudioPlayer?
    
    internal static var sharedInstance:SoundManager!{
        return manager
    }
    
    //MARK: Enable & Disable sound
    
    internal func disableSound() {
        setSoundState(false)
    }
    
    internal func enableSound() {
        setSoundState(true)
    }
    
    private func setSoundState(enabled:Bool) {
        if (!enabled) {
            cancelPlayingEffect(nil)
            self.completionHandler = nil
            noSound = true
        }
        else {
            noSound = false
        }
    }
    
    //MARK: Play & stop audio
    
    internal func playPreloadedSoundEffect(completionHandler handler:completionHandlerType?) -> Bool {
        return playSoundEffect(nil, completionHandler: handler)
    }
    
    internal func playSoundEffect(fileName: String?,completionHandler handler:completionHandlerType?) -> Bool {
        
        if (self.noSound) {
             handler?(url: nil,successfully: true)
            return true
        }
        
        var res:Bool = false
        if prepareToPlayEffect(fileName) {
            if let player = self.soundEffectPlayer {
                if !player.playing {
                    res = self.soundEffectPlayer!.play()
                    if (res) {
                        self.completionHandler = handler
                    }
                }
                else {
                    handler?(url:player.url ,successfully: false)
                    res = true
                }
            }
        }
        return res
    }
    
    internal func cancelPlayingEffect(fileName:String?) {
        
        if (self.noSound && self.soundEffectPlayer == nil) {
            return
        }
        
        var url = fileName != nil ? NSBundle.mainBundle().URLForResource(fileName!, withExtension: nil) : self.soundEffectPlayer?.url
        if (url == nil) {
            println("Could not find file: \(fileName) or there is nothing to cancel")
            return
        }
        
        
        if let curPlayer = self.soundEffectPlayer {
            if !curPlayer.url.isEqual(url) {
                return
            }
            if (curPlayer.playing) {
                curPlayer.stop()
            }
            self.completionHandler = nil
        }
    }
    
    internal func prepareToPlayEffect(fileName:String?) -> Bool {
        
        if (self.noSound) {
            return true
        }
        
        let url = fileName != nil ? NSBundle.mainBundle().URLForResource(fileName!, withExtension: nil) : self.soundEffectPlayer?.url
        if (url == nil) {
            println("Could not find file: \(fileName) or there is nothing to cancel")
            return false
        }
        
        if let curPlayer = self.soundEffectPlayer {
            if curPlayer.url.isEqual(url) {
                return true
            }
        }
        
        var error: NSError? = nil
        self.soundEffectPlayer = AVAudioPlayer(contentsOfURL: url, error: &error)
        if let player = soundEffectPlayer {
            player.delegate = self
            player.numberOfLoops = 0
            return player.prepareToPlay()
            
        } else {
            println("Could not create audio player: \(error!)")
            return false
        }
    }
    
    //MARK: AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer!, successfully flag: Bool) {
        //MARK: TODO not called if there is an interruption...
        assert((player.delegate as! SoundManager) == self,"player.delegate != self")
        
        self.completionHandler?(url: player.url,successfully: flag)
    }

}
