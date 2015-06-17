//
//  PurchaseManager.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 6/9/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit
import StoreKit
import Swift

enum ManagerState:Int {
    case None
    case Validating
    case FailedToAccessITunes
    case Failed
    case Validated
}

enum IAPPurchaseNotificationStatus: Int {
    case IAPPurchaseNone
    case IAPPurchaseFailed // Indicates that the purchase was unsuccessful
    case IAPPurchaseSucceeded // Indicates that the purchase was successful
    case IAPPurchaseCancelled
    case IAPRestoredFailed // Indicates that restoring products was unsuccessful
    case IAPRestoredSucceeded // Indicates that restoring products was successful
    case IAPRestoredCancelled
    case IAPDownloadStarted // Indicates that downloading a hosted content has started
    case IAPDownloadInProgress // Indicates that a hosted content is currently being downloaded
    case IAPDownloadFailed  // Indicates that downloading a hosted content failed
    case IAPDownloadSucceeded // Indicates that a hosted content was successfully downloaded
    case IAPDownloadCancelled
}

let kPurchaseManagerDidFailedProductsValidationNotification = "kPurchaseManagerDidFailedProductsValidationNotification"
let kPurchaseManagerValidatedProductsNotification = "kPurchaseManagerValidatedProductsNotification"

let IAPPurchaseNotification = "IAPPurchaseNotification"

private  let sPurchaseManagerSandBox:Bool = true

class PurchaseManager: NSObject, SKProductsRequestDelegate,SKPaymentTransactionObserver {

    private static let sInstance = PurchaseManager()
    private var sContext:dispatch_once_t = 0
    private var validProducs:[String:SKProduct] = [:]
    private var productsIds:[String]? = nil
    
    internal var managerState:ManagerState = .None
    
    internal class func canPurchase() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }
    
    internal var purchaseId:String!
    internal var purchasedItems:[AnyObject]! = []
    internal var restored:[AnyObject]! = []
    internal var message:String!
    internal var downloadProgress:Float = 0
    
    internal var status:IAPPurchaseNotificationStatus = IAPPurchaseNotificationStatus.IAPPurchaseNone
    
    internal var hasValidated: Bool {
        get {return self.managerState == .Validated}
    }
    
    internal class var sharedInstance:PurchaseManager {
        get {return sInstance }
    }
    
    internal var validProductsIds:[String]?{
        get {
            if self.managerState != .Validated { return nil }
            
            return validProducs.keys.array
        }
    }
    
    internal var validProducstsArray:[SKProduct]? {
        get {
            if self.managerState != .Validated { return nil }
            
            return validProducs.values.array
        }
    }
    
    override init() {
        super.init()
        accumulateProductIdentifiers()
    }
    
    internal func prepare() {
        
        SKPaymentQueue.defaultQueue().removeTransactionObserver(self)
        SKPaymentQueue.defaultQueue().addTransactionObserver(self)
        //SKPaymentQueue.defaultQueue().restoreCompletedTransactions()
    }
    
    deinit {
        SKPaymentQueue.defaultQueue().removeTransactionObserver(self)
    }
    
    private func accumulateProductIdentifiers() {
        
        if PurchaseManager.canPurchase(){
            dispatch_once(&sContext, { () -> Void in
                
                if let url = NSBundle.mainBundle().URLForResource("ProductIds", withExtension: "plist") {
                
                    if let idents = NSArray(contentsOfURL: url) {
                        self.productsIds = (idents as! [String])
                        self.validateProductIdentifiers(idents)
                    }
                }
            })
        }
    }
    
    private func validateProductIdentifiers(identifiers:NSArray!) {
       
        self.managerState = .Validating
        
        var products = Set<NSObject>()
        
        for identifier in identifiers as! [String!] {
            products.insert(identifier)
        }
        
        
        let request = SKProductsRequest(productIdentifiers:products)
        
        request.delegate = self
        request.start()
    }
    
    //MARK:SKProductsRequestDelegate
    func productsRequest(request: SKProductsRequest!, didReceiveResponse response: SKProductsResponse!) {
        
        let invProductsIdef = response.invalidProductIdentifiers
        
        var products = response.products
        
    
        if (!invProductsIdef.isEmpty){
            
            for invProductAnyObj in invProductsIdef {
                let invProduct = invProductAnyObj as! String
                
                products = products.filter({ (productAny) -> Bool in
                    let product = productAny as! SKProduct
                
                    return product.productIdentifier != invProduct
                })
                
            }
        }
        
        for product in products as! [SKProduct] {
            self.validProducs[product.productIdentifier] = product
        }
        
        self.managerState = .Validated
        self.productsIds = nil
        
        NSNotificationCenter.defaultCenter().postNotificationName(kPurchaseManagerValidatedProductsNotification, object: self)
    }
    
    func request(request: SKRequest!, didFailWithError error: NSError!){
        if (error != nil) {
            println("Error \(error)")
        }
        
        if (error.domain == "SSErrorDomain" && error.code == 0) {
            self.managerState = .FailedToAccessITunes
            
        }
        else {
            self.managerState = .Failed
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName(kPurchaseManagerDidFailedProductsValidationNotification, object: self)
        
        let delayTime = dispatch_time(DISPATCH_TIME_NOW,
            Int64(3 * Double(NSEC_PER_SEC)))
        
        dispatch_after(delayTime, dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
            [unowned self] in
            if (self.managerState != .Validating && self.managerState != .Validated) {
                self.validateProductIdentifiers(self.productsIds)
            }
        }
        
    }
    
    private func userNameForPurchases() -> String? {
        if let playerID = GameCenterManager.sharedInstance.playerID {
            
            if let hash = PurchaseManager.hashedValueForPlayerID(playerID) {
                
                return hash
            }
        }
        return nil
    }
    
    private func getProduct(productId:String) -> SKProduct? {
    
        if self.managerState != .Validated {
            return nil
        }
        
        return self.validProducs[productId]
    }
    
    //MARK: Payment request 
    
    internal func schedulePaymentWithProduct(product:SKProduct?) -> Bool {
        
        if product == nil {
            return false
        }
        
        let payment = SKMutablePayment(product: product!)
        payment.quantity = 1
        payment.simulatesAskToBuyInSandbox = sPurchaseManagerSandBox
        
        
        if let userName = userNameForPurchases() {
            payment.applicationUsername = userName
        }
        
        SKPaymentQueue.defaultQueue().addPayment(payment)
        
        return true
    }
    
    internal func schedulePayment(productId:String) -> Bool {
        
        let product = getProduct(productId)
        
        if (product == nil) {
            return false
        }
        
        return schedulePaymentWithProduct(product)
    }
    
    private class func hashedValueForPlayerID(playerID:String?) -> String? {
     
        let lenght = playerID?.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
        
        if (lenght == nil || lenght! == 0) {
            return nil
        }
        
        var context = UnsafeMutablePointer<CC_MD5_CTX>.alloc(1)
        var digest = Array<UInt8>(count:Int(CC_MD5_DIGEST_LENGTH), repeatedValue:0)
        CC_MD5_Init(context)
        CC_MD5_Update(context, playerID!,
            CC_LONG(lenght!))
        CC_MD5_Final(&digest, context)
        context.dealloc(1)
        
        if (digest.isEmpty) {
            return nil
        }
        
        var hexString = ""
        for byte in digest {
            hexString += String(format:"%02x", byte)
        }
        
        let length = min(hexString.lengthOfBytesUsingEncoding(NSUTF8StringEncoding),Int(Int32.max))
        
        
        let index = advance(hexString.startIndex,length)
        
        return hexString.substringToIndex(index)
    }
    
    //MARK: Restore products 
    internal func restore() {
        restored.removeAll(keepCapacity: false)
        let defQueue = SKPaymentQueue.defaultQueue()
        
        if let userName = userNameForPurchases() {
            defQueue.restoreCompletedTransactionsWithApplicationUsername(userName as String)
        }
        else {
            defQueue.restoreCompletedTransactions()
        }
        
    }
    
    //MARK: SKPaymentTransactionObserver
    
    func paymentQueue(queue: SKPaymentQueue!, updatedTransactions transactions: [AnyObject]!)
    {
        
        for transaction in transactions as! [SKPaymentTransaction] {
            
            var userInfo:[NSObject:AnyObject]? = ["id":transaction.payment.productIdentifier]
            
            
            switch (transaction.transactionState )
            {
            case .Purchasing:
                break
                
            case .Deferred:
                // Do not block your UI. Allow the user to continue using your app.
                println("Allow the user to continue using your app.")
                break
                // The purchase was successful
            case .Purchased:
                
                    self.purchaseId = transaction.payment.productIdentifier
                    self.purchasedItems.append(transaction)
                    
                    println("Deliver content for \(transaction.payment.productIdentifier)")
                    // Check whether the purchased product has content hosted with Apple.
                    
                    //TODO: Transaction identifier & receipt validation....
                    
                    if(transaction.downloads != nil && transaction.downloads!.count > 0) {
                        completeTransaction(transaction, status: IAPPurchaseNotificationStatus.IAPDownloadStarted, userInfo:userInfo)
                    }
                    else {
                        completeTransaction(transaction, status: IAPPurchaseNotificationStatus.IAPPurchaseSucceeded,userInfo:userInfo)
                    }
                
                break
                // There are restored products
            case .Restored:
                
                    self.purchaseId = transaction.payment.productIdentifier;
                    self.restored.append(transaction)
                    
                    println("Restore content for \(transaction.payment.productIdentifier)")
                    // Send a IAPDownloadStarted notification if it has
                    var statusInter:IAPPurchaseNotificationStatus
                    
                    if(transaction.downloads != nil && transaction.downloads.count > 0) {
                        statusInter = .IAPDownloadStarted
                    }
                    else {
                        
                        self.status = .IAPRestoredSucceeded
                        NSNotificationCenter.defaultCenter().postNotificationName(IAPPurchaseNotification, object: self, userInfo: userInfo)
                        
                        statusInter = .IAPPurchaseSucceeded
                    }
                    completeTransaction(transaction, status:statusInter,userInfo:userInfo)
                
                break
                // The transaction failed
            case .Failed:
                
                self.message = "Purchase of \(transaction.payment.productIdentifier) failed."
                
                completeTransaction(transaction, status:transaction.error.code != SKErrorPaymentCancelled ? .IAPPurchaseFailed :.IAPPurchaseCancelled ,userInfo:userInfo)
                
                break;
            default:
                break;
            }
        }
        
    }
    
    // Called when the payment queue has downloaded content
    func paymentQueue(queue: SKPaymentQueue!, updatedDownloads downloads: [AnyObject]!) {
        
        for download in downloads as! [SKDownload!]
        {
            var userInfo:[NSObject:AnyObject]? = ["id":download.transaction.payment.productIdentifier]
            switch (download.downloadState)
            {
                // The content is being downloaded. Let's provide a download progress to the user
            case .Active:
                
                    self.status = .IAPDownloadInProgress;
                    self.purchaseId = download.transaction.payment.productIdentifier;
                    self.downloadProgress = download.progress*100;
                    NSNotificationCenter.defaultCenter().postNotificationName(IAPPurchaseNotification, object: self,userInfo:userInfo)
                    
                break;
                
            case .Cancelled:
                fallthrough
            case .Failed:
                // StoreKit saves your downloaded content in the Caches directory. Let's remove it
                // before finishing the transaction.
                
                finishDownloadTransaction(download.transaction)
                
                var error:NSError? = nil
                if (!NSFileManager.defaultManager().removeItemAtURL(download.contentURL, error: &error) && error != nil) {
                    println("Error deleting file \(error)")
                }
            
                break;
                
            case .Paused:
                println("Download was paused")
                break;
                
            case .Finished:
                // Download is complete. StoreKit saves the downloaded content in the Caches directory.
                println("Location of downloaded file \(download.contentURL)");
               finishDownloadTransaction(download.transaction)
                break;
                
            case .Waiting:
                println("Download Waiting");
                SKPaymentQueue.defaultQueue().startDownloads([download])
                break;
                
            default:
                break;
            }
        }
    }
    
    
    // Logs all transactions that have been removed from the payment queue
    func paymentQueue(queue: SKPaymentQueue!, removedTransactions transactions: [AnyObject]!) {
        for transaction in transactions as! [SKPaymentTransaction!] {
            println("\(transaction.payment.productIdentifier) was removed from the payment queue.");
        }
    }
   
    func paymentQueue(queue: SKPaymentQueue!, restoreCompletedTransactionsFailedWithError error: NSError!) {
        
        if (error.code != SKErrorPaymentCancelled) {
            self.status = .IAPRestoredFailed
        }
        else {
            self.status = .IAPRestoredCancelled
        }
            
        NSNotificationCenter.defaultCenter().postNotificationName(IAPPurchaseNotification, object: self)
        
    }
   
    func paymentQueueRestoreCompletedTransactionsFinished(queue: SKPaymentQueue!) {
        println("All restorable transactions have been processed by the payment queue.");
        if (self.status != .IAPDownloadStarted) {
            self.status = .IAPRestoredSucceeded
            NSNotificationCenter.defaultCenter().postNotificationName(IAPPurchaseNotification, object: self)
        }
    }
    
    //MARK:  Complete transaction
    
    // Notify the user about the purchase process. Start the download process if status is
    // IAPDownloadStarted. Finish all transactions, otherwise.
    private func completeTransaction(transaction:SKPaymentTransaction, status:IAPPurchaseNotificationStatus,userInfo:[NSObject:AnyObject]? = nil)
    {
        self.status = status
        
        NSNotificationCenter.defaultCenter().postNotificationName(IAPPurchaseNotification, object: self, userInfo: userInfo)
        
        if status == .IAPDownloadStarted {
            SKPaymentQueue.defaultQueue().startDownloads(transaction.downloads)
        } else {
            SKPaymentQueue.defaultQueue().finishTransaction(transaction)
        }
    }
    
    func finishDownloadTransaction(transaction:SKPaymentTransaction,userInfo:[NSObject:AnyObject]? = nil) {
        
        //allAssetsDownloaded indicates whether all content associated with the transaction were downloaded.
        var allAssetsDownloaded:Bool = true
        
        // A download is complete if its state is SKDownloadStateCancelled, SKDownloadStateFailed, or SKDownloadStateFinished
        // and pending, otherwise. We finish a transaction if and only if all its associated downloads are complete.
        // For the SKDownloadStateFailed case, it is recommended to try downloading the content again before finishing the transaction.
        for download in transaction.downloads as! [SKDownload!]
        {
            if (download.downloadState != .Cancelled &&
                download.downloadState != .Failed &&
                download.downloadState != .Finished )
            {
                //Let's break. We found an ongoing download. Therefore, there are still pending downloads.
                allAssetsDownloaded = false
                break
            }
        }
        
        // Finish the transaction and post a IAPDownloadSucceeded notification if all downloads are complete
        if (allAssetsDownloaded)
        {
            self.status = .IAPDownloadSucceeded;
            SKPaymentQueue.defaultQueue().finishTransaction(transaction)
            
            NSNotificationCenter.defaultCenter().postNotificationName(IAPPurchaseNotification, object: self,userInfo:userInfo)
            
           let array = self.restored.filter({ (item) -> Bool in
                if item as! NSObject == transaction {
                    return true
                }
                else {
                    return false
                }
            })
            
            if (!array.isEmpty) {
                self.status = .IAPRestoredSucceeded;
                NSNotificationCenter.defaultCenter().postNotificationName(IAPPurchaseNotification, object: self,userInfo:userInfo)
            }
        }
    }
}
