//	
//  TwitterFriendsViewController.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 1/7/16.
//  Copyright © 2016 Siarhei Yakushevich. All rights reserved.
//

import UIKit
import TwitterKit


/*
TODO:
1) Create Main thread Context
2) Next button action (Send to the twitter)
3) Select/unselect is not displayed properly (Situation when it is not unchecked
4) Change animation activity, use damping for the next button
5) Wrong size(H) of collectionView

*/

class TwitterFriendsViewController: ProgressHDViewController {

    @IBOutlet weak var collectionView:UICollectionView!
    @IBOutlet weak var nextBtn:UIButton!
    @IBOutlet weak var nextButtonLeftLayout:NSLayoutConstraint!
    private var leftSpace:CGFloat = 0.0
    
    private var twitterManager:TwitterManager!
    private var sectionChanges:[[NSFetchedResultsChangeType:Int]]! = nil
    private var itemChanges:[[NSFetchedResultsChangeType:NSIndexPath]]! = nil
    private var controller:NSFetchedResultsController!
    
    private var animateOnce:Bool = false
    
    var twitterId:String! {
        didSet {
            fetchOnNeed()
            if !(twitterId == nil || twitterId.isEmpty) {
                
                self.performSelectorInBackground("startExecution", withObject: nil)
            }
        }
    }
    
    private func fetchOnNeed(){
        if !(twitterId == nil || twitterId.isEmpty) {
            
            //self.performSelectorInBackground("startExecution", withObject: nil)
            
            if (self.isViewLoaded()){
                performFetch()
            }
            //self.performSelectorInBackground("performFetch", withObject: nil)
        }
    }
    
    func startExecution() {
        
        self.twitterManager = TwitterManager(twitterId: self.twitterId)
        self.twitterManager.startUpdatingTotalList()
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        fetchOnNeed()
        
        self.leftSpace = self.nextButtonLeftLayout.constant
        
        print("viewDidLoad")
        
        
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let count = self.collectionView.numberOfSections()
        if (count != 0) {
            defineStateOfRightBarItem(self.collectionView.numberOfItemsInSection(count-1))
        }
        
        
        if (!self.animateOnce) {
            
            var totalCount = DBManager.sharedInstance.totalCountOfTwitterUsers()
            
            if (totalCount == 0) {
                self.displayProgress(true)
            }
            else {
                totalCount = DBManager.sharedInstance.countSelectedItems()
            }
            self.moveInOutNextButton(totalCount != 0, animated: false)
        
            self.animateOnce = true
        }
    }
    
    func performFetch() {
        
        print("%@",__FUNCTION__)
        
        let tuple = DBManager.sharedInstance.getFetchedTwitterUsers(self.twitterId, delegate: self)
        self.controller = tuple.controller
        if let error = tuple.error {
            //TODO: dipslay information about error....
            self.controller = nil
            dispatch_async(dispatch_get_main_queue()){
                [weak self] in
                self?.alertWithTitle(NSLocalizedString("Error", comment: "Error"), message: error.localizedDescription)
            }
        }
    }
    
    private func appendRightBarItem() -> Bool {
        
        if self.navigationItem.rightBarButtonItem != nil {
            print("No need to append Right Bar")
            return false
        }
        
        print("Appending Right Bar")
        
        let item = UIBarButtonItem()
        item.target = self
        item.action = "checkUnCheckedPressed"
        let selectAll = NSLocalizedString("Select All", comment: "Select All")
        let unselectAll = NSLocalizedString("Unselect All", comment: "Unselect All")
        
        item.possibleTitles = Set<String>(arrayLiteral: selectAll,unselectAll)
        item.title = selectAll
        self.navigationItem.rightBarButtonItem = item
        
        return true
    }
    
    private func removeRightBarItem() -> Bool {
        
        if self.navigationItem.rightBarButtonItem == nil {
            return false
        }
        
        self.navigationItem.rightBarButtonItem = nil
        
        return true
    }
    
    func selectAllTitle() {
         dispatch_async(dispatch_get_main_queue()) {
            let selectAll = NSLocalizedString("Select All", comment: "Select All")
        
            let item = self.navigationItem.rightBarButtonItem
        
            item?.enabled  = true
            item?.title = selectAll
        }
    }
    
    func unSelectAllTitle() {
        dispatch_async(dispatch_get_main_queue()) {
            let unselectAll = NSLocalizedString("Unselect All", comment: "Unselect All")
            
            let item = self.navigationItem.rightBarButtonItem
            
            item?.enabled  = true
            item?.title = unselectAll
        }
    }
    
    func checkUnCheckedPressed() {
        
        let selectAll = NSLocalizedString("Select All", comment: "Select All")
        let unselectAll = NSLocalizedString("Unselect All", comment: "Unselect All")
        
        let item = self.navigationItem.rightBarButtonItem
        
        if (item?.title == Optional<String>(selectAll)) {
            
            item?.enabled = false
            
            DBManager.sharedInstance.checkAllTwitterUsers({ (count,error, saved) -> Void in
                
                dispatch_async(dispatch_get_main_queue()) {
                    [weak self] in
                    
                    guard (self != nil) else  {
                        return
                    }
                    
                    
                    if (error == nil || saved) {
                        let count2 = DBManager.sharedInstance.countSelectedItems()
                        
                        self?.moveInOutNextButton(count2 != 0, animated: true)
                        
                        assert(count2 >= count)
                    }

                    
                    if (error == nil) {
                        item?.title = unselectAll
                        self?.markVisibleCells(true)
                    }
                    item?.enabled = true
                }
            })
            
        }else if (item?.title == Optional<String>(unselectAll)) {
            
            item?.enabled = false
            print("UnSelect All!")
            DBManager.sharedInstance.uncheckAllTwitterUsers({ (count,error, saved) -> Void in
                
                
                dispatch_async(dispatch_get_main_queue()) {
                    [weak self] in
                    
                    guard (self != nil) else  {
                        return
                    }
                    
                    
                    if (error == nil || saved) {
                        let count2 = DBManager.sharedInstance.countSelectedItems()
                        
                        self?.moveInOutNextButton(count2 != 0, animated: true)
                        
                        assert(count2 == 0)
                    }
                    
                    if (error == nil) {
                        item?.title = selectAll
                        
                        print("UnSelect All! reload data")
                        self?.markVisibleCells(false)
                    }
                    
                    item?.enabled = true
                }
            })
        }
    }
    
    private func markVisibleCells(selected:Bool) {
        
        for cell in  self.collectionView.visibleCells() as! [TwitterFriendCollectionViewCell] {
            cell.markAsSelected(selected)
        }
    }

    @IBAction func cancelPressed(sender:AnyObject) {
    
        self.twitterManager?.cancelAllTwitterRequests()
        self.navigationController?.dismissViewControllerAnimated(false, completion: nil)
    }
}

extension TwitterFriendsViewController : NSFetchedResultsControllerDelegate
{
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        print("controllerWillChangeContent")
        self.sectionChanges = []
        self.itemChanges = []
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        print("controllerDidChangeContent")
        //let count = controller.fetchedObjects?.count ?? 0
        
        let sections = self.sectionChanges
        let items = self.itemChanges
        
        dispatch_async(dispatch_get_main_queue()){
            
        
            var count = 0
            self.collectionView.performBatchUpdates({ [unowned self]  () -> Void in
                
                
                
                for sectionChange in sections {
                    
                    for (type,sectionIndex) in sectionChange {
                        switch type {
                        case NSFetchedResultsChangeType.Insert:
                            self.collectionView.insertSections(NSIndexSet(index: sectionIndex))
                            break
                        case NSFetchedResultsChangeType.Delete:
                            self.collectionView.deleteSections(NSIndexSet(index: sectionIndex))
                            break
                        default:
                            assert(false)
                            break
                        }
                    }
                }
                
                /*if (self.sectionChanges.isEmpty && self.collectionView.numberOfSections() == 0) {
                    self.collectionView.insertSections(NSIndexSet(index: 0))
                }*/
                
                var insertArray = [NSIndexPath]()
                var deleteArray = [NSIndexPath]()
                var reloadArray = [NSIndexPath]()
                
                for itemChange in items {
                    
                    for (type,indexPath) in itemChange {
                        
                        switch type {
                        case NSFetchedResultsChangeType.Insert:
                            
                            insertArray.append(indexPath)
                            break
                        case NSFetchedResultsChangeType.Update:
                            
                            //if self.collectionView.indexPathsForVisibleItems().contains(indexPath) {
                                reloadArray.append(indexPath)
                            //}
                            break
                        case NSFetchedResultsChangeType.Delete:
                            
                            deleteArray.append(indexPath)
                            break
                        case NSFetchedResultsChangeType.Move:
                            //assert(false)
                            break
                        }
                        
                    }
                }
                
                if !insertArray.isEmpty {
                    self.collectionView.insertItemsAtIndexPaths(insertArray)
                }
                
                if !deleteArray.isEmpty {
                    self.collectionView.deleteItemsAtIndexPaths(deleteArray)
                }
                
                if !reloadArray.isEmpty {
                    self.collectionView.reloadItemsAtIndexPaths(reloadArray)
                }
                
                count = reloadArray.count + insertArray.count - deleteArray.count
                
                }, completion: {[weak self]  (finished) -> Void in
                        self?.sectionChanges = nil
                        self?.itemChanges = nil
                    
                    self?.defineStateOfRightBarItem(count)
                    
                    if (count != 0) {
                        self?.hideProgress()
                    }
                })
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        let dic = [type:sectionIndex]
        self.sectionChanges.append(dic)
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        let index = newIndexPath ?? indexPath
        let dic = [type:index!]
        self.itemChanges.append(dic)
        
        switch type {
        case NSFetchedResultsChangeType.Insert:
            //self.collectionView.performSelectorOnMainThread("insertItemsAtIndexPaths:", withObject: [newIndexPath!], waitUntilDone: false)
            break
        case NSFetchedResultsChangeType.Update:
            
            
            break
        case NSFetchedResultsChangeType.Delete:
            //self.collectionView.performSelectorOnMainThread("deleteItemsAtIndexPaths:", withObject: [indexPath!], waitUntilDone: false)
            break
        case NSFetchedResultsChangeType.Move:
            //assert(false)
            break
        }
    }
}

//MARK: Controller's methods....
/*extension TwitterFriendsViewController {
    
    func fetchedObjectsCountInSection(section:Int) -> Int {
        
        var count:Int = 0
        DBManager.sharedInstance.managedObjectContext.performBlockAndWait { () -> Void in
            
            if let countInnter = self.controller?.sections?[section].numberOfObjects {
                count = countInnter
            }
            else {
                count = 0
            }
        }
        
        return count
    }
    
    func twitterUserAtIndexPath(indexPath:NSIndexPath) -> TwitterUser! {
        
        var twitterUser:TwitterUser! = nil
        
        DBManager.sharedInstance.managedObjectContext.performBlockAndWait { () -> Void in
            twitterUser = self.controller.objectAtIndexPath(indexPath) as! TwitterUser
        }
        return twitterUser
    }
}*/

//MARK: CollectionView DS & Delegate
extension TwitterFriendsViewController : UICollectionViewDataSource,UICollectionViewDelegate
{
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        var count:Int
        if let countInnter = self.controller?.sections?[section].numberOfObjects {
            count = countInnter
        }
        else {
            count = 0
        }
        
        
        return count

    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as! TwitterFriendCollectionViewCell
        
        let twitterUser = self.controller.objectAtIndexPath(indexPath) as! TwitterUser
        
        if let imageData = twitterUser.miniImage {
            cell.setProfileImage(imaage: UIImage(data: imageData))
        }
        else if twitterUser.profileImageMiniURL == nil {
            cell.setProfileImage(imaage: nil)
        }
        
        cell.setText(twitterUser.userName)
    
        cell.markAsSelected(twitterUser.selected)
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        collectionView.deselectItemAtIndexPath(indexPath, animated: false)
        
        let twitterUser = self.controller.objectAtIndexPath(indexPath) as! TwitterUser
        
        
        var selected:Bool
        
        if (!twitterUser.userId!.isEmpty) {
        
            selected = !twitterUser.selected
        }
        else {
            selected = false
        }
        
    
        twitterUser.selected = selected
        
        
        if let cell = collectionView.cellForItemAtIndexPath(indexPath) as? TwitterFriendCollectionViewCell {
            cell.markAsSelected(selected)
        }
        
        self.moveInOutNextButton(selected || DBManager.sharedInstance.countSelectedItems() != 0, animated: true)
    }
}

//MARK: Next Button
private extension TwitterFriendsViewController {
    
    
    func moveOutNextButton(animated:Bool = false) {
        
        assert(self.nextBtn.superview! == self.view)
        self.nextBtn.superview?.bringSubviewToFront(self.nextBtn)
        
        print("Move OUT Next button \(animated)")
        
        self.nextButtonLeftLayout.constant = -CGRectGetWidth(self.nextBtn.bounds)
        
        if (animated) {
            
            UIView.animateWithDuration(0.2, animations: { [weak self]  () -> Void in
                
                self?.view.layoutIfNeeded()
                
                }, completion: { [weak self] (finished) -> Void in
                self?.nextBtn.hidden = true
            })
        }
        else {
            self.view.layoutIfNeeded()
            self.nextBtn.hidden = true
        }
    }
    
    func moveInNextButton(animated:Bool = false) {
        
        let leftSpace = self.leftSpace
        self.nextBtn.hidden = false
        
        assert(self.nextBtn.superview! == self.view)
        
        self.nextBtn.superview?.bringSubviewToFront(self.nextBtn)
        
        print("Move in Next button \(animated)")
        self.nextButtonLeftLayout.constant = leftSpace
        
        if (animated) {
            
            UIView.animateWithDuration(0.8, delay: 0.0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0.8, options: .CurveEaseOut, animations: { [weak self]  () -> Void in
                
                self?.view.layoutIfNeeded()
                
                }, completion:nil)
        }
        else {
            self.view.layoutIfNeeded()
        }
    }
    
    @IBAction func nextButtonPressed(sender:UIButton) {
        //TODO: handle next clicked item...
    }
    
    private func defineStateOfRightBarItem(countExternal:Int = 0) {
        
        
            print("defineStateOfRightBarItem: Before append External count \(countExternal)")
            if countExternal != 0 {
                self.appendRightBarItem()
                
                if DBManager.sharedInstance.countSelectedItems() == countExternal {
                    self.unSelectAllTitle()
                }
                else {
                    self.selectAllTitle()
                }
            }
            else {
                self.removeRightBarItem()
            }
        
    }
    
    private func isNextButtonVisible() -> Bool {
        
        return self.view.bounds.contains(self.nextBtn.frame) || (self.nextButtonLeftLayout == self.leftSpace && self.nextBtn.enabled)
    }
    
    func moveInOutNextButton(moveIn:Bool, animated:Bool ) {
        
        if (moveIn) {
            let isVisible = animated ? self.isNextButtonVisible() : true
            
            self.moveInNextButton(!isVisible)
        }
        else {
            let isVisible = animated ? self.isNextButtonVisible() : false
            self.moveOutNextButton(isVisible)
        }
    }
    
}
