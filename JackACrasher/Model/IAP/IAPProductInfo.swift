//
//  IAPProductInfo.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 6/20/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit

class IAPProductInfo: NSObject {

    internal var productIdentifier:String! = nil
    internal var icon:String? = nil
    internal var consumable:Bool = false
    internal var consumableIdentifier:String?
    internal var consumableAmount:Int = 0
    internal var bundleDir:String? = nil
    private let scale:CGFloat
    
    init(scale:CGFloat,dic:[NSObject:AnyObject]) {
        self.scale = scale
        super.init()
        
        if let productId = dic["productIdentifier"] as? String {
            self.productIdentifier = productId
        }
        
        if let iconPath = dic["icon"] as? String {
            
            if (!iconPath.isEmpty) {
                
                if let fileName = iconPath.lastPathComponent {
                    let str = fileName as NSString
                    let ext = str.pathExtension as NSString
                    let name = str.substringToIndex(str.length - ext.length - 1)
                    
                    let newName = name.stringByAppendingString("@\(Int(scale))x.\(ext)")
                    
                    self.icon = iconPath.stringByReplacingOccurrencesOfString(fileName, withString: newName)
                }
            }
            else {
                self.icon = nil
            }
        }
        
        if let consumable = dic["consumable"] as? Bool {
            self.consumable = consumable
        }
        
        if let consumableAmount = dic["consumableAmount"] as? NSNumber {
            self.consumableAmount = consumableAmount.integerValue
        }
        
        if let consumableId = dic["consumableIdentifier"] as? String {
            self.consumableIdentifier = consumableId
        }
        
        if let bundleDir = dic["bundleDir"] as? String {
            self.bundleDir = bundleDir
        }
        
    }
}
