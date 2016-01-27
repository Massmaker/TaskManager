//
//  TaskInfo.swift
//  TaskCloud
//
//  Created by CloudCraft on 1/14/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//


//MARK: - task record keys
let BoardReferenceKey = "board"
let TitleStringKey = "title"
let DetailsStringKey = "details"
let SortOrderIndexIntKey = "sortOrderIndex"
let TaskCreatorReferenceKey = "taskCreator"
let CurrentOwnerStringKey = "currentOwner"
let DateFinishedDateKey = "dateFinished"
let DateTakenDateKey = "dateTaken"
let TaskRecordIdKey = "recordId"

//MARK: - imports
import Foundation
import CloudKit

//MARK: - Struct
struct TaskInfo {
    private var _recordId:CKRecordID?
    var recordId:CKRecordID?{
        get{
            return self._recordId
        }
    }
    var title:String
    var details:String = ""
    var sortOrderIndex:Int = 0
    var taskBoardId:CKRecordID    // the TASKs must be tied up to single TaskBoard
    var creatorId:CKRecordID      //the TASKs must have a creator

    var currentOwner:String?
    var dateTaken:NSDate?       //is set when somebody takes the task (current owner becomes not nil)
    var dateFinished:NSDate?    // is set when somebody releases the task (current owner becomed nil)
    var dateCreated:NSDate?
    
    init?(taskBoardRecordId:CKRecordID, creatorRecordId:CKRecordID, title:String, details:String?)
    {
        if title.characters.isEmpty{
            return nil
        }
        
        self.taskBoardId = taskBoardRecordId
        self.creatorId = creatorRecordId
        self.title = title
        if let normalDetails = details
        {
            self.details = normalDetails
        }
    }
    
    mutating func setRecordId(recordId:CKRecordID)
    {
        self._recordId = recordId
        print("task recordID: \(self.recordId)")
    }
    
    mutating func fillOptionalInfoFromTaskRecord(record:CKRecord)
    {
        self.currentOwner = record[CurrentOwnerStringKey] as? String
        self.dateTaken = record[DateTakenDateKey] as? NSDate
        self.dateFinished = record[DateFinishedDateKey] as? NSDate
        self.sortOrderIndex = (record[SortOrderIndexIntKey] as? NSNumber)?.integerValue ?? 0
        self.dateCreated = record.creationDate
    }
}

//MARK: - Extension
extension TaskInfo:SortableByIndex{
    
}

extension TaskInfo:RecordIdIndexable{
    
}




