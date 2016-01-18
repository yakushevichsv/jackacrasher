//
//  TwitterManager.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 1/15/16.
//  Copyright © 2016 Siarhei Yakushevich. All rights reserved.
//

import UIKit
import TwitterKit

/**
Used for downloading items from the twitter account for userId.
*/
class TwitterManager: NSObject {

    typealias friendsCompletion = (items:[String]?,error:NSError?) -> Void
    
    private let twitterId:String!
    private let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)
    private var clientMap  = [String:TWTRAPIClient]()
    private var userImageTasks = [String:Int]()
    
    init(twitterId:String!) {
        self.twitterId = twitterId
        super.init()
    }
    
    
    func getTwitterFriendIds(offset:Int = -1, count:Int = 5000, block:friendsCompletion!) {
        
        let userId = self.twitterId
        let client = TWTRAPIClient(userID: userId)
        clientMap[userId] = client
        
        dispatch_async(self.queue) {
            [unowned self] in
            
            //No friends.!.... - friends
            var error:NSError? = nil
            let params:[NSObject:AnyObject] = ["cursor":"\(offset)", "count":"\(count)", "screen_name":"\(self.twitterId)'s friends"]
            let request = client.URLRequestWithMethod("GET", URL: "https://api.twitter.com/1.1/friends/ids.json", parameters: params, error: &error)
            
            if let errorInner = error {
                print("Error formatting \(errorInner)")
                self.clientMap.removeValueForKey(userId)
                assert(false)
                return
            }
            
            client.sendTwitterRequest(request) {
                [unowned self]
                (response, data, connectionError)  in
                
                if self.clientMap.removeValueForKey(userId) == nil {
                    return
                }
                
                if (connectionError == nil) {
                    if let json = try? NSJSONSerialization.JSONObjectWithData(data!,
                        options: NSJSONReadingOptions.AllowFragments) as! NSDictionary {
                            let ids = json.objectForKey("ids")
                            
                            print("JSON response:\n \(json) \n Ids:\(ids))")
                            block(items: ids as? [String],error: nil)
                            
                    }
                }
                else {
                    print("twitter Request... Error: \(connectionError)")
                    block(items: nil,error: connectionError)
                    
                }
            }
        }
        
    }
    
    private func receiveTwitterFriend(userId:String,completion:((user:TWTRUser?,error:NSError?)->Void)!)  {
        
        let client = TWTRAPIClient(userID: userId)
        clientMap[userId] = client
        
        dispatch_async(self.queue) {
            [unowned self] in
            
            let client = TWTRAPIClient(userID: userId)
            client.loadUserWithID(client.userID!){
                [unowned self]
                (user,error) in
                
                if let _ = self.clientMap.removeValueForKey(userId) {
                    completion(user: user,error:error)
                }
                else {
                    completion(user:nil,error:nil)
                }
            }
        }
    }
    
    func _receiveExtendedTwitterFriend(userId:String,completion:((user:TWTRUser?,image:UIImage?,error:NSError?)->Void)!) {
        
        receiveTwitterFriend(userId) {
            [unowned self]
            (user, error) in
            
            if let user = user {
                
                self.scheduleTwitterUserImageReceive(user){
                    (image, error) in
                    
                    completion(user:user,image: image,error: error)
                    
                }
            }
            else {
                completion(user:nil,image:nil,error:nil)
            }
        }
    }
    
    private func receiveTwitterFriends(userIds:[String],completion:((users:[TWTRUser]?,error:NSError?)->Void)!) {
        
        assert(!userIds.isEmpty)
        
         var users = [TWTRUser]()
         var errorOuter:NSError? = nil
        var cancelled = false
        
        dispatch_async(self.queue) {
            [unowned self] in
            
           
            
            for userId in userIds {
                
                if (cancelled) {
                    break
                }
                
                self.receiveTwitterFriend(userId){
                    (user,error) in
                    
                    if (user != nil && error == nil) {
                        users.append(user!)
                    }
                    else if (!cancelled){
                        cancelled = error == nil
                        if (errorOuter == nil ) {
                            errorOuter = error
                        }
                    }
                    /*else {
                        completion(users: users.isEmpty ? nil : users,error: error)
                    }*/
                }
            }
            //completion(users: users.isEmpty ? nil : users,error: nil)
        }
        
        
        dispatch_barrier_async(self.queue) {
            completion(users: users.isEmpty ? nil : users,error: errorOuter)
        }
        
    }
    
    func receiveExpandedTwitterFriends(userIds:[String],completion:((expandedUsers:[ExpandedTwitterUser]?,error:NSError?)->Void)!) {
        
       _receiveExpandedTwitterFriends(userIds) { (expandedUsers, error) -> Void in
        
            let users = expandedUsers?.map({ (item) -> ExpandedTwitterUser in
                let user = ExpandedTwitterUser(user: item.user)
                user.image = item.image
                return user
            })
        
            completion(expandedUsers: users,error: error)
        
        }
    }
    
    private func _receiveExpandedTwitterFriends(userIds:[String],completion:((expandedUsers:[(user:TWTRUser,image:UIImage?)]?,error:NSError?)->Void)!) {
        
        
        self.receiveTwitterFriends(userIds) {
            [unowned self]
            (users, error)  in
            
            
            if (users?.isEmpty == Optional<Bool>(true)) {
            
                var expandedUsers = [(user:TWTRUser,image:UIImage?)]()
                var lastError:NSError? = nil
                var cancelled = false
                for user in users! {
                    
                    if cancelled {
                        break
                    }
                    
                    if user.jacImageURL == nil {
                        expandedUsers.append((user:user,image:nil))
                    }
                    else {
                        self.scheduleTwitterUserImageReceive(user) {
                            (image, error) in
                            if image != nil {
                                expandedUsers.append((user:user,image:image))
                            }
                            else if (!cancelled) {
                                cancelled = lastError == nil
                                
                                if (error != nil) {
                                    lastError = error
                                }
                            }
                        }
                    }
                }
                
                dispatch_barrier_async(self.queue){
                    completion(expandedUsers: !expandedUsers.isEmpty ? expandedUsers : nil,error:lastError)
                }
                
            }
            else {
                completion(expandedUsers: nil,error:error)
            }
        }
    }
    
    func cancelTwitterRequestForUser(userId:String) {
        
        self.clientMap.removeValueForKey(userId)
        if let taskId = self.userImageTasks.removeValueForKey(userId) {
            NetworkManager.sharedManager.cancelTask(taskId)
        }
    }
    
    func cancelTwitterRequestsForUsers(userIds:[String])  {
        for userId in userIds {
            cancelTwitterRequestForUser(userId)
        }
    }
    
    func cancelAllTwitterRequests() {
        
        let userIds = self.clientMap.keys
        
        for userId in userIds {
            cancelTwitterRequestForUser(userId)
        }
        
        if !self.clientMap.isEmpty {
            self.clientMap.removeAll()
        }
        
        if !self.userImageTasks.isEmpty {
            let userIds = self.userImageTasks.keys
            
            for userId in userIds {
                if let taskId = self.userImageTasks.removeValueForKey(userId) {
                    NetworkManager.sharedManager.cancelTask(taskId)
                }
            }
        }
    }
}

extension TWTRUser {
    
    var jacImageURL:String? {
        
        return self.profileImageMiniURL ?? self.profileImageURL ?? self.profileImageLargeURL
    }
}

//MARK: User's Image
extension TwitterManager {
    
    private func scheduleTwitterUserImageReceive(user:TWTRUser!, completion:((image:UIImage?,error:NSError?)->Void)!) {
        let userId = user.userID
        
        let taskId = getTwitterUserImage(user) {
            [unowned self]
            (image, error) in
            if let _ = self.userImageTasks.removeValueForKey(userId) {
                completion(image:image,error: error)
            }
            else {
                completion(image:nil,error:nil)
            }
        }
        
        let wrongURL = taskId == Int.min
        
        if (!wrongURL && NetworkManager.sharedManager.isValidTask(taskId)) {
            self.userImageTasks[userId] = taskId
        }
        else if (!wrongURL) {
            completion(image:nil,error:nil)
        }
    }
    
    private func getTwitterUserImage(user:TWTRUser!, completion:((image:UIImage?,error:NSError?)->Void)!) -> Int {
        
        
        guard let urlStr = user.jacImageURL  else {
            completion(image: nil,error:nil)
            return Int.min
        }
        
        return NetworkManager.sharedManager.downloadFileFromPath(urlStr) {
            (path, error)  in
            guard path != nil && error == nil else {
               completion(image: nil,error: error)
               return
            }
            completion(image: UIImage(contentsOfFile: path!),error: nil)
        }
    }
}
