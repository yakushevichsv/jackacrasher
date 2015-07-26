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
    
    
    @IBAction func buttonPressed(sender:UIButton) {
        self.dismissViewControllerAnimated(true, completion:nil)
    }

}
