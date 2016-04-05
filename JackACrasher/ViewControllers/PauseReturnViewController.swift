//
//  PauseReturnViewController.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 7/26/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit

class PauseReturnViewController: UIViewController {

    
    @IBOutlet weak var btnExit:UIButton!
    @IBOutlet weak var btnClose:UIButton!
    @IBOutlet weak var btnPause:UIButton!
    @IBOutlet weak var btnSound:UIButton!
    
    
    var exitCompletion:dispatch_block_t? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        correctSoundButton()
        
        correctFontOfChildViews(self.view,reduction: UIApplication.sharedApplication().isRussian ? 4 : 0)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    @IBAction func buttonPressed(sender:UIButton) {
        if sender == self.btnSound {
            
            sender.selected = sender.selected ? false : true
            
            let disabled = sender.selected
            
            //selected = no sound
            if disabled {
                SoundManager.sharedInstance.disableSound()
                ODRManager.sharedManager.endAcessingRequest(GameLogicManager.ODRConstants.soundSet)
                GameLogicManager.sharedInstance.storeGameSoundInfo(disabled)
            } else {
                if (!disabled) {
                    
                    dispatch_async(dispatch_get_main_queue()){
                        sender.enabled = false
                    }
                    
                    ODRManager.sharedManager.startUsingpResources(GameLogicManager.ODRConstants.soundSet, intermediateHandler: { (fraction) -> Void in
                        
                        }, completionHandler: { (error) -> Void in
                            
                            dispatch_async(dispatch_get_main_queue()){
                            if error == nil {
                                
                                SoundManager.sharedInstance.enableSound()
                                SoundManager.sharedInstance.prepareToPlayEffect("backgroundMusic.mp3")
                                GameLogicManager.sharedInstance.storeGameSoundInfo(false)
                            }
                            else {
                                GameLogicManager.sharedInstance.storeGameSoundInfo(true)
                            }
                            
                                sender.enabled = true
                            }
                    })
                }
            }

            return
        }
        else {
            
            if sender == self.btnExit && exitCompletion != nil {
                exitCompletion!()
                exitCompletion = nil
            }
            
            self.dismissViewControllerAnimated(true, completion:nil)
        }
    }
    
    func correctSoundButton() {
        let disabled = GameLogicManager.sharedInstance.gameSoundDisabled()
        
        self.btnSound.selected = !disabled
        self.buttonPressed(self.btnSound)
    }

}
