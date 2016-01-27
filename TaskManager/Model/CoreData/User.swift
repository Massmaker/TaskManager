//
//  User.swift
//  TaskCloud
//
//  Created by CloudCraft on 1/15/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class User: NSManagedObject {

// Insert code here to add functionality to your managed object subclass

    var isRegistered:Bool{
        return self.registered!.boolValue
    }
    
    var avatarImage:UIImage? {
        
        if let avatarData = self.avatarData
        {
            return UIImage(data: avatarData)
        }
        return nil
    }
    
    var displayName:String {
        
        var returnName = ""
        if let firstName = self.firstName
        {
            returnName += firstName
        }
        if let lastName = self.lastName
        {
            if !returnName.characters.isEmpty
            {
                returnName += " "
            }
            
            returnName += lastName
        }
        
        return returnName
    }
    
    func fillInfoFrom(contact:DeviceContact)
    {
        self.firstName = contact.firstName
        self.lastName = contact.lastName
        self.email = contact.email
        self.phone = contact.fixedPhoneNumber
        self.registered = NSNumber(bool:contact.registered)
        
        if let image = contact.avatarImage
        {
            self.avatarData = UIImagePNGRepresentation(image)
        }
    }
    
}
