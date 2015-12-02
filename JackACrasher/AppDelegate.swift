//
//  AppDelegate.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 4/9/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import Fabric
import Crashlytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        Fabric.with([Crashlytics.self])
        
        if let localNotification = launchOptions?[UIApplicationLaunchOptionsLocalNotificationKey] as? UILocalNotification {
            // ...do stuff...
            localNotification.applicationIconBadgeNumber = 0
        }
        else {
            
            let types = application.currentUserNotificationSettings()!.types
            
            if (types == UIUserNotificationType.None)
            {
                application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: UIUserNotificationType(rawValue: UIUserNotificationType.Alert.rawValue | UIUserNotificationType.Sound.rawValue | UIUserNotificationType.Badge.rawValue),categories:nil))
            }
        }
        
        //Fabric.with([Twitter()])
        
        appWillStart()
        
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        return true
    }
    private func appWillStart() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), { () -> Void in
            PurchaseManager.sharedInstance.prepare()
            GameLogicManager.sharedInstance.performPurchasesRestorationOnNeed()
        })
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), { () -> Void in
            CloudManager.sharedInstance.prepare()
        })
    }
    
    func applicationWillTerminate(application: UIApplication) {
        
        let types = application.currentUserNotificationSettings()!.types.rawValue
        
        if (types == UIUserNotificationType.None.rawValue) {
            return
        }
        
        if (!application.scheduledLocalNotifications!.isEmpty) {
            for anyNotification in  application.scheduledLocalNotifications! {
                let aNotification = anyNotification 
                application.cancelLocalNotification(aNotification);
            }
        }
        
        
        if (application.scheduledLocalNotifications!.isEmpty) {
            
            let localNotification = UILocalNotification()
            
            if (types & UIUserNotificationType.Sound.rawValue != 0) {
                localNotification.soundName = UILocalNotificationDefaultSoundName
            }
            
            if (types & UIUserNotificationType.Alert.rawValue != 0) {
                localNotification.alertAction = "Start crashing".syLocalizedString
                localNotification.alertBody   = "Let's crash something!".syLocalizedString
                localNotification.alertTitle  = "You didn't play for a while!".syLocalizedString
            }
            
            localNotification.timeZone = NSTimeZone.localTimeZone()
            localNotification.repeatCalendar = NSCalendar.currentCalendar()
            localNotification.repeatInterval = NSCalendarUnit.Weekday
            
            let fireInterval:NSTimeInterval = 1*24*60*60
            localNotification.fireDate = NSDate(timeIntervalSinceNow:fireInterval)
            
            
            application.scheduleLocalNotification(localNotification)
        }
    }
    
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        
        notification.applicationIconBadgeNumber  = 0
        
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        
        return  VKSdk.processOpenURL(url, fromApplication: sourceApplication) ||
            FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
    func application(application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: () -> Void) {
        
        NetworkManager.sharedManager.saveCompletionHandler(completionHandler, forSessionId: identifier)
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        FBSDKAppEvents.activateApp()
        VKSdk.handleDidBecomeActive();
    }
}

extension UIApplication {
    
    var isRussian:Bool {
        get {
            return NSLocalizedString("FontName", comment: "") != "gamerobot"
        }
    }
}

