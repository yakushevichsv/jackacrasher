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
    
    private var controller:NSFetchedResultsController!
    
    var twitterId:String! {
        didSet {
            if !(twitterId == nil || twitterId.isEmpty) {
                
                self.performSelectorInBackground("startExecution", withObject: nil)
                
                //TODO: add support for periodic update of friends....
                let request = NSFetchRequest(entityName: TwitterId.EntityName())
                request.sortDescriptors = [NSSortDescriptor(key: "userId", ascending: true)]
                self.controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: DBManager.sharedInstance.managedObjectContext, sectionNameKeyPath: nil, cacheName: "\(twitterId)")
                self.controller.delegate = self
                do {
                    try self.controller.performFetch()
                } catch let error as NSError {
                    print("\(error)")
                }
            }
        }
    }
    
    func startExecution() {
        
        self.twitterManager = TwitterManager(twitterId: twitterId)
        self.twitterManager.startUpdatingTotalList()
    }
    
    @IBAction func cancelPressed(sender:AnyObject) {
    
        self.twitterManager.cancelAllTwitterRequests()
        self.navigationController?.dismissViewControllerAnimated(false, completion: nil)
    }
}

extension TwitterFriendsViewController : NSFetchedResultsControllerDelegate
{
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
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
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as? TwitterFriendCollectionViewCell
        
        let twitterId = self.controller.objectAtIndexPath(indexPath) as! TwitterId
        
        cell?.label.text = "\(twitterId.userId)"
        
        return cell!
    }
}
