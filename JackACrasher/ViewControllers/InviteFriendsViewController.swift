//
//  InviteFriendsViewController.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 1/2/16.
//  Copyright © 2016 Siarhei Yakushevich. All rights reserved.
//

import UIKit
import FBSDKShareKit
import TwitterKit

let twitterFriendsId = "twitterFriendsId"

class InviteFriendsViewController: UIViewController {

    private var rows = 0
    private var twitterUserId:String! = nil
    
    private let isFBEnabled:Bool = { return InviteFriendsViewController.canInviteFriendsFromFB() }()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        if (self.isFBEnabled) {
            rows += 1
        }
        
        //twitter is enabled by default...
        rows += 1
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if (segue.identifier == Optional<String>(twitterFriendsId)) {
            if let dVC = segue.destinationViewController as? UINavigationController {
                if let twitterVC = dVC.topViewController as? TwitterFriendsViewController {
                    twitterVC.twitterId = self.twitterUserId
                }
            }
        }
        else {
            super.prepareForSegue(segue, sender: sender)
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    class func canInviteFriends() -> Bool {
        
        return InviteFriendsViewController.canInviteFriendsFromFB()
    }
}

//MARK: Table View DS & Delegate

extension InviteFriendsViewController:UITableViewDataSource, UITableViewDelegate {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let tc = tableView.dequeueReusableCellWithIdentifier("Cell")!
        
        var text = ""
        var isTwitter = false
        
        if (indexPath.row == 0)
        {
            if isFBEnabled {
                text = NSLocalizedString("Facebook", comment: "Facebook")
            }
            else {
                isTwitter = true
            }
        }
        else if (indexPath.row == 1)
        {
            if isFBEnabled {
                isTwitter = true
            }
        }
        
        if (isTwitter) {
            text = NSLocalizedString("Twitter", comment: "Twitter")
        }
        
        tc.textLabel?.text = text
        
        return tc
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        
        var isTwitter = false
        
        if (indexPath.row == 0) {
            if isFBEnabled {
               self.showFBDialog()
            }
            else {
                isTwitter = true
            }
        } else if (indexPath.row == 1) {
            if isFBEnabled {
                isTwitter = true
            }
        }
        
        if isTwitter {
            if let cell = tableView.cellForRowAtIndexPath(indexPath) {
                self.initiavateTweeterOperation(cell)
            }
        }
    }
}

//MARK: FB items
extension InviteFriendsViewController:FBSDKAppInviteDialogDelegate {
    
    class func canInviteFriendsFromFB() -> Bool {
        return FBSDKAppInviteDialog().canShow()
    }
    
    private func FBAppInviteContent() -> FBSDKAppInviteContent! {
        
        let content = FBSDKAppInviteContent()
        content.appLinkURL = NSURL(string: "https://fb.me/524987154334753")
        //optionally set previewImageURL
        content.appInvitePreviewImageURL = NSURL(string: "https://dl.dropboxusercontent.com/u/106064832/JackACrasher/fbInvite.png")
        //Preffered 1,200 x 628 pixels with an image ratio of 1.9:1.
        
        return content
    }
    
    func showFBDialog() -> Bool {
        
        let content = FBAppInviteContent()
        
        let dialog = FBSDKAppInviteDialog()
        dialog.content = content
        dialog.delegate = self
        return dialog.show()
    }
    
    
    //MARK: FBSDKAppInviteDialogDelegate
    
    func appInviteDialog(appInviteDialog: FBSDKAppInviteDialog!, didFailWithError error: NSError!) {
        
        if (error != nil) {
            
            self.alertWithTitle("Error", message: error.localizedFailureReason != nil && !error.localizedFailureReason!.isEmpty ? error.localizedFailureReason! : "Failed to invite FB friends")
        }
        
        self.dismissViewControllerAnimated(false, completion: nil)
    }
    
    func appInviteDialog(appInviteDialog: FBSDKAppInviteDialog!, didCompleteWithResults results: [NSObject : AnyObject]!) {
        
        self.dismissViewControllerAnimated(false, completion: nil)
    }
}


//MARK: Twitter items

extension InviteFriendsViewController {
    
    func initiavateTweeterOperation(let cell:UITableViewCell) {
        
        Twitter.sharedInstance().logInWithViewController(self.presentingViewController) { (session, error) -> Void in
        
            guard (error == nil && session != nil) else {
                if error != nil {
                    if (error!.domain == TWTRLogInErrorDomain && error!.code == TWTRLogInErrorCode.Denied.rawValue) {
                        return
                    }
                    self.alertWithTitle("Error", message: error!.localizedDescription)
                }
                return
            }
            self.twitterUserId = session!.userID
            self.performSegueWithIdentifier(twitterFriendsId, sender: cell)
        
        }
    }
    
}

