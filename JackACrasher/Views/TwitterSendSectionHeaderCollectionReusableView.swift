//
//  TwitterSendSectionHeaderCollectionReusableView.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 3/12/16.
//  Copyright © 2016 Siarhei Yakushevich. All rights reserved.
//

import UIKit

class TwitterSendSectionHeaderCollectionReusableView: UICollectionReusableView {
    
    
    @IBOutlet weak var lblTitle:UILabel!
    @IBOutlet weak var ivArrow:UIImageView!
    
    internal var checked:Bool = false {
        didSet {
            var string:String!
            if (checked) {
                string = "release_to_refresh"
            }
            else {
                string="pull_to_refresh"
            }
            ivArrow.image = UIImage(named: string)
        }
    }
}
