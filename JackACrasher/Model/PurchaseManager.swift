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
    case IAPPurchaseInProgress //Indicates that there is a purchasing activity
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

    
    private static let ProductsListPath = "https://dl.dropboxusercontent.com/u/106064832/JackACrasher/ProductIsInfo.plist"
    
    internal static let sharedInstance = PurchaseManager()
    private var sContext:dispatch_once_t = 0
    private var validProducs:[String:IAPProduct] = [:]
    private var productsIdsInternal:[String]? = nil
    private var products:[IAPProduct]? = nil
    
    private lazy var receiptValidator:IAPReceiptValidator! = IAPReceiptValidator()
    
    
    private var productsIds:[String]! {
        get {
        
            if (productsIdsInternal == nil) {
            
                var productIds = [String]()
            
                for product in self.products! {
                    productIds.append(product.productIdentifier)
                }
                self.productsIdsInternal = productIds
            }
            return self.productsIdsInternal!
        }
    }
    
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

    internal var validProductsIds:[String]?{
        get {
            if self.managerState != .Validated { return nil }
            var results = [String]()
            for item in validProducs {
                results.append(item.0)
            }
            return results
        }
    }
    
    internal var validProducstsArray:[IAPProduct]? {
        get {
            if self.managerState != .Validated { return nil }
            
            var results = [IAPProduct]()
            for item in validProducs {
                results.append(item.1)
            }
            return results
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
    
    internal func purchaseInProgress(productId:String) -> Bool {
        
        if let product = self.validProducs[productId] {
            return product.purchaseInProgress
        }
        return false
    }
    
    internal func setPurchaseProgressState(productId:String,inProgress:Bool) {
        
        if let product = self.validProducs[productId] {
            product.purchaseInProgress = inProgress
        }
    }
    
    deinit {
        SKPaymentQueue.defaultQueue().removeTransactionObserver(self)
    }
    
    private func accumulateProductIdentifiers() {
        
        if PurchaseManager.canPurchase(){
            dispatch_once(&sContext, { () -> Void in
                
                if NSFileManager.defaultManager().jacHasValidPropertiesList() {
                    self.validateProducts()
                } else {
                    
                    NetworkManager.sharedManager.downloadFileFromPath(PurchaseManager.ProductsListPath) {
                        path, error in
                        if error == nil && path != nil {
                          let defManager = NSFileManager.defaultManager()
                           
                            do {
                                let path2 = try defManager.jacStoreItemToCache(path, fileName: defManager.jacProductsInfo)
                            
                                if (path2 != nil) {
                                    self.validateProducts()
                                }
                            } catch {
                                print("Catch was gotten!")
                            }
                        }
                    }
                }
            })
        }
        
    }
    
    private func validateProducts() {
        self.products = NSFileManager.defaultManager().jacGetPropertiesInfoFromPropertiesList()
        if let productsVal = self.products  {
            self.validateProductsInternal(productsVal)
        }
    }
    
    private func validateProductsInternal(array:NSArray!) {
       
        self.managerState = .Validating
        
        var products = Set<String>()
        
        for identifier in array as! [IAPProduct] {
            products.insert(identifier.productIdentifier)
        }
        
        
        let request = SKProductsRequest(productIdentifiers:products)
        
        request.delegate = self
        request.start()
    }
    
    //MARK:SKProductsRequestDelegate
    func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {
        
        let invProductsIdef = response.invalidProductIdentifiers
        
        var products = response.products
        
    
        if (!invProductsIdef.isEmpty){
            
            for invProductAnyObj in invProductsIdef {
                let invProduct = invProductAnyObj 
                
                products = products.filter({ (productAny) -> Bool in
                    let product = productAny 
                
                    return product.productIdentifier != invProduct
                })
                
            }
        }
        
        for skProduct in products {
            for iapProduct in self.products! {
                
                if skProduct.productIdentifier == iapProduct.productIdentifier {
                    self.validProducs[iapProduct.productIdentifier] = iapProduct
                    iapProduct.skProduct = skProduct
                }
            }
            
        }
        
        self.managerState = .Validated
        self.productsIdsInternal = nil
        
        NSNotificationCenter.defaultCenter().postNotificationName(kPurchaseManagerValidatedProductsNotification, object: self)
    }
    
    func request(request: SKRequest, didFailWithError error: NSError){
        
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
                self.validateProducts()
            }
        }
        
    }
    
    private func userNameForPurchases() -> String? {
        if let playerID = GameLogicManager.sharedInstance.getPlayerId() {
            
            if let hash = PurchaseManager.hashedValueForPlayerID(playerID) {
                
                return hash
            }
        }
        return nil
    }
    
    private func getProduct(productId:String) -> IAPProduct? {
    
        if self.managerState != .Validated {
            return nil
        }
        
        return self.validProducs[productId]
    }
    
    //MARK: Payment request 
    
    internal func schedulePaymentWithProduct(product:IAPProduct?) -> Bool {
        
        if product == nil || product!.skProduct == nil {
            return false
        }
        
        let payment = SKMutablePayment(product: product!.skProduct)
        payment.quantity = 1
        if #available(iOS 8.3, *) {
            payment.simulatesAskToBuyInSandbox = sPurchaseManagerSandBox
        }
        
        
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
        
        let context = UnsafeMutablePointer<CC_MD5_CTX>.alloc(1)
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
        
        
        let index = hexString.startIndex.advancedBy(length)
        
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
    
    func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction])
    {
        
        for transaction in transactions {
            
            let userInfo:[NSObject:AnyObject]? = ["id":transaction.payment.productIdentifier]
            
            switch (transaction.transactionState )
            {
            case .Purchasing:
                self.purchaseId = transaction.payment.productIdentifier
                setPurchaseProgressState(self.purchaseId,inProgress: true)
                self.status = .IAPPurchaseInProgress
                NSNotificationCenter.defaultCenter().postNotificationName(IAPPurchaseNotification, object: self, userInfo: userInfo)
                break
                
            case .Deferred:
                // Do not block your UI. Allow the user to continue using your app.
                print("Allow the user to continue using your app.")
                break
                // The purchase was successful
            case .Purchased:
                
                    self.purchaseId = transaction.payment.productIdentifier
                    self.purchasedItems.append(transaction)
                    
                    print("Deliver content for \(transaction.payment.productIdentifier)")
                    // Check whether the purchased product has content hosted with Apple.
                    
                    if(!transaction.downloads.isEmpty) {
                        completeTransaction(transaction, status: IAPPurchaseNotificationStatus.IAPDownloadStarted, userInfo:userInfo)
                    }
                    else {
                        //TODO: support other styles...
                        let productId = transaction.payment.productIdentifier
                        self.receiptValidator.checkReceiptWithCompletionHandler{
                            [unowned self]
                            arrayAny,error in
                            print("\(arrayAny)")
                            
                            var purchaseStatus:IAPPurchaseNotificationStatus = .IAPPurchaseNone
                            var found:Bool = false
                            
                            for item in arrayAny {
                                let dic = item as! [NSObject:AnyObject]
                                if let dicProductId = dic["productIdentifier"] as? String {
                                    if (!found) {
                                        if dicProductId == productId {
                                            purchaseStatus = .IAPPurchaseSucceeded
                                            found = true
                                            
                                            if let fProduct = self.validProducs[dicProductId] {
                                                fProduct.purchaseInProgress = false
                                                fProduct.purchase = false
                                                
                                                if let prodInfo = fProduct.productInfo {
                                                    
                                                    if !prodInfo.consumable {
                                                        fProduct.availableForPurchase = false
                                                        GameLogicManager.sharedInstance.storePurchaseInDefaultsForNonConsumableWithID(productId)
                                                    }
                                                    
                                                    GameLogicManager.sharedInstance.purchasedProduct(fProduct)
                                                }
                                            }
                                            
                                        } else {
                                            purchaseStatus = .IAPPurchaseFailed
                                        }
                                    }
                                }
                            }
                            self.completeTransaction(transaction, status:purchaseStatus,userInfo:userInfo)
                        }
                    }
                
                break
                // There are restored products
            case .Restored:
                
                    self.purchaseId = transaction.payment.productIdentifier;
                    self.restored.append(transaction)
                    
                    print("Restore content for \(transaction.payment.productIdentifier)")
                    // Send a IAPDownloadStarted notification if it has
                    
                    if(!transaction.downloads.isEmpty) {
                        status = .IAPDownloadStarted
                    }
                    else {
                        
                        self.status = .IAPRestoredSucceeded
                        NSNotificationCenter.defaultCenter().postNotificationName(IAPPurchaseNotification, object: self, userInfo: userInfo)
                        
                        //statusInter = .IAPPurchaseSucceeded
                        
                        let productId = transaction.payment.productIdentifier
                        self.receiptValidator.checkReceiptWithCompletionHandler{
                            [unowned self]
                            arrayAny,error in
                            print("\(arrayAny)")
                            
                            var purchaseStatus:IAPPurchaseNotificationStatus = .IAPPurchaseNone
                            var found:Bool = false
                            
                            for item in arrayAny {
                                let dic = item as! [NSObject:AnyObject]
                                if let dicProductId = dic["productIdentifier"] as? String {
                                    if (!found) {
                                        if dicProductId == productId {
                                            purchaseStatus = .IAPPurchaseSucceeded
                                            found = true
                                            
                                            if let fProduct = self.validProducs[dicProductId] {
                                                fProduct.purchaseInProgress = false
                                                fProduct.purchase = false
                                                
                                                if let prodInfo = fProduct.productInfo {
                                                    
                                                    if !prodInfo.consumable {
                                                        fProduct.availableForPurchase = false
                                                        GameLogicManager.sharedInstance.storePurchaseInDefaultsForNonConsumableWithID(productId)
                                                    }
                                                    
                                                    GameLogicManager.sharedInstance.purchasedProduct(fProduct)
                                                }
                                            }
                                            
                                        } else {
                                            purchaseStatus = .IAPPurchaseFailed
                                        }
                                    }
                                }
                            }
                            self.completeTransaction(transaction, status:purchaseStatus,userInfo:userInfo)
                        }
                    }
                    
                break
                // The transaction failed
            case .Failed:
                
                self.message = "Purchase of \(transaction.payment.productIdentifier) failed."
                
                setPurchaseProgressState(transaction.payment.productIdentifier,inProgress: false)
                
                let code = transaction.error!.code
                
                completeTransaction(transaction, status:code != SKErrorPaymentCancelled && code != SKErrorUnknown ? .IAPPurchaseFailed :.IAPPurchaseCancelled ,userInfo:userInfo)
                
                break;
            }
        }
        
    }
    
    // Called when the payment queue has downloaded content
    func paymentQueue(queue: SKPaymentQueue, updatedDownloads downloads: [SKDownload]) {
        
        for download in downloads
        {
            let userInfo:[NSObject:AnyObject]? = ["id":download.transaction.payment.productIdentifier]
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
                
                
                if download.contentURL == nil {
                    break;
                }
                
                do {
                    try NSFileManager.defaultManager().removeItemAtURL(download.contentURL!)
                }
                catch {
                    print("Error deleting file \(download.contentURL)")
                }
            
                break;
                
            case .Paused:
                print("Download was paused")
                break;
                
            case .Finished:
                // Download is complete. StoreKit saves the downloaded content in the Caches directory.
                print("Location of downloaded file \(download.contentURL)");
                finishDownloadTransaction(download.transaction,userInfo:userInfo)
                break;
                
            case .Waiting:
                print("Download Waiting");
                SKPaymentQueue.defaultQueue().startDownloads([download])
                break;
                
            }
        }
    }
    
    func paymentQueue(queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: NSError) {
        
        if (error.code != SKErrorPaymentCancelled) {
            self.status = .IAPRestoredFailed
        }
        else {
            self.status = .IAPRestoredCancelled
        }
            
        NSNotificationCenter.defaultCenter().postNotificationName(IAPPurchaseNotification, object: self)
        
    }
   
    func paymentQueueRestoreCompletedTransactionsFinished(queue: SKPaymentQueue) {
        print("All restorable transactions have been processed by the payment queue.");
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
        for download in transaction.downloads
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
