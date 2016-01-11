//
//  DBManager.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 1/11/16.
//  Copyright © 2016 Siarhei Yakushevich. All rights reserved.
//

import UIKit
import CoreData

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
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            self.lastError = wrappedError
            self.canWork = false
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
    
    //MARK :API
    
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
