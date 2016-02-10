//
//  Task.swift
//  TaskCloud
//
//  Created by CloudCraft on 1/15/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import Foundation
import CoreData
import CloudKit

class Task: NSManagedObject {

// Insert code here to add functionality to your managed object subclass
    
    func fillInfoFrom(record:CKRecord)
    {
        self.title = record[TitleStringKey] as? String
        self.details = record[DetailsStringKey] as? String
        self.sortOrder = record[SortOrderIndexIntKey] as? Int64 ?? 0
        self.creator = record[TaskCreatorStringKey] as? String
        self.recordId = record.recordID.recordName
        print(" TAsk .recordId = \(self.recordId!) ")
        
        self.changeTag = record.recordChangeTag
        self.currentOwnerId = record[CurrentOwnerStringKey] as? String

        if let dateCreated = record.creationDate
        {
            self.dateCreated = dateCreated.timeIntervalSinceReferenceDate
        }
        
        if let dateFinished = record[DateFinishedDateKey] as? NSDate
        {
            self.dateFinished = dateFinished.timeIntervalSinceReferenceDate
        }
        else
        {
            self.dateFinished = 0.0
        }
        
        if let dateTaken = record[DateTakenDateKey] as? NSDate
        {
            self.dateTaken = dateTaken.timeIntervalSinceReferenceDate
        }
        else
        {
            self.dateTaken = 0.0
        }
    }
    
    
    var finishedDate:NSDate? {
        
        if self.dateFinished > 0
        {
            return NSDate(timeIntervalSinceReferenceDate: self.dateFinished)
        }
        return nil
    }
    
    var takenDate:NSDate? {
        
        if self.dateTaken > 0
        {
            return NSDate(timeIntervalSinceReferenceDate: self.dateTaken)
        }
        return nil
    }
    
    var createdDate:NSDate?{
        if self.dateCreated > 0
        {
            return NSDate(timeIntervalSinceReferenceDate: self.dateCreated)
        }
        return nil
    }
    

}
