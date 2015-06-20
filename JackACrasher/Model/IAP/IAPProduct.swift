//
//  IAPProduct.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 6/20/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit
import StoreKit

class IAPProduct : NSObject {
   
    internal var productIdentifier:String!
    
    internal var productInfo:IAPProductInfo? {
        didSet {
            self.productIdentifier = productInfo?.productIdentifier
        }
    }
    
    internal var availableForPurchase:Bool = true
    internal var purchaseInProgress:Bool = false
    
    override init() {
        super.init()
    }
    
    internal func allowedToPurchase() -> Bool {
        
        if !self.availableForPurchase || self.productInfo == nil || self.purchaseInProgress /* || !self.info.consumable && self.purchase*/ {
            return false
        }
        return true
    }
    
    internal var skProduct:SKProduct! 
    
}

