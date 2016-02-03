//
//  DisplayNameCapable.swift
//  TaskManager
//
//  Created by CloudCraft on 2/2/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import Foundation

protocol DisplayNameCapable{
    var firstName:String? {get set}
    var lastName:String? {get set}
}

extension DisplayNameCapable {
    var displayName:String{
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
}