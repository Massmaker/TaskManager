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
        let email = getEmailFromDefaults()
        toSync[UserDefaultKeys.EmailKey.rawValue] = email
        
        if !toSync.isEmpty
        {
            tempUbiquitmanager.saveToUbiquityStore(toSync)
        }
        
    }
    
    class func getEmailFromDefaults() -> String? {
        return defaults.objectForKey(UserDefaultKeys.EmailKey.rawValue) as? String
    }
    
    class func setEmailToDefaults(email: String?) {
        defaults.setObject(email, forKey: UserDefaultKeys.EmailKey.rawValue)
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
        defaults.removeObjectForKey(UserDefaultKeys.EmailKey.rawValue)
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
        let emailKey = UserDefaultKeys.EmailKey.rawValue
        
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
        
        if let email = info[emailKey]
        {
            setEmailToDefaults(email)
        }
        else
        {
            NSUserDefaults.standardUserDefaults().removeObjectForKey(emailKey)
        }
        
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
}