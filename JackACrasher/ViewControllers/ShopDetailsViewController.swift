//
//  ShopDetailsViewController.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 6/10/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit
import StoreKit

class ShopDetailsViewController:UIViewController,ShopDetailsCellDelegate,UICollectionViewDelegate,UICollectionViewDataSource {
    
    @IBOutlet weak var collectionView:UICollectionView!
    @IBOutlet weak var closeButton:UIButton!
    private var initialRect:CGRect = CGRectZero
    private var processingCells:Set<NSIndexPath> = Set()
    private var processingCellsImages:[NSIndexPath:Int] = [NSIndexPath:Int]()
    
    internal var products:[IAPProduct] = [] {
        
        didSet {
            
            var procesed = [IAPProduct]()
            
            for curProduct in self.products {
                
                if GameLogicManager.sharedInstance.hasStoredPurchaseOfNonConsumableWithIDInDefaults(curProduct.productIdentifier) {
                    continue
                }
                
                if let info = curProduct.productInfo {
                    if info.consumable || curProduct.availableForPurchase {
                        procesed.append(curProduct)
                    }
                }
            }
            if (self.products.count != procesed.count) {
                products = procesed
            }
            
            if self.isViewLoaded() {
                self.collectionView?.reloadData()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initialRect = self.collectionView.frame
        
        
        let layout = self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.itemSize = self.collectionView.frame.size;
        
        if CGRectGetHeight(self.view.frame) > CGRectGetWidth(self.view.frame) {
            rotatePrivateForSize(self.view.frame.size)
        }
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handlePurchasesNotification:", name: IAPPurchaseNotification, object: PurchaseManager.sharedInstance)
    }
    
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.collectionView.collectionViewLayout.invalidateLayout()
    }
    
    // Update the UI according to the purchase request notification result
    func handlePurchasesNotification(aNotification:NSNotification!)
    {
        let pManager = aNotification.object as! PurchaseManager
        
        let userInfo = aNotification.userInfo
        
        switch (pManager.status)
        {
        case .IAPPurchaseFailed:
            alertWithTitle("Purchase Status", message: pManager.message)
            disposeActivityInficationUsingNofitication(aNotification)
            break
            // Switch to the iOSPurchasesList view controller when receiving a successful restore notification
        case .IAPRestoredFailed:
            alertWithTitle("Restore Status", message: pManager.message)
            disposeActivityInficationUsingNofitication(aNotification)
            break
        case .IAPDownloadFailed:
            alertWithTitle("Download Status", message: pManager.message)
            disposeActivityInficationUsingNofitication(aNotification)
            break
        case .IAPDownloadStarted:
            // Notify the user that downloading is about to start when receiving a download started notification
            //self.hasDownloadContent = YES;
            //[self.view addSubview:self.statusMessage];
            break
            // Display a status message showing the download progress
        case .IAPDownloadInProgress:
            
            //self.hasDownloadContent = YES;
            //NSString *title = [[StoreManager sharedInstance] titleMatchingProductIdentifier:purchasesNotification.purchasedID];
            //NSString *displayedTitle = (title.length > 0) ? title : purchasesNotification.purchasedID;
            //self.statusMessage.text = [NSString stringWithFormat:@" Downloading %@   %.2f%%",displayedTitle, purchasesNotification.downloadProgress];
            //}
            break
        case .IAPPurchaseInProgress:
            
            if let productId = userInfo?["id"] as? String {
                self.markPurchaseInProgressOnNeed(productId)
            }
            break
            // Downloading is done, remove the status message
        case .IAPPurchaseSucceeded:
            fallthrough
        case .IAPRestoredSucceeded:
                dispatch_async(dispatch_get_main_queue()) {
                    [unowned self] in
                    self.disposeActivityInficationUsingNofitication(aNotification)
                    if let productId = userInfo?["id"] as? String {
                        self.removeNonConsumableItemOnNeed(productId)
                    }
                }
            break
        case .IAPDownloadSucceeded:
            //self.hasDownloadContent = NO;
            //ßself.statusMessage.text = @"Download complete: 100%";
            
            // Remove the message after 2 seconds
            //[self performSelector:@selector(hideStatusMessage) withObject:nil afterDelay:2];
            disposeActivityInficationUsingNofitication(aNotification)
            break
        case .IAPPurchaseCancelled:
            disposeActivityInficationUsingNofitication(aNotification)
            break
        default:
            break
        }
    }
    
    
    private func removeNonConsumableItemOnNeed(productId:String) {
        
        var index = 0
        for curProduct in self.products {
            if curProduct.productIdentifier == productId {
                let indexPath = NSIndexPath(forRow: index, inSection: 0)
            
                if self.isViewLoaded() {
                for vIndexPath in self.collectionView.indexPathsForVisibleItems() {
                    if vIndexPath == indexPath {
                        
                        if let info = curProduct.productInfo {
                            if !info.consumable && (!curProduct.availableForPurchase || GameLogicManager.sharedInstance.hasStoredPurchaseOfNonConsumableWithIDInDefaults(productId)) {
                                removeNonConsumableItemFromLocal(indexPath)
                                //self.collectionView.deleteItemsAtIndexPaths([vIndexPath])
                                return
                            }
                        }
                        else {
                            if (GameLogicManager.sharedInstance.hasStoredPurchaseOfNonConsumableWithIDInDefaults(productId)) {
                                removeNonConsumableItemFromLocal(indexPath)
                                //self.collectionView.deleteItemsAtIndexPaths([vIndexPath])
                                return
                            }
                        }
                    }
                }
                }
                removeNonConsumableItemFromLocal(index)
                return
            }
            index++
        }
    }
    
    private func removeNonConsumableItemFromLocal(index:Int) {
    
        let indexPath = NSIndexPath(forRow: index, inSection: 0)
        removeNonConsumableItemFromLocal(indexPath)
    }
    
    private func removeNonConsumableItemFromLocal(indexPath:NSIndexPath!) {
        self.products.removeAtIndex(indexPath.row)
        if let taskId = self.processingCellsImages[indexPath] {
            NetworkManager.sharedManager.cancelTask(taskId)
            self.processingCellsImages.removeValueForKey(indexPath)
        }
    }
    
    private func markPurchaseInProgressOnNeed(productId:String) {
        
        if PurchaseManager.sharedInstance.purchaseInProgress(productId) {
            
            var index = 0
            for curProduct in self.products {
                
                if curProduct.productIdentifier == productId {
                    let indexPath = NSIndexPath(forRow: index, inSection: 0)
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        [unowned self] in
                        
                        //self.processingCellsImages.removeValueForKey(indexPath)
                        
                        
                        for vIndexPath in self.collectionView.indexPathsForVisibleItems() {
                            if vIndexPath == indexPath {
                                
                                if let collectionViewCell = self.collectionView.cellForItemAtIndexPath(indexPath) as? ShopDetailsCollectionViewCell {
                                    self.activateIndicatorForCell(collectionViewCell, atIndexPath: indexPath)
                                    return
                                }
                            }
                        }
                        
                        if !self.processingCells.contains(indexPath) {
                            self.processingCells.insert(indexPath)
                        }
                    }
                    
                    break
                }
                index++
            }
        }
    }
    
    private func disposeActivityInficationUsingNofitication(aNotification:NSNotification!) {
        
        let userInfo = aNotification.userInfo
        
        if let productId = userInfo?["id"] as? String {
            var i = 0
            var needToBreak = false
            for product in products {
                if (productId == product.productIdentifier) {
                    let indexPath = NSIndexPath(forRow: i, inSection: 0)
                    for visibleIndexPath  in self.collectionView.indexPathsForVisibleItems() {
                        if indexPath == visibleIndexPath {
                            let cell = self.collectionView.cellForItemAtIndexPath(indexPath) as! ShopDetailsCollectionViewCell
                            deActivateIndicatorForCell(cell, atIndexPath: indexPath)
                            needToBreak = true
                            break
                        }
                    }
                    
                    if (!needToBreak) {
                        self.processingCells.remove(indexPath)
                        needToBreak = true
                        break
                    }
                }
                i++
                
                if (needToBreak) {
                    break
                }
            }
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(PurchaseManager.sharedInstance)
        
        for taskIdKey in self.processingCellsImages.keys {
            if let taskId = self.processingCellsImages[taskIdKey] {
                NetworkManager.sharedManager.cancelTask(taskId)
            }
        }
        self.processingCellsImages.removeAll(keepCapacity: false)
    }
    
    @IBAction func closeButtonPressed(sender:UIButton!) {
        sender.hidden = true
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //MARK:ShopDetailsCellDelegate
    func buyButtonPressedInCell(cell: ShopDetailsCollectionViewCell) {
        
        
        if let indexPath = self.collectionView.indexPathForCell(cell) {
            
            for curIndexPath in self.collectionView.indexPathsForVisibleItems() {
                
                if (curIndexPath == indexPath) {
                    
                    let product = self.products[curIndexPath.row]
                    PurchaseManager.sharedInstance.schedulePaymentWithProduct(product)
                    
                    activateIndicatorForCell(cell, atIndexPath:curIndexPath)
                }
            }
        }
    }
    
    private func changeActitivyIndicatorStateForCell(cell: ShopDetailsCollectionViewCell!, isEnabled enabled:Bool,indexPath:NSIndexPath!) {
        
        cell.buyButton.enabled = !enabled
        
        if ((cell.contentView.subviews.last as? UIActivityIndicatorView) == nil && enabled) {
            let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
            activityIndicator.center = CGPointMake(CGRectGetMidX(cell.contentView.bounds), CGRectGetMidY(cell.contentView.bounds))
            cell.contentView.addSubview(activityIndicator)
        }
        var appendOnNeed:Bool = false
        
        if let lastChildView = cell.contentView.subviews.last as? UIActivityIndicatorView {
            if (enabled) {
                if !lastChildView.isAnimating() {
                    lastChildView.startAnimating()
                }
                appendOnNeed = true
            }
            else {
                if lastChildView.isAnimating() {
                    lastChildView.stopAnimating()
                    lastChildView.removeFromSuperview()
                }
            }
        }
        
        if (appendOnNeed) {
            if !self.processingCells.contains(indexPath) {
                self.processingCells.insert(indexPath)
            }
        } else {
            if self.processingCells.contains(indexPath) {
                self.processingCells.remove(indexPath)
            }
        }
    }
    
    private func activateIndicatorForCell(cell: ShopDetailsCollectionViewCell, atIndexPath indexPath:NSIndexPath!) {
        changeActitivyIndicatorStateForCell(cell, isEnabled: true,indexPath:indexPath)
    }
    
    private func deActivateIndicatorForCell(cell: ShopDetailsCollectionViewCell, atIndexPath indexPath:NSIndexPath!) {
        changeActitivyIndicatorStateForCell(cell, isEnabled: false,indexPath:indexPath)
    }
    
    //MARK: Collection View source & delegate
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.products.count
    }
    
    func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        
        if let value = self.processingCellsImages[indexPath] {
            if NetworkManager.sharedManager.isValidTask(value){
                NetworkManager.sharedManager.suspendTask(value)
            }
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let collectionViewCell = collectionView.dequeueReusableCellWithReuseIdentifier("productCell", forIndexPath: indexPath) as! ShopDetailsCollectionViewCell
        let product =  self.products[indexPath.row]
        
        print("Product downloadable: \(product.skProduct.downloadable)")
        
        //collectionViewCell.productImageView.image =
        
        
        if (product.productInfo?.icon == nil || product.productInfo!.icon!.isEmpty) {
            collectionViewCell.setImage(nil)
        } else {
            let icon = product.productInfo!.icon!
            if (!NSFileManager.defaultManager().jacHasItemInCache(icon)) {
                
                collectionViewCell.displayActivityIndicatorWhileDownloading()
                
                if processingCellsImages[indexPath] == nil {
                    
                    let taskId = NetworkManager.sharedManager.downloadFileFromPath(icon){
                      (path,error) in
                        
                        if (error == nil && path != nil) {
                            do {
                            let path = try NSFileManager.defaultManager().jacStoreItemToCache(path,fileName:icon.lastPathComponent)
                                
                                var image :UIImage?
                                if (error != nil || path == nil) {
                                    image = nil
                                }
                                else {
                                    let fURL = NSURL(fileURLWithPath: path!)
                                    image = UIImage(contentsOfFile: fURL.path!)
                                }
                                
                                dispatch_async(dispatch_get_main_queue()) {
                                    [unowned self] in
                                    
                                    self.processingCellsImages.removeValueForKey(indexPath)
                                    
                                    
                                    for vIndexPath in collectionView.indexPathsForVisibleItems() {
                                        if (vIndexPath == indexPath && collectionViewCell == collectionView.cellForItemAtIndexPath(indexPath)) {
                                            collectionViewCell.hideActivityIndicatorAfterDonwloading()
                                            
                                            collectionViewCell.setImage(image)
                                            
                                            return
                                        }
                                    }
                                }
                                
                            } catch {
                                print("Catch error")
                            }
                        }
                    }
                    
                    if NetworkManager.sharedManager.isValidTask(taskId) {
                        processingCellsImages[indexPath] = taskId
                    }
                    
                }
                else {
                    if let taskId = processingCellsImages[indexPath] {
                        NetworkManager.sharedManager.resumeSuspendedTask(taskId)
                    }
                }
                
            }
            else {
                collectionViewCell.hideActivityIndicatorAfterDonwloading()
                collectionViewCell.setImage(NSFileManager.defaultManager().jacGetImageFromCache(icon))
            }
            
        }
        
        markPurchaseInProgressOnNeed(product.productIdentifier)
        
        
        let present:Bool = processingCells.contains(indexPath)
        
        if present {
            activateIndicatorForCell(collectionViewCell,atIndexPath:indexPath)
        } else {
            deActivateIndicatorForCell(collectionViewCell,atIndexPath:indexPath)
        }
        
        
        
        collectionViewCell.setTitleForProduct(product.skProduct.localizedTitle)
        collectionViewCell.productDescription.text = product.skProduct.localizedDescription
        collectionViewCell.productDescription.sizeToFit()
        
        let curSymbol = product.skProduct.priceLocale.objectForKey(NSLocaleCurrencySymbol) as? String
        var titleStr : String! = "Price \(product.skProduct.price)"
        
        if let cur = curSymbol {
            titleStr = titleStr.stringByAppendingFormat(" %@",cur)
        }
        
        collectionViewCell.buyButton.setTitle(titleStr, forState: .Normal)
        collectionViewCell.buyButton.setTitle(titleStr, forState: .Selected)
        collectionViewCell.delegate = self
        
        collectionViewCell.setNeedsLayout()
        
        return collectionViewCell
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        coordinator.animateAlongsideTransition({(context: UIViewControllerTransitionCoordinatorContext!) -> Void in
            self.rotatePrivateForSize(size)
            }, completion:nil)
    }
    
    
    private func rotatePrivateForSize(size:CGSize,animated:Bool = false) {
        
        let flowLayout:UICollectionViewFlowLayout = self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        
        let isVertic = size.height > size.width
        if isVertic {
            flowLayout.scrollDirection = .Vertical
        }
        else {
            flowLayout.scrollDirection = .Horizontal
        }
        self.collectionView.setCollectionViewLayout(flowLayout, animated: animated)
        
        let frame = self.initialRect
        
        self.collectionView.frame = isVertic ? CGRectMake(CGRectGetMinY(frame), CGRectGetMinX(frame), CGRectGetHeight(frame), CGRectGetWidth(frame)) : frame
        self.collectionView.setNeedsLayout()
    }
    
}