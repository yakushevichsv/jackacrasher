//
//  GameLogicController.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 5/12/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit

enum GameLogicSelectedStrategy : Int {
    case None = 0, Survival = 1, Company = 2, Help = 3
}


class GameLogicManager: NSObject {
    
    private var state:GameLogicSelectedStrategy = .None
    private var scoreValue:Float = 0
    private static var gSharedController:GameLogicManager!
    
    internal func resetState() {
        self.state = .None
    }
    
    
    
    internal var sharedInstance:GameLogicManager
    {
        if (GameLogicManager.gSharedController == nil) {
            var sharedPredicate:dispatch_once_t = 0
            dispatch_once(&sharedPredicate, { () -> Void in
                GameLogicManager.gSharedController = GameLogicManager()
            })
        }
        return GameLogicManager.gSharedController
    }
    
    
    //MARK: Survival
    internal func selectSurvival() {
        self.state = .Survival
        
        
    }
    
}

//MARK: Score's extension
extension GameLogicManager
{
    private struct Constants {
        static var  SurvivalScore = "SurvivalScore"
        static var  SurvivalPlayedNumber = "SurvivalPlayedNumber"
    }
    
    //MARK: Survival
    private func storeInDefaultsSurvivalScore(score:Int) {
        NSUserDefaults.standardUserDefaults().setInteger(score, forKey: Constants.SurvivalScore)
    }
    
    private func storeInDefaultsSurvivalPlayerdNumber(playedNumber:Int) {
        NSUserDefaults.standardUserDefaults().setInteger(playedNumber, forKey: Constants.SurvivalPlayedNumber)
    }
    
    private func storeInDefaultsSurvivalInfo(info:[Int]) {
        assert(info.count == 2, "not all items are presented!")
        let score = info[0]
        let numberOfGames = info[1]
        storeInDefaultsSurvivalScore(score)
        storeInDefaultsSurvivalPlayerdNumber(numberOfGames)
    }
    
    private func getFromDefautsSurvivalInfo() {
        
    }
    
    
}
