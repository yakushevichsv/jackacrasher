//
//  ExpandedTwitterUser.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 1/17/16.
//  Copyright © 2016 Siarhei Yakushevich. All rights reserved.
//

import UIKit
import TwitterKit

class ExpandedTwitterUser: NSObject {
    let twitterUser:TWTRUser!
    var image:UIImage? = nil
    
    init(user:TWTRUser!) {
        self.twitterUser = user
    }
    
    
}
