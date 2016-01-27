//
//  User+CoreDataProperties.swift
//  TaskManager
//
//  Created by CloudCraft on 1/27/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension User {

    @NSManaged var avatarData: NSData?
    @NSManaged var email: String?
    @NSManaged var firstName: String?
    @NSManaged var lastName: String?
    @NSManaged var registered: NSNumber?
    @NSManaged var phone: String?
    @NSManaged var boards: NSSet?
    @NSManaged var currentTask: Task?

}
