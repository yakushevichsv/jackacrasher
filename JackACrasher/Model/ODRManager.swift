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

    private struct Constants {
        static let Sound = "Sound"
        static let Help = "Help"
    }
    
    typealias odrCompletionBlock = (error:NSError?) -> Void
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
        
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "lowDiskSpace:", name:NSBundleResourceRequestLowDiskSpaceNotification, object: nil)
        
        
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NSBundleResourceRequestLowDiskSpaceNotification, object: nil)
    }
    
    func lowDiskSpace(notification:NSNotification) {
        
        for req in self.usedRes {
            
            var totalValue:Double = 0
            
            for tag in req.tags {
                let value =  NSBundle.mainBundle().preservationPriorityForTag(tag)
                totalValue += value/Double(req.tags.count)
            }
            
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
        
        for key in dic.keys.enumerate() {
            
            if key.element.tags == tags {
                NSBundle.mainBundle().setPreservationPriority(priority, forTags: tags)
            }
        }
    }
    
    internal func startUsingpResources(tags:Set<String>, prioriy:Double, intermediateHandler:odrIntermediateBlock,   completionHandler: odrCompletionBlock) {
        
        
        let request = NSBundleResourceRequest(tags: tags)
        
        request.conditionallyBeginAccessingResourcesWithCompletionHandler{
            [unowned self]
            (exist) in
            
            if (exist) {
                completionHandler(error: nil)
            }
            else {
                
                self.appendToDictionary(request, intermediate: intermediateHandler)
                
            
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
        
        
        if let reqObj = object as? NSBundleResourceRequest {
            
            if let intermediate = self.dic[reqObj] {
                intermediate(fraction: reqObj.progress.fractionCompleted)
            }
            
        }
    }
}

