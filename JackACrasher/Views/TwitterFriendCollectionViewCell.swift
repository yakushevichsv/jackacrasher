//
//  TwitterFriendCollectionViewCell.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 1/9/16.
//  Copyright © 2016 Siarhei Yakushevich. All rights reserved.
//

import UIKit

@IBDesignable
class TwitterFriendCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var label:UILabel!
    @IBOutlet weak var ivProfileImage:UIImageView!
    @IBOutlet weak var aiDownloadingImage:UIActivityIndicatorView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        correctProfileImage()
    }
    
    override func prepareForReuse() {
        correctProfileImage()
        
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        
        correctProfileImage()
    }
    
    private func correctProfileImage() {
        
        ivProfileImage.layer.cornerRadius = min(CGRectGetWidth(ivProfileImage.frame),CGRectGetHeight(ivProfileImage.frame)) * 0.5
        
        ivProfileImage.layer.masksToBounds = true
        
        ivProfileImage.layer.borderWidth = 10.0
        
        ivProfileImage.borderColor = UIColor.yellowColor()
        
        ivProfileImage.image = UIImage(imageLiteral: "no_twitter_profile_image")
        aiDownloadingImage.hidden = false
    }
    
    internal func setProfileImage(imaage imagePtr:UIImage?) {
        
        guard let image = imagePtr else {
            aiDownloadingImage.hidden = true
            return
        }
        
        aiDownloadingImage.hidden = true
        ivProfileImage.image = image
    }
    
}
