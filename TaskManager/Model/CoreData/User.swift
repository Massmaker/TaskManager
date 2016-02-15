//
//  User.swift
//  TaskCloud
//
//  Created by CloudCraft on 1/15/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import CloudKit
import CoreData
import UIKit

class User: NSManagedObject {

// Insert code here to add functionality to your managed object subclass

    var isRegistered:Bool{
        return self.registered
    }
    
    var avatarImage:UIImage? {
        
        if let avatarData = self.avatarData
        {
            return UIImage(data: avatarData)
        }
        return nil
    }
    
    func fillInfoFrom(contact:DeviceContact)
    {
        self.firstName = contact.firstName
        self.lastName = contact.lastName
        //self.email = contact.email
        self.phone = contact.fixedPhoneNumber
        self.registered = contact.registered
        
        if let image = contact.avatarImage
        {
            self.avatarData = UIImagePNGRepresentation(image)
        }
    }
    
    func fillInfoFrom(userRecord:CKRecord)
    {
        let recordId = userRecord.recordID.recordName
        phone = recordId
        firstName = UserDefaultsManager.getUserNameFromDefaults()
        lastName = UserDefaultsManager.getUserLastNameFromDefaults()
        avatarData = DocumentsFolderFileHandler().getAvatarDataFromDocumentsForUserID(recordId)
        registered = true
    }
    
    override func didSave() {
        if self.deleted
        {
            
        }
        else
        {
            if self.isRegistered
            {
                //print(" - User is regitered")
            }
            else
            {
                //print(" - User is NOT registered")
            }
        }
    }
}
