//
//  AppDelegate.swift
//  Ride
//
//  Created by mohamed fawzy on 12/24/18.
//  Copyright © 2018 mohamed fawzy. All rights reserved.
//

import UIKit
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    fileprivate var containerVC: ContainerViewController!
    
    var containerViewController : ContainerViewController {
        return containerVC
    }
    
    


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
        
        containerVC = ContainerViewController()
        window?.rootViewController = containerVC
        window?.makeKeyAndVisible()
        
        
        return true
    }
    
    func getAppDelegate() -> AppDelegate{
        return UIApplication.shared.delegate as! AppDelegate
    }

    
}

