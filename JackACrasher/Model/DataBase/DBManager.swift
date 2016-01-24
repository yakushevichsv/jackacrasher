//
//  DBManager.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 1/11/16.
//  Copyright © 2016 Siarhei Yakushevich. All rights reserved.
//

import UIKit
import CoreData
import TwitterKit

class DBManager: NSObject {

    internal static let sharedInstance = DBManager()
    private let queue = dispatch_queue_create("DBManager", DISPATCH_QUEUE_CONCURRENT)
    
    var lastError:NSError? = nil
    private var canWork = true
    
    
    override init() {
        super.init()
        
        //#if DEBUG
            //test()
        //#endif
    }
    
    //MARK - Core Data Stack
    
    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named \in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls.last!
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("DBModel", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("DBModel.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        } catch let error as NSError {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            
            dict[NSUnderlyingErrorKey] = error
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            self.lastError = wrappedError
            self.canWork = false
            #if DEBUG
                abort()
            #endif
        } catch {
            #if DEBUG
                abort()
            #endif
        }
        
        return coordinator
    }()
    
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    //MARK: Test Method
    
   private func test() {
        
        dispatch_async(self.queue){
            
            let fetchRequest = NSFetchRequest(entityName: TwitterId.EntityName())
            
            fetchRequest.predicate =
                NSPredicate(format: "userId != nil")
        
            let count = self.managedObjectContext.countForFetchRequest(fetchRequest, error: nil)
        
            if count > 0 {return }
        
        
            
            let entity = NSEntityDescription.insertNewObjectForEntityForName(TwitterId.EntityName(),
                inManagedObjectContext: self.managedObjectContext) as! TwitterId
            
            entity.userId = "Sam"
            
            let result = self.saveContext()
            
            if (result) {
                
                if let entity2 = try! self.managedObjectContext.executeFetchRequest(fetchRequest).last as? TwitterId {
                    
                    self.managedObjectContext.deleteObject(entity2)
                    
                    assert(self.saveContext())
                    return
                }
            }
            
            assert(false)
        }
    }
    
    
    //MARK: Twitter Ids methods....
    
    internal func insertOrUpdateTwitterIds(userIds:[String],completionHandler:(error:NSError?,saved:Bool) -> Void) {
        
        dispatch_async(self.queue) {
            [unowned self] in
            
         
            let request = NSFetchRequest(entityName: TwitterId.EntityName())
            request.predicate = NSPredicate(format: "userId IN {%@}", userIds.joinWithSeparator(","))
            
            do {
                let existingDBTwitterIds = try self.managedObjectContext.executeFetchRequest(request) as! [TwitterId]
                
                
               let nonExistingUserIds = userIds.filter{ (value) in
                    for existingDBTwitterId in existingDBTwitterIds {
                        
                        if (existingDBTwitterId.userId == Optional<String>(value)){
                            return false
                        }
                    }
                    return true
                }
                
                for nonExistingUserId in nonExistingUserIds {
                    self.insertTwitterIdRecord(nonExistingUserId)
                }
                
                self.saveContextWithCompletion({ (error, saved) -> Void in
                    completionHandler(error: error, saved: saved)
                })
            }
            catch let error as NSError {
                completionHandler(error: error, saved: false)
            }
        }
    }
    
    /*
    
    func deleteAllRecords() {
        
    
    }
*/
    
    func insertTwitterIdRecord(userId:String) -> TwitterId! {
     
        let twitterId =  NSEntityDescription.insertNewObjectForEntityForName(TwitterId.EntityName(), inManagedObjectContext: self.managedObjectContext) as! TwitterId
        twitterId.userId = userId
        return twitterId
    }
    
    private func updateTwitterUser(dbTwitterUser:TwitterUser, userRecord:TWTRUser) {
        
        dbTwitterUser.userId = userRecord.userID//(userRecord.objectForKey("id_str") as! String)
        
        if let urlStr = userRecord.profileImageMiniURL ?? userRecord.profileImageMiniURL ?? userRecord.profileImageLargeURL {
        
            if urlStr != dbTwitterUser.profileImageMiniURL {
                dbTwitterUser.profileImageMiniURL = urlStr
                dbTwitterUser.miniImage = nil;
            }
        }
        
        if let userName = userRecord.name /*userRecord.objectForKey("name") as? String*/ {
            dbTwitterUser.userName = userName
        }
        
        if let screenName = userRecord.screenName/*userRecord.objectForKey("screen_name") as? String*/ {
            dbTwitterUser.screenName = screenName
        }
        
        //if let verified = userRecord.isVerified/*userRecord.objectForKey("verified") as? Bool*/ {
        dbTwitterUser.isVerified = userRecord.isVerified
        //}
        dbTwitterUser.lastUpdateTime = NSDate().timeIntervalSinceReferenceDate
    }
    
    func insertTwitterUserRecord(userRecord: TWTRUser /*NSDictionary*/) -> TwitterUser! {
        
        let dbTwitterUser =  NSEntityDescription.insertNewObjectForEntityForName(TwitterUser.EntityName(), inManagedObjectContext: self.managedObjectContext) as! TwitterUser
        
        self.updateTwitterUser(dbTwitterUser,userRecord: userRecord)

        return dbTwitterUser
    }
    
    //MARK: Twitter Users
    
    func fetchTwitterUsersWithEmptyProfileImages(completionHandler:(users:[TwitterUser]?, error:NSError?) -> Void) {
        
        dispatch_async(self.queue) {
            [unowned self] in
        
            let request = NSFetchRequest(entityName: TwitterUser.EntityName())
            request.predicate = NSPredicate(format: "miniImage == NULL")
            
            let asyncReq = NSAsynchronousFetchRequest(fetchRequest: request){
                (result) in
                if let res = result.finalResult as? [TwitterUser] {
                    completionHandler(users: res, error: nil)
                }
            }
            
            do {
                try self.managedObjectContext.executeRequest(asyncReq)
            }
            catch let error as NSError {
                completionHandler(users: nil, error: error)
            }
            
        }
    }
    
    private func countTestTwitterUser() -> Int {
        
        let request = NSFetchRequest(entityName: TwitterUser.EntityName())
        var error:NSError? = nil
        let count = self.managedObjectContext.countForFetchRequest(request, error: &error)
        return error == nil ? count : 0
    }
    
    func getFetchedTwitterUsers<T:AnyObject where T:protocol<NSFetchedResultsControllerDelegate>>(twitterId:String, delegate:T) -> (controller:NSFetchedResultsController?,error:NSError?) {
        
        var controllerRet:NSFetchedResultsController? = nil
        var errorRet:NSError? = nil
        
        assert(countTestTwitterUser() != 0)
        
        dispatch_sync(self.queue){
            //TODO: add support for periodic update of friends....
            let request = NSFetchRequest(entityName: TwitterUser.EntityName())
            request.sortDescriptors = [NSSortDescriptor(key: "userName", ascending: true)]
            request.fetchBatchSize = 20
            let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: "\(twitterId)")
                controller.delegate = delegate
                do {
                    try controller.performFetch()
                    controllerRet = controller
                } catch let error as NSError {
                    print("\(error)")
                    errorRet = error
                }
        }
        return (controller:controllerRet,error: errorRet)
    }
    
    func deleteOldAgedTwitterUsers(completionHandler:(error:NSError?,saved:Bool) -> Void) {
        
        dispatch_async(self.queue)
            {
         [unowned self] in
                
        let request = NSFetchRequest(entityName: TwitterId.EntityName())
        
        let timeInterval = NSDate().dateByAddingTimeInterval( -3 * 30 * 24 * 60 * 60)
        
        request.predicate = NSPredicate(format: "twitterUser != nil AND twitterUser.lastUpdateTime < %@", timeInterval)
        
        request.resultType = NSFetchRequestResultType.ManagedObjectIDResultType
        
                do {
                    let result = try self.managedObjectContext.executeFetchRequest(request) as! [NSManagedObjectID]
                    
                    if (result.isEmpty) {
                        completionHandler(error: nil, saved: false)
                        return
                    }
                    
                    let batchDelete = NSBatchDeleteRequest(objectIDs: result)
                    
                    try self.managedObjectContext.executeRequest(batchDelete)
                    
                    self.saveContextWithCompletion(completionHandler)
                }
                catch let error as NSError {
                    completionHandler(error: error,saved: false)
                }
        }
    }

    func insertOrUpdateTwitterUsers(users:[TWTRUser],completionHandler:(error:NSError?,saved:Bool) -> Void) {
       
        dispatch_async(self.queue) {
            [unowned self] in
            
            
            let userIds = users.map{ (item) in
                return item.userID //item.objectForKey("id_str") as! String
            }
            
            let request = NSFetchRequest(entityName: TwitterUser.EntityName())
            
            let userIdsStr =  userIds.reduce("", combine: { (prevStr, elem) -> String in
                if !prevStr.isEmpty {
                    return prevStr + "," + elem
                }
                else {
                    return elem
                }
            })
            
            request.predicate = NSPredicate(format: "userId IN {%@}",userIdsStr)
            
            do {
                let existingDBTwitterUsers = try self.managedObjectContext.executeFetchRequest(request) as! [TwitterUser]
                
                for twitterUser in existingDBTwitterUsers {
                    if twitterUser.twitterId == nil {
                        
                        let dbTwitterIdRecord = self.insertTwitterIdRecord(twitterUser.userId!)
                        
                        twitterUser.twitterId = dbTwitterIdRecord
                        
                    }
                }
                
                let nonExistingUsers = users.filter{ (value) in
                    for existingDBTwitter in existingDBTwitterUsers {
                        
                        let idValue = value.userID//value.objectForKey("id_str") as? String
                        
                        if (existingDBTwitter.userId == idValue){
                            
                            self.updateTwitterUser(existingDBTwitter,userRecord: value)
                            
                            return false
                        }
                    }
                    return true
                }
                
                for nonExistingUser in nonExistingUsers {
                    
                    let idValue = nonExistingUser.userID//nonExistingUser.objectForKey("id_str") as? String
                    
                    if let id = idValue {
                        let twitterIdRecord = self.insertTwitterIdRecord(id)
                        let twitterUserRecord = self.insertTwitterUserRecord(nonExistingUser)
                        
                        twitterUserRecord.twitterId = twitterIdRecord
                        twitterIdRecord.twitterUser = twitterUserRecord
                    }
                }
                
                self.saveContextWithCompletion({ (error, saved) -> Void in
                    completionHandler(error: error, saved: saved)
                })
                
            }
            catch let error as NSError {
                completionHandler(error: error, saved: false)
            }
        }
    }
    
    func insertTwitterUser(user:ExpandedTwitterUser!, completion:(error:NSError?,saved:Bool,dbTwitterUser:TwitterUser?) -> Void) {
        
        let dbTwitterId = NSEntityDescription.insertNewObjectForEntityForName(TwitterId.EntityName(), inManagedObjectContext: self.managedObjectContext) as! TwitterId
        let dbTwitterUser =  NSEntityDescription.insertNewObjectForEntityForName(TwitterUser.EntityName() , inManagedObjectContext: self.managedObjectContext) as! TwitterUser
        
        dbTwitterUser.userId = dbTwitterId.userId
        dbTwitterUser.profileImageMiniURL = user.twitterUser.jacImageURL
        dbTwitterUser.userName = user.twitterUser.name
        dbTwitterUser.screenName = user.twitterUser.screenName
        if let image = user.image {
            dbTwitterUser.miniImage = UIImagePNGRepresentation(image) ?? UIImageJPEGRepresentation(image, 1.0)
        }
        dbTwitterId.twitterUser = dbTwitterUser
        dbTwitterUser.twitterId = dbTwitterId
        
        saveContextWithCompletion {
            (error, saved) in
            
            let value = saved && error == nil
            
            if value {
                completion(error:nil,saved:value,dbTwitterUser:dbTwitterUser)
            }
            else if error != nil {
                completion(error:error,saved:value,dbTwitterUser:nil)
            }
        }
    }
    
    func fetchTwitterUserWithId(userId:String,completion:(dbTwitterUser:TwitterUser?) -> Void) {
        
        let request = NSFetchRequest(entityName: TwitterUser.EntityName())
        request.fetchBatchSize = 1
        
        request.predicate = NSPredicate(format: "userId = %@", userId)
        request.resultType = NSFetchRequestResultType.ManagedObjectResultType
        
        let result = try? self.managedObjectContext.executeFetchRequest(request) as! [TwitterUser]
        
        completion(dbTwitterUser: result?.last)
    }
    
    func updateTwitterUser(user:ExpandedTwitterUser,completion:(error:NSError?,updated:Bool) -> Void) {
        
        fetchTwitterUserWithId(user.twitterUser.userID) {
            [unowned self]
            (dbTwitterUserPtr) in
            
            if let dbTwitterUser = dbTwitterUserPtr {
                
                dbTwitterUser.profileImageMiniURL = user.twitterUser.jacImageURL
                dbTwitterUser.userName = user.twitterUser.name
                dbTwitterUser.screenName = user.twitterUser.screenName
                dbTwitterUser.miniImage = UIImagePNGRepresentation(user.image!)
                
                self.saveContextWithCompletion{
                    (error,saved) in
                    completion(error: error, updated: saved)
                }
            }
            else {
                completion(error: nil,updated: false)
            }
        }
    }
    
    
    //MARK: Save context
    
    func saveContextWithCompletion(completionHandler:(error:NSError?,saved:Bool) -> Void) {
        
        if (!self.canWork) {
            completionHandler(error: self.lastError, saved: false)
            return
        }
        
        dispatch_async(self.queue) {
            [unowned self] in
            
            if self.managedObjectContext.hasChanges {
                do {
                    try self.managedObjectContext.save()
                    self.lastError = nil
                    completionHandler(error: nil, saved: true)
                } catch let nserror as NSError {
                    self.lastError = nserror
                    NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                    completionHandler(error: nserror, saved: false)
                }
            }
            else {
                completionHandler(error: nil, saved: false)
            }
        }
    }
    
    func saveContext () -> Bool {
        
        var retSaved :Bool = false
        let semaphore = dispatch_semaphore_create(0)
        
        
        self.saveContextWithCompletion { (error, saved) -> Void in
                
            retSaved = saved && error == nil
            
            dispatch_semaphore_signal(semaphore)
        }
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        
        return retSaved
    }
}
