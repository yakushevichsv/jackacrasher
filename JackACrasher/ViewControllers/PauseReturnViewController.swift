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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let disabled = GameLogicManager.sharedInstance.gameSoundDisabled()
        
        self.btnSound.selected = !disabled
        self.buttonPressed(self.btnSound)
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
            self.dismissViewControllerAnimated(true, completion:nil)
        }
    }

}
