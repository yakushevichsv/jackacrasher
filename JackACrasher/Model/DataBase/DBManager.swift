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
    var lastError:NSError? = nil
    private var canWork = true
    
    
    override init() {
        super.init()
        
        //#if DEBUG
            //test()
        //#endif
        
        //#if DEBUG
            //testDBInsertOrUpdate()
        //#endif
    }
    
    //MARK - Core Data Stack
    
    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named \in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls.last!
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        //assert(NSThread.isMainThread())
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("DBModel", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        
        //assert(NSThread.isMainThread())
        var coordinator:NSPersistentStoreCoordinator! = nil
        
        //dispatch_sync(dispatch_get_main_queue()) {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
         coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
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
            //#if DEBUG
                abort()
            //#endif
        } catch {
            //#if DEBUG
                abort()
            //#endif
        }
        //}
        return coordinator
    }()
    
    private var _mainManagedObjectContext:NSManagedObjectContext! = nil
    private var _mainMOCDisposed:Bool = false
    
    var mainManagedObjectContext: NSManagedObjectContext!
    {
        get {
            if (_mainManagedObjectContext == nil) {
                
                if (_mainMOCDisposed) {
                    return nil
                }
                let coordinator = self.managedObjectContext.persistentStoreCoordinator
                let context = NSManagedObjectContext(concurrencyType:.MainQueueConcurrencyType)
                context.persistentStoreCoordinator = coordinator
                context.mergePolicy = NSRollbackMergePolicy
                context.stalenessInterval = 0
                _mainManagedObjectContext = context
                self.startListeningForChangesInManagedContext()
            }
            return _mainManagedObjectContext
        }
    }
    
    var needToRestartListening:Bool = false
    
    lazy var managedObjectContext: NSManagedObjectContext =
        {
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        managedObjectContext.mergePolicy = NSRollbackMergePolicy
        managedObjectContext.stalenessInterval = 0
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    //MARK: Test Method
    
   private func test() {
        
    self.managedObjectContext.performBlock {
        
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
    
    #if DEBUG
    
    private func testDBInsertOrUpdate() {
    
        self.testInsertOrUpdate(["XYZ","XYZ2"]) {
            (flags,error,saved) in
            
            let XYZinsert = flags["XYZ"] == true
            let XYZ2insert = flags["XYZ"] == true
            
            print("XYZ first time \(XYZinsert)")
            
            print("XYZ2 first time \(XYZ2insert)")
            
            self.testInsertOrUpdate(["XYZ","XYZ3"]) {
                (flags,error,saved) in
            
                let XYZNewInsert = flags["XYZ"] == true
                let XYZ3Insert = flags["XYZ3"] == true
                
                print("XYZ second time \(XYZNewInsert)")
                print("XYZ3 first time \(XYZ3Insert)")
            }
        }
        
    }
    
    
    private func testInsertOrUpdate(userIds:[String],completionHandler:(flags:[String:Bool],error:NSError?,saved:Bool) -> Void) {
        
        self.managedObjectContext.performBlock  {
            [unowned self] in
            
            var results = [String:Bool]()
            
            let request = NSFetchRequest(entityName: TwitterId.EntityName())
            request.predicate = NSPredicate(format: "userId IN %@", userIds)
            
            do {
                let existingDBTwitterIds = try self.managedObjectContext.executeFetchRequest(request) as! [TwitterId]
                
                for twitterId in existingDBTwitterIds {
                    results[twitterId.userId!] = false
                }
                
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
                    
                    results[nonExistingUserId] = true
                }
                
                self.saveContextWithCompletion({ (error, saved) -> Void in
                    completionHandler(flags:results, error: error, saved: saved)
                })
            }
            catch let error as NSError {
                completionHandler(flags:results,error: error, saved: false)
            }
        }
        
    }
    
    #endif
    
    //MARK: Twitter Ids methods....
    
    internal func insertOrUpdateTwitterIds(userIds:[String],completionHandler:(error:NSError?,saved:Bool) -> Void) {
        
        self.managedObjectContext.performBlock {
            [unowned self] in
            
            print("User ids \(userIds)")
         
            let request = NSFetchRequest(entityName: TwitterId.EntityName())
            request.predicate = NSPredicate(format: "userId IN %@", userIds)
            
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
                
                
                print("Non existing user ids count \(nonExistingUserIds.count) \n Existing user ids count \(existingDBTwitterIds.count) ")
                
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
        
        if let urlStr = userRecord.profileImageMiniURL ?? userRecord.profileImageURL ?? userRecord.profileImageLargeURL {
        
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
        
        self.managedObjectContext.performBlock  {
            [unowned self] in
        
            let request = NSFetchRequest(entityName: TwitterUser.EntityName())
            request.predicate = NSPredicate(format: "miniImage = nil")
            
            
            do {
                let res = try self.managedObjectContext.executeFetchRequest(request) as! [TwitterUser]
                
                completionHandler(users: res, error: nil)
                
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
    
    
    func deleteOldAgedTwitterUsers(completionHandler:(error:NSError?,saved:Bool) -> Void) {
        
        self.managedObjectContext.performBlock
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
    
    func increaseInviteCount(completeionHandler:((error:NSError?,saved:Bool) -> Void)?) {
        
        changeInviteCount(true, completeionHandler: completeionHandler)
    }
    
    func decreaseInviteCount(completeionHandler:((error:NSError?,saved:Bool) -> Void)?) {
        
        changeInviteCount(false, completeionHandler: completeionHandler)
    }
    
    private func changeInviteCount(addition:Bool, completeionHandler:((error:NSError?,saved:Bool) -> Void)?) {
        
       self.managedObjectContext.performBlock  {
            [unowned self] in
        
        let batchSize = 30
        
        let request = NSFetchRequest(entityName: TwitterUser.EntityName())
        request.fetchBatchSize = batchSize
        
        let predicate = NSPredicate()
        
        request.sortDescriptors = [NSSortDescriptor(key: "userName", ascending: true)]
        request.predicate = predicate
        
        var error:NSError? = nil
        
        let count = self.managedObjectContext.countForFetchRequest(request, error: &error)
        
        
            guard let _ = error else {
                completeionHandler?(error: error, saved: false)
                return
            }
        
            var offset = 0
            
            while (offset < count) {
                
                // TODO : fetch items....
                
                do {
                    request.fetchOffset = offset
                    let users = try self.managedObjectContext.executeFetchRequest(request) as! [TwitterUser]
                    
                    for user in users {
                        
                        if addition {
                            user.inviteCount += 1
                        } else if (user.inviteCount > 0) {
                            user.inviteCount -= 1
                        }
                    }
                    
                    offset += users.count
                    
                } catch let error as NSError {
                    completeionHandler?(error: error, saved: false)
                    return
                }
                
            }
            
            if let completion = completeionHandler {
                self.saveContextWithCompletion(completion)
            }
        }
    }
    
    func checkAllTwitterUsers(completeionHandler:((count:Int, error:NSError?,saved:Bool) -> Void)?) {
        changeSelectionState(true, completeionHandler: completeionHandler)
    }
    
    func uncheckAllTwitterUsers(completeionHandler:((count:Int,error:NSError?,saved:Bool) -> Void)?) {
        changeSelectionState(false, completeionHandler: completeionHandler)
    }
    
    
    private func changeSelectionState(selected:Bool,completeionHandler:((count:Int,error:NSError?,saved:Bool) -> Void)?) {
        
        self.managedObjectContext.performBlock {
            [unowned self] in
            
            let request = NSBatchUpdateRequest(entityName: TwitterUser.EntityName())
            request.predicate = NSPredicate(format: "selected != %@",NSNumber(bool: selected))
            request.resultType = NSBatchUpdateRequestResultType.UpdatedObjectIDsResultType
            request.propertiesToUpdate = ["selected":NSNumber(bool:selected)]
            do {
                let result = try self.managedObjectContext.executeRequest(request) as! NSBatchUpdateResult
                
                let objIDs = result.result as![NSManagedObjectID]
                
                print("changeSelectionState Changed items \(objIDs.count)",#function)
                
                for objID in objIDs {
                    let retObj = self.managedObjectContext.objectWithID(objID)
                    
                    if (retObj.fault == false) {
                        self.managedObjectContext.refreshObject(retObj, mergeChanges: true)
                    }
                }
                
                if let completion = completeionHandler {
                    let count = objIDs.count
                    self.saveContextWithCompletion({ (error, saved) -> Void in
                        print("Check uncheck db saved \(saved) Stored \(count)")
                        
                        if (!saved && error == nil) {
                            
                            let context = self.mainManagedObjectContext
                            context?.performBlockAndWait() {
                                
                                for objID in objIDs {
                                    let retObj = context.objectWithID(objID)
                                    
                                    if (retObj.fault == false) {
                                        context.refreshObject(retObj, mergeChanges: false)
                                    }
                                    /*else {
                                        try? context.existingObjectWithID(objID)
                                    }*/
                                }
                                self.saveContextWithCompletion(context) {
                                    (error, saved) in
                                    
                                    print("Main Context Check uncheck db saved \(saved) Stored \(count)")
                                    completion(count: count ,error:error,saved:saved)
                                }
                            }
                        }
                        else {
                            completion(count: count ,error:error,saved:saved)
                        }
                    })
                }
            }
            catch let error as NSError {
                completeionHandler?(count:0,error: error, saved: false)
            }
        
        }
    }
    
    func storeTwitterUsers( info:[TWTRUser : [FriendshipStatus]],completionHandler:(error:NSError?,saved:Bool) -> Void) {
        
        self.managedObjectContext.performBlock {
            
            for (twUser,connections) in info {
                
                let request = NSFetchRequest(entityName: TwitterUser.EntityName())
                request.predicate = NSPredicate(format: "userId == %@", twUser.userID)
                
                let dbUser = (try! self.managedObjectContext.executeFetchRequest(request) as! [TwitterUser]).last!
                if !connections.isEmpty {
                    
                    dbUser.fromFriendShip = Int16(connections.first!.rawValue)
                    if (connections.count == 2) {
                        dbUser.toFriendShip = Int16(connections.last!.rawValue)
                    }
                }
            }
            self.saveContextWithCompletion(completionHandler)
        }
    }

    func insertOrUpdateTwitterUsers(users:[TWTRUser],completionHandler:(error:NSError?,saved:Bool) -> Void) {
       
        self.managedObjectContext.performBlock {
            [unowned self] in
            
            
            let userIds = users.map{ (item) in
                return item.userID //item.objectForKey("id_str") as! String
            }
            
            let request = NSFetchRequest(entityName: TwitterUser.EntityName())
            
            request.predicate = NSPredicate(format: "userId IN %@",userIds)
            
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
        saveContextWithCompletion(self.managedObjectContext,completionHandler:completionHandler)
    }
    
    private func saveContextWithCompletion(context:NSManagedObjectContext!, completionHandler:(error:NSError?,saved:Bool) -> Void) {
        
        if (!self.canWork) {
            completionHandler(error: self.lastError, saved: false)
            return
        }
        
        context.performBlock {
            [unowned self] in
            if context.hasChanges {
                do {
                    try context.save()
                    self.lastError = nil
                    
                    print("Did save changes!")
                    
                    if let parent = context.parentContext {
                        
                        parent.performBlock {
                            [unowned self] in
                            
                        if parent.hasChanges {
                                do {
                                    try parent.save()
                                    self.lastError = nil
                                    completionHandler(error: nil, saved: true)
                                }
                                catch let nserror as NSError {
                                    self.lastError = nserror
                                    NSLog("Unresolved Parent error \(nserror), \(nserror.userInfo)")
                                    completionHandler(error: nserror, saved: false)
                                }
                            }
                        }
                    }
                    else {
                        completionHandler(error: nil, saved: true)
                    }
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

//MARK:Context's changes
extension DBManager {
    
    func startListeningForChangesInManagedContext() {
        let context = self.managedObjectContext
        
        if context.parentContext != nil {
            return
        }
        print("Start listening")
        
        assert(self.mainManagedObjectContext != nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(DBManager.didChangeContext(_:)), name: NSManagedObjectContextDidSaveNotification, object: context)
    }
    
    func stopListeningForChangesInManagedContext() {
        if self.managedObjectContext.parentContext != nil {
            return
        }
        
        print("Stop listening")
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NSManagedObjectContextDidSaveNotification, object: self.managedObjectContext)
    }
    
    
    func didChangeContext(notification:NSNotification) {
       
        print("didChangeContext start!")
        
        guard let sContext = notification.object as? NSManagedObjectContext else {
            return
        }
        
        if (sContext == self.mainManagedObjectContext ) {
            return
        }
        
       
        
        
            print("didChangeContext merge performBlock!")
            self.mainManagedObjectContext.performBlockAndWait({ () -> Void in
                print("didChangeContext merge changes!")
                
                self.mainManagedObjectContext.mergeChangesFromContextDidSaveNotification(notification)
            })
        
    }
}

//MARK: Main Context's methods...

extension DBManager {
    
    
    func getFetchedTwitterUsers<T:AnyObject where T:protocol<NSFetchedResultsControllerDelegate>>(twitterId:String, delegate:T) -> (controller:NSFetchedResultsController?,error:NSError?) {
        
        var controllerRet:NSFetchedResultsController? = nil
        var errorRet:NSError? = nil
    
        assert(NSThread.isMainThread())
        _mainMOCDisposed = false
        //self.stopListeningForChangesInManagedContext()
        
        //self.mainManagedObjectContext.performBlockAndWait{
          //  [unowned self] in
            
            print(#function)
        
            //assert(self.countTestTwitterUser() != 0)
            let request = NSFetchRequest(entityName: TwitterUser.EntityName())
            request.sortDescriptors = [NSSortDescriptor(key: "userName", ascending: true)]
            let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.mainManagedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
            controller.delegate = delegate
            do {
            
                if self.needToRestartListening  {
                    
                    self.startListeningForChangesInManagedContext()
                    
                    self.needToRestartListening = false
                }
                
                try controller.performFetch()
                
                controllerRet = controller
                print("CONTROLLER performFetch ")
            } catch let error as NSError {
                print("ERROR CONTROLLER! \(error)")
                errorRet = error
                self.stopListeningForChangesInManagedContext()
                
                self.needToRestartListening = true
            }
        //}
        return (controller:controllerRet,error: errorRet)
    }
    
    func getSelectedItemsCount(completion:(count:Int,error:NSError?)->Void) {
        countItemsWithPredicateAsync(NSPredicate(format: "selected == %@",NSNumber(bool: true)),completion:completion)
    }
    
    func selectedITwitterUsers(offset:Int,batchSize:Int) -> [TwitterUser]? {
        
        let request = NSFetchRequest(entityName: TwitterUser.EntityName())
        request.sortDescriptors = [NSSortDescriptor(key: "userName", ascending: true)]
        request.predicate = NSPredicate(format: "selected == %@",NSNumber(bool: true))
        request.resultType = NSFetchRequestResultType.ManagedObjectResultType
        request.fetchOffset = offset
        request.fetchLimit = batchSize
        //request.fetchBatchSize = batchSize
        
        return try? self.mainManagedObjectContext.executeFetchRequest(request) as! [TwitterUser]
    }
    
    func countSelectedItems() -> Int {
        
        return countItemsWithPredicate(NSPredicate(format: "selected == %@",NSNumber(bool: true)))
    }
    
    func totalCountOfTwitterUsers() -> Int {
        
        return countItemsWithPredicate(nil)
    }
    
    func disposeUIContext() {
        stopListeningForChangesInManagedContext()
        _mainMOCDisposed = true
        _mainManagedObjectContext = nil
    }
    
    private func countItemsWithPredicateAsync(predicate:NSPredicate?,completion:(count:Int,error:NSError?)->Void) {
        
        let context = self.managedObjectContext
        
        context.performBlock{
            let request = NSFetchRequest(entityName: TwitterUser.EntityName())
            request.predicate = predicate
            
            var error:NSError? = nil
            let countInner = context.countForFetchRequest(request, error: &error)
            
            if (error != nil){
                print("Error \(error)\n")
            }
            completion(count: countInner,error:error)
        }
        
    }
    
    
    private func countItemsWithPredicate(predicate:NSPredicate?) -> Int {
        
        var count:Int = NSNotFound
        let context = self.managedObjectContext
        
        context.performBlockAndWait{
            let request = NSFetchRequest(entityName: TwitterUser.EntityName())
            request.predicate = predicate
            
            var error:NSError? = nil
            let countInner = context.countForFetchRequest(request, error: &error)
            
            if (error != nil){
                print("Error \(error)\n")
            }
            count = countInner
        }
        
        return count
    }
}
