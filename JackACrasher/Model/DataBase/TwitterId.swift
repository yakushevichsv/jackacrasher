//
//  TwitterId.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 1/12/16.
//  Copyright © 2016 Siarhei Yakushevich. All rights reserved.
//

import Foundation
import CoreData

protocol EntityPropertyProtocol:class {
    static func EntityName() -> String
}

class TwitterId: NSManagedObject,EntityPropertyProtocol {

// Insert code here to add functionality to your managed object subclass
    
    static func EntityName() -> String {
        return "TwitterId"
    }
}
