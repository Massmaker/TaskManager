//
//  Task+CoreDataProperties.swift
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

extension Task {

    @NSManaged var toBeDeleted:Bool
    @NSManaged var changeTag: String?
    @NSManaged var dateFinished: NSTimeInterval
    @NSManaged var dateTaken: NSTimeInterval
    @NSManaged var dateCreated:NSTimeInterval
    @NSManaged var details: String?
    @NSManaged var recordId: String?
    @NSManaged var sortOrder: Int64
    @NSManaged var title: String?
    @NSManaged var creator:String?
    
    @NSManaged var board: Board?
    @NSManaged var currentOwner: User?


}
