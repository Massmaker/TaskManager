//
//  Board+CoreDataProperties.swift
//  TaskManager
//
//  Created by CloudCraft on 2/2/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Board {

    @NSManaged var changeTag: String?
    @NSManaged var creatorId: String?
    @NSManaged var dateCreated: NSTimeInterval
    @NSManaged var details: String?
    @NSManaged var recordId: String?
    @NSManaged var sortOrder: Int64
    @NSManaged var title: String?
    @NSManaged var tasks: NSSet?
    @NSManaged var participants: NSSet?
    @NSManaged var toBeDeleted:Bool
    
    @NSManaged func addTasks(tasks:[Task])
}
