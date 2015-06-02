//
//  CustomTransitionSegue.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 6/1/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit

class CustomTransitionSegue: UIStoryboardSegue {

    override func perform() {
        
        let sVC = self.sourceViewController as! UIViewController
        let dVC = self.destinationViewController as! UIViewController
        
        sVC.navigationController?.pushViewController(dVC, animated: false)
    }
}
