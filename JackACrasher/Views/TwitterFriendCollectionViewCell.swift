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
    
    private weak var bgProfileImageLayer:CAShapeLayer? = nil
    
    
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
        
        ivProfileImage.image = UIImage(imageLiteral: "no_twitter_profile_image")
        aiDownloadingImage.hidden = false
        aiDownloadingImage.startAnimating()
        
        createImageLayer()
        
        setProfileImageLayerBg(UIColor.yellowColor())
    }
    
    
    internal func markAsSelected(selected:Bool) {
        setProfileImageLayerBg(selected ? UIColor.redColor() : UIColor.yellowColor(), duration: 10, animated: true)
    }
    
    internal func createImageLayer() {
        
        if self.bgProfileImageLayer != nil {
            return
        }
        
    
        let layer = CAShapeLayer()
    
        
        let borderWidth = CGFloat(10.0)
        
        let radius = ivProfileImage.layer.cornerRadius
    
        let rect = CGRectMake(0,0,2*radius+borderWidth,2*radius+borderWidth)
        layer.frame = rect
        
        let size = layer.frame.size
        
        let point = CGPoint(x: size.width * 0.5,y: size.height * 0.5)
    
        let path = UIBezierPath()
        
        path.addArcWithCenter(point, radius: radius, startAngle: 0, endAngle: 2 * 3.14, clockwise: true)
        
        path.addArcWithCenter(point, radius: radius + borderWidth, startAngle: 0, endAngle: 2 * 3.14, clockwise: true)
        
        layer.fillRule = kCAFillRuleEvenOdd
        layer.path = path.CGPath
        
        layer.position = ivProfileImage.center
        
        ivProfileImage.superview?.layer.insertSublayer(layer, atIndex: 0) //insertSublayer(layer, above: ivProfileImage.layer) //addSublayer(layer)
        
        self.bgProfileImageLayer = layer
    }
    
    
    internal func setProfileImageLayerBg(color:UIColor,duration:NSTimeInterval = 0,animated:Bool = false) {
        
        self.bgProfileImageLayer?.fillColor = color.CGColor
        
        if (animated) {
        
            if let _  = self.bgProfileImageLayer?.animationForKey("strokeEndAnimation") {
                
                self.bgProfileImageLayer?.removeAnimationForKey("strokeEndAnimation")
            }
            
            let basic = CABasicAnimation(keyPath: "strokeEnd")
            basic.duration = duration
            basic.fromValue = 0.0
            basic.toValue = 1.0
            basic.removedOnCompletion = false
            self.bgProfileImageLayer?.addAnimation(basic, forKey: "strokeEndAnimation")
            
        }
    }
    
    internal func setProfileImage(imaage imagePtr:UIImage?) {
        
        guard let image = imagePtr else {
            aiDownloadingImage.hidden = true
            return
        }
        
        aiDownloadingImage.hidden = true
        aiDownloadingImage.stopAnimating()
        ivProfileImage.image = image
    }
    
}
