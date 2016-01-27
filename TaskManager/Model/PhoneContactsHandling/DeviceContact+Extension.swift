//
//  DeviceContact+Extension.swift
//  TaskCloud
//
//  Created by CloudCraft on 1/12/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import Foundation

extension DeviceContact:Hashable{
    //MARK: - Hashable
    var hashValue:Int{
        return self.phoneNumber.hashValue
    }
}

extension DeviceContact{
    
    var displayName:String? {
        
        var toReturn = ""
        if let firstName = getStringIfNotEmpty(self.firstName)
        {
            toReturn += firstName
        }
        
        if let lastName = getStringIfNotEmpty(self.lastName)
        {
            if !toReturn.isEmpty
            {
                toReturn += " "
            }
            toReturn += lastName
        }
        
        if toReturn.isEmpty
        {
            return nil
        }
        
        return toReturn
    }
    
    var initialsString:String? {
        var letters = ""
        if let firstName = getStringIfNotEmpty(self.firstName)
        {
            letters += firstName.substringToIndex(firstName.startIndex.advancedBy(1))
        }
        
        if let lastName = getStringIfNotEmpty(self.lastName)
        {
            letters += lastName.substringToIndex(lastName.startIndex.advancedBy(1))
        }
        
        if letters.isEmpty{
            return nil
        }
        
        return letters
    }
    
    var fixedPhoneNumber:String{
        return self.phoneNumber.fixedPhoneNumber!
    }

    
}

func getStringIfNotEmpty(stringToCheck:String?) -> String? {
    if let aString = stringToCheck where aString.characters.count > 0
    {
        return aString
    }
    return nil
}