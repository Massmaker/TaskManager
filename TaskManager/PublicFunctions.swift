//
//  PublicFunctions.swift
//  TaskCloud
//
//  Created by CloudCraft on 1/14/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//


import UIKit
import CloudKit

func anAppDelegate() -> AppDelegate?
{
    guard let delegate = UIApplication.sharedApplication().delegate as? AppDelegate else
    {
        return nil
    }
    return delegate
}

func networkingIndicator(visible:Bool)
{
    UIApplication.sharedApplication().networkActivityIndicatorVisible = visible
}

func dispatchMain(closure:dispatch_block_t)
{
    dispatch_async(dispatch_get_main_queue(),closure)
}

func dispatchMainSync(closure:dispatch_block_t)
{
    dispatch_sync(dispatch_get_main_queue(), closure)
}

func dispatchBackground(closure:dispatch_block_t)
{
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), closure)
}

//MARK: -  sort Tasks or Boards by "sortOrderIndex"

func == <T: SortableByIndex> (lhs: T, rhs: T) -> Bool {
    return lhs.sortOrderIndex == rhs.sortOrderIndex
}

func < <T: SortableByIndex> (lhs: T, rhs: T) -> Bool {
    return lhs.sortOrderIndex < rhs.sortOrderIndex
}

func > <T:SortableByIndex> (lhs: T, rhs: T) -> Bool {
    return lhs.sortOrderIndex > rhs.sortOrderIndex
}

//MARK: - find index in array of values that conform to "RecordIdIndexable"
func indexOf <T:RecordIdIndexable> (target:T, inArray:[T]) -> Int?
{
    if target.recordId == nil
    {
        return nil
    }
    
    for (index, value) in inArray.enumerate()
    {
        if let recordId = value.recordId where recordId.recordName == target.recordId!.recordName
        {
            return index
        }
    }
    
    return nil
}


func createTaskRecordFrom(taskInfo:Task, recordID:String? = nil) throws -> CKRecord
{
    guard let title = taskInfo.title, creator = taskInfo.creator, _ = taskInfo.board?.recordId else
    {
        throw TaskError.Unknown
    }
    
    var newTaskRecord = CKRecord(recordType: CloudRecordTypes.Task.rawValue)
    if let anID = recordID {
        newTaskRecord = CKRecord(recordType: CloudRecordTypes.Task.rawValue, recordID: CKRecordID(recordName: anID))
    }
    
    newTaskRecord[TaskCreatorStringKey] = creator //not optional
    
    newTaskRecord[TitleStringKey] = title //not optional
    
    newTaskRecord[DetailsStringKey] = taskInfo.details ?? "" //non optional but can be empty string
    newTaskRecord[SortOrderIndexIntKey] = NSNumber(integer: Int(taskInfo.sortOrder)) // not optional , ZERO by default
    newTaskRecord[CurrentOwnerStringKey] = taskInfo.currentOwnerId // optional
    newTaskRecord[DateTakenDateKey] = taskInfo.takenDate //optional
    newTaskRecord[DateFinishedDateKey] = taskInfo.finishedDate //optional
    
    return newTaskRecord
}

func createBoardRecordFrom(board:Board) throws -> CKRecord
{
    guard let creator = board.creatorId, title = board.title else
    {
        throw TaskError.Unknown
    }
    
    let recordTypeBoard = CloudRecordTypes.TaskBoard.rawValue
    
    var newBoardRecord = CKRecord(recordType: recordTypeBoard)
    
    if let recordID = board.recordId
    {
        newBoardRecord = CKRecord(recordType: recordTypeBoard, recordID: CKRecordID(recordName: recordID))
    }
    
    newBoardRecord[BoardCreatorIDKey] = creator
    newBoardRecord[TitleStringKey] = title
    newBoardRecord[DetailsStringKey] = board.details
    newBoardRecord[SortOrderIndexIntKey] = NSNumber(integer: Int(board.sortOrder))
    
    //fill participants field if present
    let participantsSet = board.participantIDsSet
    if !participantsSet.isEmpty
    {
        let array = Array(participantsSet)
        newBoardRecord[BoardParticipantsKey] = array
    }
    
    
    //fill task references field if present
    var references = [CKReference]()
    
    if let boardTasks = board.taskIDs as? [String]
    {
        for aTaskRecordName in boardTasks
        {
            let recordId = CKRecordID(recordName: aTaskRecordName)
            let taskReference = CKReference(recordID: recordId, action: .None)
            references.append(taskReference)
        }
    }
    
    newBoardRecord[BoardTasksReferenceListKey] = references
    
    return newBoardRecord
}


func postNotificationInMainThread(name:String, object:AnyObject? = nil, userInfo:[NSObject:AnyObject]? = nil) {
    
    let note = NSNotification(name: name, object: object, userInfo: userInfo)
    
    dispatchMain(){
        NSNotificationCenter.defaultCenter().postNotification(note)
    }
}


func spaceConcatenatedStrings(var stringsToConcat:[String]) -> String{
    var toReturn = ""
    
    if !stringsToConcat.isEmpty {
        
        repeat{
            let first = stringsToConcat.removeFirst()
            if first.characters.count > 0{
                toReturn += " "
                toReturn += first
            }
        }while !stringsToConcat.isEmpty
        
        toReturn = toReturn.substringFromIndex(toReturn.startIndex.advancedBy(1))
    }
    return toReturn
}
