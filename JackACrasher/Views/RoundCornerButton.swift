//
//  RoundCornerButton.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 5/11/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit

@IBDesignable
class RoundCornerButton: UIButton {
    
    private  struct Constants {
        static let sBorderWidth:CGFloat  = 2.0
        static let sCornerRadius:CGFloat = 5.0
        static let sBorderColor = UIColor.blackColor()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    @IBInspectable
    var borderWidth:CGFloat = 2.0 {
        didSet {
            self.layer.borderWidth = borderWidth
        }
    }
    
    @IBInspectable
    var borderColor:UIColor = Constants.sBorderColor {
        didSet {
            self.layer.borderColor = self.borderColor.CGColor
        }
    }
    
    @IBInspectable
    var cornerRadius:CGFloat = Constants.sCornerRadius {
        didSet {
            self.layer.cornerRadius = self.cornerRadius
        }
    }
    
    private func setup() {
        self.borderColor = Constants.sBorderColor
        self.borderWidth = Constants.sBorderWidth
        self.cornerRadius = Constants.sCornerRadius
        
        self.setTitleColor(UIColor(red: 0, green: 0, blue: 0.5, alpha: 0.8), forState: UIControlState.Normal)
        let color = UIColor.darkTextColor().colorWithAlphaComponent(0.8)
        self.setTitleColor(color, forState: UIControlState.Disabled)
    }

    
    override func prepareForInterfaceBuilder() {
        setup()
    }
}
