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
    
    internal static let eSmallInternal = SKAction.playSoundFileNamed("explosion_small.wav", waitForCompletion: false)
    internal static let eLargeInternal = SKAction.playSoundFileNamed("explosion_large.wav", waitForCompletion: false)
    internal static let eLostInternal = SKAction.playSoundFileNamed("lose.wav", waitForCompletion: false)
    internal static let eLapInternal = SKAction.playSoundFileNamed("lap.wav", waitForCompletion: false)
    
    internal static let emptyAction = SKAction.waitForDuration(0)
    
    internal static var explosionSmall:SKAction! {
        get { return !SoundManager.sharedInstance.noSound ? eSmallInternal : emptyAction }
    }
    
    internal static var explosionLarge:SKAction! {
        get { return !SoundManager.sharedInstance.noSound ? eLargeInternal : emptyAction }
    }
    
    internal static var gameOverAction:SKAction! {
        get {return !SoundManager.sharedInstance.noSound ? eLostInternal: emptyAction }
    }
    
    internal static var lapAction:SKAction! {
        get {return !SoundManager.sharedInstance.noSound ? eLapInternal: emptyAction }
    }
    
    private var completionHandler:completionHandlerType? = nil
    private var noSound:Bool = false
    
    internal var soundEffectPlayer: AVAudioPlayer?
    internal var backgroundMusicPlayer: AVAudioPlayer?
    
    internal static var sharedInstance:SoundManager!{
        return manager
    }
    
    private struct Constants {
        static let bgFileName = "backgroundMusic.mp3"
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
    
    //MARK: Background player's methods
    internal func prepareToPlayBGMusic() -> Bool {
        
        let (prepared,player) = self.prepareToPlayEffect(Constants.bgFileName, useSoundEffectPlayer: false)
        
        if prepared && player != nil {
            self.backgroundMusicPlayer = player
        }
        
        return prepared
    }
    
    internal func pauseBGMusic() {
        
        if self.noSound {
            return
        }
        
        if let bgPlayer = self.backgroundMusicPlayer {
            if bgPlayer.playing {
                bgPlayer.pause()
            }
        }
    }
    
    internal func playBGMusic() {
        
        if self.noSound {
            return
        }
        
        if let bgPlayer = self.backgroundMusicPlayer {
            if !bgPlayer.playing {
                bgPlayer.play()
            }
        }
    }
    
    internal func cancelPlayingBGMusic() {
        cancelPlayingEffect(Constants.bgFileName, player: self.backgroundMusicPlayer, resetCompletionHandler: false)
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
        
        cancelPlayingEffect(fileName, player: self.soundEffectPlayer)
    }
    
    private func cancelPlayingEffect(fileName:String?,player:AVAudioPlayer?,resetCompletionHandler:Bool = true) {
        
        if (self.noSound && player == nil) {
            return
        }
        
        var url = fileName != nil ? NSBundle.mainBundle().URLForResource(fileName!, withExtension: nil) : player?.url
        if (url == nil) {
            println("Could not find file: \(fileName) or there is nothing to cancel")
            return
        }
        
        
        if let curPlayer = player {
            if !curPlayer.url.isEqual(url) {
                return
            }
            if (curPlayer.playing) {
                curPlayer.stop()
            }
            
            if resetCompletionHandler {
                self.completionHandler = nil
            }
        }
    }
    
    private func prepareToPlayEffect(fileName:String?,useSoundEffectPlayer:Bool = true) -> (prepared:Bool,player:AVAudioPlayer?) {
        
        if (self.noSound) {
            return (true,nil)
        }
        
        let url = fileName != nil ? NSBundle.mainBundle().URLForResource(fileName!, withExtension: nil) : (useSoundEffectPlayer ? self.soundEffectPlayer?.url : nil)
        if (url == nil) {
            println("Could not find file: \(fileName) or there is nothing to cancel")
            return (false,nil)
        }
        
        if useSoundEffectPlayer {
            if let curPlayer = self.soundEffectPlayer {
                if curPlayer.url.isEqual(url) {
                    return (true,curPlayer)
                }
            }
        }
        
        var error: NSError? = nil
        let player = AVAudioPlayer(contentsOfURL: url, error: &error)
        if let cPlayer = player {
            if useSoundEffectPlayer {
                cPlayer.delegate = self
            }
            cPlayer.numberOfLoops = 0
            let res = cPlayer.prepareToPlay()
            return (res,player)
            
        } else {
            println("Could not create audio player: \(error!)")
            return (false,nil)
        }
    }
    
    internal func prepareToPlayEffect(fileName:String?) -> Bool {
        
        let (prepared,player) = prepareToPlayEffect(fileName)
        
        if player != nil {
            self.soundEffectPlayer = player
        }
        
        return prepared
    }
    
    //MARK: AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer!, successfully flag: Bool) {
        //MARK: TODO not called if there is an interruption...
        assert((player.delegate as! SoundManager) == self,"player.delegate != self")
        
        self.completionHandler?(url: player.url,successfully: flag)
    }

}
