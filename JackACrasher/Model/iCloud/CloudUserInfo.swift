//
//  File.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 6/25/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit
import CloudKit

class CloudUserInfo  {
    
    private let container:CKContainer!
    var userRecordID :CKRecordID!
    
    init(container:CKContainer!) {
        self.container = container
    }
    
    //MARK: Public functions
    
    internal func loggedInToICloud(completion : (accountStatus : CKAccountStatus, error : NSError?) -> ()) {
        
        self.container.accountStatusWithCompletionHandler() { (status : CKAccountStatus, error : NSError?)
            in
            completion(accountStatus: status, error: error)
        }
    }
    
    internal func getUserId(completion: (userRecordId:CKRecordID!, error:NSError!) ->()) {
        if self.userRecordID != nil {
            completion(userRecordId:self.userRecordID, error:nil)
        } else {
            self.container.fetchUserRecordIDWithCompletionHandler() {
                [unowned self]
                recordID, error in
                if recordID != nil {
                    self.userRecordID = recordID
                }
                completion(userRecordId: self.userRecordID, error: error)
            }
        }
    }
    
    func requestDiscoverability(completion: (discoverable: Bool) -> ()) {
        container.statusForApplicationPermission(
            CKApplicationPermissions.UserDiscoverability) {
                status, error in
                if error != nil || status == CKApplicationPermissionStatus.Denied {
                    completion(discoverable: false)
                } else {
                    self.container.requestApplicationPermission(CKApplicationPermissions.UserDiscoverability) { status, error in
                        completion(discoverable: status == .Granted)
                    }
                }
        }
    }
    
    internal func getUserInfo(recordID: CKRecordID!,
        completion:(userInfo: CKDiscoveredUserInfo?, error: NSError?)->()) {
            container.discoverUserInfoWithUserRecordID(recordID,
                completionHandler:completion)
    }
    
    internal func getUserInfo(completion: (userInfo: CKDiscoveredUserInfo?, error: NSError?)->()){
        
        requestDiscoverability() { discoverable in
            self.getUserId() { recordID, error in
                if error != nil {
                    completion(userInfo: nil, error: error)
                } else {
                    self.getUserInfo(recordID, completion: completion)
                }
            }
        }
    }
}
