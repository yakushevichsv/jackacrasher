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
        
        self.tasksDic[task.taskIdentifier] = task
        if let completionInternal = completion {
            self.tasksCompletions[task.taskIdentifier] = completionInternal
        }
        
        if task.state == .Suspended {
            task.resume()
        }
        return task.taskIdentifier
    }
    
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        
        if (self.tasksDic[downloadTask.taskIdentifier] != nil) {
            self.tasksDic.removeValueForKey(downloadTask.taskIdentifier)
        }
        
        if let completion = self.tasksCompletions.removeValueForKey(downloadTask.taskIdentifier){
            completion(path: location.path, error:nil)
        }
        
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        
        self.tasksDic.removeValueForKey(task.taskIdentifier)
        if let errorInter = error {
            print("\(errorInter)")
            if let completion = self.tasksCompletions.removeValueForKey(task.taskIdentifier){
                completion(path: nil, error:error)
            }
        }
    }
    
    
    internal func cancelTask(taskId:Int) -> Bool {
        if taskId != NetworkManager.invalidTaskIdentifier  {
            
        
            if let oldTask = self.tasksDic.removeValueForKey(taskId) {
                oldTask.cancel()
                self.tasksCompletions.removeValueForKey(taskId)
                return true
            }
        }
        
        return false
    }
    
    internal func suspendTask(taskId:Int) -> Bool {
        if taskId != NetworkManager.invalidTaskIdentifier  {
            
            
            if let oldTask = self.tasksDic.removeValueForKey(taskId) {
                oldTask.suspend()
                return true
            }
        }
        
        return false
    }
    
    internal func resumeSuspendedTask(taskId:Int) -> Bool {
        
        if taskId != NetworkManager.invalidTaskIdentifier  {
            
            
            if let oldTask = self.tasksDic[taskId] {
                if (oldTask.state == .Suspended) {
                
                    oldTask.resume()
                    return true
                }
            }
        }
        return false
    }
}
