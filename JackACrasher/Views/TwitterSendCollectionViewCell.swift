//
//  TwitterSendCollectionViewCell.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 3/13/16.
//  Copyright © 2016 Siarhei Yakushevich. All rights reserved.
//

import UIKit

enum TwitterSendingState {
    case None
    case Sending
    case Success
    case Failed
}

class TwitterSendCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var btnCheck:UIButton!
    @IBOutlet weak var ivImage:UIImageView!
    @IBOutlet weak var lblName:UILabel!
    @IBOutlet weak var lblFriendship:UILabel!
    @IBOutlet weak var lblStatus:UILabel!
    
    var sendingState:TwitterSendingState = .None {
        didSet {
            
            if (sendingState != oldValue || lblStatus.text == nil || lblStatus.text!.isEmpty || lblStatus.text == Optional("CorrectThis")) {
                
                var text = ""
                
                switch (sendingState){
                    
                case .Sending:
                    text = "Sending"
                    self.lblStatus.textColor = UIColor.whiteColor()
                    self.lblStatus.backgroundColor = UIColor.yellowColor()
                    break
                case .Success:
                    text = "OK"
                    self.lblStatus.textColor = UIColor.whiteColor()
                    self.lblStatus.backgroundColor = UIColor.greenColor()
                    break
                case .Failed:
                    text = "Failed"
                    self.lblStatus.textColor = UIColor.whiteColor()
                    self.lblStatus.backgroundColor = UIColor.redColor()
                    break
                default:
                    assert(sendingState == .None)
                    text = "Not Sended"
                    self.lblStatus.textColor = UIColor.blackColor()
                    self.lblStatus.backgroundColor = self.contentView.backgroundColor
                    break
                }
                
                if !text.isEmpty {
                    lblStatus.text = NSLocalizedString(text, comment: text)
                }
                else {
                    lblStatus.text = text
                }
            }
        }
    }
    
    var checked:Bool = false {
        didSet {
            if (checked != oldValue) {
                btnCheck.selected = checked
            }
        }
    }
}
