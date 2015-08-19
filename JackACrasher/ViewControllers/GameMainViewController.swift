//
//  GameMainViewController.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 5/10/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit
import GameKit
import FBSDKShareKit
import TwitterKit

class GameMainViewController: UIViewController,FBSDKSharingDelegate {

    internal var needToDisplayAnimation:Bool = false
    private let gcManager = GameCenterManager.sharedInstance
    private let ckManager = CloudManager.sharedInstance
    
    private var needToAuthGC:Bool = true
    
    @IBOutlet weak var btnCompany:UIButton!
    @IBOutlet weak var btnStrategy:UIButton!
    @IBOutlet weak var btnHelp:UIButton!
    @IBOutlet weak var btnShop:UIButton!
    @IBOutlet weak var btnRUpCorner:UIButton!
    @IBOutlet weak var btnSound:UIButton!
    @IBOutlet weak var btnFB:UIButton!
    @IBOutlet weak var btnTwitter:UIButton!
    @IBOutlet weak var btnGameCenter:UIButton!
    
    @IBOutlet weak var twConstraint:NSLayoutConstraint!
    @IBOutlet weak var gcConstraint:NSLayoutConstraint!
    
    @IBOutlet weak var ivAsteroidL:UIImageView!
    @IBOutlet weak var ivAsteroidR:UIImageView!
    @IBOutlet weak var ivBlackHole:UIImageView!
    @IBOutlet weak var ivExplosion:UIImageView!
    @IBOutlet weak var lAsterCenterX:NSLayoutConstraint!
    @IBOutlet weak var rAsterCenterX:NSLayoutConstraint!
    
    
    weak var btnRSoundCornerYConstraitnt:NSLayoutConstraint!
    weak var btnFBXSpaceConstraint:NSLayoutConstraint!
    
    private lazy var transitionDelegate:PopUpTransitioningDelegate = PopUpTransitioningDelegate()
    
    private func shiftOutButtons() {
        
        shiftXButton(self.btnCompany, isLeft: true)
        shiftXButton(self.btnStrategy, isLeft: false)
        shiftYButton(self.btnHelp, isUp: false)
    }
    
    private func shiftInButtons() {
        
        shiftXButton(self.btnCompany, isLeft: false)
        shiftXButton(self.btnStrategy, isLeft: true)
        shiftYButton(self.btnHelp, isUp: true)
    }
    
    private func shiftXButton(button:UIButton!, isLeft:Bool) {
        
        button.frame = CGRectOffset(button.frame, (isLeft ? -1 : 1 ) *  CGRectGetWidth(button.frame), 0)
    }
    
    private func shiftYButton(button:UIButton!, isUp:Bool) {
        
        button.frame = CGRectOffset(button.frame, 0, (isUp ? 1 : -1) * CGRectGetHeight(button.frame) )
    }
    
    private func disableButtons() {
        setButtonsState(false)
    }
    
    private func enableButtons() {
        setButtonsState(true)
    }
    
    private func setButtonsState(enabled:Bool) {
        for btn in [self.btnCompany,self.btnStrategy,self.btnHelp,self.btnShop] {
            btn.enabled = enabled
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        SoundManager.sharedInstance.prepareToPlayEffect("button_press.wav")
        authDidChange(nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "authDidChange:", name: GKPlayerAuthenticationDidChangeNotificationName, object: nil)
        
        let disabled = GameLogicManager.sharedInstance.gameSoundDisabled()
        
        self.btnSound.selected = !disabled
        self.btnPressed(self.btnSound)
        
        self.performActionOnRMainButton(nil,animated:false)
        
        let btn = self.btnGameCenter
        btn.layer.cornerRadius = 3;//half of the width
        btn.layer.borderColor = UIColor.blackColor().CGColor//[UIColor blackColor].CGColor;
        btn.layer.borderWidth = 1.0
    
        let images = UIImage.spritesWithContentsOfAtlas("blackhole", sequence: "BlackHole%01d.png", start: 0, end: 4) as! [UIImage]
        let animImage = UIImage.animatedImageWithImages(images, duration: 0.4)
        self.ivBlackHole.image = animImage;
        self.ivBlackHole.startAnimating()
        
        
        
        let images2 = UIImage.spritesWithContentsOfAtlas("sprites", sequence: "explosion%04d.png", start: 1, end: 3) as! [UIImage]
        let animImage2 = UIImage.animatedImageWithImages(images2, duration: 0.4)
        self.ivExplosion.image = animImage2
        
        let image = UIImage.spriteWithContentsOfAtlas("sprites", name: "asteroid-large.png")
        self.ivAsteroidL.image = image
        self.ivAsteroidR.image = image
        
        self.ivAsteroidL.hidden = true
        self.ivAsteroidR.hidden = true
    }
    
    private func hideAsters() {
    
        self.ivAsteroidL.hidden = true
        self.lAsterCenterX.constant = -CGRectGetMidX(self.view.bounds)
        self.ivAsteroidL.layoutIfNeeded()
        
        self.ivAsteroidR.hidden = true
        self.rAsterCenterX.constant = CGRectGetMidX(self.view.bounds)
        self.ivAsteroidR.layoutIfNeeded()
        
        if self.ivExplosion.isAnimating() {
            self.ivExplosion.stopAnimating()
        }
        self.ivExplosion.hidden = true
        
    }
    
    private func foreverAsterAnim() {
        
        if !(self.ivAsteroidL.hidden &&
            self.ivAsteroidR.hidden) {
            return
        }
        
        self.hideAsters()
        
        self.ivAsteroidL.hidden = false
        self.ivAsteroidR.hidden = false
        
        
        UIImageView.animateWithDuration(2, animations: {[unowned self] () -> Void  in
            
            self.lAsterCenterX.constant = -CGRectGetMidX(self.ivAsteroidL.bounds) * 0.8
            self.ivAsteroidL.layoutIfNeeded()
            
            self.rAsterCenterX.constant = CGRectGetMidX(self.ivAsteroidR.bounds) * 0.8
            self.ivAsteroidR.layoutIfNeeded()
            self.ivAsteroidR.transform = CGAffineTransformMakeRotation(CGFloat(Double(rand() % 7 + 1) *  M_PI_4));
            self.ivAsteroidL.transform = CGAffineTransformMakeRotation(CGFloat(Double(rand() % 7 + 1) *  M_PI_4));
            
            }){[unowned self]
                _ in
                //if finished {
                    self.ivExplosion.hidden = false
                    self.ivExplosion.startAnimating()
                    self.ivAsteroidL.hidden = true
                    self.ivAsteroidR.hidden = true
                    
                    let delayTime = dispatch_time(DISPATCH_TIME_NOW,
                        Int64(0.4 * Double(NSEC_PER_SEC)))
                    
                    dispatch_after(delayTime, dispatch_get_main_queue()){
                        [unowned self] in
                        self.ivExplosion.stopAnimating()
                        self.foreverAsterAnim()
                    }
                //}
                //else {
                  //  self.hideAsters()
                //}
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if (!self.needToDisplayAnimation) {
            self.scheduleAnimation()
            self.needToDisplayAnimation = true
        }
        
        foreverAsterAnim()
        
        displayCloudKitAuthStatus()
    }

    override func viewWillDisappear(animated: Bool) {
        viewWillDisappear(animated)
        self.hideAsters()
    }

    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    private func displayOnNeedGameKitAuthStatus() -> Bool {
        if (!self.gcManager.isLocalUserAuthentificated) {
            
            if let error = self.gcManager.lastError {
                
                if error.domain == GKErrorDomain  && error.code == GKErrorCode.UserDenied.rawValue {
                    needToEnableGC()
                    return true
                }
            }
            needToAuthPlayerToGC()
            return true
        }
        return false
    }
    
    private func displayCloudKitAuthStatus() {
        
        if (!self.ckManager.simulateAlertAboutPermissionGrant()) {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "needToEnableCloudKit", name: SYLoggingToCloudNotification, object: self.ckManager)
        }
        else {
            //needToEnableCloudKit()
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self,name:SYLoggingToCloudNotification, object:self.ckManager)
    }
    
    //MARK: Authefication's related methods
    func authDidChange(notification:NSNotification!) {
        self.needToAuthGC = !self.gcManager.isLocalUserAuthentificated
    }
    
    func needToEnableCloudKit() {
        
        let alertVC = UIAlertController(title: "iCloud is disabled", message: "Please log in to iCloud or create account for keeping purchases' information", preferredStyle: .Alert)
        
        self.presentViewController(alertVC, animated: true, completion: nil)
        
        let delayTime = dispatch_time(DISPATCH_TIME_NOW,
            Int64(3 * Double(NSEC_PER_SEC)))
        
        dispatch_after(delayTime, dispatch_get_main_queue(), { () -> Void in
            alertVC.dismissViewControllerAnimated(true, completion: nil)
        })
    }
    
    func needToDisplayGC(title:String,message:String) {
        
        if self.gcManager.isLocalUserAuthentificated {
            return
        }
        else if (self.needToAuthGC){
            self.needToAuthGC = false
            let alertVC = UIAlertController(title: title, message: message, preferredStyle: .Alert)
            self.btnGameCenter.enabled = false
            self.presentViewController(alertVC, animated: true, completion: nil)
            
            let delayTime = dispatch_time(DISPATCH_TIME_NOW,
                Int64(3 * Double(NSEC_PER_SEC)))
            
            dispatch_after(delayTime, dispatch_get_main_queue(), { () -> Void in
                alertVC.dismissViewControllerAnimated(true) {
                    [unowned self] in
                    self.btnGameCenter.enabled = true
                    self.needToAuthGC = true
                }
            })
        }
    }
    
    func needToEnableGC() {
        
        needToDisplayGC("Game Center is disabled", message: "To participate in Leaderboard\nPlease enable it")
    }
    
    func needToAuthPlayerToGC() {
        needToDisplayGC("Attention", message: "Please enable Game Center!")
    }
    
    //MARK: -
    private func scheduleAnimation() {
        
        shiftOutButtons()
        disableButtons()
        var didLoadAssets:Bool = false
        var didAnimated:Bool = false
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), { () -> Void in
           GameScene.loadAssets()
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if (didAnimated) {
                    self.enableButtons()
                }
                else {
                    didLoadAssets = true
                }
            });
        });
        
        UIView.animateWithDuration(2, delay: 0.0, usingSpringWithDamping: 0.7, initialSpringVelocity: 8, options: .CurveEaseOut, animations: { () -> Void  in
                self.shiftInButtons()
            }, completion: { (finished) -> Void in
                if (didLoadAssets) {
                    self.enableButtons()
                }
                else {
                    didAnimated = true
                }
        })
    }
    
    //MARK: eee  Why it is not called?
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        
        if let identifier = segue.identifier {
            if (identifier == "startSurvival") {
                GameLogicManager.sharedInstance.selectSurvival()
                SoundManager.sharedInstance.cancelPlayingEffect(nil)
            } else if (identifier == "displayShop") {
                ///TODO: prepare before displaying...
                let dVC = segue.destinationViewController as! ShopDetailsViewController
                
                
                if let productsArray = PurchaseManager.sharedInstance.validProducstsArray {
                    dVC.products = productsArray
                }
                
                dVC.modalPresentationStyle = UIModalPresentationStyle.Custom
                
                
                let isPortrait = CGRectGetHeight(self.view.frame) > CGRectGetWidth(self.view.frame)
                
                self.transitionDelegate.isPortrait = isPortrait
                self.transitionDelegate.rect = self.view.frame
                
                dVC.transitioningDelegate = self.transitionDelegate
            }
        }
    }
    
    override func shouldPerformSegueWithIdentifier(identifierObj: String?, sender: AnyObject?) -> Bool {
        
        if let identifier = identifierObj {
            if (identifier == "displayShop") {
                
                return PurchaseManager.canPurchase() && PurchaseManager.sharedInstance.hasValidated
            }
        }
        return super.shouldPerformSegueWithIdentifier(identifierObj, sender: sender)
    }
    
    
    func displayAlertAboutImpossiblePayments() ->Bool {
        
        let canPurhase = PurchaseManager.canPurchase()
        let isValid = PurchaseManager.sharedInstance.hasValidated
        
        var title:String!
        var message:String!
        
        if (!canPurhase) {
            title = "Please enable In-App-Purchases"
            message = "For purchasing things please enable IAP"
        } else if (!isValid) {
            title = "Error"
            message = "Couldn't access iTunes Store"
        }
        else {
            return false
        }
        

        let alert = UIAlertController(title: title , message: message, preferredStyle: .Alert)
        
        let okAction = UIAlertAction(title: "OK", style: .Default) { (_) -> Void in
            
            alert.dismissViewControllerAnimated(false, completion: nil)
        }
        
        alert.addAction(okAction)
        
        self.presentViewController(alert, animated: true, completion: nil)
        
        return true
    }
    
    private func performActionOnRMainButton(sender:UIButton?,animated:Bool = true) {
        if sender?.selected == Optional<Bool>.Some(true) {
            //TODO: Animate button appearance
            
            //TODO: put into Constants section...
            let yMargin:CGFloat = 40
            let fbXSpce:CGFloat = 50
            
            let origin = sender!.frame.origin
            let oFrame = CGRect(origin:origin,size:self.btnSound.bounds.size)
    
            self.btnSound.center = CGPoint(x: self.btnSound.center.x, y: self.btnRUpCorner.center.y)
            self.btnSound.hidden = false
            
            self.btnFB.center = CGPointMake(self.btnRUpCorner.center.x, self.btnFB.center.y)
            self.btnFB.hidden = false
            
            self.btnTwitter.hidden = true
            self.btnGameCenter.hidden = true
            
            sender!.superview?.bringSubviewToFront(sender!)
            println("Original center \(self.btnSound.center)")
            
            UIView.animateWithDuration(animated ? 0.5 : 0.0, animations: { [unowned self]
                () -> Void in
                
                self.btnSound.center = CGPoint(x: self.btnSound.center.x, y: self.btnSound.center.y + yMargin)
                
                self.btnFB.frame = CGRectOffset(self.btnFB.frame, -fbXSpce, 0)
                
                println("Final 1 center \(self.btnSound.center)")
                
                }){
                    [unowned self]
                    finished in
                    
                    self.btnSound.superview?.bringSubviewToFront(self.btnSound)
                    
                    let attr = NSLayoutConstraint(item: self.btnSound, attribute: .CenterY, relatedBy: .Equal, toItem: self.btnRUpCorner, attribute: .CenterY, multiplier: 1, constant: yMargin)
                    self.btnRSoundCornerYConstraitnt = attr
                    
                    let xDiff = CGRectGetMaxX(self.btnFB.frame) - CGRectGetMinX(self.btnRUpCorner.frame)
                    
                    let attr2 = NSLayoutConstraint(item: self.btnFB, attribute: .Trailing, relatedBy: .Equal, toItem: self.btnRUpCorner, attribute: .Leading, multiplier: 1, constant: xDiff)
                    self.btnFBXSpaceConstraint = attr2
                    
                    NSLayoutConstraint.activateConstraints([attr,attr2])
                    
                    println("Final 2 center \(self.btnSound.center)")
                    
                    //self.btnTwitter.center = self.btnFB.center
                    println("BTN Twitter center x  \(self.btnTwitter.center.x)")
                    
                    self.twConstraint.constant = -CGRectGetMidX(self.btnFB.bounds)
                    self.btnTwitter.layoutIfNeeded()
                    self.btnTwitter.alpha = 0.0
                    self.btnTwitter.hidden = false
                    
                    
                    self.gcConstraint.constant = -CGRectGetMidY(self.btnSound.bounds)
                    self.btnGameCenter.layoutIfNeeded()
                    self.btnGameCenter.alpha = 0.0
                    self.btnGameCenter.hidden = false
                    
                    self.btnFB.superview?.bringSubviewToFront(self.btnFB)
                    self.btnSound.superview?.bringSubviewToFront(self.btnSound)
                    
                    UIView.animateWithDuration(animated && finished ? 0.2 : 0.0, animations: {  [unowned self]
                        () -> Void in
                        
                        self.twConstraint.constant = 25
                        self.btnTwitter.alpha = 1.0
                        self.btnTwitter.layoutIfNeeded()
                        
                        self.gcConstraint.constant = 20
                        self.btnGameCenter.alpha = 1.0
                        self.btnGameCenter.layoutIfNeeded()
                        
                        }) {
                        [unowned self]
                        finished in
                    }
            }
        }
        else {
            
            println("Original center \(self.btnSound.center)")
            self.btnFB.superview?.bringSubviewToFront(self.btnFB)
            self.btnTwitter.alpha = 1.0
            self.btnTwitter.layoutIfNeeded()
            
            self.btnCompany.superview?.bringSubviewToFront(self.btnCompany)
            self.btnGameCenter.alpha = 1.0
            self.btnGameCenter.layoutIfNeeded()
            
            UIView.animateWithDuration(animated ? 0.5 : 0.0, animations: {[unowned self]
                () -> Void in
                
                    self.twConstraint.constant = -CGRectGetMidX(self.btnFB.bounds)
                    self.btnTwitter.alpha = 0.0
                    self.btnTwitter.layoutIfNeeded()
                
                    self.gcConstraint.constant = -CGRectGetMidY(self.btnSound.bounds)
                    self.btnGameCenter.alpha = 0.0
                    self.btnGameCenter.layoutIfNeeded()
                
                }){
                    [unowned self]
                    finished in
                    
                    self.btnTwitter.hidden = true
                    self.btnGameCenter.hidden = true
                    
                    UIView.animateWithDuration(animated && finished ? 0.25 : 0.0, animations: {[unowned self]
                        () -> Void in
                        
                        self.btnSound.center = CGPoint(x: self.btnSound.center.x, y: self.btnRUpCorner.center.y)
                        println("Final 1 center \(self.btnSound.center)")
                        
                        self.btnFB.center = CGPoint(x:self.btnRUpCorner.center.x,y:self.btnFB.center.y)
                        
                        }){
                            [unowned self]
                            finished in
                            self.btnRUpCorner.superview?.bringSubviewToFront(self.btnRUpCorner)
                            self.btnSound.hidden = true
                            self.btnFB.hidden = true
                            
                            var constraint = self.btnRSoundCornerYConstraitnt
                            if constraint != nil {
                                NSLayoutConstraint.deactivateConstraints([constraint])
                                self.btnRSoundCornerYConstraitnt = nil
                            }
                            
                            constraint = self.btnFBXSpaceConstraint
                            if constraint != nil {
                                NSLayoutConstraint.deactivateConstraints([constraint])
                                self.btnFBXSpaceConstraint = nil
                            }
                            
                            println("Final 2 center \(self.btnSound.center)")
                    }
                }
            
        }
    }
    
    //MARK: IBActions
    
    @IBAction func unwindSegue(segue:UIStoryboardSegue) {
       
        if segue.identifier == Optional("selectAction") {
            
            self.needToDisplayAnimation = false
        }
        
    }
    
    @IBAction  func btnPressed(sender: UIButton) {
        if sender == self.btnStrategy {
            SoundManager.sharedInstance.playPreloadedSoundEffect(completionHandler: { (_, _) -> Void in
                self.performSegueWithIdentifier("startSurvival", sender: self)
                sender.enabled = true
            })
        } else if (sender == self.btnGameCenter) {
            
            if !self.displayOnNeedGameKitAuthStatus() {
                SoundManager.sharedInstance.playPreloadedSoundEffect(completionHandler: { (url, successfully) -> Void in
                    GameCenterManager.sharedInstance.showGKGameCenterViewController(self)
                })
            }
        } else if (sender == self.btnShop) {
            SoundManager.sharedInstance.playPreloadedSoundEffect(completionHandler: { (_, _) -> Void in
                
                self.displayAlertAboutImpossiblePayments()
                
            })
        } else if (sender == self.btnSound) {
            sender.selected = sender.selected ? false : true
            
            let disabled = sender.selected
            
            //selected = no sound 
            if disabled {
                SoundManager.sharedInstance.disableSound()
            } else {
                SoundManager.sharedInstance.enableSound()
            }
            
            GameLogicManager.sharedInstance.storeGameSoundInfo(disabled)
        }
    }
    
    @IBAction func sharingPressed(sender:UIButton) {
        
        if sender == self.btnFB {
            //Share to FB.....
            shareOnFB()
        } else if sender == self.btnTwitter{
            //Share to Twitter
            shareOnTweeter()
        }
        
    }
    
    @IBAction func btnRightUpCornerPressed(sender:UIButton) {
        
        sender.selected = sender.selected ? false : true
        
        performActionOnRMainButton(sender)
    }
    
    //MARK: Twitter's methos
    private func shareOnTweeter() {
        
        Twitter.sharedInstance().logInWithCompletion() {[unowned self]
            session, error in
            if (session != nil) {
                if self.view.window != nil {
                    let composer = TWTRComposer()
                    
                    composer.setText("I am playing on JackACrasher!")
                    composer.setImage(UIImage(named: "player"))
                    composer.setURL(NSURL(string: "https://developers.facebook.com"))
                    // Called from a UIViewController
                    composer.showFromViewController(self) { result in
                        if (result == TWTRComposerResult.Cancelled) {
                            println("Tweet composition cancelled")
                        }
                        else {
                            println("Sending tweet!")
                            self.alertWithTitle("Success", message: "Thanks for tweeting!", actionTitle: nil)
                        }
                    }
                }
                // make API calls that do not require user auth
            } else {
                println("error: \(error.localizedDescription)");
            }
        }
    }
    

    //MARK: FB's methods
    
    private func shareOnFB() {
        
        let content = FBSDKShareLinkContent()
        content.contentTitle = "I am playing on JackACrasher!"
        content.contentURL = NSURL(string: "https://developers.facebook.com")
        content.contentDescription = "Have fun!. Help Jack to crash as much as you can!"
        
        
        content.imageURL = NSURL(string:"http://www.nasa.gov/sites/default/files/images/685735main_pia15678-43_full.jpg")
        let dialog = FBSDKShareDialog() //.showFromViewController(self, withContent: content, delegate: self)
        dialog.fromViewController = self
        dialog.delegate = self
        dialog.shareContent = content
        
        var mode = FBSDKShareDialogMode.Native
        dialog.mode = mode
        
        var count = UInt(0)
        while(!dialog.canShow() && mode != .Automatic)  {
                if let res = FBSDKShareDialogMode(rawValue: FBSDKShareDialogMode.FeedWeb.rawValue - count) {
                    mode = res
                }
                else {
                    mode = .Automatic
                }
                
                count += 1
                dialog.mode = mode
        }
        
        dialog.show()
        
    }
    
    //MARK: FBSDKSharingDelegate's methods 
    
    func sharer(sharer: FBSDKSharing!, didFailWithError error: NSError!) {
        
        if error != nil {
            self.alertWithTitle("Error", message: "Error posting on the timeline.\n Please try again latter", actionTitle: "OK")
        }
    }
    
    func sharer(sharer: FBSDKSharing!, didCompleteWithResults results: [NSObject : AnyObject]!) {
        if (!results.isEmpty){
            self.alertWithTitle("Success", message: "Thanks for posting", actionTitle: nil)
        }
        else {
            sharerDidCancel(sharer)
        }
    }
    
    func sharerDidCancel(sharer: FBSDKSharing!){}
    
}
