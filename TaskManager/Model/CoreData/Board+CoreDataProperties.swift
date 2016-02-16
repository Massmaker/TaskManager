//
//  Board+CoreDataProperties.swift
//  TaskManager
//
//  Created by CloudCraft on 2/4/16.
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
    @NSManaged var dateModified: NSTimeInterval
    @NSManaged var details: String?
    @NSManaged var recordId: String?
    @NSManaged var sortOrder: Int64
    @NSManaged var title: String?
    @NSManaged var toBeDeleted: Bool
    ///array of user ids
    @NSManaged var participants: NSObject? //array of strings
    @NSManaged var tasks: NSSet? // <Task>
    ///array of task record ids
    @NSManaged var taskIDs: NSObject? // array of <String>
    
    @NSManaged func addTasksObject(task:Task)
    @NSManaged func removeTasksObject(task:Task)

}
