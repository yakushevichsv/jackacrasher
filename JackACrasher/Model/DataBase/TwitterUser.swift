//
//  TwitterUser.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 1/12/16.
//  Copyright © 2016 Siarhei Yakushevich. All rights reserved.
//

import Foundation
import CoreData


class TwitterUser: NSManagedObject,EntityPropertyProtocol {

    // Insert code here to add functionality to your managed object subclass

    static func EntityName() -> String {
        return "TwitterUser"
    }
    
}
