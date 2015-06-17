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
    
    internal var products:[SKProduct] = [] {
        didSet {
            if self.isViewLoaded() {
                self.collectionView?.reloadData()
            }
         }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initialRect = self.collectionView.frame
        
        if CGRectGetHeight(self.view.frame) > CGRectGetWidth(self.view.frame) {
            rotatePrivateForSize(self.view.frame.size)
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handlePurchasesNotification:", name: IAPPurchaseNotification, object: PurchaseManager.sharedInstance)
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
            // Downloading is done, remove the status message
        case .IAPPurchaseSucceeded:
            disposeActivityInficationUsingNofitication(aNotification)
            break
        case .IAPRestoredSucceeded:
            disposeActivityInficationUsingNofitication(aNotification)
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
    
    private func disposeActivityInficationUsingNofitication(aNotification:NSNotification!) {
    
        let userInfo = aNotification.userInfo
        
        if let productId = userInfo?["id"] as? String {
            var i = 0
            var needToBreak = false
            for product in products {
                if (productId == product.productIdentifier) {
                    let indexPath = NSIndexPath(forRow: i, inSection: 0)
                    for visibleIndexPath  in self.collectionView.indexPathsForVisibleItems() as! [NSIndexPath!] {
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
    }
    
    @IBAction func closeButtonPressed(sender:UIButton!) {
        sender.hidden = true
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //MARK:ShopDetailsCellDelegate
    func buyButtonPressedInCell(cell: ShopDetailsCollectionViewCell) {
        
        
        if let indexPath = self.collectionView.indexPathForCell(cell) {
            
            for curIndexPath in self.collectionView.indexPathsForVisibleItems() as! [NSIndexPath] {
                
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
        
        if let lastChildView = cell.contentView.subviews.last as? UIActivityIndicatorView {
            if (enabled) {
                if !lastChildView.isAnimating() {
                    lastChildView.startAnimating()
                }
                if !self.processingCells.contains(indexPath) {
                    self.processingCells.insert(indexPath)
                }
            }
            else {
                if lastChildView.isAnimating() {
                    lastChildView.stopAnimating()
                    lastChildView.removeFromSuperview()
                }
                if self.processingCells.contains(indexPath) {
                    self.processingCells.remove(indexPath)
                }
            }
        }
        else {
            assert(enabled == false)
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
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let collectionViewCell = collectionView.dequeueReusableCellWithReuseIdentifier("productCell", forIndexPath: indexPath) as! ShopDetailsCollectionViewCell
        let product =  self.products[indexPath.row]
    
        println("Product downloadable: \(product.downloadable)")
        
        //collectionViewCell.productImageView.image =
        
        if (!product.downloadable) {
            collectionViewCell.setImage(nil)
        } else {
            assert(false)
        }
        
        let present:Bool = processingCells.contains(indexPath)
        
        if present {
            activateIndicatorForCell(collectionViewCell,atIndexPath:indexPath)
        } else {
            deActivateIndicatorForCell(collectionViewCell,atIndexPath:indexPath)
        }
        
        
        
        collectionViewCell.productTitle.text = product.localizedTitle
        collectionViewCell.productDescription.text = product.localizedDescription
        collectionViewCell.productDescription.sizeToFit()
    
        var title:String! = nil
        var curSymbol = product.priceLocale.objectForKey(NSLocaleCurrencySymbol) as? String
        var titleStr : String! = "Price \(product.price)"
        
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