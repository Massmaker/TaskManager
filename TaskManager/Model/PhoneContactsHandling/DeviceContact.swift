//
//  DeviceContact.swift
//  TaskCloud
//
//  Created by CloudCraft on 1/12/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import Foundation
import UIKit
import CloudKit

class DeviceContact  {
    var firstName:String?
    var lastName:String?
    var email:String?
    var phoneNumber:String = ""
    var avatarImage:UIImage?
    var registered = false
    
    convenience init?(phoneNumber:String?){
        guard let aNumber = phoneNumber, _ = aNumber.fixedPhoneNumber else
        {
            return nil
        }
        self.init()
        self.phoneNumber = aNumber
    }
    
   
}

//MARK: - Equatable

func ==(lhs:DeviceContact, rhs:DeviceContact) -> Bool
{
    return lhs.phoneNumber == rhs.phoneNumber
}

func <(lhs:DeviceContact, rhs:DeviceContact) -> Bool
{
    return lhs.phoneNumber < rhs.phoneNumber
}