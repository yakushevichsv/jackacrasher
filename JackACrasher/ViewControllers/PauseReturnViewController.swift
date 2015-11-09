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
        
        correctFontOfChildViews(self.view)
        
        let disabled = GameLogicManager.sharedInstance.gameSoundDisabled()
        
        self.btnSound.selected = !disabled
        self.buttonPressed(self.btnSound)
        
        correctFontOfChildViews(self.view)
    }
    
    @IBAction func buttonPressed(sender:UIButton) {
        if sender == self.btnSound {
            
            sender.selected = sender.selected ? false : true
            
            let disabled = sender.selected
            
            //selected = no sound
            if disabled {
                SoundManager.sharedInstance.disableSound()
            } else {
                SoundManager.sharedInstance.enableSound()
                SoundManager.sharedInstance.prepareToPlayEffect("button_press.wav")
            }
            
            GameLogicManager.sharedInstance.storeGameSoundInfo(disabled)

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

}
