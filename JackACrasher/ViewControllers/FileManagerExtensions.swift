//
//  BundleExtensions.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 6/19/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit

extension NSFileManager {
    private static let sJacCacheDictory:String = "syJackCa"
    
    //MARK: Cache logic
    private var jacCacheDirectory:String! {
        get {
            
            let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true) as! [String]
            
            return paths.first!.stringByAppendingPathComponent(NSFileManager.sJacCacheDictory)
        }
    }
    
    var jacProductsInfo :String! {
        get {return "ProductsInfo.plist" }
    }
    
    
    func jacStoreItemToCache(path:String!,fileName:String? = nil) -> (path:String?,error:NSError?) {
        
        var fileName1 = path.lastPathComponent
        
        if (fileName != nil) {
            fileName1 = fileName!.lastPathComponent
        }
        
        var isDir:ObjCBool = false
        var error:NSError? = nil
        if (!self.fileExistsAtPath(self.jacCacheDirectory, isDirectory: &isDir)) {
            let res =  self.createDirectoryAtPath(self.jacCacheDirectory, withIntermediateDirectories: true, attributes: nil, error: &error)
            
            if (!res && error != nil){
                println("Error \(error)")
                return (nil,error)
            }
        }
        
        let filePath = self.jacCacheDirectory.stringByAppendingPathComponent(fileName1)
        
        
        
        let res = self.moveItemAtPath(path, toPath: filePath
            , error: &error)
        
        return (path:filePath,error:error)
    }
    
    func jacStoreItemToCache(path:String!,fileName:String? = nil ,completion:((realPah:String?,error:NSError?)->Void)?) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)){
            [unowned self] in
         
            let (filePath,error) = self.jacStoreItemToCache(path, fileName: fileName)
            
            completion?(realPah: filePath,error: error)
        }
    }
    
    func jacGetImageFromCache(path:String!) -> UIImage? {
        if !jacHasItemInCache(path) {
            return nil
        }
        
        var fileName = path.lastPathComponent
        
        if (fileName.isEmpty) {
            fileName = path
        }
        
        let path = self.jacCacheDirectory.stringByAppendingPathComponent(fileName)
        
        return UIImage(contentsOfFile: path)
    }
    
    func jacHasItemInCache(path:String!) -> Bool {
        
        var fileName = path.lastPathComponent
        
        if (fileName.isEmpty) {
            fileName = path
        }
        
        let path = self.jacCacheDirectory.stringByAppendingPathComponent(fileName)
        
        
        return self.fileExistsAtPath(path)
    }
    
    func jacRemoveItemFromCache(path:String!,completion:((result:Bool,error:NSError?)->Void)?) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)){
            [unowned self] in
            
            var fileName = path.lastPathComponent
            
            if (fileName.isEmpty) {
                fileName = path
            }
            
            
            let filePath = self.jacCacheDirectory.stringByAppendingPathComponent(fileName)
            var error:NSError? = nil
            
            let res = self.removeItemAtPath(filePath, error: &error)
            completion?(result: res, error: error)
        }
    }
    
    func jacHasValidPropertiesList() -> Bool {
        
        let path = self.jacCacheDirectory
        
        let filePath = path.stringByAppendingPathComponent(self.jacProductsInfo)
        
        if self.fileExistsAtPath(filePath) {
         
            let array = NSArray(contentsOfFile: filePath)
            if (array?.count == 4) {
                
                if let dic = array!.firstObject as? [String:AnyObject] {
                    if dic["listVersion"] is NSNumber {
                        return dic["listVersion"]?.integerValue == 1
                    }
                }
            }
        }
        
        return false
    }
    
    
    func jacGetPropertiesInfoFromPropertiesList() -> [IAPProduct]? {
        
        if !jacHasValidPropertiesList() {
            return nil
        }
        
        let path = self.jacCacheDirectory
        
        let filePath = path.stringByAppendingPathComponent(self.jacProductsInfo)
        var result:[IAPProduct]? = nil
        
        if self.fileExistsAtPath(filePath) {
            
            let array = NSArray(contentsOfFile: filePath)
            if (array?.count == 4) {
            
                for i in 1...array!.count - 1  {
                    if let dic = array?[i] as? [NSObject:AnyObject]{
                        let info = IAPProductInfo(dic: dic)
                        let product = IAPProduct()
                        product.productInfo = info
                        
                        if result == nil {
                            result = [IAPProduct]()
                        }
                        result!.append(product)
                    }
                }
            }
        }
        
        return result
    }
    
    //MARK: iCloud 
    
    /* Checks if the user has logged into her iCloud account or not */
    func jacIsIcloudAvailable() -> Bool{
        if let _ = NSFileManager.defaultManager().ubiquityIdentityToken{
            return true
        } else {
            return false
        }
    }
}