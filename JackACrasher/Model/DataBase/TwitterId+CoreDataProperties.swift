//
//  TwitterId+CoreDataProperties.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 1/12/16.
//  Copyright © 2016 Siarhei Yakushevich. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension TwitterId {

    @NSManaged var userId: String?
    @NSManaged var twitterUser: NSManagedObject?

}
