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
        let reason = notification.queryNotificationReason
        switch reason
        {
            case .RecordDeleted:
                if let recordID = notification.recordID
                {
                    print(" - Should delete record: \(recordID.recordName)")
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
                        print("record changed: \(recId.recordName)")
                    }
                }
                else //pruned
                {
                    if let recId = notification.recordID
                    {
                        print("record changed (pruned): \(recId.recordName)")
                    }
                }
        }
    }
    
    func handleNotes(notifications:[CKQueryNotification])
    {
        var deletionNotes = [CKRecordID]()
        var updateNotes = [CKRecordID]()
        var insertNotes = [CKRecordID]()
        
        for aNote in notifications
        {
            let reason = aNote.queryNotificationReason
           
            switch reason
            {
                case .RecordDeleted:
                    if let recordID = aNote.recordID
                    {
                        print(" - Should delete record: \(recordID.recordName)")
                        deletionNotes.append(recordID)
                    }
                
                case .RecordCreated:
                    print(" Record Created")
                    if let recID = aNote.recordID
                    {
                        print(" - Should fetch new record by ID:  \(recID.recordName)")
                        insertNotes.append(recID)
                    }
                
                case .RecordUpdated:
                    if let recId = aNote.recordID
                    {
                        print("record changed (pruned): \(recId.recordName)")
                        updateNotes.append(recId)
                    }
            }//switch end
        }//for loop end
        
    
        print(" \(deletionNotes.count) - toDelete")
        print(" \(updateNotes.count) - toUpdate")
        print(" \(insertNotes.count) - toInsert")
    }
    
    
    
}