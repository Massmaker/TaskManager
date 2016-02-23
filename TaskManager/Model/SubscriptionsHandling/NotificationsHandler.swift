//
//  NotificationsHandler.swift
//  TaskManager
//
//  Created by CloudCraft on 2/1/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import Foundation
import UIKit
import CloudKit

class NotificationsHandler{
    
    static let sharedInstance = NotificationsHandler()
    
    func handleNote(notification:CKQueryNotification)
    {
        print("\n- Handling CloudKit Query Notification -\n")
        let reason = notification.queryNotificationReason
        switch reason
        {
            case .RecordDeleted:
                if let recordID = notification.recordID
                {
                    print(" - Should delete record: \(recordID.recordName)")
                    startDeletingRecordById(recordID)
                }
            case .RecordCreated:
                print(" Record Created")
                if let recID = notification.recordID
                {
                    print(" - Should fetch new record by ID:  \(recID.recordName)")
                }
            case .RecordUpdated:
                if !notification.isPruned
                {
                    if let recId = notification.recordID
                    {
                        
                        if #available(iOS 9.0, *) {
                            print("SubscriotionId: \(notification.subscriptionID)")
                            print("\n Notification record changed: \(recId.recordName)")
                        } else {
                            print("\n Notification record changed: \(recId.recordName)")
                        }
                        
                        startUpdatingRecordById(recId)
                    }
                }
                else //pruned
                {
                    if let recId = notification.recordID
                    {
                        print("\n Notification record changed (pruned): \(recId.recordName)")
                        startUpdatingRecordById(recId)
                    }
                }
        }
    }
    
    func handleNotes(notifications:[CKQueryNotification])
    {
        var deletionNotes = Set<CKRecordID>()
        var updateNotes = Set<CKRecordID>()
        var insertNotes = Set<CKRecordID>()
        
        for aNote in notifications
        {
            let reason = aNote.queryNotificationReason
           
            switch reason
            {
                case .RecordDeleted:
                    if let recordID = aNote.recordID
                    {
                        print(" - Should delete record: \(recordID.recordName)")
                        deletionNotes.insert(recordID)
                    }
                
                case .RecordCreated:
                    print(" Record Created")
                    if let recID = aNote.recordID
                    {
                        print(" - Should fetch new record by ID:  \(recID.recordName)")
                        insertNotes.insert(recID)
                    }
                
                case .RecordUpdated:
                    if let recId = aNote.recordID
                    {
                        print("record changed (pruned): \(recId.recordName)")
                        updateNotes.insert(recId)
                    }
            }//switch end
        }//for loop end
        
    
        print(" \(deletionNotes.count) - toDelete")
        print(" \(updateNotes.count) - toUpdate")
        print(" \(insertNotes.count) - toInsert")
    }
    
    private func startUpdatingRecordById(recordId:CKRecordID){
        //visualize some stuff
        let localNote = UILocalNotification()
        localNote.fireDate = NSDate().dateByAddingTimeInterval(5.0)
         localNote.alertTitle = "test local alert"
        localNote.alertBody = "Updating info for board"
        localNote.soundName = UILocalNotificationDefaultSoundName
        
        UIApplication.sharedApplication().scheduleLocalNotification(localNote)
        
        //preform actual work
        anAppDelegate()?.cloudKitHandler.findRecordWithID(recordId) { (record, error) -> () in
            if let recordFound = record{
                dispatchMain(){
                    if let foundBoard = anAppDelegate()?.coreDatahandler?.findBoardByRecordId(recordFound.recordID.recordName){
                        let currentTaskIDs = foundBoard.taskIDsSet
                       
                        foundBoard.fillInfoFromRecord(recordFound)
                        
                        anAppDelegate()?.coreDatahandler?.saveMainContext()
                        let freshTaskIDs = foundBoard.taskIDsSet
                        
                        //perform task loading or deleting
                        if freshTaskIDs != currentTaskIDs {
                            let toLoadFreshTasks = freshTaskIDs.subtract(currentTaskIDs)
                            let toRemoveOldTasks = currentTaskIDs.subtract(freshTaskIDs)
                            
                            if !toRemoveOldTasks.isEmpty{
                                anAppDelegate()?.coreDatahandler?.deleteTasksByIDs(Array(toRemoveOldTasks))
                            }
                            
                            if !toLoadFreshTasks.isEmpty{
                                
                                var recordIDsToQuery = [CKRecordID]()
                                
                                for aString in toLoadFreshTasks{
                                    recordIDsToQuery.append(CKRecordID(recordName: aString))
                                }
                                
                                anAppDelegate()?.cloudKitHandler.findTasksByTaskIDs(recordIDsToQuery) { (tasks, error) -> () in
                                    if !tasks.isEmpty{
                                        dispatchMain(){
                                            if let boardRefreshed = anAppDelegate()?.coreDatahandler?.findBoardByRecordId(recordId.recordName){
                                                anAppDelegate()?.coreDatahandler?.insertTaskRecords(tasks, forBoard: boardRefreshed, saveImmediately: true)
                                            }
                                            postNotificationInMainThread(DataSyncronizerDidStopSyncronyzingNotificationName, object: NotificationsHandler.sharedInstance)
                                        }
                                    }
                                    else{
                                        postNotificationInMainThread(DataSyncronizerDidStopSyncronyzingNotificationName, object: NotificationsHandler.sharedInstance)
                                    }
                                }
                            }
                            else{
                                postNotificationInMainThread(DataSyncronizerDidStopSyncronyzingNotificationName, object: NotificationsHandler.sharedInstance)
                            }
                        }
                        else{
                            postNotificationInMainThread(DataSyncronizerDidStopSyncronyzingNotificationName, object: NotificationsHandler.sharedInstance)
                        }
                        
                    }
                    else if let foundTask = anAppDelegate()?.coreDatahandler?.findTaskById(recordFound.recordID.recordName){
                        foundTask.fillInfoFrom(recordFound)
                        anAppDelegate()?.coreDatahandler?.saveMainContext()
                        postNotificationInMainThread(DataSyncronizerDidStopSyncronyzingNotificationName, object: NotificationsHandler.sharedInstance, userInfo: nil)
                    }
                    else{
                        let recordType = recordFound.recordType
                        switch recordType{
                        case CloudRecordTypes.TaskBoard.rawValue:
                            do{
                                try anAppDelegate()?.coreDatahandler?.createBoardFromRecord(recordFound)
                                // next 2 lines will not be executed if `try` line fails
                                anAppDelegate()?.coreDatahandler?.saveMainContext()
                                postNotificationInMainThread(DataSyncronizerDidStopSyncronyzingNotificationName, object: NotificationsHandler.sharedInstance, userInfo: nil)

                            }catch let insertError{
                                
                            }
                        case CloudRecordTypes.Task.rawValue:
                            print("Some trouble happened: We don`t expect refreshing tasks here")
                        default:
                            break
                        }
                    }
                        
                }
            }
        }
    }
    
    func startDeletingRecordById(recordID:CKRecordID){
        if let _ = anAppDelegate()?.coreDatahandler?.findBoardByRecordId(recordID.recordName){
            do{
                try anAppDelegate()?.coreDatahandler?.deleteBoardsByIDs([recordID.recordName])
                postNotificationInMainThread(DataSyncronizerDidStopSyncronyzingNotificationName, object: NotificationsHandler.sharedInstance, userInfo: nil)

            }catch{
                
            }
        }
        else if let _ = anAppDelegate()?.coreDatahandler?.findTaskById(recordID.recordName){
            anAppDelegate()?.coreDatahandler?.deleteTasksByIDs([recordID.recordName])
            postNotificationInMainThread(DataSyncronizerDidStopSyncronyzingNotificationName, object: NotificationsHandler.sharedInstance, userInfo: nil)

        }
        else{
            print("\n _ Warning!:  Did not find local Task or Board to delete by remote notification recieved:  RecordID: (recordID.recordName) ")
        }
    }
    
    
}