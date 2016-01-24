//
//  TwitterUser+CoreDataProperties.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 1/22/16.
//  Copyright © 2016 Siarhei Yakushevich. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension TwitterUser {

    @NSManaged var isVerified: Bool
    @NSManaged var miniImage: NSData?
    @NSManaged var profileImageMiniURL: String?
    @NSManaged var screenName: String?
    @NSManaged var userId: String?
    @NSManaged var userName: String?
    @NSManaged var inviteCount: Int32
    @NSManaged var lastUpdateTime: NSTimeInterval
    @NSManaged var twitterId: TwitterId?

}
