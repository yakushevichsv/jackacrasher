//
//  SNFriendInfo.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 12/2/15.
//  Copyright © 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit

class SNFriendInfo: NSObject {

    private let userId:String
    
    init(userId:String) {
        self.userId = userId
        super.init()
    }
    
    var imageURL:NSURL? {
        didSet {
            if (imageURL != nil && !imageURL!.isEqual(oldValue) ) {
                // load new image.....
            }
        }
    }
    
    var image:UIImage?
    
}
