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

    func correctFontOfChildViews(currentView:UIView!,reduction:CGFloat = 0) {
    
        let fontName = NSLocalizedString("FontName", comment: "Font Name")
    
        for subView in currentView.subviews {
            
            if let lView = subView as? UILabel {
                let font = UIFont(name: fontName, size: lView.font!.pointSize)
                lView.font = font
            }
            else if let bView = subView as? UIButton {
                //var correction:CGFloat = 0
                //var lblSize = bView.bounds.size
                //lblSize.width -= (bView.contentEdgeInsets.left + bView.contentEdgeInsets.right)
                
                //while (true) {
                    let pSize  = bView.titleLabel!.font.pointSize - reduction
                
                    let font = UIFont(name: fontName,  size: pSize)
                    bView.titleLabel?.font = font
                
                    /*if let lbl = bView.titleLabel {
                        lbl.font = font
                        
                        
                        
                        let size = lbl.sizeThatFits(lblSize)
                        
                        if (size.width <= lblSize.width) {
                            break
                        }
                        else {
                            correction++
                        }
                        
                        var frame =  bView.frame
                        frame.size = size
                        bView.frame = frame
                    }*/
                //}
            }
            else if let tView = subView as? UITextField {
                let font = UIFont(name: fontName, size: tView.font!.pointSize)
                tView.font = font
            }
            else if let tView = subView as? UITextView {
                let font = UIFont(name: fontName, size: tView.font!.pointSize)
                tView.font = font
            }
            
            correctFontOfChildViews(subView)
        }
    }
}
