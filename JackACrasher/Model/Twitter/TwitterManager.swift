//
//  TwitterManager.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 1/15/16.
//  Copyright © 2016 Siarhei Yakushevich. All rights reserved.
//

import UIKit
import TwitterKit

enum TwitterManagerState {
    case None
    case DownloadingTwitterIds(offset:Int)
    case DownloadingTwitterIdsRateLimit(offset:Int)
    case DownloadingTwitterIdsError(offset:Int,error:NSError!)
    
    case DownloadingTwitterUsers(offset:Int)
    case DownloadingTwitterUsersRateLimit(userIds:[String])
    case DownloadingTwitterUsersError(offset:Int)
    
    case DownloadingFinished(totalCount:Int)
    
    case DonwloadingTwitterUsersCancelled(lastEror:NSError?)
}

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


enum FriendshipStatus {
    case Following
    case FollowingRequested
    case FollowedBy
    case None
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
}

/**
Used for downloading items from the twitter account for userId.
*/
class TwitterManager: NSObject {

    typealias friendsCompletion = (items:[String]?,error:NSError?,last:Bool) -> Void
    typealias twitterFriendsCompletion = (items:[TWTRUser]? ,error:NSError?) -> Void
    typealias twitterFriendShipCompletion = (usersInfo:[TWTRUser:[FriendshipStatus]]?,error:NSError?) -> Void
    
    private let twitterId:String!
    private let queue = dispatch_queue_create("sy.jac.twittermanager.queue", DISPATCH_QUEUE_CONCURRENT)//dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)
    private var clientMap  = [String:TWTRAPIClient]()
    private var userImageTasks = [String:Int]()
    
    private var managerState = TwitterManagerState.None
    
    private var timer:NSTimer! = nil
    
    init(twitterId:String!) {
        self.twitterId = twitterId
        super.init()
    }
    
    
    func startUpdatingTotalList() {
        
        print("%@",__FUNCTION__)
        
        switch self.managerState {
            
            case .None: fallthrough
            case .DownloadingFinished(_):
                
                print("DownloadingFinished state. DeleteOldAgedTwitterUsers")
                DBManager.sharedInstance.deleteOldAgedTwitterUsers{
                    [unowned self]
                    (error, saved) in
                    print("Error deleting old aged twitter \(error)")
                    if error == nil {
                        self.startUpdatingInCycle(-1)
                    }
                }
                
                break;
            default:
                break;
        }
    }
    
    private func startDownloadingTwitterUsers(items:[String]?, offset:Int, isLast:Bool) {
        
        if let count = items?.count  {
            if (count != 0) {
            self.managerState = .DownloadingTwitterUsers(offset:offset)
            
            self.getTwitterUsers(items!){
                (twitterUsers, errorTwitterUsers) in
                
                if let error1 = errorTwitterUsers {
                    
                    //TODO: store just user Ids here...
                    
                    if let timerInner = self.timer {
                        timerInner.invalidate()
                    }
                    
                    self.timer = NSTimer.scheduledTimerWithTimeInterval(15*60, target: self, selector: "restartTwitterUsersDownload:", userInfo: ["offset":offset,"isLast":isLast], repeats: false)
                    
                    DBManager.sharedInstance.insertOrUpdateTwitterIds(items!, completionHandler: { (error, saved) -> Void in
                    })
                    
                    //TODO: find out when it is downloading error....
                    print("Error twitter users \(error1)")
                    self.managerState = .DownloadingTwitterUsersRateLimit(userIds:items!)
                    
                    
                    
                    //self.managerState = .DownloadingTwitterUsersError(offset:offset,error:error)
                }
                else {
                    
                    if let countUsers = twitterUsers?.count {
                        //TODO: store into DB status.., of friendShip...
                        
                        //var count = 0;
                        
                        //for twitterUser in twitterUsers! {
                            
                            //count++
                            
                            //if (count == 20) {
                            //    break
                            //}
                            //dispatch_async(dispatch_get_main_queue()) {
                            self.detectFriendShipWithUsers(twitterUsers!, block: { (usersInfo, error) -> Void in
                                print("Friendship error %@",error)
                               
                                if let usersInfoPrivate = usersInfo {
                                    for (userInfo,connections) in usersInfoPrivate {
                                        
                                        guard let f = connections.first,l = connections.last else {
                                            continue
                                        }
                                        
                                        let isFriend = f.isFriend(l)
                                        let isFollowing = f.isFollowing() || l.isFollowing()
                                        
                                       print("\(userInfo.name) Connections \(connections)   is Friend \(isFriend) IS following \(isFollowing)")
                                        }
                                    
                                    /*
                                    Телеканал Дождь Connections [JackACrasher.FriendshipStatus.Following]   is Friend false IS following true
                                    Jason Majoue Connections [JackACrasher.FriendshipStatus.Following, JackACrasher.FriendshipStatus.FollowedBy]
*/
                                    
                                    }
                                })
                            //}
                            
                        //}
                        DBManager.sharedInstance.insertOrUpdateTwitterUsers(twitterUsers!) { (error, saved) in
                            print("insertOrUpdateTwitterUsers Saved \(saved)\n Error \(error)")
                            
                            if (!saved || error != nil) {
                                return
                            }
                            
                            DBManager.sharedInstance.fetchTwitterUsersWithEmptyProfileImages({ (users, error) -> Void in
                                
                                if (error == nil && users != nil) {
                                    
                                 
                                    if (!users!.isEmpty) {
                                        
                                        //dispatch_async(self.queue) {
                                        var cancelled = false
                                        let counter = SignalCounter(barrier: users!.count)
                                        for user in users! {
                                            
                                            if cancelled {
                                                return
                                            }
                                            
                                            
                                                self.scheduleDBTwitterUserImageReceive(user) {
                                                    (image, error) in
                                                    
                                                    
                                                    
                                                    print("Increment counter Image \(image) Error \(error)")
                                                    
                                                    if let imageInner = image {
                                                        
                                                        DBManager.sharedInstance.managedObjectContext.performBlock({ () -> Void in
                                                            
                                                            counter.increment()
                                                            
                                                            user.miniImage = UIImagePNGRepresentation(imageInner) ?? UIImageJPEGRepresentation(imageInner, 0.8)
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
                                                    
                                                    if counter.didReachBarrierOnce() {
                                                        
                                                        DBManager.sharedInstance.saveContextAsynchWithCompletion({ (error, saved) -> Void in
                                                        print("Saved images update or not... \(error)\n Saved \(saved)")
                                                            if (countUsers == 100 && !isLast && !cancelled) {
                                                                self.startUpdatingInCycle(countUsers + offset)
                                                            }
                                                        })
                                                    }
                                                    
                                                    
                                                }
                                            
                                        }
                                        
                                        //}
                
                                        
                                    }
                                    else {
                                        if (countUsers == 100 && !isLast) {
                                            self.startUpdatingInCycle(countUsers + offset)
                                        }
                                    }
                                }
                                else {
                                    if (countUsers == 100 && !isLast) {
                                        self.startUpdatingInCycle(countUsers + offset)
                                    }
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
            
            
            if (count < 100 && isLast) {
                self.managerState = .DownloadingFinished(totalCount:offset + count)
            }
        }
        else if (isLast) {
            self.managerState = .DownloadingFinished(totalCount:offset)
        }
    }
    
    private var isCancelled :Bool {
        
        switch self.managerState {
        case .DonwloadingTwitterUsersCancelled(_):
            return true
        default:
            break
        }
        return false
    }
    
    private func startUpdatingInCycle(offset:Int) {
        
        print("%@ Offset %d",__FUNCTION__,offset)
        
        if self.isCancelled {
            print("Cancelled")
            return
        }
        
        self.managerState = .DownloadingTwitterIds(offset:offset)
        
         print("Calling getTwitterFriendIds")
        getTwitterFriendIds(offset, count:100){
            (items, error,last) in
            
            print("getTwitterFriendIds Finished")
            switch self.managerState {
                
            case let .DownloadingTwitterIds(offset) :
                
                if let error = error {
                    //TODO: find out when it is downloading error....
                    print("Error twitter ids \(error). Items \(items)")
                    self.managerState = .DownloadingTwitterIdsRateLimit(offset:offset)
                    
                    //self.managerState = .DownloadingTwitterIdsError(offset:offset,error:error)
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
        
        self.timer = nil;
        
        switch self.managerState {
        case .DownloadingTwitterUsersRateLimit(let items) :
            
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
        let client = TWTRAPIClient(userID: userId)
        clientMap[key] = client
        
        //https:
        
        dispatch_async(self.queue) {
            [unowned self] in
            
        
            
             var error:NSError? = nil
            
            let params:[NSObject:AnyObject] = ["user_id":userIdsStr,"screen_name":key]
            let request = client.URLRequestWithMethod("GET", URL: "https://api.twitter.com/1.1/friendships/lookup.json", parameters: params, error: &error)
            
            if let errorInner = error {
                print("Error formatting \(errorInner)")
                self.clientMap.removeValueForKey(key)
                assert(false)
                return
            }
            
            print("detectFriendShipWithUsers start... sendTwitterRequest")
            client.sendTwitterRequest(request) {
                [unowned self]
                (response, data, connectionError)  in
                
                if self.clientMap.isEmpty || self.clientMap.removeValueForKey(key) == nil {
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
    
    func getTwitterUsers(userIds:[String],block:twitterFriendsCompletion!) {
        assert(!userIds.isEmpty)
        
        let userId = self.twitterId
        let client = TWTRAPIClient(userID: userId)
        clientMap[userId] = client
        
        dispatch_async(self.queue) {
            [unowned self] in
            
            //No friends.!.... - friends
            var error:NSError? = nil
            
            let userIdsStr = userIds.joinWithSeparator(",")
            /*let screenNamesInternal = userIds.map{
                return "\($0)'s friends"
            }*/
            //.let screenNames = screenNamesInternal.joinWithSeparator(",")
            
            let params:[NSObject:AnyObject] = ["user_id":userIdsStr/*,"screen_name":screenNames*/]
            let request = client.URLRequestWithMethod("POST", URL: "https://api.twitter.com/1.1/users/lookup.json", parameters: params, error: &error)
            
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
                        options: NSJSONReadingOptions.AllowFragments) as! NSArray {
                            
                            print("JSON response:\n \(json)")
                            
                            if let jsonArray = json as? [NSDictionary] {
                                
                                let users =  jsonArray.map({ (value) -> TWTRUser in
                                    return TWTRUser(JSONDictionary: value as [NSObject : AnyObject])
                                })
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
    
    
    private func scheduleDBTwitterUserImageReceive(user:TwitterUser!, completion:((image:UIImage?,error:NSError?)->Void)!) {
        let userId = user.userId!
        
        let taskId = getTwitterUserImageForUrl(user.profileImageMiniURL) {
            [unowned self]
            (image, error) in
            if let _ = self.userImageTasks.removeValueForKey(userId) {
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
