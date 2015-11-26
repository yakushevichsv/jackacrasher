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
    func restoreButtonPressedInCell(cell:ShopDetailsCollectionViewCell)
}


class ShopDetailsCollectionViewCell: UICollectionViewCell {

    private static var originImageW:CGFloat = 0
    private static var originImageH:CGFloat = 0
    
    private static var sPredicate:dispatch_once_t = 0
    private static let sBgColor = "backgroundColor"
    
    @IBOutlet weak var productImageView:UIImageView!
    @IBOutlet weak var productTitle:UILabel!
    @IBOutlet weak var buyButton:UIButton!
    @IBOutlet weak var restoreButton:UIButton!
    @IBOutlet weak var productDescription:UITextView!
    @IBOutlet weak var descriptionTextView:UITextView!
    
    
    @IBOutlet weak var delegate:ShopDetailsCellDelegate!
    
    
    @IBAction func buyButtonPressed(sender:UIButton!) {
        delegate.buyButtonPressedInCell(self)
    }
    
    @IBAction func restoreButtonPressed(sender:UIButton!){
        delegate.restoreButtonPressedInCell(self)
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        
        let wConstraint = NSLayoutConstraint(item:self.productImageView , attribute: .Width, relatedBy: .Equal, toItem: self, attribute: .Width, multiplier: 0.4, constant: 0.0)
        let hConstraint = NSLayoutConstraint(item:self.productImageView , attribute: .Height, relatedBy: .Equal, toItem: self, attribute: .Height, multiplier: 0.4, constant: 0.0)
       
        let hConstraint2 = NSLayoutConstraint(item: self.descriptionTextView, attribute: .Height, relatedBy: .Equal, toItem: self, attribute: .Height, multiplier: 0.47, constant: 0.0)
        
        self.addConstraints([wConstraint,hConstraint,hConstraint2])
        self.setNeedsUpdateConstraints()
    }
    
    internal func shouldEnableRestore(restore:Bool){
        
        let layer = self.restoreButton.layer
        let anim = layer.animationForKey(ShopDetailsCollectionViewCell.sBgColor)
        
        if (restore) {
            
            if (anim != nil ) {
                return
            }
            let anim = CABasicAnimation(keyPath: ShopDetailsCollectionViewCell.sBgColor)
            anim.duration = 2.0
            anim.repeatCount = .infinity
            anim.toValue = UIColor.blueColor().CGColor;
            layer.addAnimation(anim, forKey: ShopDetailsCollectionViewCell.sBgColor)
            anim.removedOnCompletion = true
        }
        else {
            if (anim != nil) {
                layer.removeAnimationForKey(ShopDetailsCollectionViewCell.sBgColor)
            }
        }
    }
    
    internal func indicateiTunesOpInProgress(isPurchase:Bool) {
        
        var btnD:UIButton! = nil ,btnE:UIButton! = nil
        shouldEnableRestore(false)
        if (isPurchase) {
            btnD = self.restoreButton
            btnE = self.buyButton
        }
        else {
            btnD = self.buyButton
            btnE = self.restoreButton
        }
        
        btnD.hidden = true
        btnE.hidden = false
        btnE.enabled = false
    }
    
    internal func indicateiTunesOpFinished() {
        
        if (!self.buyButton.hidden) {
            self.buyButton.enabled = true
        }
        else if (!self.restoreButton.hidden) {
            self.restoreButton.hidden = true
        }
    }
    
    internal func setTitleForProduct(title:String) {
        self.productTitle?.text = title
        self.productTitle?.sizeToFit()
        self.setNeedsLayout()
    }
    
    internal func setImage(imagePtr:UIImage?) {
        if let image = imagePtr {
            self.productImageView?.image = image
        }
        else {
            self.productImageView?.image = nil
            self.productImageView.sizeToFit()
            self.productImageView?.hidden = true
            self.setNeedsLayout()
        }
    }
    
    internal func displayActivityIndicatorWhileDownloading() {
        
        self.hideActivityIndicatorAfterDonwloading()
        
        let activity = UIActivityIndicatorView(activityIndicatorStyle: .White)
        activity.center = CGPointMake(CGRectGetMidX(self.productImageView.bounds), CGRectGetMidY(self.productImageView.bounds))
        activity.hidesWhenStopped = true
        activity.startAnimating()
        self.productImageView.addSubview(activity)
    }
    
    internal func hideActivityIndicatorAfterDonwloading() {
        
        if let activity = self.productImageView.subviews.last as? UIActivityIndicatorView {
            activity.stopAnimating()
            activity.removeFromSuperview()
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.delegate = nil
        self.productImageView?.hidden = false
        self.hideActivityIndicatorAfterDonwloading()
        self.restoreButton.hidden = true
        self.restoreButton.enabled = true
        self.buyButton.hidden = false
        self.buyButton.enabled = true
        shouldEnableRestore(false)
    }
}
