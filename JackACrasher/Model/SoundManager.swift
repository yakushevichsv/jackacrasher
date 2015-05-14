//
//  SoundManager.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 4/19/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit
import SpriteKit

class SoundManager: NSObject {
   
    internal static let explosionSmall = SKAction.playSoundFileNamed("explosion_small.wav", waitForCompletion: false)
    
    internal static let explosionLarge = SKAction.playSoundFileNamed("explosion_large.wav", waitForCompletion: false)
    
}
