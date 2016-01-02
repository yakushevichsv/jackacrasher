//
//  InviteFriendsViewController.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 1/2/16.
//  Copyright © 2016 Siarhei Yakushevich. All rights reserved.
//

import UIKit
import FBSDKShareKit

class InviteFriendsViewController: UIViewController {

    private var rows = 0
    
    private let isFBEnabled:Bool = { return InviteFriendsViewController.canInviteFriendsFromFB() }()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        if (self.isFBEnabled) {
            rows += 1
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
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
        
        if (indexPath.row == 0)
        {
            if isFBEnabled {
                text = NSLocalizedString("Facebook", comment: "Facebook")
            }
            
        }
        
        tc.textLabel?.text = text
        
        return tc
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        
        if (indexPath.row == 0) {
            if isFBEnabled {
               self.showFBDialog()
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


