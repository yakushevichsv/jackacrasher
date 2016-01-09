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
    private var client : TWTRAPIClient!
    private let ids = NSMutableArray()
    
    var twitterId:String! {
        didSet {
            if !(twitterId == nil || twitterId.isEmpty) {
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
                    [unowned self] in
                
                    //No friends.!.... - friends
                    self.client = TWTRAPIClient(userID: self.twitterId)
                    var error:NSError? = nil
                    let params:[NSObject:AnyObject] = ["cursor":"-1", "count":"5000", "screen_name":"\(self.twitterId)'s friends"]
                    let request = self.client.URLRequestWithMethod("GET", URL: "https://api.twitter.com/1.1/friends/ids.json", parameters: params, error: &error)
                    
                    if let errorInner = error {
                        print("Error formatting \(errorInner)")
                        return
                    }
                    
                    self.client.sendTwitterRequest(request, completion: { (response, data, connectionError) -> Void in
                        
                        if (connectionError == nil) {
                            if let json = try? NSJSONSerialization.JSONObjectWithData(data!,
                                options: NSJSONReadingOptions.AllowFragments) as! NSDictionary {
                                    let ids = json.objectForKey("ids")
                                    print("JSON response:\n \(json) \n Ids:\(ids))")
                                    self.ids.removeAllObjects()
                            
                                    let range = NSMakeRange(0, ids!.count)
                                    let indexes = NSMutableIndexSet(indexesInRange: range)
                                    self.ids.insertObjects(ids as! [AnyObject], atIndexes: indexes)
                                    
                                    dispatch_async(dispatch_get_main_queue()){
                                        [unowned self ] in
                                        self.collectionView.reloadData()
                                    }
                            }
                        }
                        else {
                            self.ids.removeAllObjects()
                            print("Error: \(connectionError)")
                        }
                    })
                }
            }
        }
    }
    
    @IBAction func cancelPressed(sender:AnyObject) {
    
        self.navigationController?.dismissViewControllerAnimated(false, completion: nil)
    }
}

extension TwitterFriendsViewController : UICollectionViewDataSource,UICollectionViewDelegate
{
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.ids.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as? TwitterFriendCollectionViewCell
        
        cell?.label.text = "\(self.ids[indexPath.row].doubleValue!)"
        
        return cell!
    }
}
