//
//  DataSyncronizer.swift
//  TaskManager
//
//  Created by CloudCraft on 2/2/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

let DataSyncronizerDidStartSyncronizyngNotificationName = "DataSyncronizerDidStartSyncronizyngNotification"
let DataSyncronizerDidStopSyncronyzingNotificationName = "DataSyncronizerDidStopSyncronyzingNotification"

import UIKit
import CoreData
import CloudKit

class DataSyncronizer {
    
    static let sharedSyncronizer = DataSyncronizer()
    var isSyncing:Bool{
        return syncing
    }
    
    private var syncing = false

    func requestForRemoteChanges()
    {
        guard let anAppDelegate  = anAppDelegate() else
        {
            return
        }
        
        objc_sync_enter(self)
        syncing = true
        objc_sync_exit(self)
        
        NSNotificationCenter.defaultCenter().postNotificationName(DataSyncronizerDidStartSyncronizyngNotificationName, object: DataSyncronizer.sharedSyncronizer)
        
        let group = dispatch_group_create()
        dispatch_group_enter(group)
        
        SubscriptionsHandler.sharedInstance.loadAll()
        
        anAppDelegate.cloudKitHandler.requestChanges { (notifications) -> () in
            defer
            {
                dispatch_group_leave(group)
            }
            
            if !notifications.isEmpty
            {
                NotificationsHandler.sharedInstance.handleNotes(notifications)
            }
        }
        
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER)
        
        objc_sync_enter(self)
        syncing = false
        objc_sync_exit(self)
        
        NSNotificationCenter.defaultCenter().postNotificationName(DataSyncronizerDidStopSyncronyzingNotificationName, object: DataSyncronizer.sharedSyncronizer)
    }
    
    func startSyncingBoards()
    {
        objc_sync_enter(self)
        syncing = true
        objc_sync_exit(self)
        
        NSNotificationCenter.defaultCenter().postNotificationName(DataSyncronizerDidStartSyncronizyngNotificationName, object: DataSyncronizer.sharedSyncronizer)
        
        //TODO: -
        
        objc_sync_enter(self)
        syncing = false
        objc_sync_exit(self)
        
        NSNotificationCenter.defaultCenter().postNotificationName(DataSyncronizerDidStopSyncronyzingNotificationName, object: DataSyncronizer.sharedSyncronizer)
    }
    
    func startSyncingTasks()
    {
        objc_sync_enter(self)
        syncing = true
        objc_sync_exit(self)
        
        NSNotificationCenter.defaultCenter().postNotificationName(DataSyncronizerDidStartSyncronizyngNotificationName, object: DataSyncronizer.sharedSyncronizer)
     
        
        //TODO: -
        
        objc_sync_enter(self)
        syncing = false
        objc_sync_exit(self)
        
        NSNotificationCenter.defaultCenter().postNotificationName(DataSyncronizerDidStopSyncronyzingNotificationName, object: DataSyncronizer.sharedSyncronizer)
    }
}