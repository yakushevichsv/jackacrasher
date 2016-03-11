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
2) Go to the next screen...
3) Save relationships into DB ....
4) Next screen with sending information...
6) Correct Progress HD indicator...

*/

class TwitterFriendsViewController: ProgressHDViewController {
    
    @IBOutlet weak var collectionView:UICollectionView!
    @IBOutlet weak var nextBtn:UIButton!
    @IBOutlet weak var nextButtonLeftLayout:NSLayoutConstraint!
    private var leftSpace:CGFloat = 0.0
    
    private var twitterManager:TwitterManager!
    private var sectionChanges:[[NSFetchedResultsChangeType:Int]]! = nil
    private var itemChanges:[[NSFetchedResultsChangeType:[NSIndexPath]]]! = nil
    private var controller:NSFetchedResultsController!
    
    private var animateOnce:Bool = false
    
    var twitterId:String! {
        didSet {
            fetchOnNeed()
            if !(twitterId == nil || twitterId.isEmpty) {
                
                self.performSelectorInBackground("setupTM", withObject: nil)
            }
        }
    }
    
    private func fetchOnNeed(){
        if !(twitterId == nil || twitterId.isEmpty) {
            
            //self.performSelectorInBackground("setupTM", withObject: nil)
            
            if (self.isViewLoaded()){
                performFetch()
            }
            //self.performSelectorInBackground("performFetch", withObject: nil)
        }
    }
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.leftSpace = self.nextButtonLeftLayout.constant
        
        print("viewDidLoad")
        
        fetchOnNeed()
        
        initRefresh()
        
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if (!animateOnce) {
            animateOnce = true
            
            //self.collectionView.contentInset = UIEdgeInsetsMake(self.heightOfPullToRefreshControl(), 0, 0, 0)
            
            self.collectionView.setContentOffset(CGPointZero, animated: animated)
            
            DBManager.sharedInstance.managedObjectContext.performBlock{
                
                
                var totalCount = DBManager.sharedInstance.totalCountOfTwitterUsers()
                
                if (totalCount == 0) {
                    dispatch_async(dispatch_get_main_queue()) {
                        [weak self] in
                        self?.displayProgress(true)
                    }
                }
                else {
                    totalCount = DBManager.sharedInstance.countSelectedItems()
                }
                
                dispatch_async(dispatch_get_main_queue()) {
                    [weak self] in
                    
                    self?.moveInOutNextButton(totalCount != 0, animated: false)
                }
                print("Total count of items in the context \(totalCount)")
            }
            
        }
        
        let count = self.collectionView.numberOfSections()
        if (count != 0) {
            defineStateOfRightBarItem(self.collectionView.numberOfItemsInSection(count-1))
        }
        
        //self.collectionView.performSelector("reloadData", withObject: nil, afterDelay: 7.0)
    }
    
    func performFetch() {
        guard self.controller == nil else {
            return
        }
        
        print("%@",__FUNCTION__)
        assert(NSThread.isMainThread())
        
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
        
        print("\(self.controller)",__FUNCTION__)
    }
    
    private func appendRightBarItem() -> Bool {
        
        if self.navigationItem.rightBarButtonItem != nil {
            print("No need to append Right Bar")
            self.navigationItem.rightBarButtonItem!.enabled = true
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
        
        self.stopListeningTMNotifications()
        self.twitterManager?.cancelAllTwitterRequests()
        DBManager.sharedInstance.disposeUIContext()
        
        self.collectionView.unload()
        
        self.controller = nil
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
        
        //dispatch_async(dispatch_get_main_queue()){
        
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
                    case .Update:
                        self.collectionView.reloadSections(NSIndexSet(index: sectionIndex))
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
            var moveArray = [[NSIndexPath]]()
            
            for itemChange in items {
                
                for (type,indexPaths) in itemChange {
                    
                    switch type {
                    case NSFetchedResultsChangeType.Insert:
                        
                        insertArray.append(indexPaths.last!)
                        break
                    case NSFetchedResultsChangeType.Update:
                        
                        //if self.collectionView.indexPathsForVisibleItems().contains(indexPath) {
                        
                        reloadArray.append(indexPaths.first!)
                        
                        if indexPaths.last != indexPaths.first {
                            print("Last \(indexPaths.last) \nFirst \(indexPaths.first)")
                            reloadArray.append(indexPaths.last!)
                        }
                        //}
                        break
                    case NSFetchedResultsChangeType.Delete:
                        
                        deleteArray.append(indexPaths.last!)
                        break
                    case NSFetchedResultsChangeType.Move:
                        //assert(false)
                        moveArray.append(indexPaths)
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
            
            if (!moveArray.isEmpty) {
                for pairs in moveArray {
                    let oldIndex = pairs.first
                    let newIndex = pairs.last
                    
                    self.collectionView.moveItemAtIndexPath(oldIndex!,toIndexPath: newIndex!)
                    
                    
                }
            }
            
            
            
            print("Insert \(insertArray.count) \nDelete \(deleteArray.count) \nUpdate \(reloadArray.count) \nMove \(moveArray.count)")
            
            //count = reloadArray.count + insertArray.count - deleteArray.count
            
            }, completion: {[weak self]  (finished) -> Void in
                self?.sectionChanges = nil
                self?.itemChanges = nil
                
                self?.checkTMState(self?.twitterManager)
                
                if let count = self?.collectionView.numberOfSections() {
                    if (count != 0) {
                        if let count2 = self?.collectionView.numberOfItemsInSection(count-1) {
                            self?.defineStateOfRightBarItem(count2)
                        }
                    }
                    
                    
                    
                    if (count != 0) {
                        self?.hideProgress()
                    }
                }
            })
        //}
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        let dic = [type:sectionIndex]
        self.sectionChanges.append(dic)
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        var indexes = [NSIndexPath]()
        if newIndexPath != nil {
            indexes.append(newIndexPath!)
        }
        
        if indexPath != nil {
            indexes.append(indexPath!)
        }
        
        let dic = [type:indexes]
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
        
        /*if !((newIndexPath == nil && indexPath != nil) ||
        (newIndexPath != nil && indexPath == nil) ||
        (newIndexPath == indexPath)) {
        print("New Index \(newIndexPath) Old Index \(indexPath)")
        assert(false)
        }*/
        
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
        
        assert(!(twitterUser.objectID.temporaryID /*|| twitterUser.fault*/))
        
        if let imageData = twitterUser.miniImage {
            cell.setProfileImage(imaage: UIImage(data: imageData))
        }
        else if twitterUser.profileImageMiniURL == nil {
            cell.setProfileImage(imaage: nil)
        }
        
        if (self.twitterManager.isCancelled) {
            cell.stopActivityIndicator()
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
        
        
        /*if let cell = collectionView.cellForItemAtIndexPath(indexPath) as? TwitterFriendCollectionViewCell {
        cell.markAsSelected(selected)
        }*/
        
        let context = DBManager.sharedInstance.managedObjectContext
        context.performBlock {
            [weak self] in
            
            do {
                
                let rUser = try context.existingObjectWithID(twitterUser.objectID) as! TwitterUser
                
                rUser.selected = selected
                
                if context.hasChanges {
                    
                    try context.save()
                }
                
                let condition = selected || DBManager.sharedInstance.countSelectedItems() != 0
                
                dispatch_async(dispatch_get_main_queue()) {
                    [weak self] in
                    self?.moveInOutNextButton(condition, animated: true)
                }
                
            }
                
            catch let error as NSError  {
                print("Erorr select \(error)")
            }
        }
        
        
        
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
            
            DBManager.sharedInstance.getSelectedItemsCount({  (count, error) -> Void in
                
                dispatch_async(dispatch_get_main_queue()) {
                    [weak self] in
                    
                    self?.appendRightBarItem()
                    
                    if count == countExternal {
                        self?.unSelectAllTitle()
                    }
                    else {
                        self?.selectAllTitle()
                    }
                }
            })
            
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

//MARK: Refresh Control
extension TwitterFriendsViewController/*: UIScrollViewDelegate*/ {
    
    func beginRefreshing() {
        self.refreshAction()
    }
    
    func initRefresh() {
        if (!self.collectionView.refreshing) {
            self.collectionView.initRefresh()
        }
    }
    
    func refreshAction() {
        if (self.twitterManager == nil) {
            self.setupTM()
        }
        
        if let result = self.twitterManager?.startUpdatingTotalList() {
            if !result {
                
                self.checkTMState(self.twitterManager)
                
                let errorInfo = self.twitterManager.isError()
                
                dispatch_async(dispatch_get_main_queue()){
                    [weak self] in
                    if (errorInfo.result && errorInfo.error != nil) {
                        self?.alertWithTitle(NSLocalizedString("Error",comment:""),message: !errorInfo.error!.userInfo.isEmpty ? errorInfo.error!.localizedDescription : errorInfo.error!.description)
                    }
                    else if let limitRate = self?.twitterManager.isLimitRate() {
                        if (limitRate){
                            self?.alertWithTitle(NSLocalizedString("Error", comment: "Error"), message: NSLocalizedString("Twitter API Rate Limit",comment:""))
                        }
                    }
                }
            }
        }
    }
    
    func finishRefresh() {
        self.collectionView.endRefreshing()
    }
    
    /*func scrollViewDidScroll(scrollView: UIScrollView) {
        
        if (scrollView.contentOffset.y <= 0) {
            let x = scrollView.contentOffset.x + CGRectGetWidth(scrollView.frame) * 0.5
            
            if let view = self.collectionView.refreshActivityIndicator {
                view.center = CGPoint(x: x ,y: view.center.y)
            }
            
            if let view = self.collectionView.arrowImageView {
                view.center = CGPoint(x: x ,y: view.center.y)
            }
            
            if let view = self.collectionView.pullLabel {
                view.center = CGPoint(x: x ,y: view.center.y)
            }
            
            self.collectionView.pullLabel?.layoutIfNeeded()
        }
    }*/
}

//MARK: Twitter's Manager methods
extension TwitterFriendsViewController {
    
    private func startListeningTMNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didChangeTMState:", name: TwitterManagerStateNotification, object: self.twitterManager)
    }
    
    private func stopListeningTMNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: TwitterManagerStateNotification, object: self.twitterManager)
    }
    
    func setupTM() {
        
        if (self.twitterManager != nil) {
            return
        }
        
        self.twitterManager = TwitterManager(twitterId: self.twitterId)
        
        startListeningTMNotifications()
    }
    
    func didChangeTMState(aNotification:NSNotification) {
        
        let manager = aNotification.object as! TwitterManager
        
        checkTMState(manager)
    }
    
    private func checkTMState(manager:TwitterManager?) {
        guard let manager = manager else {
            return
        }
        
        switch (manager.managerState) {
        case .DownloadingTwitterIdsError(_, _): fallthrough
        case .DownloadingTwitterIdsRateLimit(_, _): fallthrough
        case .DownloadingTwitterUsersRateLimit(_,_): fallthrough
        case .DownloadingTwitterUsersError(_): fallthrough
        case .DownloadingFinished(_): fallthrough
        case .DonwloadingTwitterUsersCancelled(_):
            
            dispatch_async(dispatch_get_main_queue()) {
                [weak self] in
                //print("RELOAD RELOAT")
                self?.finishRefresh()
                self?.collectionView.reloadData()
                //try! self?.controller.performFetch()
                
            }
            break
        default:
            break
        }
    }
}
