//
//  NetworkManager.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 6/20/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit


class NetworkManager: NSObject, NSURLSessionDelegate,NSURLSessionDownloadDelegate,NSURLSessionTaskDelegate {
   
    private static var sContext:dispatch_once_t = 0
    private static var sManager:NetworkManager! = nil
    private static let sBGConfiguration = "sBGConfiguration"
    
    private var bgSession:NSURLSession! = nil
    
    private let queue = NSOperationQueue()
    
    typealias downloadCompletion = (path:String?,error:NSError?)->Void
    
    private var completionHandler: (() -> Void)! = nil
    
    private var tasksDic = [Int:NSURLSessionTask]()
    private var tasksCompletions = [Int:downloadCompletion]()
    internal static var sharedManager:NetworkManager! {
        
        dispatch_once(&NetworkManager.sContext){
            NetworkManager.sManager = NetworkManager()
        }
        return NetworkManager.sManager
    }
    
    override init() {
        super.init()
        
        initQueue()
        
        initBGSession()
    }
    
    private func initQueue() {
        self.queue.name = "sy.jac.network.queue"
        self.queue.maxConcurrentOperationCount = 5
        self.queue.qualityOfService = .Utility
    }
    
    private func initBGSession() {
        
        self.bgSession = NSURLSession(configuration: NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(NetworkManager.sBGConfiguration), delegate: self, delegateQueue: self.queue)
        self.bgSession.configuration.allowsCellularAccess = true
    }
    
    private class var invalidTaskIdentifier:Int {
        get {return Int.max}
    }
    
    //MARK: NSURLSessionDelegate's methods
    func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        assert(self.bgSession.configuration.identifier == session.configuration.identifier)
        
        completionHandler?()
        
        self.completionHandler  = nil
    }
    
    //MARK: Public interface
    
    internal func isValidTask(taskId:Int) -> Bool {
        return NetworkManager.invalidTaskIdentifier != taskId
    }
    internal func saveCompletionHandler(handler:(() -> Void),forSessionId sessionId:String!) {
        assert(self.bgSession.configuration.identifier == sessionId)
        
        self.completionHandler = handler
        print("Saved BG Session with ID: \(sessionId)")
    }
    
    internal func downloadFileFromPath(path:String!,completion:((path:String?,error:NSError?)->Void)?) -> Int! {
        
        let url = NSURL(string: path)
        
        if url == nil {
            return NetworkManager.invalidTaskIdentifier
        }
        
        let req = NSURLRequest(URL: url!)
    
        let task = self.bgSession.downloadTaskWithRequest(req)
        synch(self) {
         self.tasksDic[task.taskIdentifier] = task
         if let completionInternal = completion {
            self.tasksCompletions[task.taskIdentifier] = completionInternal
          }
        }
        
        if task.state == .Suspended {
            task.resume()
        }
        
        assert(task.state != .Completed || task.state != .Canceling)
        return task.taskIdentifier
    }
    
    func synch(lockObj:AnyObject!,closure:()->Void) {
        
        objc_sync_enter(lockObj)
        closure()
        objc_sync_exit(lockObj)
        return
    }
    
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, var didFinishDownloadingToURL location: NSURL) {
        
        let taskId = downloadTask.taskIdentifier
        
    synch(self) {
        if (!self.tasksDic.isEmpty  && self.tasksDic[taskId] != nil) {
            self.tasksDic.removeValueForKey(taskId)
        }
    }
        
        
        if let ext = downloadTask.originalRequest?.URL?.lastPathComponent {
            
        
            do{
                if let location2Path = try NSFileManager.defaultManager().jacStoreItemToCache(location.path!, fileName: ext) {
                
                    location = NSURL(fileURLWithPath: location2Path)
                    print("NEtworkManager downloading corrected location \(location)")
                }
            }
            catch let error as NSError {
                print("Error NEtworkManager downloading \(error)")
                }
        }
        
        synch(self) {
         if (self.tasksCompletions[taskId] != nil) {
            if let completion = self.tasksCompletions.removeValueForKey(taskId){
                completion(path: location.path, error:nil)
            }
         }
        }
        
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
    synch(self) {
            
        if (!self.tasksDic.isEmpty  && self.tasksDic[task.taskIdentifier] != nil) {
            self.tasksDic.removeValueForKey(task.taskIdentifier)
        }
    }
        
        if let errorInter = error {
            print("\(errorInter)")
            synch(self) {
             if let completion = self.tasksCompletions.removeValueForKey(task.taskIdentifier){
                completion(path: nil, error:error)
             }
            }
        }
    }
    
    
    internal func cancelTask(taskId:Int) -> Bool {
        var result:Bool = false
        
        if taskId != NetworkManager.invalidTaskIdentifier  {
        
         synch(self) {
            if let oldTask = self.tasksDic.removeValueForKey(taskId) {
                oldTask.cancel()
                self.tasksCompletions.removeValueForKey(taskId)
                result = true
            }
         }
            
        }
        
        return result
    }
    
    internal func suspendTask(taskId:Int) -> Bool {
        
        var result:Bool = false
        
        
        if taskId != NetworkManager.invalidTaskIdentifier  {
            
           synch(self) {
             if let oldTask = self.tasksDic.removeValueForKey(taskId) {
                oldTask.suspend()
                result = true
             }
            }
        }
        
        return result
    }
    
    internal func resumeSuspendedTask(taskId:Int) -> Bool {
        
        var result:Bool = false
        
        if taskId != NetworkManager.invalidTaskIdentifier  {
            
            synch(self) {
             if let oldTask = self.tasksDic[taskId] {
                if (oldTask.state == .Suspended) {
                
                    oldTask.resume()
                    result = true
                }
              }
            }
        }
        return result
    }
}
