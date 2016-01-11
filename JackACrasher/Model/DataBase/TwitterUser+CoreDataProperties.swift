//
//  TwitterUser+CoreDataProperties.swift
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

extension TwitterUser {

    @NSManaged var userId: String?
    @NSManaged var profileImageMiniURL: String?
    @NSManaged var userName: String?
    @NSManaged var screenName: String?
    @NSManaged var isVerified: Bool
    @NSManaged var miniImage: NSData?
    @NSManaged var twitterId: TwitterId?

}
