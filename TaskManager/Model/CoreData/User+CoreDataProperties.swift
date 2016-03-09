//
//  User+CoreDataProperties.swift
//  TaskManager
//
//  Created by CloudCraft on 3/9/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension User {

    @NSManaged var avatarData: NSData?
    @NSManaged var firstName: String?
    @NSManaged var lastName: String?
    @NSManaged var phone: String?
    @NSManaged var registered: Bool

}

extension User:DisplayNameCapable{
    
}