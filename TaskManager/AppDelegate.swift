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
import CloudKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    lazy var cloudKitHandler = CloudKitDatabaseHandler()

    lazy var keyValueCloudStore = UserCloudPreferencesHandler()
    
    var coreDatahandler:CoreDataManager?
    
    private var reachability:Reachability?
    
    var internetReachable:Bool = false{
        didSet(oldValue){
             if oldValue != internetReachable{
                dispatchMain(){[weak self] in
                    self?.applyNavigationBarAppearance()
                }
            }
        }
    }
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        let appThemeColor = UIColor.appThemeColorBlue
        let whiteColor = UIColor.whiteColor()
        
        UINavigationBar.appearance().tintColor = appThemeColor
        UINavigationBar.appearance().translucent = false
        UINavigationBar.appearance().barTintColor = whiteColor
        UINavigationBar.appearance().setBackgroundImage(UIImage(), forBarMetrics: .Default)
        UINavigationBar.appearance().shadowImage = UIImage()
        
        UITabBar.appearance().tintColor = appThemeColor
        UITabBar.appearance().translucent = false
        UITabBar.appearance().barTintColor = whiteColor
        UITabBar.appearance().shadowImage = UIImage()
        UITabBar.appearance().backgroundImage = UIImage()
        
        Fabric.with([Digits.self])
        
        let lastSyncedInfo = keyValueCloudStore.userDataFromUbuquity()
        
        UserDefaultsManager.updateUserDefaultsWith(lastSyncedInfo)
        
        let _ = keyValueCloudStore.startObservingUbiquityNotifications()
        
        
        let completionBlock = {(initialized:Bool, error:ErrorType?) in
            print("\n - initialized CoreData: \(initialized), error: \(error) \n")
            if initialized == false
            {
                self.coreDatahandler = nil
            }
        }
        
        if let dataModel = CoreDataManager.getManagedObjectModel()
        {
            do
            {
                if let store = try CoreDataManager.getPersistentStoreCoordinatorForModel(dataModel)
                {
                    self.coreDatahandler = CoreDataManager(storeCoordinator: store, completion: { (initialized) -> () in
                        completionBlock(initialized, nil)
                    })
                }
            }
            catch let error
            {
                completionBlock(false, error)
            }
        }
        else
        {
            completionBlock(false, unknownError)
        }
       
        let queue = dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)
        dispatch_async(queue) {
            
            let settings = UIUserNotificationSettings(forTypes: [.Alert, .Sound, .Badge], categories: nil)
            UIApplication.sharedApplication().registerUserNotificationSettings(settings)
            UIApplication.sharedApplication().registerForRemoteNotifications()
            
            do{
                let reachability = try Reachability(hostname: "google.com")
                
                if reachability.isReachable(){
                    self.internetReachable = true
                }
                
                try reachability.startNotifier()
                NSNotificationCenter.defaultCenter().addObserver(self, selector: "reachabilityStatusChangedNotificationHandler:", name: ReachabilityChangedNotification, object: reachability)
                self.reachability = reachability
            }
            catch let error as ReachabilityError{
                switch error{
                case ReachabilityError.FailedToCreateWithHostname(_):
                    self.internetReachable = false
                case ReachabilityError.FailedToCreateWithAddress(_):
                    self.internetReachable = false
                default:
                    self.internetReachable = false
                }
            }
            catch{
                self.internetReachable = false
            }
            
        }
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        
        UserDefaultsManager.syncronyzeDefaults()
        
        coreDatahandler?.saveMainContext()
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

    //MARK: - PUSH
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        print("\n didFailToRegisterForRemoteNotificationsWithError: \n \(error)")
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        print("\n didRegisterForRemoteNotificationsWithDeviceToken")
        let string = deviceToken.description
        print(string)
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        if let userInfo = userInfo as? [String:NSObject]
        {
            let ckNote = CKQueryNotification(fromRemoteNotificationDictionary: userInfo)
            NotificationsHandler.sharedInstance.handleNote(ckNote)
        }
    }
    
    //MARK: -
    func reachabilityStatusChangedNotificationHandler(notification:NSNotification){
        if let reach = notification.object as? Reachability{
            self.internetReachable = ( reach.isReachableViaWiFi() || reach.isReachableViaWWAN()  )
        }
    }
    
    func applyNavigationBarAppearance(){
        
        if self.internetReachable{
            UINavigationBar.appearance().barTintColor = UIColor.whiteColor()
            UINavigationBar.appearance().tintColor = UIColor.appThemeColorBlue
        }else{
            UINavigationBar.appearance().barTintColor = UIColor.redColor().colorWithAlphaComponent(0.7)
            UINavigationBar.appearance().tintColor = UIColor.whiteColor()
        }
        
        if let tabBarController = window?.rootViewController as? UITabBarController, let navViewControllers = tabBarController.viewControllers{
            for aVC in navViewControllers{
                if let navVC = aVC as? UINavigationController{
                    navVC.setNavigationBarHidden(true, animated: false)
                    navVC.setNavigationBarHidden(false, animated: true)
                }
            }
        }
    }
    
}

