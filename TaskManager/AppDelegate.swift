//
//  AppDelegate.swift
//  TaskManager
//
//  Created by CloudCraft on 1/18/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import UIKit
import Fabric
import DigitsKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    lazy var cloudKitHandler = CloudKitDatabaseHandler()

    lazy var keyValueCloudStore = UserCloudPreferencesHandler()
    
    var coreDatahandler:CoreDataManager?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        Fabric.with([Digits.self])
        
        let lastSyncedInfo = keyValueCloudStore.userDataFromUbuquity()
        UserDefaultsManager().updateUserDefaultsWith(lastSyncedInfo)
        
        let _ = keyValueCloudStore.startObservingUbiquityNotifications()
        
        
        let completionBlock = {(initialized:Bool, error:ErrorType?) in
            print("\n - initialized CoreData: \(initialized), error: \(error) \n")
        }
        
        if let dataModel = CoreDataManager.getManagedObjectModel()
        {   do
            {
                if let store = try CoreDataManager.getPersistentStoreCoordinatorForModel(dataModel)
                {
                    coreDatahandler = CoreDataManager(storeCoordinator: store, completion: { (initialized) -> () in
                        completionBlock(initialized, nil)
                    })
                }
            }
            catch let error{
                completionBlock(false, error)
            }
        }
        else
        {
            completionBlock(false, unknownError)
        }
       
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        UserDefaultsManager().syncronyzeDefaults()
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
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

