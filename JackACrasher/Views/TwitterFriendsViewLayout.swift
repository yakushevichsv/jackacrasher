//
//  TwitterFriendsViewLayout.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 1/7/16.
//  Copyright © 2016 Siarhei Yakushevich. All rights reserved.
//

import UIKit

class TwitterFriendsViewLayout: UICollectionViewLayout {

    private var layoutAttributes = [UICollectionViewLayoutAttributes]()
    
    var numberOfColumns:Int = 10 {
        didSet {
            if (numberOfColumns != oldValue) {
                self.invalidateLayout()
            }
        }
    }
    
    var itemSize:CGSize = CGSizeMake(202 , 150) {
        didSet {
            if (!CGSizeEqualToSize(itemSize, oldValue)) {
                self.invalidateLayout()
            }
        }
    }
    
    private var numberOfRows:UInt = 0
    
    var itemEdgeInset:UIEdgeInsets = UIEdgeInsetsMake(10, 10, 5, 5) {
            didSet {
                if (!UIEdgeInsetsEqualToEdgeInsets(self.itemEdgeInset, oldValue)) {
                    self.invalidateLayout()
                }
        }
    }
    
    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        
        return false
    }
    
    override func targetContentOffsetForProposedContentOffset(proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        
        return self.targetContentOffsetForProposedContentOffset(proposedContentOffset)
    }
    
    override func targetContentOffsetForProposedContentOffset(var proposedContentOffset: CGPoint) -> CGPoint {
        
        let height = self.collectionViewContentSize().height
        
        if (proposedContentOffset.y > height) {
            proposedContentOffset.y = height
        }
        /*else if (proposedContentOffset.y < 0 && proposedContentOffset.y > -CGRectGetHeight(self.collectionView!.pullToRefreshController.frame)/2){
            proposedContentOffset.y = 0
        }*/
        
        return proposedContentOffset
    }
    
    override func prepareLayout() {
        super.prepareLayout()
        
        
        if let colView = self.collectionView {
         
            let numberOfItems = colView.numberOfItemsInSection(0);
            
            if numberOfItems == 0 {
                return
            }
            
            //print("Number of items \(numberOfItems)\n ")
            
            //var rowCount:UInt = 0
            
            var even = false
            let maxEvenRowItem = Int(ceil(Double(self.numberOfColumns)/2.0))
            
            
            let pairs = numberOfItems/(2*maxEvenRowItem - 1)
            numberOfRows = UInt(2*pairs)
            
            let reminder = numberOfItems - pairs * (2*maxEvenRowItem - 1)
            
            let extraRows = UInt(ceil(Double(reminder/maxEvenRowItem)))
            numberOfRows += extraRows
            
            //print("Extra rows \(numberOfRows)")
            
            
            var maxRowItem = maxEvenRowItem
            
            var yOffset:CGFloat = self.itemEdgeInset.top
            var xOffset:CGFloat = self.itemEdgeInset.left
            
            let width = self.itemSize.width - self.itemEdgeInset.left - self.itemEdgeInset.right
            
            let height = self.itemSize.height - self.itemEdgeInset.top - self.itemEdgeInset.bottom
            
            for index in 0..<numberOfItems {
            
                let attribute = UICollectionViewLayoutAttributes(forCellWithIndexPath: NSIndexPath(forItem: index, inSection: 0))
                
                let frame = CGRectMake(xOffset, yOffset, width, height)
                attribute.frame = frame
                
                layoutAttributes.append(attribute)
                
                maxRowItem--
                
                if (maxRowItem == 0 && index != numberOfItems - 1) {
                    
                    maxRowItem = maxEvenRowItem
                    
                    even = !even
                    
                    if even {
                        maxRowItem -= 1
                    }
                    
                    
                    if even {
                        xOffset = self.itemSize.width + self.itemEdgeInset.left
                    }
                    else {
                        xOffset = self.itemEdgeInset.left
                    }
                    
                    yOffset += self.itemSize.height
                    
                }
                else {
                    xOffset += 2*self.itemSize.width
                }

            }
        }
        else {
            self.layoutAttributes.removeAll()
        }
    }
    
    
    override func collectionViewContentSize() -> CGSize {
        var width  = self.itemSize.width * CGFloat(self.numberOfColumns)
        
        if (self.numberOfColumns % 2 == 0) {
            width -= self.itemSize.width
        }
        
        let height = self.itemSize.height * CGFloat(self.numberOfRows)
        
        var size = CGSizeMake(width, height)
        
        if  CGSizeEqualToSize(size,CGSizeZero) {
        
            if let colView = self.collectionView {
                var frame = colView.frame
                frame = CGRectInset(frame, colView.contentInset.left + colView.contentInset.right, colView.contentInset.bottom + colView.contentInset.top)
                size = frame.size
            }
        }
        
        return size
        
    }
    
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        
        return self.layoutAttributes.filter { (attribute) -> Bool in
            
            return CGRectIntersectsRect(attribute.frame, rect)
        }
    }
    
    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        
        guard indexPath.row < self.layoutAttributes.count else {
            return nil
        }
        
        return self.layoutAttributes[indexPath.row]
    }
}
