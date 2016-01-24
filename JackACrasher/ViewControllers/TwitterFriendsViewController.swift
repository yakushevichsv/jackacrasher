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
    private var twitterManager:TwitterManager!
    private var sectionChanges:[[NSFetchedResultsChangeType:Int]]! = nil
    private var itemChanges:[[NSFetchedResultsChangeType:NSIndexPath]]! = nil
    private var controller:NSFetchedResultsController!
    
    var twitterId:String! {
        didSet {
            if !(twitterId == nil || twitterId.isEmpty) {
                
                //self.performSelectorInBackground("startExecution", withObject: nil)
                
                performFetch()
                //self.performSelectorInBackground("performFetch", withObject: nil)
            }
        }
    }
    
    func startExecution() {
        
        self.twitterManager = TwitterManager(twitterId: twitterId)
        self.twitterManager.startUpdatingTotalList()
    }
    
    func performFetch() {
        
        /*let tuple = DBManager.sharedInstance.getFetchedTwitterUsers(self.twitterId, delegate: self)
        self.controller = tuple.controller
        if let error = tuple.error {
            //TODO: dipslay information about error....
        }*/
        
        let request = NSFetchRequest(entityName: TwitterUser.EntityName())
        request.sortDescriptors = [NSSortDescriptor(key: "userName", ascending: true)]
        request.fetchBatchSize = 20
        let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: DBManager.sharedInstance.managedObjectContext, sectionNameKeyPath: nil, cacheName: "\(twitterId)")
        controller.delegate = self
        do {
            try controller.performFetch()
            self.controller = controller
        } catch let error as NSError {
            print("\(error)")
        }

    }
    
    private func appendRightBarItem() -> Bool {
        
        if self.navigationItem.rightBarButtonItem == nil {
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
    
    func checkUnCheckedPressed() {
        
        let selectAll = NSLocalizedString("Select All", comment: "Select All")
        let unselectAll = NSLocalizedString("Unselect All", comment: "Unselect All")
        
        let item = self.navigationItem.rightBarButtonItem
        
        if (item?.title == Optional<String>(selectAll)) {
            
            item?.enabled = false
            
            DBManager.sharedInstance.checkAllTwitterUsers({ (count,error, saved) -> Void in
                if (error == nil) {
                    item?.title = unselectAll
                    
                    //TODO: display next button....
                }
                item?.enabled = true
            })
            
        }else if (item?.title == Optional<String>(unselectAll)) {
            
            item?.enabled = false
            DBManager.sharedInstance.uncheckAllTwitterUsers({ (count,error, saved) -> Void in
                if (error == nil) {
                    item?.title = selectAll
                }
                item?.enabled = true
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
        
        let count = controller.fetchedObjects?.count ?? 0
        
        dispatch_async(dispatch_get_main_queue()){
            [unowned self] in
            
            self.collectionView.performBatchUpdates({ [unowned self]  () -> Void in
                
                for sectionChange in self.sectionChanges {
                    
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
                
                for itemChange in self.itemChanges {
                    
                    for (type,indexPath) in itemChange {
                        
                        switch type {
                        case NSFetchedResultsChangeType.Insert:
                            
                            insertArray.append(indexPath)
                            break
                        case NSFetchedResultsChangeType.Update:
                            
                            if self.collectionView.indexPathsForVisibleItems().contains(indexPath) {
                                reloadArray.append(indexPath)
                            }
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
                
                
                }, completion: {[unowned self]  (finished) -> Void in
                        self.sectionChanges = nil
                        self.itemChanges = nil
                    
                    if count != 0 {
                        self.appendRightBarItem()
                    }
                    else {
                        self.removeRightBarItem()
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
        
        let twitterUser = self.controller.objectAtIndexPath(indexPath) as! TwitterUser
        
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
}
