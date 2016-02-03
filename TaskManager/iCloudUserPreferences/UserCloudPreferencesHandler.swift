//
//  UserCloudPreferencesHandler.swift
//  TaskManager
//
//  Created by CloudCraft on 1/25/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import UIKit

let UserDefaultsWereUpdatedAfteriCloudSyncNotification = "UserDefaultsWereUpdatedAfteriCloudSyncNotification"

class UserCloudPreferencesHandler: NSObject {

    private lazy var keyValueCloudStore = NSUbiquitousKeyValueStore.defaultStore()
    
    deinit
    {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NSUbiquitousKeyValueStoreDidChangeExternallyNotification, object: keyValueCloudStore)
    }
    
    /**
     It is crucial to call this function as early as pissible
     */
    @warn_unused_result
    func startObservingUbiquityNotifications() -> Bool
    {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateUserDefaultsValues:", name: NSUbiquitousKeyValueStoreDidChangeExternallyNotification, object: keyValueCloudStore)
        
        return keyValueCloudStore.synchronize()
    }
    
    func updateUserDefaultsValues(notification:NSNotification)
    {
        guard let userInfo = notification.userInfo as? [String : AnyObject] else
        {
            return
        }
        
        let aReasonForChange = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey] as? NSNumber
        
        var reason = -1
        
        guard let reasonForChange = aReasonForChange else
        {
            return
        }
        
        reason = reasonForChange.integerValue
        
        switch reason
        {
            case NSUbiquitousKeyValueStoreServerChange:
                fallthrough
            case NSUbiquitousKeyValueStoreInitialSyncChange:
                guard let changedKeys = userInfo[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] else
                {
                    return
                }
                
                var keysAndValues = [String:AnyObject]()
                for aKey in changedKeys
                {
                    if let value = keyValueCloudStore.objectForKey(aKey) as? String
                    {
                        //print("key: \"\(aKey)\", value: \"\(value)\"")
                        keysAndValues[aKey] = value
                    }
                }
                
                if let infoProper = keysAndValues as? [String:String]
                {
                    self.saveToUserDefaults(infoProper)
                }
            default:
                break
        }
    }
    
    func saveToUbiquityStore(info:[String:String?]) -> Bool
    {
        //print("saving to ubuquity")
        for (key, value) in info
        {
            //print("\(key) : \(value)")
            if let aValue = value
            {
                keyValueCloudStore.setObject(aValue, forKey: key)
            }
//            else
//            {
//                keyValueCloudStore.removeObjectForKey(key)
//            }
        }
        
        return keyValueCloudStore.synchronize()
    }
    
    func userDataFromUbuquity() -> [String:String]
    {
        var forUserDefaults = [String:String]()
        
        if let name = keyValueCloudStore.objectForKey(UserDefaultKeys.FirstNameKey.rawValue) as? String
        {
            forUserDefaults[UserDefaultKeys.FirstNameKey.rawValue] = name
        }
        
        if let lastName = keyValueCloudStore.objectForKey(UserDefaultKeys.LastNameKey.rawValue) as? String
        {
            forUserDefaults[UserDefaultKeys.LastNameKey.rawValue] = lastName
        }
        
        return forUserDefaults
    }
    
    private func saveToUserDefaults(info:[String:String]? = nil)
    {
        
        if let info = info
        {
            UserDefaultsManager.setUserNameToDefaults(info[UserDefaultKeys.FirstNameKey.rawValue])
            UserDefaultsManager.setUserLastNameToDefaults(info[UserDefaultKeys.LastNameKey.rawValue])
        }
        else
        {
            let fName = keyValueCloudStore.objectForKey(UserDefaultKeys.FirstNameKey.rawValue) as? String
            let lName = keyValueCloudStore.objectForKey(UserDefaultKeys.LastNameKey.rawValue) as? String

            UserDefaultsManager.setUserLastNameToDefaults(lName)
            UserDefaultsManager.setUserNameToDefaults(fName)
        }
        NSUserDefaults.standardUserDefaults().synchronize() //call this for not calling tempDefaultsManager.synchronizeDefaults(), beacuse it will create a cycle
        NSNotificationCenter.defaultCenter().postNotificationName(UserDefaultsWereUpdatedAfteriCloudSyncNotification, object: nil)
    }
    
}
