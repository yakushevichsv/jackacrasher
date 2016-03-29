//
//  TwitterFriendsSendViewController.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 3/12/16.
//  Copyright © 2016 Siarhei Yakushevich. All rights reserved.
//

import UIKit
//import TwitterKit

/*
TODO:
4) Correct position when item is not selected for sending...
5) add some fancy layers animation...
Display at the end total description.
Number of send/failed items....
*/

class TwitterFriendsSendViewController: ProgressHDViewController {

    var twitterManager:TwitterManager!
    private let rowsCount:Int = DBManager.sharedInstance.countSelectedItems()
    private var countSendItems:Int = 0
    private var bulkNumber:Int = 0
    private var checkedRows = Set<Int>()
    private var textLimit:Int = 200
    
    private var messageToSend:String! = nil
    private var sendMessageError:NSError? = nil
    
    private lazy var objCache:NSCache = {
        let cache = NSCache()
        cache.countLimit = self.bulkNumber != 0 ? 3 * self.bulkNumber : 30
        return cache
    }()
    
    private var isFirstSecionExpanded = true
    private var isLastSectionExpanded = true
    
    private var sendingSet = Set<Int>()
    private var failedSet  = Set<Int>()
    private var successSet = Set<Int>()
    
    
    @IBOutlet weak var collectionView:UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        countSendItems = self.rowsCount
        for i in 0..<countSendItems {
            checkedRows.insert(i)
        }
        
        detectBulkRowsNumber()
        self.twitterManager.tryToGetConfiguration()
        correctTitleOfNavigationItemOnNeed()
    }
}

//MARK: Cache Logic
extension TwitterFriendsSendViewController {
    
    func detectBulkRowsNumber() {
        
        if self.rowsCount != 0  {
            let h = CGRectGetHeight(collectionView.frame)
            
            let cell =  collectionView.dequeueReusableCellWithReuseIdentifier("sendCell", forIndexPath: NSIndexPath(forRow: 0, inSection: 1)) as! TwitterSendCollectionViewCell
            
            let hCell = CGRectGetHeight(cell.frame)
            
            self.bulkNumber = Int(ceil(h/hCell))
        }
        else {
            self.bulkNumber = 0
        }
    }
    
    func twitterUserFromCache(indexPath:NSIndexPath) -> TwitterUser? {
        
        return objCache.objectForKey(indexPath) as? TwitterUser
    }
    
    func fillInTwitterUsersFromNewScreen(indexPath:NSIndexPath) -> TwitterUser! {
        
        let index = indexPath.row/self.bulkNumber
        
        let startRow = index * self.bulkNumber
        
        var fUser:TwitterUser! = nil
        
        if let array = DBManager.sharedInstance.selectedITwitterUsers(startRow, batchSize: self.bulkNumber) {
            
            var index = 0
            
            
            for twitterUser in array {
                
                let indexPath2 = NSIndexPath(forRow: startRow + index, inSection: indexPath.section)
                index++
            
                if indexPath2 == indexPath {
                    fUser = twitterUser
                }
                
                objCache.setObject(twitterUser, forKey: indexPath2)
            }
        }
        return fUser
    }
    
    func getTwitterUser(indexPath:NSIndexPath) -> TwitterUser? {
        
        var twUser = self.twitterUserFromCache(indexPath)
        
        if twUser == nil {
            twUser = fillInTwitterUsersFromNewScreen(indexPath)
        }
        return twUser
    }
}

//MARK: UICollectionView DataSource & Delegate
extension TwitterFriendsSendViewController : UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if (section == 0) {
            return self.isFirstSecionExpanded ? 1 : 0
        }
        else  {
            assert(section == 1)
            return self.isLastSectionExpanded ? self.rowsCount : 0
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        if (indexPath.section == 0) {
            
             let cell = collectionView.dequeueReusableCellWithReuseIdentifier("messageCell", forIndexPath: indexPath) as! TwitterSendMessageCollectionViewCell
            
            let limit = self.twitterManager.textLimit()
            
            if limit != 0  {
                textLimit = limit
            }
            
            let realCount = cell.tvMessage.text.characters.count
            cell.lblCharacters.text = "\(realCount)/\(self.textLimit)"
            
            //TODO: Store message Template...
            
            if self.messageToSend == nil {
                self.messageToSend = cell.tvMessage.text
            }
            
            return cell
        }
        else  {
            
            assert(indexPath.section == 1)
            
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("sendCell", forIndexPath: indexPath) as! TwitterSendCollectionViewCell
            
            cell.checked =  checkedRows.contains(indexPath.row)
            
            if let twUser =  getTwitterUser(indexPath) {
                configureCell(cell, user: twUser,indexPath: indexPath)
            }
            return cell
        }
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize
    {
        return CGSizeMake(CGRectGetWidth(self.collectionView.frame), 50)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let w = CGRectGetWidth(self.collectionView.frame)
        var h:CGFloat = 0
        
        if (indexPath.section == 0) {
           h = 150
        }
        else {
            assert(indexPath.section == 1)
            h = 70
        }
        return CGSizeMake(w, h)
    }
    
    
    
    private func configureCell(cell:TwitterSendCollectionViewCell, user:TwitterUser ,indexPath:NSIndexPath) {
        
        cell.lblName.text = user.userName
        var image:UIImage!
        
        if let miniImage = user.miniImage {
            image = UIImage(data: miniImage)
        }
        else {
            image = nil
        }
        cell.ivImage.image = image
        
        if let descr = user.friendshipDescription() {
            cell.lblFriendship.text = descr
            cell.lblFriendship.hidden = false
        }
        else {
            cell.lblFriendship.hidden = true
        }
        
        if needToSendRow(indexPath.row) {
            cell.sendingState = .None
        }
        else if isOK(indexPath.row) {
            cell.sendingState = .Success
        }
        else if hasFailed(indexPath.row) {
            cell.sendingState = .Failed
        }
        else if isSending(indexPath.row) {
            cell.sendingState = .Sending
        }
    }
    
    
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        
        var cell:TwitterSendSectionHeaderCollectionReusableView!
        
        if (kind == UICollectionElementKindSectionHeader) {
            cell = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier:"headerCell", forIndexPath: indexPath) as! TwitterSendSectionHeaderCollectionReusableView
            
            if (cell.gestureRecognizers == nil || cell.gestureRecognizers!.isEmpty) {
                
                let recognizer = UITapGestureRecognizer(target: self, action: "tapGestureRecogniser:")
                
                if cell.gestureRecognizers == nil {
                    cell.gestureRecognizers = [UIGestureRecognizer](arrayLiteral: recognizer)
                }
                else {
                    cell.gestureRecognizers?.append(recognizer)
                }
            }
        }
        
        var text:String
        
        if (indexPath.section == 0) {
            cell.tag = 256
            cell.checked = self.isFirstSecionExpanded
            text = "Message To Send"
        }
        else {
            assert(indexPath.section == 1)
            cell.tag = 1024
            cell.checked = self.isLastSectionExpanded
            text = "Twitter Users"
        }
        cell.lblTitle.text = NSLocalizedString(text, comment: " ")
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        collectionView.deselectItemAtIndexPath(indexPath, animated: false)
        
        
        if (indexPath.section != 0) {
            
            if let cell = collectionView.cellForItemAtIndexPath(indexPath) as? TwitterSendCollectionViewCell {
                cell.checked = !cell.checked
                
                if cell.checked {
                    countSendItems++
                    checkedRows.insert(indexPath.row)
                }
                else {
                    countSendItems--
                    checkedRows.remove(indexPath.row)
                }
                
                correctTitleOfNavigationItemOnNeed()
            }
        }
    }
    
    @IBAction func tapGestureRecogniser(recogniser:UITapGestureRecognizer!) {
    
        if let cell = recogniser.view as? UICollectionReusableView {
            
            
            var section:Int
            
            if cell.tag == 1024 {
                //the last section...
                self.isLastSectionExpanded = !self.isLastSectionExpanded
                section = 1
            } else   {
                assert(cell.tag == 256)
                //the first section....
                self.isFirstSecionExpanded = !self.isFirstSecionExpanded
                section = 0
            }
            
            self.collectionView.reloadSections(NSIndexSet(index: section))
        }
    }    
}


//MARK: Sending,Success, Fail Methods 
extension TwitterFriendsSendViewController {
    
    func needToSendRow(index:Int) -> Bool {
        return  !(self.sendingSet.contains(index) ||
                  self.successSet.contains(index) ||
                  self.failedSet.contains(index))
    }
    
    func isOK(index:Int) -> Bool {
        return self.successSet.contains(index)
    }
    
    func isSending(index:Int) -> Bool {
        return self.sendingSet.contains(index)
    }
    
    func hasFailed(index:Int) -> Bool {
        return self.failedSet.contains(index)
    }
    
    func markAsFailed(index:Int) {
        self.failedSet.insert(index)
    }
    
    func markAsSent(index:Int) {
        self.successSet.insert(index)
    }
    
    func markAsSending(index:Int) {
        self.sendingSet.insert(index)
    }
    
}

//TODO: Store checked items into context on going back step....

//MARK : Navigation Item Methods

extension TwitterFriendsSendViewController {
    
    private struct BarButtonItemConstants {
        static let Send = NSLocalizedString("Send", comment: "Send")
        static let Cancel = NSLocalizedString("Cancel", comment: "Cancel")
    }
    
    func refreshItemPressed(sender:UIBarButtonItem) {
        
        navigationItemPressed(sender)
    }
    
    func navigationActionForRefresh() {
        
        let count = self.checkedRows.count
        
        self.sendMessageError = nil
        
        for selectedRow in self.checkedRows {
            
            let indexPath = NSIndexPath(forRow: selectedRow, inSection: 1)
            
            
            if let twUser =  getTwitterUser(indexPath) {
                
                self.sendingSet.insert(selectedRow)
                
                self.twitterManager.sendMessageToUser(twUser.userId!, text: self.messageToSend) {
                    (messageId,error) in
                    
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        [weak self] in
                        
                        let row = indexPath.row
                        
                        self?.sendingSet.remove(row)
                        
                        if messageId != nil {
                            self?.checkedRows.remove(row)
                            self?.successSet.insert(row)
                        }
                        else if error != nil {
                            self?.failedSet.insert(row)
                            self?.sendMessageError = error
                        }
                        else {
                            assert(false)
                        }
                        
                        
                        
                        guard self != nil else {
                            return
                        }
                        
                        let failedCount  = self!.failedSet.count
                        let successCount = self!.successSet.count
                        
                        if (count == failedCount + successCount)
                        {
                            self?.collectionView.performBatchUpdates({ () -> Void in
                                self?.collectionView.reloadItemsAtIndexPaths([indexPath])
                                }, completion: { (finished) -> Void in
                                    
                                    self?.navigationItem.rightBarButtonItem?.enabled = true
                                    self?.hideProgress()
                                    
                                    var message = NSLocalizedString("Number of sent messages", comment: "Number of sent messages") + " \(successCount)"
                                    
                                    guard failedCount == 0 && self?.sendMessageError == nil  else {
                                        
                                        let eMessage = self!.sendMessageError!
                                        
                                        print("Error \(eMessage)")
                                        message += "\n" + eMessage.description
                                        self?.alertWithTitle(NSLocalizedString("Error", comment: "Error"), message: message)
                                        self?.createRetryNavigationItem()
                                        
                                        //TODO: grant write permissions to the app...
                                        
                                        
                                        return
                                    }
                                    
                                    
                                    self?.alertWithTitle(NSLocalizedString("Information",comment: "Information"), message: message)
                                    
                                    
                            })
                        }
                        else {
                            self?.collectionView.reloadItemsAtIndexPaths([indexPath])
                        }
                    }
                }
            }
        }
        
        self.displayProgress()
        self.navigationItem.rightBarButtonItem?.enabled = false
        //sender.title = BarButtonItemConstants.Cancel
    }
    
    @IBAction func navigationItemPressed(sender:UIBarButtonItem) {
        
        if sender.title == Optional(BarButtonItemConstants.Send) || sender.action == "refreshItemPressed:" {
            
            
            /*Twitter.sharedInstance().logInWithCompletion {[weak self]  (session, error) in
                if (session != nil) {
                    self?.navigationActionForRefresh()
                } else if let errorInner = error {
                    print("error: \(errorInner.localizedDescription)");
                }
            }*/
            self.navigationActionForRefresh()
        }
        else if sender.title == Optional(BarButtonItemConstants.Cancel) {
            
            self.hideProgress()
            sender.title = BarButtonItemConstants.Send
        }
    }
    
    func correctTitleOfNavigationItemOnNeed() {
        if let rButton = self.navigationItem.rightBarButtonItem {
            rButton.enabled = self.countSendItems != 0
        }
    }
    
    func createRetryNavigationItem() {
        
         if let rButton = self.navigationItem.rightBarButtonItem {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Refresh, target: rButton.target, action: "refreshItemPressed:")
        }
    }
}
