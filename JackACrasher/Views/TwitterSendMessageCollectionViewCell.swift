//
//  TwitterSendMessageCollectionViewCell.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 3/12/16.
//  Copyright © 2016 Siarhei Yakushevich. All rights reserved.
//

import UIKit

class TwitterSendMessageCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var tvMessage:UITextView!
    @IBOutlet weak var lblTitle:UILabel!
    @IBOutlet weak var lblCharacters:UILabel!
}

//MARK: TextView Delegate
extension TwitterSendMessageCollectionViewCell:UITextViewDelegate {
    
}
