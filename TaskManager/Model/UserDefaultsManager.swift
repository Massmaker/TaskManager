//
//  UserDefaultsManager.swift
//  TaskManager
//
//  Created by CloudCraft on 1/25/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import Foundation
class UserDefaultsManager{
    
    private static let defaults = NSUserDefaults.standardUserDefaults()
    
    class func syncronyzeDefaults() {
        
        let tempUbiquitmanager = UserCloudPreferencesHandler()
        defaults.synchronize()
        
        var toSync = [String:String?]()
        
        let name = getUserNameFromDefaults()
        toSync[UserDefaultKeys.FirstNameKey.rawValue] = name
        
        let lastName = getUserLastNameFromDefaults()
        toSync[UserDefaultKeys.LastNameKey.rawValue] = lastName
        
        if !toSync.isEmpty
        {
            tempUbiquitmanager.saveToUbiquityStore(toSync)
        }
        
    }
    
    
    
    class func setUserNameToDefaults(name:String?)
    {
        defaults.setObject(name, forKey: UserDefaultKeys.FirstNameKey.rawValue)
    }
    
    class func getUserNameFromDefaults() -> String?
    {
        return defaults.objectForKey(UserDefaultKeys.FirstNameKey.rawValue) as? String
    }
    
    class func setUserLastNameToDefaults(lastName:String?)
    {
        defaults.setObject(lastName, forKey: UserDefaultKeys.LastNameKey.rawValue)
    }
    
    class func getUserLastNameFromDefaults() -> String?
    {
        return defaults.objectForKey(UserDefaultKeys.LastNameKey.rawValue) as? String
    }
    
    /**
     Removes email, firstname, last name values from user defaults. Calls *synchronize* after execution
     - Note: use this when user initiates "Logout" procedure
     */
    class func clearUserDefaults()
    {
        defaults.removeObjectForKey(UserDefaultKeys.LastNameKey.rawValue)
        defaults.removeObjectForKey(UserDefaultKeys.FirstNameKey.rawValue)
  
        syncronyzeDefaults()
    }
    
    class func updateUserDefaultsWith(info:[String:String])
    {
        if info.isEmpty
        {
            clearUserDefaults()
            return
        }
        
        let nameKey = UserDefaultKeys.FirstNameKey.rawValue
        let lastNameKey = UserDefaultKeys.LastNameKey.rawValue
        
        if let name = info[nameKey]
        {
            setUserNameToDefaults(name)
        }
            
        else
        {
            NSUserDefaults.standardUserDefaults().removeObjectForKey(nameKey)
        }
        
        if let last = info[lastNameKey]
        {
            setUserLastNameToDefaults(last)
        }
        else
        {
            NSUserDefaults.standardUserDefaults().removeObjectForKey(lastNameKey)
        }
        
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    //MARK: - CloudKit change token
    class func getCloudKitChangeToken() -> NSData?
    {
        return defaults.objectForKey("ChangeToken") as? NSData
    }
    
    class func setCloudKitChangeToken(token:NSData?)
    {
        if let token = token
        {
            defaults.setObject(token, forKey: "ChangeToken")
        }
        else
        {
            defaults.removeObjectForKey("ChangeToken")
        }
        defaults.synchronize()
    }
    
}