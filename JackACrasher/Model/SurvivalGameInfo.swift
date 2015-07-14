//
//  SurvivalGameInfo.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 7/14/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit

class SurvivalGameInfo: NSObject {
   
    typealias survivalNumberOfLives = Int
    
    internal var currentScore:Int64 = 0
    internal var playedTime:NSTimeInterval = 0
    internal var ratio:Float = 0
    internal var numberOfLives:survivalNumberOfLives = 0
    
}
