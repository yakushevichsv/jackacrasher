//
//  TwitterFriendCollectionViewCell.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 1/9/16.
//  Copyright © 2016 Siarhei Yakushevich. All rights reserved.
//

import UIKit

class TwitterFriendCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var label:UILabel!
    
    override func awakeAfterUsingCoder(aDecoder: NSCoder) -> AnyObject? {
        
        self.clipsToBounds =  self.layer.cornerRadius > 0 ? true : false
        
        return super.awakeAfterUsingCoder(aDecoder)
    }
    
}
