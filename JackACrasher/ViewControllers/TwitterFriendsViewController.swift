//	
//  TwitterFriendsViewController.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 1/7/16.
//  Copyright © 2016 Siarhei Yakushevich. All rights reserved.
//

import UIKit
import TwitterKit

class TwitterFriendsViewController: UIViewController {

    @IBOutlet weak var collectionView:UICollectionView!
    @IBOutlet weak var nextBtn:UIButton!
    @IBOutlet weak var nextButtonLeftLayout:NSLayoutConstraint!
    private var leftSpace:CGFloat = 0.0
    
    private var twitterManager:TwitterManager!
    private var sectionChanges:[[NSFetchedResultsChangeType:Int]]! = nil
    private var itemChanges:[[NSFetchedResultsChangeType:NSIndexPath]]! = nil
    private var controller:NSFetchedResultsController!
    
    private var selectedTwitterIds = Set<String>()
    
    var twitterId:String! {
        didSet {
            if !(twitterId == nil || twitterId.isEmpty) {
                
                self.performSelectorInBackground("startExecution", withObject: nil)
                
                if (self.isViewLoaded()){
                    performFetch()
                }
                //self.performSelectorInBackground("performFetch", withObject: nil)
            }
        }
    }
    
    func startExecution() {
        
        self.twitterManager = TwitterManager(twitterId: twitterId)
        self.twitterManager.startUpdatingTotalList()
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        performFetch()
        
        self.leftSpace = self.nextButtonLeftLayout.constant
        
    }
    
    func performFetch() {
        
        print("%@",__FUNCTION__)
        
        let tuple = DBManager.sharedInstance.getFetchedTwitterUsers(self.twitterId, delegate: self)
        self.controller = tuple.controller
        if let error = tuple.error {
            //TODO: dipslay information about error....
            self.controller = nil
            dispatch_async(dispatch_get_main_queue()){
                [unowned self] in
                self.alertWithTitle(NSLocalizedString("Error", comment: "Error"), message: error.localizedDescription)
            }
        }
        
        /*let request = NSFetchRequest(entityName: TwitterUser.EntityName())
        request.sortDescriptors = [NSSortDescriptor(key: "userName", ascending: true)]
        request.fetchBatchSize = 20
        request.fetchLimit = 2
        let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: DBManager.sharedInstance.managedObjectContext, sectionNameKeyPath: nil, cacheName: "\(twitterId)")
        controller.delegate = self
        do {
            try controller.performFetch()
            self.controller = controller
        } catch let error as NSError {
            print("\(error)")
        }*/

    }
    
    private func appendRightBarItem() -> Bool {
        
        if self.navigationItem.rightBarButtonItem != nil {
            return false
        }
        
        
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
                    
                    if (error == nil) {
                        item?.title = unselectAll
            
                        //TODO: display next button....
                    }
                    item?.enabled = true
                }
            })
            
        }else if (item?.title == Optional<String>(unselectAll)) {
            
            item?.enabled = false
            DBManager.sharedInstance.uncheckAllTwitterUsers({ (count,error, saved) -> Void in
                
                dispatch_async(dispatch_get_main_queue()) {
                    [weak self] in
                    
                    guard (self != nil) else  {
                        return
                    }
                    if (error == nil) {
                        item?.title = selectAll
                    }
                    
                    item?.enabled = true
                }
            })
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
        self.sectionChanges = []
        self.itemChanges = []
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
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
                    /*if anObject is TwitterUser {
                    let twitterUser = anObject as! TwitterUser
                    
                    if (twitterUser.miniImage != nil) {
                    //TODO: add some fancy cool animation....
                    }
                    
                    dispatch_async(dispatch_get_main_queue()){
                    [unowned self] in
                    
                    if self.collectionView.indexPathsForVisibleItems().contains(newIndexPath!) {
                    self.collectionView.reloadItemsAtIndexPaths([newIndexPath!])
                    }
                    }
                    }*/

                    self.collectionView.reloadItemsAtIndexPaths(reloadArray)
                }
                
                count = reloadArray.count + insertArray.count - deleteArray.count
                
                }, completion: {[unowned self]  (finished) -> Void in
                        self.sectionChanges = nil
                        self.itemChanges = nil
                    
                    self.defineStateOfRightBarItem(count)
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
            
            /*if anObject is TwitterUser {
                let twitterUser = anObject as! TwitterUser
                
                if (twitterUser.miniImage != nil) {
                    //TODO: add some fancy cool animation....
                }
                
                dispatch_async(dispatch_get_main_queue()){
                    [unowned self] in
                    
                    if self.collectionView.indexPathsForVisibleItems().contains(newIndexPath!) {
                        self.collectionView.reloadItemsAtIndexPaths([newIndexPath!])
                    }
                }
            }*/
            
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

extension TwitterFriendsViewController : UICollectionViewDataSource,UICollectionViewDelegate
{
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        guard let count = self.controller?.fetchedObjects?.count else {
            return 0
        }
        
        return count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as! TwitterFriendCollectionViewCell
        
        let twitterUser = self.controller.fetchedObjects?[indexPath.row] as! TwitterUser
        
        if let imageData = twitterUser.miniImage {
            cell.setProfileImage(imaage: UIImage(data: imageData))
        }
        else if twitterUser.profileImageMiniURL == nil {
            cell.setProfileImage(imaage: nil)
        }
    
        cell.label.text = twitterUser.userName
        cell.label.sizeToFit()
        
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        collectionView.deselectItemAtIndexPath(indexPath, animated: false)
        
        let twitterUser = self.controller.fetchedObjects?[indexPath.row] as! TwitterUser
        
        var selected = false
        
        if let uId = twitterUser.userId {
        
            if self.selectedTwitterIds.contains(uId) {
                self.selectedTwitterIds.remove(uId)
            }
            else {
                self.selectedTwitterIds.insert(uId)
                selected = true
            }
        }
        
        if let cell = collectionView.cellForItemAtIndexPath(indexPath) as? TwitterFriendCollectionViewCell {
            cell.markAsSelected(selected)
        }
    }
}

//MARK: Next Button 
private extension TwitterFriendsViewController {
    
    
    func moveOutNextButton(duration:NSTimeInterval = 0.5, animated:Bool = false) {
        
        if (animated && duration != 0 ) {
            UIView.animateWithDuration(duration, animations: { [weak self]  () -> Void in
                
                self?.nextButtonLeftLayout.constant = -30
            
                }, completion: { [weak self] (finished) -> Void in
                self?.nextBtn.hidden = true
                self?.nextBtn.setNeedsLayout()
            })
        }
        else {
            self.nextButtonLeftLayout.constant = -30
            self.nextBtn.setNeedsLayout()
            self.nextBtn.hidden = true
        }
    }
    
    func moveInNextButton(duration:NSTimeInterval = 0.5, animated:Bool = false) {
        
        let leftSpace = self.leftSpace
        self.nextBtn.hidden = false
        
        if (animated && duration != 0 ) {
            UIView.animateWithDuration(duration, animations: { [weak self]  () -> Void in
                
                self?.nextButtonLeftLayout.constant = leftSpace
                
                }, completion: { [weak self] (finished) -> Void in
                    self?.nextBtn.setNeedsLayout()
                })
        }
        else {
            self.nextButtonLeftLayout.constant = leftSpace
            self.nextBtn.setNeedsLayout()
        }
    }
    
    @IBAction func nextButtonPressed(sender:UIButton) {
        //TODO: handle next clicked item...
    }
    
    private func defineStateOfRightBarItem(countExternal:Int = 0) {
        
        
            
            if countExternal != 0 {
                self.appendRightBarItem()
                
                if self.selectedTwitterIds.count == countExternal {
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
    
}
