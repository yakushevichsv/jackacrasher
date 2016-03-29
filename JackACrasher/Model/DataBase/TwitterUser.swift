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
    
    
    func friendshipDescription() -> String? {
        
        let fFriendship = FriendshipStatus(rawValue: Int(self.fromFriendShip))
        let tFriendship = FriendshipStatus(rawValue: Int(self.toFriendShip))
        
        guard let f = fFriendship, let t = tFriendship else {
            return nil
        }
        
        var descr:String? = nil
        
        if f.isFriend(t) {
            descr = "Friend"
        }
        else if f.isBlockingAnother(t) {
            descr = "Blocking"
        }
        else if f.isBlockedByAnother(t) {
            descr = "Blocked"
        }
        else if f.isFollowingRequested() {
            descr = "Request was sent"
        }
        else if f.isFollowing() {
            descr = "Following"
        }
        else if t.isFollowedBy() && t != f {
            descr = "FollowedBy"
        }
        
        if let descrInner = descr {
            return NSLocalizedString(descrInner, comment: "")
        }
        else {
            return nil
        }
    }
    
}
