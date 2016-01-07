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
    
    var twitterId:String! {
        didSet {
            if !(twitterId == nil || twitterId.isEmpty) {
                
                
                //No friends.!.... - friends
                client = TWTRAPIClient(userID: twitterId)
                var error:NSError? = nil
                let params:[NSObject:AnyObject] = ["cursor":"-1", "count":"5000", "screen_name":"\(twitterId)'s friends"]
                let request = client.URLRequestWithMethod("GET", URL: "https://api.twitter.com/1.1/friends/ids.json", parameters: params, error: &error)
                
                if let errorInner = error {
                    print("Error formatting \(errorInner)")
                    return
                }
                
                client.sendTwitterRequest(request, completion: { (response, data, connectionError) -> Void in
                    
                    if (connectionError == nil) {
                        if let json = try? NSJSONSerialization.JSONObjectWithData(data!,
                            options: NSJSONReadingOptions.AllowFragments) as! NSDictionary {
                                let ids = json.objectForKey("ids")
                                print("JSON response:\n \(json) \n Ids:\(ids))")
                        }
                    }
                    else {
                        print("Error: \(connectionError)")
                    }
                })
            }
        }
    }
    
    @IBAction func cancelPressed(sender:AnyObject) {
    
        self.navigationController?.dismissViewControllerAnimated(false, completion: nil)
    }
}
