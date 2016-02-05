//
//  Board.swift
//  TaskCloud
//
//  Created by CloudCraft on 1/15/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import Foundation
import CoreData
import CloudKit

class Board: NSManagedObject {

// Insert code here to add functionality to your managed object subclass
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        
        self.toBeDeleted = false
        self.sortOrder = 0
        self.title = ""
    }
    
    var createDate:NSDate {
        return NSDate(timeIntervalSinceReferenceDate: self.dateCreated)
    }
    
    var shortDateString:String{
        return createDate.dateTimeCustomString()
    }
    
    var participantIDsSet:Set<String>{
        
        guard let participants = self.participants as? NSArray where participants.count > 0 else
        {
            return Set<String>()
        }
        
        guard let participantsStringArray = participants as? [String] else
        {
            return Set<String>()
        }
        
        var participantIDs = Set<String>()
        for aParticipant in participantsStringArray
        {
            participantIDs.insert(aParticipant)
        }
        print("Board Participains: \(participantIDs.count)")
        return participantIDs
    }
    
    var orderedTasks:[Task]{
        var tasks = [Task]()
        
        if let currentTasksSet = self.tasks as? Set<Task>
        {
            tasks = Array(currentTasksSet)
        }
        
        if !tasks.isEmpty && tasks.count > 1
        {
            var notDeletedTasks = tasks.filter{ (aTask) -> Bool in
                return  aTask.toBeDeleted != true
            }
            
            notDeletedTasks.sortInPlace() { $0.0.sortOrder < $0.1.sortOrder }
            tasks = notDeletedTasks
        }
        
        return tasks
    }
    
    private var allTasksOrdered:[Task]{
        var tasks = [Task]()
        
        if let currentTasksSet = self.tasks as? Set<Task>
        {
            tasks = Array(currentTasksSet)
        }
        
        if !tasks.isEmpty && tasks.count > 1
        {
            tasks.sortInPlace() { $0.0.sortOrder < $0.1.sortOrder }
        }
        
        return tasks
    }
    
    func checkTaskIDsToBeEqualToTasks()
    {
        let currentTasks = self.orderedTasks
        var allTaskIDs = NSMutableArray(capacity: currentTasks.count)
        for aTask in currentTasks
        {
            allTaskIDs.addObject(aTask.recordId!)
        }
        self.taskIDs = allTaskIDs
    }
    
    
    func fillInfoFromRecord(record:CKRecord)
    {
        self.changeTag = record.recordChangeTag
        self.recordId = record.recordID.recordName
        self.title = record[TitleStringKey] as? String
        self.details = record[DetailsStringKey] as? String
        if let date = record.creationDate
        {
            self.dateCreated = date.timeIntervalSinceReferenceDate
        }
        self.creatorId = record[BoardCreatorIDKey] as? String
        if let order = record[SortOrderIndexIntKey] as? Int64
        {
            self.sortOrder = order
        }
        
        if let taskReferences = record[BoardTasksReferenceListKey] as? [CKReference]
        {
            let recordIDs = NSMutableArray(capacity: taskReferences.count)
            for aRef in taskReferences
            {
                recordIDs.addObject(aRef.recordID.recordName)
            }
            self.taskIDs = recordIDs
        }
        else
        {
            self.taskIDs = NSArray()
        }
        
        if let participantIDs = record[BoardParticipantsKey] as? [String]
        {
            let anArray = NSArray(array: participantIDs)
            self.participants = anArray
        }
        else
        {
            self.participants = NSArray()
        }
    }
    
}
