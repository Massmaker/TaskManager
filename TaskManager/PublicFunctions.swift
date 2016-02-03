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


func createTaskRecordFrom(taskInfo:Task) throws -> CKRecord
{
    guard let title = taskInfo.title, creator = taskInfo.creator, _ = taskInfo.board?.recordId else
    {
        throw TaskError.Unknown
    }
    
    let newTaskRecord = CKRecord(recordType: CloudRecordTypes.Task.rawValue)
    
    newTaskRecord[TaskCreatorStringKey] = creator //not optional
    
    newTaskRecord[TitleStringKey] = title //not optional
    
    newTaskRecord[DetailsStringKey] = taskInfo.details ?? "" //non optional but can be empty string
    newTaskRecord[SortOrderIndexIntKey] = NSNumber(integer: Int(taskInfo.sortOrder)) // not optional , ZERO by default
    newTaskRecord[CurrentOwnerStringKey] = taskInfo.currentOwner?.phone // optional
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
    newBoardRecord[BoardTitleKey] = title
    newBoardRecord[BoardDetailsKey] = board.details
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
    
    let boardTasks = board.orderedTasks
    if !boardTasks.isEmpty
    {
        for aTask in boardTasks
        {
            if let taskID = aTask.recordId
            {
                let recordId = CKRecordID(recordName: taskID)
                let taskReference = CKReference(recordID: recordId, action: .DeleteSelf)
                references.append(taskReference)
            }
        }
    }
    
    newBoardRecord[BoardTasksReferenceListKey] = references
    
    return newBoardRecord
}

func createBoardFromRecord(boardRecord:CKRecord) throws -> Board
{
    let recordType = boardRecord.recordType
    guard recordType == CloudRecordTypes.TaskBoard.rawValue else
    {
        throw TaskError.WrongRecordType
    }
    
    guard let title = boardRecord[TitleStringKey] as? String, creator = boardRecord[BoardCreatorIDKey] as? String else
    {
        throw TaskError.CloudKit(cloudError:
                NSError(domain: "com.TaskManager.ConvertingError", code: -11, userInfo: [NSLocalizedDescriptionKey:"unknown board creator or board title values", NSLocalizedFailureReasonErrorKey:"Wrong Required parameters"]) )
    }
    
    let board = Board()
    board.title = title
    board.creatorId = creator
    board.details = boardRecord[DetailsStringKey] as? String
    board.sortOrder = Int64(boardRecord[SortOrderIndexIntKey] as? Int ?? 0)
    board.recordId = boardRecord.recordID.recordName
    board.dateCreated = boardRecord.creationDate?.timeIntervalSinceReferenceDate ?? 0.0
    if let participantReferences = boardRecord[BoardParticipantsKey] as? [CKReference]
    {
        let strings = NSMutableSet(capacity: participantReferences.count)
        for aParticipant in participantReferences
        {
            strings.addObject(aParticipant.recordID.recordName)
        }
        board.participants = NSSet(set: strings)
    }
    return board
}

