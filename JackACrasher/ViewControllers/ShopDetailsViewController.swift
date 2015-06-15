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
                    
                }
            }
        }
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
        
        
        collectionViewCell.productTitle.text = product.localizedTitle
        collectionViewCell.productDescription.text = product.localizedDescription
        collectionViewCell.productDescription.sizeToFit()
    
        var title:String! = nil
        if (product.priceLocale.objectForKey(NSLocaleLanguageCode) as! String == "en"){
            title = "Price \(product.price)"
        }
        else {
            title = "\(product.price)"
        }
        collectionViewCell.buyButton.setTitle(title, forState: .Normal)
        collectionViewCell.buyButton.setTitle(title, forState: .Selected)
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