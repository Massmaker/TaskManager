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
    
    var createDate:NSDate {
        return NSDate(timeIntervalSinceReferenceDate: self.dateCreated)
    }
    
    var shortDateString:String{
        return createDate.dateTimeCustomString()
    }
    
    var participantIDsSet:Set<String>{
        
        guard let participants = self.participants as? Set<User> where participants.count > 0 else
        {
            return Set<String>()
        }
        
        var participantIDs = Set<String>()
        for aParticipant in participants
        {
            if let aPhone = aParticipant.phone
            {
                participantIDs.insert(aPhone)
            }
        }
        
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
            tasks.sortInPlace() { $0.0.sortOrder < $0.1.sortOrder }
        }
        
        return tasks
    }
    
    func fillBasicInfoFrom(boardInfo:TaskBoardInfo)
    {
        self.creatorId = boardInfo.creatorId
        self.recordId = boardInfo.recordId?.recordName
        self.details = boardInfo.details
        self.title = boardInfo.title
        self.dateCreated = boardInfo.dateCreated?.timeIntervalSinceReferenceDate ?? 0.0
        self.sortOrder = Int64( boardInfo.sortOrderIndex )
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
    }
    
}
