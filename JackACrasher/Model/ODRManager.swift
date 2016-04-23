//
//  ODRManager.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 1/31/16.
//  Copyright © 2016 Siarhei Yakushevich. All rights reserved.
//

import UIKit

let ODRManagerShouldEndAccessOfRequestNotitification = "ODRManagerShouldEndAccessOfRequestNotitification"

class ODRManager: NSObject {
    
    typealias odrCompletionBlock = (error:NSError?) -> Void
    typealias odrExistCompletionBlock = (exist:Bool) -> Void
    typealias odrIntermediateBlock = (fraction:Double) -> Void
    
    private static var sContext:dispatch_once_t = 0
    private var myContext = 0
    
    private static var g_manager : ODRManager! = nil
    private var dic = [NSBundleResourceRequest:odrIntermediateBlock]()
    private var usedRes = Set<NSBundleResourceRequest>()
    
    class var sharedManager:ODRManager {
        
        dispatch_once(&sContext) {
            g_manager = ODRManager()
        }
        
        return g_manager
    }
    
    override init() {
        super.init()
        
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ODRManager.lowDiskSpace(_:)), name:NSBundleResourceRequestLowDiskSpaceNotification, object: nil)
        
        
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NSBundleResourceRequestLowDiskSpaceNotification, object: nil)
    }
    
    func lowDiskSpace(notification:NSNotification) {
        
        for req in self.usedRes {
            
            let totalValue = self.preservationPriorityForResource(req.tags)
            
            NSNotificationCenter.defaultCenter().postNotificationName(ODRManagerShouldEndAccessOfRequestNotitification, object: self, userInfo: ["preservation":totalValue, "request":req])
            
        }
    }
    
    
    private func removeFromDictionary(req:NSBundleResourceRequest!) {
        
        synced(self)
            {
                let contains = self.dic.contains { (keyInDic,request) -> Bool in
                    return req == keyInDic
                }
                
                if (contains) {
                    self.dic.removeValueForKey(req)
                    req.progress.removeObserver(self, forKeyPath: "fractionCompleted", context: &self.myContext)
                }
        }
    }
    
    private func appendToDictionary(req:NSBundleResourceRequest! ,intermediate:odrIntermediateBlock) {
        synced(self) {
                self.dic[req] = intermediate
        }
        req.progress.addObserver(self, forKeyPath: "fractionCompleted", options: NSKeyValueObservingOptions.New, context: &self.myContext)
    }
    
    internal func startUsingpResources(tags:Set<String>, intermediateHandler:odrIntermediateBlock,  completionHandler: odrCompletionBlock) {
        return self.startUsingpResources(tags, prioriy: 0.5, intermediateHandler: intermediateHandler, completionHandler: completionHandler)
    }
    
    internal func definePreservationPriorityForResources(tags:Set<String>,priority:Double) {
        
        NSBundle.mainBundle().setPreservationPriority(priority, forTags: tags)
    }
    
    internal func preservationPriorityForResource(tags:Set<String>) -> Double {
        var priority:Double = 0;
        for tag in tags {
            priority += NSBundle.mainBundle().preservationPriorityForTag(tag)/Double(tags.count)
        }
        return priority
    }
    
    internal func checkForResources(tags:Set<String>, completionHandler: odrExistCompletionBlock) {
        
        let request = NSBundleResourceRequest(tags: tags)
        self.appendToDictionary(request) {_ in }
        
        request.conditionallyBeginAccessingResourcesWithCompletionHandler{
            [unowned self]
            (exist) in
            
            self.removeFromDictionary(request)
            completionHandler(exist: exist)
        }
    }
    
    internal func startUsingpResources(tags:Set<String>, prioriy:Double, intermediateHandler:odrIntermediateBlock,   completionHandler: odrCompletionBlock) {
        
        
        let request = NSBundleResourceRequest(tags: tags)
        self.appendToDictionary(request, intermediate: intermediateHandler)
        
        request.conditionallyBeginAccessingResourcesWithCompletionHandler{
            [unowned self]
            (exist) in
            
            
            if (exist) {
                self.removeFromDictionary(request)
                self.usedRes.insert(request)
                completionHandler(error: nil)
            }
            else {
                
                
                request.beginAccessingResourcesWithCompletionHandler {
                    [unowned self]
                    (errorObj) in
                    self.removeFromDictionary(request)
                    if ((errorObj == nil)) {
                        self.usedRes.insert(request)
                    }
                    
                    completionHandler(error: errorObj)
                }
            }
        }
    }
    
    internal func endAcessingRequest(tags:Set<String>) -> Bool {
        
        for key in dic.keys.enumerate() {
            if key.element.tags == tags {
                
                key.element.endAccessingResources()
                self.removeFromDictionary(key.element)
                
                break
            }
        }
        
        for req in self.usedRes {
            if (req.tags == tags) {
                req.endAccessingResources()
                self.usedRes.remove(req)
                return true
            }
        }
        
        return false
    }
    
    internal func pauseRequest(tags:Set<String>) -> Bool {
        
        return actionOnRequest(tags, action: { (progress) -> Bool in
            
            if (progress.pausable && !progress.paused) {
                progress.pause()
                return true
            }
            return false
        })
    }
    
    internal func cancelRequest(tags:Set<String>) -> Bool {
        
        return actionOnRequest(tags, action: { (progress) -> Bool in
            
            if (progress.cancellable && !progress.cancelled) {
                progress.cancel()
                return true
            }
            return false
        })
    }
    
    internal func resumeRequest(tags:Set<String>) -> Bool {
        
        return actionOnRequest(tags, action: { (progress) -> Bool in
            
            if (progress.paused) {
                progress.resume()
                return true
            }
            return false
        })
    }
    
    private func synced(lock: AnyObject, closure: () -> ()) {
        objc_sync_enter(lock)
        closure()
        objc_sync_exit(lock)
    }
    
    private func actionOnRequest(tags:Set<String>, action:(progress:NSProgress)->Bool) -> Bool {
        
        for key in dic.keys.enumerate() {
            
            if (key.element.tags == tags) {
                return action(progress: key.element.progress)
            }
        }
        return false
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        
        
        if let progressObj = object as? NSProgress {
            
            for key in self.dic.keys {
                
                if key.progress == progressObj {
                    
                    if let intermediate = self.dic[key] {
                        intermediate(fraction: progressObj.fractionCompleted)
                    }
                }
            }
            
        }
    }
}

