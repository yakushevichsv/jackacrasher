//
//  TwitterManager.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 1/15/16.
//  Copyright © 2016 Siarhei Yakushevich. All rights reserved.
//

import UIKit
import TwitterKit

/*TODO:
1) Add rate_limit_status - usage
2) Add message send opportunity
*/

enum TwitterManagerState {
    case None
    case DownloadingTwitterIds(offset:Int)
    case DownloadingTwitterIdsRateLimit(offset:Int,error:NSError!)
    case DownloadingTwitterIdsError(offset:Int,error:NSError!)
    
    case DownloadingTwitterUsers(offset:Int)
    case DownloadingTwitterUsersRateLimit(userIds:[String],error:NSError!)
    case DownloadingTwitterUsersError(offset:Int,error:NSError!)
    
    
    case DownloadingTwitterUserConnection(offset:Int)
    case DonwloadingTwitteruserConnectionRateLimit(users:[TWTRUser],error:NSError!)
    case DownloadingTwitterUserConnectionError(offset:Int,error:NSError!)
    
    case DownloadingFinished(totalCount:Int)
    
    case DonwloadingTwitterUsersCancelled(lastEror:NSError?)
}

let TwitterManagerStateNotification = "JC.TwitterManagerStateNotification"

extension TwitterManagerState : Equatable {
}

func == (lhs: TwitterManagerState, rhs: TwitterManagerState) -> Bool {

    switch (lhs,rhs) {
        
    case (let .DownloadingTwitterIds(offset1), let .DownloadingTwitterIds(offset2)):
        return offset1 == offset2
    case (.None, .None):
            return true
    case (.DownloadingTwitterIdsError, .DownloadingTwitterIdsError):
        return true
    default:
        return false
    }
}


enum FriendshipStatus:Int {
    case None = 0
    case Following
    case FollowingRequested
    case FollowedBy
    case Blocking
    case Muting
    
    func isFriend(status:FriendshipStatus) -> Bool {
        
        return (self == .Following && status == .FollowedBy) ||
              (self == .FollowedBy &&  status == .Following)
    }
    
    func isBlockedByAnother(status:FriendshipStatus) -> Bool {
        return self == .Following && status == .Blocking
    }
    
    func isBlockingAnother(status:FriendshipStatus) -> Bool {
        return status.isBlockedByAnother(self)
    }
    
    func isNone(status:FriendshipStatus) -> Bool {
        return self == status && self == .None
    }
    
    func isFollowing() -> Bool {
        return self == .Following
    }
    
    func isFollowedBy() -> Bool {
        return self == .FollowedBy
    }
    
    func isFollowingRequested() -> Bool {
        return self == .FollowingRequested
    }
}

/**
Used for downloading items from the twitter account for userId.
*/
class TwitterManager: NSObject {

    typealias friendsCompletion = (items:[String]?,error:NSError?,last:Bool) -> Void
    typealias twitterFriendsCompletion = (items:[TWTRUser]? ,error:NSError?) -> Void
    typealias twitterFriendShipCompletion = (usersInfo:[TWTRUser:[FriendshipStatus]]?,error:NSError?) -> Void
    typealias twitterConfigurationCompletion = (configuration:[String:AnyObject]?,error:NSError?) -> Void
    
    private let twitterId:String!
    private let twitterClient:TWTRAPIClient!
    
    private let queue = dispatch_queue_create("sy.jac.twittermanager.queue", DISPATCH_QUEUE_CONCURRENT)
    private var userImageTasks = [String:Int]()
    
    private (set) var managerState = TwitterManagerState.None {
        didSet {
            
            NSNotificationCenter.defaultCenter().postNotificationName(TwitterManagerStateNotification, object: self)
        }
    }
    
    init(twitterId:String!) {
        self.twitterId = twitterId
        self.twitterClient = TWTRAPIClient(userID: twitterId)
        
        super.init()
        
    }
    
    
    func startUpdatingTotalList() -> Bool {
        
        //print("%@",__FUNCTION__)
        switch self.managerState {
            
            case .None: fallthrough
            case .DownloadingFinished(_): fallthrough
            case .DonwloadingTwitterUsersCancelled: fallthrough
            case .DownloadingTwitterUsersError(_, _): fallthrough
            case .DownloadingTwitterIdsError(_, _): fallthrough
            case .DownloadingTwitterUserConnectionError(_,_):
                //print("Downloading should start. DeleteOldAgedTwitterUsers")
                DBManager.sharedInstance.deleteOldAgedTwitterUsers{
                    [weak self]
                    (error, saved) in
                    print("Error deleting old aged twitter \(error)")
                    
                    self?.startUpdatingInCycle(-1)
                }
                return true
            
            case .DownloadingTwitterUsersRateLimit(_,_):
                if self.resetFailedState(self.hasPassedFailUserIdLimit(), userLimit: self.hasPassedFailUsersLimit(),userConnectionLimit: self.hasPassedUserConnectionLimit()) {
                    return startUpdatingTotalList()
                }
                break;
            case .DownloadingTwitterIdsRateLimit(_,_):
                if self.resetFailedState(self.hasPassedFailUserIdLimit(), userLimit: self.hasPassedFailUsersLimit(),userConnectionLimit: self.hasPassedUserConnectionLimit()) {
                    return startUpdatingTotalList()
                }
                break;
            case .DonwloadingTwitteruserConnectionRateLimit(_,_):
                if self.resetFailedState(self.hasPassedFailUserIdLimit(), userLimit: self.hasPassedFailUsersLimit(),userConnectionLimit: self.hasPassedUserConnectionLimit()) {
                    return startUpdatingTotalList()
                }
                break;
            default:
                break;
        }
        return false
    }
    
    
    
    private func startDownloadingTwitterUsers(items:[String]?, offset:Int, isLast:Bool) {
        
        if let count = items?.count  {
            if (count != 0) {
            self.managerState = .DownloadingTwitterUsers(offset:offset)
            
            self.getTwitterUsers(items!){
                (twitterUsers, errorTwitterUsers) in
                
                if let error1 = errorTwitterUsers {
                    
                    DBManager.sharedInstance.insertOrUpdateTwitterIds(items!, completionHandler: { (error, saved) -> Void in
                    })
                    
                    print("Error twitter users \(error1)")
                    if (TwitterManager.isTwitterLimitError(error1)) {
                        self.managerState = .DownloadingTwitterUsersRateLimit(userIds:items!,error:error1)
                    }
                    else {
                        self.managerState = .DownloadingTwitterUsersError(offset:offset,error:error1)
                    }
                }
                else {
                    
                    if let countUsers = twitterUsers?.count {
                        
                        DBManager.sharedInstance.insertOrUpdateTwitterUsers(twitterUsers!) { (error, saved) in
                            print("insertOrUpdateTwitterUsers Saved \(saved)\n Error \(error)")
                            
                            if (!saved || error != nil) {
                                return
                            }
                            
                            
                            self.managerState = .DownloadingTwitterUserConnection(offset:offset)
                            self.detectFriendShipWithUsers(twitterUsers!, block: { (usersInfo, error) -> Void in
                                
                                if let error = error {
                                
                                    if TwitterManager.isTwitterLimitError(error) {
                                        self.managerState = .DonwloadingTwitteruserConnectionRateLimit(users: twitterUsers!,error:error)
                                    }
                                    else {
                                        self.managerState = .DownloadingTwitterUserConnectionError(offset: offset,error: error)
                                    }
                                }
                                else if let usersInfoPrivate = usersInfo {
                                    
                                    if self.isCancelled {
                                        return;
                                    }
                                    
                                    DBManager.sharedInstance.storeTwitterUsers(usersInfoPrivate, completionHandler: { (error, saved) -> Void in
                                        print("Connections save operation \(error) \(saved)")
                                    })
                                    
                                }
                            })
                            
                            DBManager.sharedInstance.fetchTwitterUsersWithEmptyProfileImages({ (users, error) -> Void in
                                
                                if (error == nil && users != nil) {
                                    
                                 
                                    if (!users!.isEmpty) {
                                        
                                        //dispatch_async(self.queue) {
                                        var cancelled = self.isCancelled
                                        let counter = SignalCounter(barrier: users!.count)
                                        
                                        counter.completionBlock = {
                                            [weak self] in
                                            
                                            print("Did reach barrier!")
                                            DBManager.sharedInstance.saveContextWithCompletion({ (error, saved) -> Void in
                                                print("Saved images update or not... \(error)\n Saved \(saved)")
                                                
                                                self?.defineStateUsingCount(countUsers, count: countUsers, offset: offset, isLast: isLast, cancelled: cancelled)
                                                
                                            })
                                        }
                                        
                                        for user in users! {
                                            
                                            if cancelled || self.isCancelled {
                                                return
                                            }
                                            
                                                let userId = user.objectID
                                            
                                            print("Init user ID \(user.userId). IS Temporaty \(userId.temporaryID)")
                                            
                                                self.scheduleDBTwitterUserImageReceive(user) {
                                                    (image, error) in
                                                    
                                                    
                                                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND,0)) {
                                                        
                                                    
                                                    print("Increment counter \(counter.value) Barrier \(counter.barrier) Image \(image) Error \(error)")
                                                    
                                                    if let imageInner = image {
                                                        
                                                        
                                                        DBManager.sharedInstance.managedObjectContext.performBlock({ () -> Void in
                                                            
                                                            let retContext = DBManager.sharedInstance.managedObjectContext
                                                            do {
                                                            let retUser =  retContext.objectWithID(userId) as! TwitterUser
                                                            
                                                retUser.miniImage = UIImagePNGRepresentation(imageInner) ?? UIImageJPEGRepresentation(imageInner, 0.8)
                                                 
                                                 print("Ret user ID \(retUser.userId) Update \(retUser.updated)")
                                                                
                                                                if (!retUser.fault) {
                                                  retUser.managedObjectContext?.refreshObject(retUser, mergeChanges: true)
                                                                }
                                                                try retContext.save()
                                                                
                                                                print("Image saved. ")
                                                            }
                                                            catch let error as NSError {
                                                                print("Error Saving Image \(error)")
                                                            }
                                                            
                                                            counter.increment()
                                                            
                                                            
                                                        })
                                                        
                                                    }
                                                    else if (!cancelled && error != nil) {
                                                        
                                                        counter.increment()
                                                        
                                                        self.managerState = .DonwloadingTwitterUsersCancelled(lastEror:error)
                                                        
                                                        cancelled = true
                                                    }
                                                    else {
                                                        counter.increment()
                                                    }
                                                    
                                                    
                                                    
                                                    }
                                                }
                                            
                                        }
                                        
                                        //}
                
                                        
                                    }
                                    else {
                                        self.defineStateUsingCount(countUsers, count: count, offset: offset, isLast: isLast)
                                    }
                                }
                                else {
                                    self.defineStateUsingCount(countUsers, count: count, offset: offset, isLast: isLast)
                                }
                            })
                        }
                        
                        /*
                        // TODO : Store or update users here....
                        DBManager.sharedInstance.insertOrUpdateTwitterIds(items!, completionHandler: { (error, saved) -> Void in
                            print("Saved \(saved)\n Error \(error)")
                            if (countUsers == 100 && !isLast) {
                                
                                self.startUpdatingInCycle(countUsers + offset)
                            }
                        }) */
                        
                        }
                    }
                }
            }
            
            //self.managerState = .DownloadingTwitterIds(offset:max(offset,0) + count)
            
            //eee Store items here!.....
            
        }
        else if (isLast) {
            self.managerState = .DownloadingFinished(totalCount:offset)
        }
    }
    
    func defineStateUsingCount(countUsers:Int,count:Int,offset:Int,isLast:Bool,cancelled:Bool = false) {
        
        if (countUsers == 100 && !isLast && !cancelled) {
            self.startUpdatingInCycle(countUsers + offset)
        }
        else if (isLast){
            self.managerState = .DownloadingFinished(totalCount:offset + count)
        }

    }
    
    var isCancelled :Bool {
        
        switch self.managerState {
        case .DonwloadingTwitterUsersCancelled(_):
            return true
        default:
            break
        }
        return false
    }
    
    private func startUpdatingInCycle(offset:Int) {
        
        print("%@ Offset %d",#function,offset)
        
        if self.isCancelled {
            print("Cancelled")
            return
        }
        
        self.managerState = .DownloadingTwitterIds(offset:offset)
        
         print("Calling getTwitterFriendIds")
        self.getTwitterFriendIds(offset, count:100){
            (items, error,last) in
            
            print("getTwitterFriendIds Finished")
            switch self.managerState {
                
            case let .DownloadingTwitterIds(offset) :
                
                if let error = error {
                    print("Error twitter ids \(error). Items \(items)")
                    if TwitterManager.isTwitterLimitError(error) {
                        self.managerState = .DownloadingTwitterIdsRateLimit(offset:offset,error:error)
                    }
                    else {
                        self.managerState = .DownloadingTwitterIdsError(offset:offset,error:error)
                    }
                }
                else {
                    self.startDownloadingTwitterUsers(items, offset: offset,isLast: last)
                }
                
                
                break
            default:
                break
            }
        }
    }
    
    func restartTwitterUsersDownload(aNotification:NSNotification) {
        
        
        switch self.managerState {
        case .DownloadingTwitterUsersRateLimit(let items, _) :
            
            let offset = aNotification.userInfo?["offset"] as! Int
            let isLast = aNotification.userInfo?["isLast"] as! Bool
            self.startDownloadingTwitterUsers(items, offset: offset,isLast: isLast)
            
            break;
        default:
            assert(false)
            break;
        }
    }
    
    func detectFriendShipWithUsers(users:[TWTRUser],block:twitterFriendShipCompletion!) {
        
        let userId = self.twitterId
        
        var usersSetId = [String:TWTRUser]()
        
        var userIdsStr = ""
        
        for curUser in users {
            if let curUserId = curUser.userID {
                usersSetId[curUserId] = curUser
                
                if (!userIdsStr.isEmpty){
                    userIdsStr = userIdsStr.stringByAppendingString(",")
                }
                
                userIdsStr += curUserId
                
            }
        }
        
        let key = "friendship.\(userId).\(userIdsStr.hashValue))"
        print("detectFriendShipWithUsers start...")
        
        
        dispatch_async(self.queue) {
            [weak self] in
            
        
            
             var error:NSError? = nil
            
            let params:[NSObject:AnyObject] = ["user_id":userIdsStr,"screen_name":key]
            let request = self?.twitterClient.URLRequestWithMethod("GET", URL: "https://api.twitter.com/1.1/friendships/lookup.json", parameters: params, error: &error)
            
            if let errorInner = error {
                print("Error formatting \(errorInner)")
                
                assert(false)
                return
            }
            
            print("detectFriendShipWithUsers start... sendTwitterRequest")
            
            guard let requestInner = request else {
                return
            }
            
            self?.twitterClient.sendTwitterRequest(requestInner) {
                [weak self]
                (response, data, connectionError)  in
                
                guard self != nil else {
                    return
                }
                
                
                if (connectionError == nil) {
                    if let json = try? NSJSONSerialization.JSONObjectWithData(data!,
                        options: NSJSONReadingOptions.AllowFragments) as! NSArray {
                            
                            print("detectFriendShipWithUsers JSON response:\n \(json)")
                            
                            if let jsonArray = json as? [NSDictionary] {
                                
                                var result = [TWTRUser:[FriendshipStatus]]()
                                
                                for curJson in jsonArray {
                                    
                                    guard let curUserId = curJson["id_str"] as? String else {
                                        continue
                                    }
                                    
                                    guard let fUser = usersSetId[curUserId] else {
                                        continue
                                    }
                                    
                                    if let connections = curJson["connections"] as? [String] {
                                        
                                        var curState = [FriendshipStatus]()
                                        for connection in connections {
                                            
                                            switch connection{
                                                
                                            case "following":
                                                curState.append(.Following)
                                                break
                                            case "followed_by":
                                                curState.append(.FollowedBy)
                                                break
                                            case "following_requested":
                                                curState.append(.FollowingRequested)
                                                break
                                            case "none":
                                                curState.append(.None)
                                                break
                                            case "blocking":
                                                curState.append(.Blocking)
                                                break
                                            case "muting":
                                                curState.append(.Muting)
                                                break
                                            default:
                                                break
                                            }
                                        }
                                        result[fUser] = curState
                                    }
                                }
                                
                                block(usersInfo:result,error:nil)
                            }
                            else {
                                block(usersInfo:nil ,error: nil)
                            }
                    }
                }
                else {
                    print("twitter Request... Error: \(connectionError)")
                    block(usersInfo:nil,error:connectionError)
                    //block(items: nil,error: connectionError)
                    /*
Optional(Error Domain=TwitterAPIErrorDomain Code=88 "Request failed: client error (429)" UserInfo={NSErrorFailingURLKey=https://api.twitter.com/1.1/friendships/lookup.json, NSLocalizedDescription=Request failed: client error (429), NSLocalizedFai*/
                    
                }
                
            }
            
        }
    }
    
    deinit {
        print("DeInit")
        NSObject.cancelPreviousPerformRequestsWithTarget(self, selector: #selector(TwitterManager.tryToGetConfiguration), object: nil)
    }
    
    func getTwitterUsers(userIds:[String],block:twitterFriendsCompletion!) {
        assert(!userIds.isEmpty)
        
        
        dispatch_async(self.queue) {
            [weak self] in
            
            //No friends.!.... - friends
            var error:NSError? = nil
            
            let userIdsStr = userIds.joinWithSeparator(",")
            /*let screenNamesInternal = userIds.map{
                return "\($0)'s friends"
            }*/
            //.let screenNames = screenNamesInternal.joinWithSeparator(",")
            
            let params:[NSObject:AnyObject] = ["user_id":userIdsStr/*,"screen_name":screenNames*/]
            let request = self?.twitterClient.URLRequestWithMethod("POST", URL: "https://api.twitter.com/1.1/users/lookup.json", parameters: params, error: &error)
            
            if let errorInner = error {
                print("Error formatting \(errorInner)")
                assert(false)
                return
            }
            
            guard let requestInner = request else {
                return
            }
            
            self?.twitterClient.sendTwitterRequest(requestInner) {
                [weak self]
                (response, data, connectionError)  in
                
                guard self != nil else {
                    return
                }
            
                
                if (connectionError == nil) {
                    if let json = try? NSJSONSerialization.JSONObjectWithData(data!,
                        options: NSJSONReadingOptions.AllowFragments) as! NSArray {
                            
                            print("JSON response:\n \(json)")
                            
                            if let jsonArray = json as? [NSDictionary] {
                                
                                let users =  jsonArray.map({ (value) -> TWTRUser in
                                    return TWTRUser(JSONDictionary: value as! [NSObject : AnyObject])
                                })
                                //users.removeRange(Range(start: 0,end: users.count - 4))
                                
                                block(items:users,error:nil)
                            }
                            else {
                                block(items:nil ,error: nil)
                            }
                    }
                }
                else {
                    print("twitter Request... Error: \(connectionError)")
                    block(items: nil,error: connectionError)
                    
                }
                
            }
        }
    }
    
    func getTwitterFriendIds(offset:Int = -1, count:Int = 100, block:friendsCompletion!) {
        
        dispatch_async(self.queue) {
            [weak self] in
            
            //No friends.!.... - friends
            var error:NSError? = nil
            let params:[NSObject:AnyObject] = ["cursor":"\(offset)", "count":"\(count)", "screen_name":"\(self?.twitterId)'s friends"]
            let request = self?.twitterClient.URLRequestWithMethod("GET", URL: "https://api.twitter.com/1.1/friends/ids.json", parameters: params, error: &error)
            
            if let errorInner = error {
                print("Error formatting \(errorInner)")
                assert(false)
                return
            }
            
            guard let requestInner = request else {
                return
            }
            
            self?.twitterClient.sendTwitterRequest(requestInner) {
                [weak self]
                (response, data, connectionError)  in
                
                guard self != nil else {
                    return
                }
                
                
                if (connectionError == nil) {
                    if let json = try? NSJSONSerialization.JSONObjectWithData(data!,
                        options: NSJSONReadingOptions.AllowFragments) as! NSDictionary {
                            let ids = json.objectForKey("ids")
                            
                            print("JSON response:\n \(json) \n Ids:\(ids))")
                            
                            var items = [String]()
                            
                            for id in (ids as? NSArray)! {
                                
                                if let number = id as? NSNumber {
                                    items.append("\(number.longLongValue)")
                                }
                            }
                            
                            block(items: items,error: nil,last:(json.objectForKey("next_cursor_str") as? String) == Optional<String>("0"))
                            
                    }
                }
                else {
                    print("twitter Request... Error: \(connectionError)")
                    block(items: nil,error: connectionError,last: false)
                    
                }
            }
        }
        
    }
    
    private func receiveTwitterFriend(userId:String,completion:((user:TWTRUser?,error:NSError?)->Void)!)  {
        
        dispatch_async(self.queue) {
            [weak self] in
            
            self?.twitterClient.loadUserWithID(userId){
                (user,error) in
                
                completion(user: user,error:error)
            }
        }
    }
    
    func _receiveExtendedTwitterFriend(userId:String,completion:((user:TWTRUser?,image:UIImage?,error:NSError?)->Void)!) {
        
        receiveTwitterFriend(userId) {
            [weak self]
            (user, error) in
            
            if let user = user {
                
                self?.scheduleTwitterUserImageReceive(user){
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
            [weak self] in
            
           
            
            for userId in userIds {
                
                if (cancelled) {
                    break
                }
                
                self?.receiveTwitterFriend(userId){
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
            [weak self]
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
                        self?.scheduleTwitterUserImageReceive(user) {
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
                if let queue = self?.queue {
                    dispatch_barrier_async(queue){
                        completion(expandedUsers: !expandedUsers.isEmpty ? expandedUsers : nil,error:lastError)
                    }
                }
                
            }
            else {
                completion(expandedUsers: nil,error:error)
            }
        }
    }
    
    func cancelTwitterRequestForUser(userId:String) {
        
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
        
        if !self.userImageTasks.isEmpty {
            let userIds = self.userImageTasks.keys
            
            for userId in userIds {
                if let taskId = self.userImageTasks.removeValueForKey(userId) {
                    NetworkManager.sharedManager.cancelTask(taskId)
                }
            }
        }
        
        self.managerState = .DonwloadingTwitterUsersCancelled(lastEror:nil)
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
            [weak self]
            (image, error) in
            if let _ = self?.userImageTasks.removeValueForKey(userId) {
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
    
    
    private func scheduleDBTwitterUserImageReceive(user:TwitterUser!, completion:((image:UIImage?,error:NSError?)->Void)!) {
        let userId = user.userId!
        
        let taskId = getTwitterUserImageForUrl(user.profileImageMiniURL) {
            [weak self]
            (image, error) in
            if let _ = self?.userImageTasks.removeValueForKey(userId) {
                completion(image:image,error: error)
            }
            else {
                completion(image:image,error:error)
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
    
    private func getTwitterUserImageForUrl(userUrlStr:String!,completion:((image:UIImage?,error:NSError?)->Void)!) -> Int {
        
        guard let urlStr = userUrlStr  else {
            completion(image: nil,error:nil)
            return Int.min
        }
        
        print("Downloading image \(urlStr)")
        
        return NetworkManager.sharedManager.downloadFileFromPath(urlStr) {
            (path, error)  in
            
            print("Result of Downloading image \(urlStr). Local Path \(path) Error \(error)")
            
            guard path != nil && error == nil else {
                
                let image = TwitterManager.imageFromPathOrUrl(path,urlStr: urlStr)
                
                completion(image: image,error: error)
                return
            }
            
            let image = TwitterManager.imageFromPathOrUrl(path,urlStr: urlStr)
            completion(image: image,error: nil)
        }

    }
    
    private class func imageFromPathOrUrl(path:String?,urlStr:String!) -> UIImage? {
        
        var image:UIImage? = nil
        if (path != nil) {
            image = UIImage(contentsOfFile: path!)
        }
        if (image == nil) {
            if let data = NSData(contentsOfURL: NSURL(string:urlStr)!) {
                image = UIImage(data: data)
            }
        }
        return image
    }
}

//MARK: Limit Rate Processing
extension TwitterManager {
    
    private struct Constants {
        static let userIdLimit = "jc.userIdLimit"
        static let userLimit   = "jc.userLimit"
        static let userConnectionLimit = "jc.userConnection"
        
        static let userConnectionLimitInterval = NSTimeInterval(15*60)
        static let userIdLimitInterval = NSTimeInterval(15*60)
        static let userLimitInterval   = NSTimeInterval(15*60)
    }
    
    func storeFailUserIdLimit() -> Bool {
        let res =  TwitterManager.storeFailForKey(Constants.userIdLimit)
    
        let delayTime = dispatch_time(DISPATCH_TIME_NOW,
            Int64(Constants.userIdLimitInterval * Double(NSEC_PER_SEC)))
        
        dispatch_after(delayTime,self.queue) {
            [weak self] in
            self?.resetFailedState(true,userLimit: false,userConnectionLimit: false)
        }
        
        return res
    }
    
    func storeFailUsersLimit() -> Bool {
        let res =  TwitterManager.storeFailForKey(Constants.userLimit)
    
        let delayTime = dispatch_time(DISPATCH_TIME_NOW,
            Int64(Constants.userLimitInterval * Double(NSEC_PER_SEC)))
        
        dispatch_after(delayTime,self.queue) {
            [weak self] in
            self?.resetFailedState(false,userLimit: true,userConnectionLimit: false)
        }
        
        return res
    }
    
    func storeFailUserConnectionLimit() -> Bool {
        let res =  TwitterManager.storeFailForKey(Constants.userConnectionLimit)
        
        let delayTime = dispatch_time(DISPATCH_TIME_NOW,
            Int64(Constants.userConnectionLimitInterval * Double(NSEC_PER_SEC)))
        
        dispatch_after(delayTime,self.queue) {
            [weak self] in
            self?.resetFailedState(false,userLimit: false,userConnectionLimit: true)
        }
        
        return res
    }
    
    
    func resetFailedState(let userIdLimit:Bool,let userLimit:Bool,let userConnectionLimit:Bool) -> Bool {
     
        var result:Bool = false
        
        switch (self.managerState) {
            
        case .DownloadingTwitterIdsRateLimit(_,_):
            if (userIdLimit) {
                result = removeFailUserIdLimit()
                self.managerState = .None
            }
            break
        case .DownloadingTwitterUsersRateLimit(_,_):
            if (userLimit) {
                result = removeFailUsersLimit()
                self.managerState = .None
            }
            break
        case .DonwloadingTwitteruserConnectionRateLimit(_, _):
            if (userConnectionLimit) {
                result = removeFailUserConnectionLimit()
                self.managerState = .None
            }
        default:
            break
        }
        
        return result
    }
    
    
    func hasPassedFailUserIdLimit() -> Bool {
        return TwitterManager.hasPassedForKey(Constants.userIdLimit, interval: Constants.userIdLimitInterval)
    }
    
    func hasPassedFailUsersLimit() -> Bool {
         return TwitterManager.hasPassedForKey(Constants.userLimit, interval: Constants.userLimitInterval)
    }
    
    func hasPassedUserConnectionLimit() -> Bool {
        return TwitterManager.hasPassedForKey(Constants.userConnectionLimit, interval: Constants.userConnectionLimitInterval)
    }
    
    func removeFailUserConnectionLimit() -> Bool {
        return TwitterManager.removeFailForKey(Constants.userConnectionLimit)
    }
    
    func removeFailUserIdLimit() -> Bool {
        return TwitterManager.removeFailForKey(Constants.userIdLimit)
    }
    
    func removeFailUsersLimit() -> Bool {
        return TwitterManager.removeFailForKey(Constants.userLimit)
    }
    
    private class func removeFailForKey(let key:String) -> Bool {
        NSUserDefaults.standardUserDefaults().removeObjectForKey(key)
        return NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    private class func storeFailForKey(let key:String) -> Bool {
        let timeInterval = NSDate().timeIntervalSinceReferenceDate
        NSUserDefaults.standardUserDefaults().setDouble(timeInterval, forKey: key)
        return NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    private class func hasPassedForKey(let key:String,let interval:NSTimeInterval) -> Bool {
        let timeInterval = NSDate().timeIntervalSinceReferenceDate
        let timeIntervalOld = NSUserDefaults.standardUserDefaults().doubleForKey(key)
        
        return timeIntervalOld != 0 && (timeInterval - timeIntervalOld >= interval)
    }
    
}

// MARK: Configuration
extension TwitterManager {
    
    private struct ConfConst {
        static let ConfigurationPrevDate = "ConfigurationPrevDate"
        static let ConfigurationPrevDateInterval: Double = 1*24*60*60 // 1 day
        static let ConfigurationPrevAttemptDate = "ConfigurationPrevAttemptDate"
        static let ConfigurationPrevAttemptInterval:Double = 15*60
        static let ConfigurationTextLimit = "ConfigurationTextLimit"
    }
    
    func tryToGetConfiguration() -> Bool {
        
        let prevTimeInterval = prevConfigurationAttempDate()
        let prevReqInterval = prevConfigurationPrevDate()
        
        let diff1 = NSDate().timeIntervalSinceReferenceDate  -  prevTimeInterval
        let diff2 = NSDate().timeIntervalSinceReferenceDate  -  prevReqInterval
        
        
        if  diff1 < ConfConst.ConfigurationPrevAttemptInterval || diff2 < ConfConst.ConfigurationPrevDateInterval {
            
            assert(prevTimeInterval != 0 || prevReqInterval != 0)
            
                NSObject.cancelPreviousPerformRequestsWithTarget(self, selector: #selector(TwitterManager.tryToGetConfiguration), object: nil)
                self.performSelector(#selector(TwitterManager.tryToGetConfiguration), withObject: nil, afterDelay: min(diff1,diff2))
            
            return false
        }
        
        self.getConfiguration {
            [weak self]
            (configuration,error) in
            
            if let errorInternal = error {
                
                if TwitterManager.isTwitterLimitError(errorInternal) {
                    self?.storePrevConfigurationAttempDate()
                }
            }
            else {
                self?.storePrevConfigurationPrevDate()
             
                if let dic = configuration {
                    
                    let textCharacterLimit =  dic["dm_text_character_limit"] as! Int
                    
                    if self?.storeTextLimitKey(textCharacterLimit) == Optional(true) {
                        self?.storePrevConfigurationPrevDate()
                        self?.storePrevConfigurationAttempDate(true)
                    }
                }
            }
        }
        
        return true
    }
    
    func storeTextLimitKey(limit:Int) -> Bool {
        NSUserDefaults.standardUserDefaults().setInteger(limit, forKey: ConfConst.ConfigurationTextLimit)
        
        return NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    func textLimit() -> Int {
        
        let limit = NSUserDefaults.standardUserDefaults().integerForKey(ConfConst.ConfigurationTextLimit)
        
        return limit
    }
    
    func prevConfigurationPrevDate() -> NSTimeInterval {
        return NSUserDefaults.standardUserDefaults().doubleForKey(ConfConst.ConfigurationPrevDate)
    }
    
    func storePrevConfigurationAttempDate(remove:Bool = false) -> Bool {
        
        let key = ConfConst.ConfigurationPrevAttemptDate
        
        if (remove) {
            NSUserDefaults.standardUserDefaults().removeObjectForKey(key)
        }
        else {
            NSUserDefaults.standardUserDefaults().setDouble(NSDate().timeIntervalSinceReferenceDate, forKey: key)
        }
        
        return NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    func storePrevConfigurationPrevDate() -> Bool {
        
        NSUserDefaults.standardUserDefaults().setDouble(NSDate().timeIntervalSinceReferenceDate, forKey: ConfConst.ConfigurationPrevDate)
        
        return NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    func prevConfigurationAttempDate() -> NSTimeInterval {
        
        return NSUserDefaults.standardUserDefaults().doubleForKey(ConfConst.ConfigurationPrevAttemptDate)
    }
    
    func getConfiguration(completion:twitterConfigurationCompletion) {
       
        let client = self.twitterClient
        
        
        dispatch_async(self.queue) {
            
            
            var error:NSError? = nil
            
            let request = client.URLRequestWithMethod("GET", URL: "https://api.twitter.com/1.1/help/configuration.json", parameters: nil, error: &error)
            
            if let errorInner = error {
                print("Error formatting \(errorInner)")
                
                assert(false)
                return
            }

            client.sendTwitterRequest(request) {
                (response, data, connectionError)  in
                
                
                if (connectionError == nil) {
                    if let json = try? NSJSONSerialization.JSONObjectWithData(data!,
                        options: NSJSONReadingOptions.AllowFragments) as! [String:AnyObject] {
                        print("Configuration: \(json)")
                            completion(configuration: json, error: nil)
                    }
                    else {
                        print("Error was not able to convert response")
                        completion(configuration: nil, error: nil)
                    }
                }
                else {
                    print("Error configuration \(connectionError)")
                    completion(configuration: nil, error: connectionError)
                }
                
            }
            
        }
    }
    
    func configurationKey() -> String {
        
        let key = "configuration-\(self.twitterId)"
        return key
    }
    
    
}

//MARK: Error analysis
extension TwitterManager {
    
    private class func isTwitterLimitError(error:NSError) -> Bool {
        
        return error.domain == "TwitterAPIErrorDomain" && error.code == 88
    }
    
    func isLimitRate() -> Bool {
        
        switch self.managerState {
        case .DownloadingTwitterUsersRateLimit(_, _): fallthrough
        case .DownloadingTwitterIdsRateLimit(_, _): fallthrough
        case .DonwloadingTwitteruserConnectionRateLimit(_, _):
            return true
        default:
            break
        }
        
        return false
    }
    
    func isError() -> (result:Bool,error:NSError?) {
        
        var result:Bool = false
        var retError:NSError? = nil
        
        switch self.managerState {
        case .DownloadingTwitterUsersError(_, let error):
            result = false
            retError = error
            break
        case .DownloadingTwitterIdsError(_, let error):
            result = false
            retError = error
            break
        case .DownloadingTwitterUserConnectionError(_,let error):
            result = false
            retError = error
            break
        default:
            break
        }
        
        return (result,retError)
    }
}

//MARK: Send direct message
extension TwitterManager {
    
    func sendMessageToUser(userId:String,text:String,completion:(messageId:String?,error:NSError?) ->Void) {
        
        dispatch_async(self.queue) {
            [weak self] in
            
            
            var error:NSError? = nil
            
            
            let customAllowedSet =  NSCharacterSet.URLQueryAllowedCharacterSet()
            let eText = text.stringByAddingPercentEncodingWithAllowedCharacters(customAllowedSet)!
            
            let request = self?.twitterClient.URLRequestWithMethod("POST", URL: "https://api.twitter.com/1.1/direct_messages/new.json", parameters: ["user_id":userId,"text":eText], error: &error)
            
            guard error == nil else {
                assert(false)
                return
            }
            
            self?.twitterClient.sendTwitterRequest(request!) {
                (response, data, connectionError)  in

                if (connectionError == nil) {
                    if let json = try? NSJSONSerialization.JSONObjectWithData(data!,
                        options: NSJSONReadingOptions.AllowFragments) as! [String:AnyObject] {
                            print("Configuration: \(json)")
                            completion(messageId: json["id_str"] as? String, error: nil)
                    }
                    else {
                        print("Error was not able to convert response")
                        completion(messageId: nil, error: nil)
                    }
                }
                else {
                    print("Error sendTwitterRequest \(connectionError)")
                    completion(messageId: nil, error: connectionError)
                }

            }
        }
        
    }
}
