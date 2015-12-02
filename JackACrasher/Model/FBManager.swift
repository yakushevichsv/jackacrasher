//
//  FBManager.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 12/2/15.
//  Copyright © 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit


class FBManager: NSObject {

    private static var g_manager:FBManager!
    private static var g_managerContext:dispatch_once_t = 0
    private var currentConnection:FBSDKGraphRequestConnection? = nil
    private lazy var loginManager:FBSDKLoginManager! = {
        let manager = FBSDKLoginManager()
        manager.loginBehavior = .Browser
        return manager
    }()
    
    class var sharedManager:FBManager! {
        get {
            dispatch_once(&FBManager.g_managerContext) { () -> Void in
                g_manager = FBManager()
            }
            return g_manager
        }
    }
    
    internal typealias FBManagerFriendRequestHandler = ([SNFriendInfo]?, NSError?) -> Void
    
    func getFriends(handler:FBManagerFriendRequestHandler) {
    
    }
    
    func getFriends_old(handler:FBManagerFriendRequestHandler) {
       
        self.currentConnection?.cancel()
        
        //HACK: doesn't work anymore......
        //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)){
          //  [unowned self] in
            

            if let token = FBSDKAccessToken.currentAccessToken() {
                
                if (!token.hasGranted("user_friends")) {
                    print("Not granted friends request")
                    return
                }
                
                let graphPath = "\(token.userID)/friends"
                
                let request = FBSDKGraphRequest(graphPath: graphPath, parameters: ["fields":"email,id,name,cover"])
                let connection = request.startWithCompletionHandler({ (connect, result, error) -> Void in
                    
                    if (error != nil) {
                        
                        print("Localized description: \(error.userInfo[FBSDKErrorLocalizedDescriptionKey])")
                        
                        // ee analyize error here.....
                        if let category = error.userInfo[FBSDKGraphRequestErrorCategoryKey] as? FBSDKGraphRequestErrorCategory {
                            
                            switch category {
                            case .Transient:
                                //HACK: retry here brother!....
                                break
                            case .Recoverable:
                                //HACK: login here brother!...
                                break
                            default:
                                break
                            }
                        }
                    }
                    else {
                        print("Result \(result)")
                    }
                })
                
                connection.delegate = self
                self.currentConnection = connection
                //connection.start()
        }
        else  {
                
                FBSDKLoginManager.renewSystemCredentials(){
                    [unowned self]
                    (result, error) -> Void in
                    if (error == nil && result == .Renewed) {
                        
                        
                        self.loginManager.logInWithReadPermissions(nil){
                            [unowned self]
                            (result, error) -> Void in
                            if error == nil && !result.isCancelled {
                                self.getFriends(handler)
                            }
                            else if (error != nil){
                                print("Version \(FBSDKSettings.sdkVersion())\n Error login \(error). Info \(error.userInfo)")
                                //self.getFriends(handler)
                            }
                        }
                    }
                }
                return
            }

        
       // }
    }
}

extension FBManager: FBSDKGraphRequestConnectionDelegate {
    func requestConnectionDidFinishLoading(connection: FBSDKGraphRequestConnection!) {
        
        if (Optional<FBSDKGraphRequestConnection>(connection) == self.currentConnection) {
            self.currentConnection = nil
        }
    }
    
    func requestConnection(connection: FBSDKGraphRequestConnection!, didFailWithError error: NSError!) {
        
        print("Error connection \(error)")
        if (Optional<FBSDKGraphRequestConnection>(connection) == self.currentConnection) {
            self.currentConnection = nil
        }
    }
}
