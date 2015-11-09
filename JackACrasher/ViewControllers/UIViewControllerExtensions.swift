//
//  UIViewControllerExtensions.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 6/17/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit

extension UIViewController {
    
    func alertWithTitle(title:String?, message:String?,actionTitle:String! = "OK",completion: (() -> Void)? = nil)
    {
        let vc = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        var needToDisp:Bool = false
        if !(actionTitle == nil || actionTitle.isEmpty) {
            let alertAction = UIAlertAction(title: actionTitle, style: .Default){
                action in
                
                if let completion = completion {
                    completion()
                }
            }
            vc.addAction(alertAction)
        }
        else {
            needToDisp = true
        }
        presentViewController(vc, animated: true){
            [unowned self] in
            if needToDisp {
                let delayTime = dispatch_time(DISPATCH_TIME_NOW,
                    Int64(1 * Double(NSEC_PER_SEC)))
                
                dispatch_after(delayTime, dispatch_get_main_queue()){
                    self.dismissViewControllerAnimated(true, completion: nil)
                }
            }
        }
    }
    

   func correctFontOfChildViews(currentView:UIView!) {
        
        let fontName = NSLocalizedString("FontName", comment: "Font Name")
        
        for subView in currentView.subviews {
            
            if let lView = subView as? UILabel {
                let font = UIFont(name: fontName, size: lView.font!.pointSize)
                lView.font = font
                correctFontOfChildViews(lView)
            }
            else if let bView = subView as? UIButton {
                let pSize  = bView.titleLabel!.font.pointSize
                let font = UIFont(name: fontName,  size: pSize)
                bView.titleLabel?.font = font
            }
            else if let tView = subView as? UITextField {
                let font = UIFont(name: fontName, size: tView.font!.pointSize)
                tView.font = font
                correctFontOfChildViews(tView)
            }
            else if let tView = subView as? UITextView {
                let font = UIFont(name: fontName, size: tView.font!.pointSize)
                tView.font = font
                correctFontOfChildViews(tView)
            }
            else {
                correctFontOfChildViews(subView)
            }
        }
    }
}
