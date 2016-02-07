//
//  ProgressViewController.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 2/7/16.
//  Copyright © 2016 Siarhei Yakushevich. All rights reserved.
//

import UIKit

class ProgressViewController: UIViewController {

    @IBOutlet weak var pvStatus:UIProgressView!
    @IBOutlet weak var lblProgress:UILabel!
    @IBOutlet weak var btnClose:UIButton!
    @IBOutlet weak var ivIndicator:UIActivityIndicatorView!
    
    var cancelBlock:dispatch_block_t? = nil
    
    var progressValue:Double = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        stopIndicator()
        self.pvStatus.progress = 0
        btnClose.addTarget(self, action: "btnPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        activateIndicator()
        
        if progressValue != 0 {
            
            setProgressValue(progressValue,animated: true)
            progressValue = 0;
        }
    }

    
    func btnPressed(sender:UIButton!) {
        
        if sender != nil && self.btnClose == sender {
            self.cancelBlock?()
        }
        self.presentingViewController?.dismissViewControllerAnimated(true,completion: nil)
    }
    
    func setProgressValue(value:Double,animated:Bool = false) {
        
        if (!self.isViewLoaded()){
            progressValue = value
        } else {
            if (self.pvStatus.hidden) {
                self.ivIndicator.stopAnimating()
                self.pvStatus.hidden = false
            }
            
            self.pvStatus.setProgress(Float(value), animated: animated)
            
            self.lblProgress.text = "\(Int(value * 100)) %"
        }
    }
    
    func activateIndicator() {
        self.pvStatus.hidden = true;
        progressValue = 0
        self.lblProgress.text = nil;
        self.ivIndicator.startAnimating()
    }
    
    func stopIndicator() {
        self.ivIndicator.stopAnimating()
        btnPressed(nil)
    }
}
