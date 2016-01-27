//
//  Task+CoreDataProperties.swift
//  TaskManager
//
//  Created by CloudCraft on 1/26/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Task {

    @NSManaged var changeTag: String?
    @NSManaged var details: String?
    @NSManaged var recordId: String?
    @NSManaged var sortOrder: NSNumber?
    @NSManaged var title: String?
    @NSManaged var dateTaken: NSDate?
    @NSManaged var dateFinished: NSDate?
    @NSManaged var board: Board?
    @NSManaged var currentOwner: User?

}
