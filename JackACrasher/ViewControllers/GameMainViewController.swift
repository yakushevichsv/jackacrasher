//
//  GameMainViewController.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 5/10/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit
import GameKit
import Social
import FBSDKShareKit
import iAd

class GameMainViewController: UIViewController {

    internal var needToDisplayAnimation:Bool = false
    private let gcManager = GameCenterManager.sharedInstance
    private let ckManager = CloudManager.sharedInstance
    
    private var needToAuthGC:Bool = true
    private var vkToken:VKAccessToken? = nil
    
    private var interstitial:ADInterstitialAd!
    private static let simulateDisableAdv:Bool = false
    private weak var adContainerView:UIView! = nil
    //private weak var activityIndicatorView:UIActivityIndicatorView! = nil
    private weak var btnClose:UIButton! = nil
    private var timeInterval:NSTimeInterval = NSDate.timeIntervalSinceReferenceDate()
    
    private var startLayer:JCStartLayer? = nil
    private var displStartLayerAnim = false
    
    @IBOutlet weak var btnStrategy:UIButton!
    @IBOutlet weak var btnHelp:UIButton!
    @IBOutlet weak var btnShop:UIButton!
    @IBOutlet weak var btnRUpCorner:UIButton!
    @IBOutlet weak var btnSound:UIButton!
    @IBOutlet weak var btnFB:UIButton!
    @IBOutlet weak var btnTwitter:UIButton!
    @IBOutlet weak var btnGameCenter:UIButton!
    @IBOutlet weak var btnVK:UIButton!
    
    @IBOutlet weak var twConstraint:NSLayoutConstraint!
    @IBOutlet weak var gcConstraint:NSLayoutConstraint!
    @IBOutlet weak var vkConstraint:NSLayoutConstraint!
    @IBOutlet weak var lAsterCenterX:NSLayoutConstraint!
    @IBOutlet weak var rAsterCenterX:NSLayoutConstraint!
    @IBOutlet weak var fbConstraint:NSLayoutConstraint!
    
    @IBOutlet weak var ivAsteroidL:UIImageView!
    @IBOutlet weak var ivAsteroidR:UIImageView!
    @IBOutlet weak var ivBlackHole:UIImageView!
    @IBOutlet weak var ivExplosion:UIImageView!
    
    weak var btnRSoundCornerYConstraitnt:NSLayoutConstraint!
    
    private lazy var transitionDelegate:PopUpTransitioningDelegate = PopUpTransitioningDelegate()
    
    private func shiftOutButtons() {
        shiftXButton(self.btnShop, isLeft: false)
        shiftXButton(self.btnStrategy, isLeft: false)
        self.btnHelp.transform = CGAffineTransformMakeScale(1.2, 1.2)
    }
    
    private func shiftInButtons() {
        shiftXButton(self.btnShop, isLeft: true)
        shiftXButton(self.btnStrategy, isLeft: true)
        self.btnHelp.transform = CGAffineTransformIdentity
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
        for btn in [self.btnStrategy,self.btnHelp,self.btnShop] {
            btn.enabled = enabled
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initVK()
        
        authDidChange(nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "authDidChange:", name: GKPlayerAuthenticationDidChangeNotificationName, object: nil)
        
        self.performActionOnRMainButton(nil,animated:false)
        
        let btn = self.btnGameCenter
        btn.layer.cornerRadius = 3;//half of the width
        btn.layer.borderColor = UIColor.blackColor().CGColor//[UIColor blackColor].CGColor;
        btn.layer.borderWidth = 1.0
    
        var images:[UIImage] = []
        
        let blackHoleAtas = SKTextureAtlas(named: "blackhole")
        for i in 0...4 {
            print("Textures: \(blackHoleAtas.textureNames)")
            let texture = blackHoleAtas.textureNamed(String(format: "BlackHole%d", i))
            let image = UIImage(CGImage: texture.CGImage())
            images.append(image)
        }
        let animImage = UIImage.animatedImageWithImages(images, duration: 0.4)
        self.ivBlackHole.image = animImage;
        self.ivBlackHole.startAnimating()
        
        var images2:[UIImage] = []
        let spriteAtlas = SKTextureAtlas(named: "sprites")
        for i in 1...3 {
            let texture = spriteAtlas.textureNamed(String(format: "explosion%04d", i))
            let image = UIImage(CGImage: texture.CGImage())
            images2.append(image)
        }
        let animImage2 = UIImage.animatedImageWithImages(images2, duration: 0.4)
        self.ivExplosion.image = animImage2
        
        let image = UIImage(CGImage: spriteAtlas.textureNamed("asteroid-large").CGImage())
        self.ivAsteroidL.image = image
        self.ivAsteroidR.image = image
        
        self.ivAsteroidL.hidden = true
        self.ivAsteroidR.hidden = true
        
        let scale = Int(self.traitCollection.displayScale != 0 ? self.traitCollection.displayScale : UIScreen.mainScreen().scale)
        
        let template = scale == 1 ? "" : "@\(scale)x"
        
        var name = "VKSdkResources.bundle"
        name = name.stringByAppendingPathComponent("ic_vk_activity_logo")
        name = name.stringByAppendingString("\(template).png")
        
        self.btnVK.setImage(UIImage(named:name), forState: .Normal)
        
        processAdv()
        
        correctFontOfChildViews(self.view,reduction: UIApplication.sharedApplication().isRussian ? 5 : 0)
        
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
        self.view.layoutIfNeeded()
        
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
            self.view.layoutIfNeeded()
            
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
    
    func correctSoundButton() {
        
        let disabled = GameLogicManager.sharedInstance.gameSoundDisabled()
        
        self.btnSound.selected = !disabled
        self.btnPressed(self.btnSound)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "correctSoundButton", name: SYGameLogicManagerSoundNotification, object: GameLogicManager.sharedInstance)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "willMoveToFG:", name: UIApplicationWillEnterForegroundNotification, object: nil)
        
        correctSoundButton()
        
        if (!self.needToDisplayAnimation) {
            self.scheduleAnimation()
            self.needToDisplayAnimation = true
        } else if self.btnStrategy.enabled {
            shakeStrategyBtn()
        }
        
        foreverAsterAnim()
        
        displayCloudKitAuthStatus()
        
        performStartLayerAnimation()
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.hideAsters()
        
    
        NSNotificationCenter.defaultCenter().removeObserver(self, name: SYGameLogicManagerSoundNotification, object: GameLogicManager.sharedInstance)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillEnterForegroundNotification, object: nil)
    }
    
    func willMoveToFG(aNotification:NSNotification) {
        if self.btnStrategy.enabled {
            shakeStrategyBtn()
        }
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
        
        let alertVC = UIAlertController(title: NSLocalizedString("CKDisabledTitle", comment:""), message: NSLocalizedString("CKDisabledMessage", comment:""), preferredStyle: .Alert)
        
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
        
        needToDisplayGC(NSLocalizedString("GCDisabledTitle", comment:"Game Center is disabled"), message:NSLocalizedString("GCDisabledMessage", comment: "To participate in Leaderboard\nPlease enable it"))
    }
    
    func needToAuthPlayerToGC() {
        needToDisplayGC(NSLocalizedString("Attention", comment:"Attention"), message:NSLocalizedString("Attention", comment:"EnableGC") )
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
                    self.shakeStrategyBtn()
                    self.enableButtons()
                }
                else {
                    didAnimated = true
                }
        })
    }
    
    private func shakeStrategyBtn() {
        
        if self.view.gestureRecognizers == nil || self.view.gestureRecognizers!.isEmpty {
            let recog = UITapGestureRecognizer(target: self, action: "handlePress:")
            self.view.addGestureRecognizer(recog)
        }
        
        if CGAffineTransformEqualToTransform(self.btnStrategy.transform, CGAffineTransformIdentity) {
            self.btnStrategy.transform = CGAffineTransformMakeRotation(-π/90)
            self.btnStrategy.userInteractionEnabled = false
        }
        
        UIView.animateWithDuration(0.25, delay: 0.0, options: UIViewAnimationOptions(rawValue: UIViewAnimationOptions.Repeat.rawValue | UIViewAnimationOptions.Autoreverse.rawValue), animations: {
            [unowned self]
            () -> Void in
                self.btnStrategy.clipsToBounds = true
                self.btnStrategy.transform = CGAffineTransformMakeRotation(π/90)
            }) {
                [unowned self]
                (finisehd) in
                self.btnStrategy.clipsToBounds = false
                self.btnStrategy.transform = CGAffineTransformIdentity
                self.btnStrategy.userInteractionEnabled = true
        }
    }
    
    func handlePress(recognizer:UITapGestureRecognizer) {
        
        if (recognizer.state == UIGestureRecognizerState.Ended) {
            
            let count = recognizer.numberOfTouches()
            
            for index  in 0...count-1 {
               let location = recognizer.locationOfTouch(index, inView: self.view)
                
                if (CGRectContainsPoint(self.btnStrategy.frame, location)) {
                    
                    btnPressed(self.btnStrategy)
                    
                    self.view.removeGestureRecognizer(recognizer)
                    
                    break
                }
            }
            
        }
    }
    
    //MARK: eee  Why it is not called?
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        
        if let identifier = segue.identifier {
            if (identifier == "startSurvival") {
                cancelAdvActions()
                GameLogicManager.sharedInstance.selectSurvival()
                SoundManager.sharedInstance.cancelPlayingEffect(nil)
            } else if (identifier == "displayShop") {
                ///TODO: prepare before displaying...
                cancelAdvActions()
                let dVC = segue.destinationViewController as! ShopDetailsViewController
                
                
                if let productsArray = PurchaseManager.sharedInstance.validProducstsArray {
                    dVC.products = productsArray
                }
                
                dVC.modalPresentationStyle = UIModalPresentationStyle.Custom
                
                
                let isPortrait = CGRectGetHeight(self.view.frame) > CGRectGetWidth(self.view.frame)
                
                self.transitionDelegate.isPortrait = isPortrait
                self.transitionDelegate.rect = self.view.frame
                self.transitionDelegate.backgroundColor = UIColor.lightGrayColor()
                self.transitionDelegate.backgroundAlpha = 1.0
                
                dVC.transitioningDelegate = self.transitionDelegate
            } else if (identifier == "help") {
                cancelAdvActions()
                let start:Int32 = 1
                let end :Int32 = 6
                
                var images = [UIImage]()
                
                for index in start...end {
                    let name = "help-page00\(index).png".syLocalizedString
                    let image = UIImage(named: name)
                    images.append(image!)
                }
                
                assert(images.count == Int(end - start + 1))
                let dVC = segue.destinationViewController as! HelpViewController
                
                dVC.pageImages = images
                let p1 = NSLocalizedString("HelpPage1", comment: "Player can't move\n Attack trash asteroids")
                
                let p2 = NSLocalizedString("HelpPage2", comment: "Player can't move\n Destroy trash - asteroids")
                
                let p3 = NSLocalizedString("HelpPage3", comment:"When there is a bomb\n Destroy it,being under the transmitter\n")
                
                let p4 = NSLocalizedString("HelpPage4", comment:"When there is a bomb\n  Wait specified time interval to destroy it automatically")
                
                let p5 = NSLocalizedString("HelpPage5", comment:"")
                
                let p6 = NSLocalizedString("HelpPage6", comment:"")
                
                dVC.pageDescriptions = [p1,p2,p3,p4,p5,p6]
            }
        }
    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        
        if !identifier.isEmpty {
            
            var adPresent:Bool
            
            if let value = interstitial?.actionInProgress {
                adPresent = value
            }
            else {
                adPresent = false
            }
            
            
            if (identifier == "displayShop") {
                
                let canPurchase = PurchaseManager.canPurchase()
                let validated = PurchaseManager.sharedInstance.hasValidated
            
                return canPurchase && validated && !adPresent
            }
            else if (identifier == "startSurvival" || identifier == "help") {
                
                return !adPresent
            }
        }
        return super.shouldPerformSegueWithIdentifier(identifier, sender: sender)
    }
    
    
    func displayAlertAboutImpossiblePayments() ->Bool {
        
        let canPurhase = PurchaseManager.canPurchase()
        let isValid = PurchaseManager.sharedInstance.hasValidated
        
        var title:String!
        var message:String!
        
        if (!canPurhase) {
            title = NSLocalizedString("EnableIAPTitle", comment:"Please enable In-App-Purchases")
            message = NSLocalizedString("EnableIAP", comment: "For purchasing things please enable IAP")
        } else if (!isValid) {
            title = NSLocalizedString("Error", comment: "Error")
            message = NSLocalizedString("NoITunesStore", comment: "Couldn't access iTunes Store")
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
            
            self.btnSound.center = CGPoint(x: self.btnSound.center.x, y: self.btnRUpCorner.center.y)
            self.btnSound.hidden = false
            
            self.fbConstraint.constant = 0
            self.btnFB.alpha  = 0.0
            self.btnFB.hidden = false
            self.btnFB.layoutIfNeeded()
                
            self.btnTwitter.hidden = true
            self.btnGameCenter.hidden = true
            
            sender!.superview?.bringSubviewToFront(sender!)
            print("Original center \(self.btnSound.center)")
            
            UIView.animateWithDuration(animated ? 0.5 : 0.0, animations: { [unowned self]
                () -> Void in
                
                self.btnSound.center = CGPoint(x: self.btnSound.center.x, y: self.btnSound.center.y + yMargin)
                
                self.fbConstraint.constant = -30
                self.btnFB.alpha = 1.0
                self.btnFB.layoutIfNeeded()
                
                print("Final 1 center \(self.btnSound.center)")
                
                }){
                    [unowned self]
                    finished in
                    
                    self.btnSound.superview?.bringSubviewToFront(self.btnSound)
                    
                    let attr = NSLayoutConstraint(item: self.btnSound, attribute: .CenterY, relatedBy: .Equal, toItem: self.btnRUpCorner, attribute: .CenterY, multiplier: 1, constant: yMargin)
                    self.btnRSoundCornerYConstraitnt = attr
                    
                    
                    NSLayoutConstraint.activateConstraints([attr])
                    
                    print("Final 2 center \(self.btnSound.center)")
                    
                    //self.btnTwitter.center = self.btnFB.center
                    print("BTN Twitter center x  \(self.btnTwitter.center.x)")
                    
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
                            
                        self.vkConstraint.constant = -CGRectGetMidX(self.btnTwitter.bounds)
                        self.btnVK.layoutIfNeeded()
                        self.btnVK.alpha = 0.0
                        self.btnVK.hidden = false
                        
                            UIView.animateWithDuration(animated && finished ? 0.2 : 0.0, animations:{  [unowned self]
                                () -> Void in
                                
                                self.vkConstraint.constant = 22
                                self.btnVK.layoutIfNeeded()
                                self.btnVK.alpha = 1.0
                                
                                }) {
                                    finished in
                            
                                    
                            }
                            
                    }
            }
        }
        else {
            
            self.btnVK.alpha = 1.0
            self.btnVK.layoutIfNeeded()
            
            self.btnTwitter.superview?.bringSubviewToFront(self.btnTwitter)
            
            UIView.animateWithDuration(animated ? 0.5 : 0.0, animations: {[unowned self]
                () -> Void in
                
                self.vkConstraint.constant = -CGRectGetMidX(self.btnTwitter.bounds)
                self.btnVK.alpha = 0.0
                self.btnVK.layoutIfNeeded()
                
                }) {
                    [unowned self]
                    finished in
             
                    print("Original center \(self.btnSound.center)")
                    self.btnFB.superview?.bringSubviewToFront(self.btnFB)
                    self.btnTwitter.alpha = 1.0
                    self.btnTwitter.layoutIfNeeded()
                    
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
                                print("Final 1 center \(self.btnSound.center)")
                                
                                self.btnFB.center = CGPoint(x:self.btnRUpCorner.center.x,y:self.btnFB.center.y)
                                
                                }){
                                    [unowned self]
                                    finished in
                                    self.btnRUpCorner.superview?.bringSubviewToFront(self.btnRUpCorner)
                                    self.btnSound.hidden = true
                                    self.btnFB.hidden = true
                                    
                                    let constraint = self.btnRSoundCornerYConstraitnt
                                    if constraint != nil {
                                        NSLayoutConstraint.deactivateConstraints([constraint])
                                        self.btnRSoundCornerYConstraitnt = nil
                                    }
                                    
                                    self.fbConstraint.constant = 0
                                    self.btnFB.alpha  = 0.0
                                    self.btnFB.layoutIfNeeded()
                                    
                                    print("Final 2 center \(self.btnSound.center)")
                            }
                    }
            }
        }
    }
    
    //MARK: IBActions
    
    @IBAction func unwindSegue(segue:UIStoryboardSegue) {
       
        if segue.identifier == Optional("selectActionUnwind") {
            
            self.needToDisplayAnimation = false
        }
        
        correctSoundButton()
        
        unwindForAd()
        
        
        if self.btnStrategy.enabled {
            self.shakeStrategyBtn()
        }
        
    }
    
    @IBAction  func btnPressed(sender: UIButton) {
        if sender == self.btnStrategy {

            SoundManager.sharedInstance.playPreloadedSoundEffect(completionHandler: { (_, _) -> Void in
                self.performSegueWithIdentifier("startSurvival", sender: self)
                sender.enabled = true
            })
            sender.userInteractionEnabled = true
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
                SoundManager.sharedInstance.prepareToPlayEffect("button_press.wav")
            }
            
            GameLogicManager.sharedInstance.storeGameSoundInfo(disabled)
        }
        else if (sender == self.btnHelp) {
            SoundManager.sharedInstance.playPreloadedSoundEffect(completionHandler: { [unowned self ] (_, _) -> Void in
                self.performSegueWithIdentifier("help", sender: sender)
            })
        }
    }
    
    @IBAction func sharingPressed(sender:UIButton) {
        
        if sender == self.btnFB {
            //Share to FB.....
            shareOnFB()
        } else if sender == self.btnTwitter{
            //Share to Twitter
            shareOnTweeter()
        } else if sender == self.btnVK {
            shareOnVK()
        }
    }
    
    @IBAction func btnRightUpCornerPressed(sender:UIButton) {
        
        sender.selected = sender.selected ? false : true
        
        performActionOnRMainButton(sender)
    }
    
    
    //MARK: Twitter's methos
    private func shareOnTweeter() {
        
        if !SLComposeViewController.isAvailableForServiceType(SLServiceTypeTwitter) {
            
            self.alertWithTitle(NSLocalizedString("Sorry",comment:"Sorry"), message: NSLocalizedString("SorryTwitter", comment: "You can\'t send a tweet right now,\n make sure your device has an internet connection and you have\n at least one Twitter account setup"), actionTitle: NSLocalizedString("OK",comment:"OK"), completion: nil)
            return
        }
        
        let tweetSheet = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
        tweetSheet.setInitialText( NSLocalizedString("LogoText",comment:"I am playing on JackACrasher!"))
        tweetSheet.addImage(UIImage(named: "enemyShip"))
        tweetSheet.addURL(NSURL(string: "https://developers.facebook.com"))
        
        tweetSheet.completionHandler = {
            (result) in
            
            if result == SLComposeViewControllerResult.Cancelled {
                print("Tweet composition cancelled")
            }
            else {
                print("Sending tweet!")
                self.alertWithTitle(NSLocalizedString("Success",comment:"Success"), message: NSLocalizedString("ThanksTweeting",comment:"Thanks for tweeting!"), actionTitle: nil)
            }
        }
        
        self.presentViewController(tweetSheet, animated: true, completion: nil)
    }
    

    //MARK: FB's methods
    
    private func shareOnFB() {
        
        let content = FBSDKShareLinkContent()
        content.contentTitle = NSLocalizedString("LogoText",comment:"I am playing on JackACrasher!")
        content.contentURL = NSURL(string: "https://developers.facebook.com")
        content.contentDescription = NSLocalizedString("FBDecsr", comment:  "Have fun!. Help Jack to crash as much as you can!")
        
        
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
}

//MARK: FBSDKSharingDelegate's methods
extension GameMainViewController: FBSDKSharingDelegate {
    
    //MARK: FBSDKSharingDelegate's methods
    
    func sharer(sharer: FBSDKSharing!, didFailWithError error: NSError!) {
        
        if error != nil {
            self.alertWithTitle(NSLocalizedString("Error",comment:""), message: NSLocalizedString("ErrorTimeLine",comment:""), actionTitle: NSLocalizedString("OK",comment:""))
        }
    }
    
    func sharer(sharer: FBSDKSharing!, didCompleteWithResults results: [NSObject : AnyObject]!) {
        if (!results.isEmpty){
            self.alertWithTitle(NSLocalizedString("Success", comment: "Success"), message:  NSLocalizedString("ThanksPosting",comment:"Thanks for posting"), actionTitle: nil)
        }
        else {
            sharerDidCancel(sharer)
        }
    }
    
    func sharerDidCancel(sharer: FBSDKSharing!){}
}

//MARK: VK delegate's methods
extension GameMainViewController:VKSdkDelegate {
    
    //MARK:VK's methods
    
    private func initVK() {
        
        VKSdk.initializeWithDelegate(self, andAppId: VKAppID)
        
        if (VKSdk.wakeUpSession())
        {
            // start working.... - go to sharing..
            self.vkToken =  VKSdk.getAccessToken()
        }
    }
    
    private func shareOnVK() {
        
        if self.btnVK.selected {
            return
        }
        
        self.btnVK.selected = true
        
        if self.vkToken != nil {
            
            let shareDialog = VKShareDialogController()
            shareDialog.text = NSLocalizedString("LogoText", comment: "I am playing in JackACrasher!")
            
            /*shareDialog.shareLink    = [[VKShareLink alloc] initWithTitle:@"Super puper link, but nobody knows" link:[NSURL URLWithString:@"https://vk.com/dev/ios_sdk"]];*/
            
            shareDialog.completionHandler = {
                [unowned self]
                result  in
                self.dismissViewControllerAnimated(true) {
                    [unowned self] in
                    self.btnVK.selected = false
                    
                    if result == .Done {
                        let str = NSLocalizedString("Success", comment: "Success")
                        let str2 = NSLocalizedString("ThanksVK", comment: "Thanks for posting on VK!")
                        self.alertWithTitle(str, message: str2, actionTitle: nil)
                    }
                }
            }
            
            self.presentViewController(shareDialog, animated: true, completion: nil)
            
        }
        else {
            authorize();
        }
    }
    
    private func authorize() {
        VKSdk.authorize([VK_PER_WALL,VK_PER_OFFLINE,VK_PER_STATUS], revokeAccess: true, forceOAuth: true, inApp: true, display: VK_DISPLAY_IOS)
    }
    
    func vkSdkAcceptedUserToken(token: VKAccessToken!) {
        processToken(token)
    }
    
    func vkSdkReceivedNewToken(newToken: VKAccessToken!) {
        processToken(newToken)
    }
    
    private func processToken(token:VKAccessToken!) {
        self.vkToken = token
        
        if self.btnVK.selected && self.presentedViewController == nil {
            self.btnVK.selected = false
            shareOnVK()
        }
    }
    
    func vkSdkNeedCaptchaEnter(captchaError: VKError!) {
        
        let vc = VKCaptchaViewController.captchaControllerWithError(captchaError)
        vc.presentIn(self.navigationController?.topViewController)
    }
    
    func vkSdkTokenHasExpired(expiredToken: VKAccessToken!) {
        if (self.vkToken == expiredToken) {
            self.vkToken = nil
        }
        self.btnVK.selected = false
    }
    
    func vkSdkUserDeniedAccess(authorizationError: VKError!) {
        if self.btnVK.selected && authorizationError.errorCode != Int(VK_API_CANCELED) {
            let aDenied = NSLocalizedString("aDenied", comment: "Access denied")
            let ok = NSLocalizedString("OK", comment: "OK")
            self.alertWithTitle(aDenied, message: authorizationError.description, actionTitle: ok) {
                [unowned self ] in
                self.navigationController?.popToRootViewControllerAnimated(true)
            }
        }
        self.vkToken = nil
    }
    
    func vkSdkShouldPresentViewController(controller: UIViewController!) {
        self.navigationController?.topViewController?.presentViewController(controller, animated: true, completion: nil)
    }
}

//MARK:Interstitial Management
extension GameMainViewController : ADInterstitialAdDelegate {
    
    
    //MARK: Adv methods
    private func cycleInterstitial() {
        
        interstitial?.cancelAction()
        interstitial?.delegate = nil
        interstitial = nil
        
        if isDisabledAdv(){
            return
        }
        
        let ad = ADInterstitialAd()
        ad.delegate = self
        interstitial = ad
        self.interstitialPresentationPolicy = .Manual
        //UIViewController.prepareInterstitialAds()
    }
    
    
    private func processAdv() {
        
        if GameMainViewController.simulateDisableAdv  {
            GameLogicManager.sharedInstance.disableAdv()
        }
        
        if !GameLogicManager.sharedInstance.isAdvDisabled {
            cycleInterstitial()
        }
        
    }
    
    private func unwindForAd() {
        
        if (!GameLogicManager.sharedInstance.isAdvDisabled) {
            
            isDisabledAdv()
            //activityIndicatorView?.stopAnimating()
            adContainerView?.hidden = true
            btnClose?.hidden = true
            
            let interval = NSDate.timeIntervalSinceReferenceDate() - self.timeInterval
            let present = self.presentInterlude() //60 minutes * 60 seconds...
            
            if !(interval < 3600 || present || self.interstitial?.actionInProgress == Optional<Bool>(true)) {
                cycleInterstitial()
            }
        }
    }
    
    private func isDisabledAdv() -> Bool {
        
        if GameLogicManager.sharedInstance.isAdvDisabled{
            self.adContainerView?.removeFromSuperview()
            self.btnClose?.removeFromSuperview()
            return true
        }
        return false
    }
    
    private func createAdContainer() {
        if (self.adContainerView == nil) {
            
            let containerView = UIView(frame: self.view.bounds)
            containerView.frame.origin = CGPointZero
            containerView.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(containerView)
            self.adContainerView = containerView
            
            
            let constLeft = NSLayoutConstraint(item: containerView, attribute: .Left, relatedBy: .Equal, toItem: self.view, attribute: .Left, multiplier: 1.0, constant: 0)
            
            let constRight = NSLayoutConstraint(item: containerView, attribute: .Right, relatedBy: .Equal, toItem: self.view, attribute: .Right, multiplier: 1.0, constant: 0)
            
            let constTop = NSLayoutConstraint(item: containerView, attribute: .Top, relatedBy: .Equal, toItem: self.view, attribute: .Top, multiplier: 1.0, constant: 0)
            
            let constBottom = NSLayoutConstraint(item: containerView, attribute: .Bottom, relatedBy: .Equal, toItem: self.view, attribute: .Bottom, multiplier: 1.0, constant: 0)
            
            self.view.addConstraints([constLeft,constRight,constTop,constBottom])
            
        }
    }
    
    private func presentInterlude() -> Bool {
        var result = false
        if self.interstitial != nil  && self.interstitial!.loaded {
            if !GameLogicManager.sharedInstance.isAdvDisabled{
                createAdContainer()
                if let resultNew = interstitial?.presentInView(self.adContainerView) {
                    result = resultNew
                    
                    if result && self.view.window != nil {
                        //didMoveToBGPrivate()
                        self.timeInterval = NSDate.timeIntervalSinceReferenceDate()
                        if self.btnClose == nil {
                            
                            let btn = UIButton()
                            btn.setImage(UIImage(named: "close"), forState: .Normal)
                            btn.addTarget(self, action: "closePressed:", forControlEvents: UIControlEvents.TouchUpInside)
                            let btnCenter = CGPointMake(CGRectGetWidth(self.view.bounds) * 0.9, CGRectGetHeight(self.view.bounds)*0.1)
                            btn.center = btnCenter
                            btn.bounds = CGRectMake(0, 0, btn.imageForState(.Normal)!.size.width, btn.imageForState(.Normal)!.size.height)
                            self.view.insertSubview(btn, belowSubview: self.adContainerView)
                            
                            self.adContainerView.hidden = false
                            
                            self.view.addSubview(btn)
                            self.view.bringSubviewToFront(btn)
                            self.btnClose = btn
                        }
                        //activityIndicatorView?.stopAnimating()
                    }
                }
            }
        }
        return result
    }
    
    func closePressed(sender:UIButton!) {
        sender?.removeFromSuperview()
        interstitial?.cancelAction()
        interstitialAdActionDidFinish(interstitial)
        adContainerView?.hidden = true
        //self.activityIndicatorView?.stopAnimating()
    }
    
    //MARK: ADInterstitialAdDelegate
    
    func interstitialAd(interstitialAd: ADInterstitialAd!, didFailWithError error: NSError!) {
        print("Error interstitialAd \(error)")
        let domainFault = error.domain == ADErrorDomain
        let codeFault = error.code == ADError.InventoryUnavailable.rawValue
        
        //activityIndicatorView?.stopAnimating()
        btnClose?.hidden = true
        
        if !(domainFault && codeFault) {
            cycleInterstitial()
        }
        
        //self.willMoveToFGPrivate()
    }
    
    func interstitialAdActionShouldBegin(interstitialAd: ADInterstitialAd!, willLeaveApplication willLeave: Bool) -> Bool {
        if !willLeave {
            adContainerView.hidden = true
            self.btnClose.hidden = true
        }
        return true
    }
    
    func interstitialAdDidUnload(interstitialAd: ADInterstitialAd!) {
        
        cycleInterstitial()
        
        //self.willMoveToFGPrivate()
    }
    
    func interstitialAdDidLoad(interstitialAd: ADInterstitialAd!) {
        print("Did load interstitialAdDidLoad")
        
        if interstitialAd.loaded && self.startLayerWasDisplayed {
            presentInterlude()
        }
    }
    
    override var shouldPresentInterstitialAd:Bool {
        get { return !GameLogicManager.sharedInstance.isAdvDisabled}
    }
    
    func interstitialAdActionDidFinish(interstitialAd: ADInterstitialAd!) {
        //self.willMoveToFGPrivate()
        adContainerView?.hidden = true
        
        self.btnClose?.removeFromSuperview()
    }
    
    func cancelAdvActions() {
        self.interstitial?.cancelAction()
        interstitialAdActionDidFinish(self.interstitial)
        interstitial = nil
    }
}

//MARK: CA Start Layer methods
extension GameMainViewController {
    
    private var startLayerWasDisplayed:Bool {
        get {
            return self.displStartLayerAnim && self.startLayer == nil
        }
    }
    
    private func imageFromLaunchScreenOrSelf(useSelfView:Bool = false) -> UIImage? {
        
        let scale = UIScreen.mainScreen().scale
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, true, scale)
        if UIGraphicsGetCurrentContext() == nil  {
            return nil
        }
        
        if (useSelfView) {
            if (!self.view.drawViewHierarchyInRect(self.view.bounds, afterScreenUpdates: false)){
                view.layoutIfNeeded();
                view.layer.renderInContext(UIGraphicsGetCurrentContext()!)
            }
        }
        else {
            let array = NSBundle.mainBundle().loadNibNamed("LaunchScreen", owner: self, options: nil)
            if let retView = array.last as? UIView {
                
                retView.frame = self.view.frame;
                
                retView.layoutIfNeeded();
                retView.layer.renderInContext(UIGraphicsGetCurrentContext()!)
                
            }
            else {
                UIGraphicsEndImageContext()
                return nil
            }
        }
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    private func performStartLayerAnimation() {
        
        if (!self.displStartLayerAnim)
        {
            
            let rect = self.ivBlackHole.frame
            
            self.startLayer = JCStartLayer(midRect:rect)
            //self.startLayer?.fillColor = self.view.layer.backgroundColor
            self.startLayer?.frame = self.view.layer.bounds
            self.startLayer?.contents = imageFromLaunchScreenOrSelf(false)?.CGImage
            
            print("Mid rect \(rect)\n Frame \(self.startLayer!.frame)")
            
            self.view.layer.addSublayer(self.startLayer!)
            
            self.startLayer?.animate(){
                [unowned self] in
                self.removeStartLayer()
            }
            
            self.displStartLayerAnim = true
        }
    }
    
    func removeStartLayer() {
        self.startLayer?.removeAllAnimations()
        self.startLayer?.removeFromSuperlayer()
        self.startLayer = nil
     
        if self.interstitial?.loaded == true {
            self.presentInterlude()
        }
    }
}
