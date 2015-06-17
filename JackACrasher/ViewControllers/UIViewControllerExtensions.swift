//
//  UIViewControllerExtensions.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 6/17/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit

extension UIViewController {
    
    func alertWithTitle(title:String?, message:String?,actionTitle:String = "OK")
    {
        let vc = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        
        let alertAction = UIAlertAction(title: actionTitle, style: .Default){
            action in
        }
        vc.addAction(alertAction)
        presentViewController(vc, animated: true, completion: nil)
    }
}
