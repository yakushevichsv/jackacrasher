//
//  RoundCornerButton.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 5/11/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit

class RoundCornerButton: UIButton {

    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    private func setup() {
        self.layer.cornerRadius = 5.0
        self.layer.borderColor = UIColor.blackColor().CGColor
        self.layer.borderWidth = 2.0
        
        self.setTitleColor(UIColor(red: 0, green: 0, blue: 0.5, alpha: 0.8), forState: UIControlState.Normal)
        let color = UIColor.darkTextColor().colorWithAlphaComponent(0.8)
        self.setTitleColor(color, forState: UIControlState.Disabled)
    }

}
