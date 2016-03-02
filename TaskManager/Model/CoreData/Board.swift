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
    
    override func didSave() {
        if self.deleted
        {
            return
        }
        else //check for deleted BoardID
        {
            if let dbManager = anAppDelegate()?.coreDatahandler
            {
                if self.toBeDeleted
                {
                    dbManager.appendBoardIDToDelete(self.recordId)
                }
                else
                {
                    dbManager.removeBoardIDFromToBeDeleted(self.recordId)
                }
            }
        }
        
        super.didSave()
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
            var notDeletedTasks = tasks.filter{ $0.toBeDeleted != true }
            
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
    
    var taskIDsSet:Set<String>{
        var toReturn = Set<String>()
        if let taskIDs = self.taskIDs as? [String]{
            toReturn = Set(taskIDs)
        }
        return toReturn
    }
    func checkTaskIDsToBeEqualToTasks()
    {
        let currentTasks = self.orderedTasks
        let allTaskIDs = NSMutableArray(capacity: currentTasks.count)
        for aTask in currentTasks
        {
            allTaskIDs.addObject(aTask.recordId!)
        }
        self.taskIDs = allTaskIDs
    }
    
    func assignParticipants(newValue:Set<String>?)
    {
        guard let participants = newValue else
        {
            self.participants = nil
            return
        }
        
        let anArray = NSMutableArray(capacity: participants.count)
        for aString in participants
        {
            anArray.addObject(aString as NSString)
        }
        
        self.participants = anArray
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
        
        if let modDate = record.modificationDate{
            self.dateModified = modDate.timeIntervalSinceReferenceDate
        }
        else{
            self.dateModified = 0.0
        }
        
        self.creatorId = record[BoardCreatorIDKey] as? String
        if let order = record[SortOrderIndexIntKey] as? NSNumber
        {
            self.sortOrder = Int64(order.integerValue)
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
