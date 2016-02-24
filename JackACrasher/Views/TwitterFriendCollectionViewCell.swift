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
    @IBOutlet weak var aiDownloadingImage:UIActivityIndicatorView!
    
    private weak var bgProfileImageLayer:CAShapeLayer! = nil
    
    private weak var labelLayer:CATextLayer! = nil
    private weak var imageLayer:CALayer! = nil
    
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
        
        aiDownloadingImage.hidden = false
        aiDownloadingImage.startAnimating()
        
        var center = self.contentView.layer.bounds.center
        center.y -= 15
        
        createImageLayer(center)
        createImageBorderLayer(center)
        createTextLayer(center)
        
        self.imageLayer.contents = UIImage(imageLiteral: "no_twitter_profile_image").CGImage
        self.setText(nil)
        
        markAsSelected(false)
        
        aiDownloadingImage.superview?.bringSubviewToFront(aiDownloadingImage)
    }
    
    
    internal func markAsSelected(selected:Bool) {
        setProfileImageLayerBg(selected ? UIColor.redColor() : UIColor.yellowColor(), duration: 10, animated: true)
    }
    
    internal func createImageLayer(center:CGPoint) {
     
        if self.imageLayer != nil {
            return
        }
        
        
        let layer = CALayer()
        
        layer.bounds = CGRect(origin:CGPointZero,size:CGSizeMake(80,80))
        layer.position = center
        
        self.contentView.layer.addSublayer(layer)
        
        layer.masksToBounds = true
        layer.cornerRadius = round(0.5*min(CGRectGetWidth(layer.bounds),CGRectGetHeight(layer.bounds)))
        layer.contentsGravity = kCAGravityResizeAspectFill
        layer.backgroundColor = UIColor.lightGrayColor().CGColor
        self.imageLayer = layer
    }
    
    internal func createImageBorderLayer(center:CGPoint) {
        
        if self.bgProfileImageLayer != nil {
            return
        }
        
        assert(self.imageLayer != nil)
        
    
        let layer = CAShapeLayer()
    
        
        let borderWidth = CGFloat(10.0)
        
        let radius = self.imageLayer.cornerRadius
    
        let rect = CGRectMake(0,0,2*radius+borderWidth,2*radius+borderWidth)
        layer.frame = rect
        
        let size = layer.frame.size
        
        let point = CGPoint(x: size.width * 0.5,y: size.height * 0.5)
    
        let path = UIBezierPath()
        
        path.addArcWithCenter(point, radius: radius, startAngle: 0, endAngle: 2 * 3.14, clockwise: true)
        
        path.addArcWithCenter(point, radius: radius + borderWidth, startAngle: 0, endAngle: 2 * 3.14, clockwise: true)
        
        layer.fillRule = kCAFillRuleEvenOdd
        layer.path = path.CGPath
        
        layer.position = center
        
        self.contentView.layer.insertSublayer(layer, atIndex: 0) //insertSublayer(layer, above: ivProfileImage.layer) //addSublayer(layer)
        
        self.bgProfileImageLayer = layer
        
        //print("Layer frame \(layer.frame) \n Image frame \(ivProfileImage.frame)\n Image center \(layer.position) \n Image View position \(ivProfileImage.center)")
    }
    
    internal func createTextLayer(center:CGPoint) {
        
        if self.labelLayer != nil {
            return
        }
        
        assert(self.bgProfileImageLayer != nil)
        
        let layer = CATextLayer()
        let font = UIFont.systemFontOfSize(17)
        
        layer.fontSize = font.pointSize
        layer.font = CTFontCreateWithName(font.fontName,font.pointSize,nil)
        layer.foregroundColor = UIColor.blackColor().CGColor
        layer.contentsScale = UIScreen.mainScreen().scale
        layer.alignmentMode = kCAAlignmentCenter
        layer.truncationMode = kCATruncationMiddle
        layer.position = CGPoint(x: center.x, y: CGRectGetMaxY(self.bgProfileImageLayer.frame) + 15)
        
        let size = CGSizeMake(CGRectGetWidth(self.contentView.layer.bounds),30)
        
        layer.bounds = CGRect(origin:CGPointZero,size:size)
        
        self.contentView.layer.addSublayer(layer)
        
        self.labelLayer = layer
    }
    
    internal func setProfileImageLayerBg(color:UIColor,duration:NSTimeInterval = 0,animated:Bool = false) {
        
        self.bgProfileImageLayer.fillColor = color.CGColor
        
        if (animated) {
        
            if let _  = self.bgProfileImageLayer.animationForKey("strokeEndAnimation") {
                
                self.bgProfileImageLayer.removeAnimationForKey("strokeEndAnimation")
            }
            
            let basic = CABasicAnimation(keyPath: "strokeEnd")
            basic.duration = duration
            basic.fromValue = 0.0
            basic.toValue = 1.0
            basic.removedOnCompletion = false
            self.bgProfileImageLayer.addAnimation(basic, forKey: "strokeEndAnimation")
        
            self.bgProfileImageLayer.strokeColor = color.CGColor
            self.bgProfileImageLayer.strokeEnd = 0.0
            self.bgProfileImageLayer.strokeStart = 0.0
        }
    }
    
    internal func setProfileImage(imaage imagePtr:UIImage?) {
        
        aiDownloadingImage.hidden = true
        aiDownloadingImage.stopAnimating()
        
        guard let image = imagePtr else {
            self.imageLayer.contents = UIImage(imageLiteral: "no_twitter_profile_image").CGImage
            
            return
        }
        
        
        self.imageLayer.contents = image.CGImage
    }
    
    internal func setText(text:String?) {
        self.labelLayer.string = text
    }
    
}
