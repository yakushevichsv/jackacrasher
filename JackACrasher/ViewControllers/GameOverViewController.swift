//
//  GameOverViewController.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 5/9/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit
import SpriteKit

class GameOverViewController: UIViewController, GameOverSceneDelegate {

    @IBOutlet weak var containerView:UIView!
    @IBOutlet weak var btnReplay:UIButton!
    @IBOutlet weak var btnMainMenu:UIButton!
    
    var didWin:Bool = false {
        didSet {
            if let scene  = self.skView?.scene as? GameOverScene {
                scene.didWin = didWin
            }
        }
    }
    
    private var skView:SKView! {
        get { return self.view as! SKView}
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /*#if DEBUG
            let manager = DBManager.sharedInstance
            print("Manager \(manager)")
            
        #endif*/
        
        self.containerView.hidden = true
        
        if let scene = GameOverScene.unarchiveFromFile("GameOverScene") as? GameOverScene {
            
            skView.showsFPS = false
            skView.showsNodeCount = false
            /* Sprite Kit applies additional optimizations to improve rendering performance */
            skView.ignoresSiblingOrder = false
            
            /* Set the scale mode to scale to fit the window */
            scene.scaleMode = .AspectFill
            scene.gameOverDelegate = self
            scene.userInteractionEnabled = false
            self.skView.presentScene(scene)
            
            self.containerView.superview?.bringSubviewToFront(self.containerView)
            
            self.btnMainMenu.superview?.bringSubviewToFront(self.btnMainMenu)
            
            self.btnReplay.superview?.bringSubviewToFront(self.btnReplay)
        }
        
        if UIApplication.sharedApplication().isRussian {
            self.correctFontOfChildViews(self.view,reduction:10)
        }
        else {
            self.correctFontOfChildViews(self.view)
        }
    }
    
    
    internal func displayGameOverContainerView(scenePosition:CGPoint) {
        
        let dScale = self.traitCollection.displayScale
        let sceneY = CGFloat(ceil(scenePosition.y / dScale))
        let xPos = CGRectGetWidth(self.view.bounds) * 0.5 //CGFloat(ceil(scenePosition.x / dScale))
        _ = CGRectGetHeight(self.view.bounds) - sceneY
        
        self.containerView.hidden = false;
        self.containerView.center = CGPointMake(xPos, self.containerView.center.y /*yPos*/)
    }
    
    func gameOverScene(scene:GameOverScene, didDisplayLabelWithFrame frame:CGRect)
    {
        let xMid = CGRectGetMidX(frame)
        let yMid = CGRectGetMidY(frame)
        
        displayGameOverContainerView(CGPointMake(xMid, yMid))
    }
    
    
    @IBAction func btnPressed(sender: UIButton) {
        if (sender == self.btnMainMenu){
          //TODO: write here logic for selecting what to replay
            
            self.navigationController?.popToRootViewControllerAnimated(false)
            if let vc = self.navigationController?.topViewController as? GameMainViewController {
                vc.needToDisplayAnimation = true
            }
        }
        else if (sender == self.btnReplay) {
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if (segue.identifier == Optional<String>("inviteFriendsSegue"))
        {
            //TODO: detect allowance to use different social functions....
            
            let dVC = segue.destinationViewController
            
            if let popVC = dVC.popoverPresentationController {
                popVC.delegate = self
                popVC.permittedArrowDirections = .Any
                var prefHeight = popVC.preferredContentSize.height;
                if let uiSender = sender as? UIButton {
                    if uiSender == popVC.sourceView {
                        popVC.sourceRect = uiSender.frame
                    }
                }
                prefHeight = 200;
                
                dVC.preferredContentSize = CGSizeMake(min(300,popVC.preferredContentSize.width),prefHeight)
            }
        }
    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if (identifier == "inviteFriendsSegue") {
            
            return InviteFriendsViewController.canInviteFriends()
        }
        else {
            return super.shouldPerformSegueWithIdentifier(identifier, sender: sender)
        }
    }
}


//MARK: Pop over for invite friends...
extension GameOverViewController:UIPopoverPresentationControllerDelegate
{
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return .None
    }
}
