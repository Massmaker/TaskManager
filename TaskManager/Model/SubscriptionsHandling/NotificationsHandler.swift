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
                    let localNote = UILocalNotification()
                    localNote.alertTitle = "Task Deleted"
                    localNote.alertBody = "\(recordID.recordName)"
                    localNote.fireDate = NSDate().dateByAddingTimeInterval(1.0)
                    localNote.soundName = "default"
                    UIApplication.sharedApplication().scheduleLocalNotification(localNote)
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
                    var alertDetails = " "
                    if let recordInfo = notification.recordFields
                    {
                        if let title = recordInfo[TitleStringKey] as? String
                        {
                            alertDetails += title
                            alertDetails += " / "
                        }
                        
                        var toDisplay = [String:String]()
                        if let dateTaken = recordInfo[DateTakenDateKey] as? NSDate
                        {
                            toDisplay["started"] = dateTaken.dateTimeCustomString()
                        }
                        if let owner = recordInfo[CurrentOwnerStringKey] as? String
                        {
                            toDisplay["owner"] = owner
                        }
                        if let dateFinished = recordInfo[DateFinishedDateKey] as? NSDate
                        {
                            toDisplay["finished"] = dateFinished.dateTimeCustomString()
                        }
                        
                        for (key, value) in toDisplay
                        {
                            alertDetails += "\(key):\(value)"
                        }
                        
                        let localNote = UILocalNotification()
                        localNote.alertTitle = "Task changed"
                        localNote.alertBody = alertDetails
                        localNote.fireDate = NSDate().dateByAddingTimeInterval(1.0)
                        localNote.soundName = "default"
                        UIApplication.sharedApplication().scheduleLocalNotification(localNote)
                    }
                }
                else //pruned
                {
                    let localNote = UILocalNotification()
                    localNote.alertTitle = "Task changed"
                    localNote.alertBody = notification.recordID?.recordName ?? "unknown task"
                    localNote.fireDate = NSDate().dateByAddingTimeInterval(1.0)
                    localNote.soundName = "default"
                    UIApplication.sharedApplication().scheduleLocalNotification(localNote)
                }
        }
        
    }
    
    
}