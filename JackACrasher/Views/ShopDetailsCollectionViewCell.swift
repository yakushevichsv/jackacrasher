//
//  ShopDetailsCollectionViewCell.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 6/11/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit

@objc protocol ShopDetailsCellDelegate {
    
    func buyButtonPressedInCell(cell:ShopDetailsCollectionViewCell)
}


class ShopDetailsCollectionViewCell: UICollectionViewCell {

    private static var originImageW:CGFloat = 0
    private static var originImageH:CGFloat = 0
    
    private static var sPredicate:dispatch_once_t = 0
    
    @IBOutlet weak var productImageView:UIImageView!
    @IBOutlet weak var productTitle:UILabel!
    @IBOutlet weak var buyButton:UIButton!
    @IBOutlet weak var productDescription:UITextView!
    
    @IBOutlet weak var delegate:ShopDetailsCellDelegate!
    
    @IBOutlet weak var imageWConstraint:NSLayoutConstraint!
    @IBOutlet weak var imageHConstraint:NSLayoutConstraint!
    
    @IBAction func buyButtonPressed(sender:UIButton!) {
        delegate.buyButtonPressedInCell(self)
    }
    
    override func applyLayoutAttributes(layoutAttributes: UICollectionViewLayoutAttributes!) {
        super.applyLayoutAttributes(layoutAttributes)
        
        dispatch_once(&ShopDetailsCollectionViewCell.sPredicate) {
            ShopDetailsCollectionViewCell.originImageW = self.imageWConstraint.constant
            ShopDetailsCollectionViewCell.originImageH = self.imageHConstraint.constant
        }
    }
    
    internal func setImage(imagePtr:UIImage?) {
        if let image = imagePtr {
            self.productImageView?.image = image
        }
        else {
            self.productImageView?.image = nil
            self.productImageView.sizeToFit()
            //self.imageWConstraint.constant = 0
            //self.imageHConstraint.constant = 0
            self.productImageView?.hidden = true
            self.setNeedsLayout()
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.delegate = nil
        self.productImageView?.hidden = false
        self.imageWConstraint.constant = ShopDetailsCollectionViewCell.originImageW
        self.imageHConstraint.constant = ShopDetailsCollectionViewCell.originImageH
    }
}
