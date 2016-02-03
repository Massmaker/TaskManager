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
        
        let dispatchGroupForBoards = dispatch_group_create()
        
        let timeout:dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 1.0))
        
        var boardRecordsToSave = [CKRecord]()
        
        dispatch_group_enter(dispatchGroupForBoards)
        anAppDelegate()?.cloudKitHandler.queryForBoardsByCurrentUser(){ (boards, error) -> () in
            if let boards = boards
            {
                boardRecordsToSave += boards
            }
            
            anAppDelegate()?.cloudKitHandler.queryForBoardsSharedWithMe(){ (boards, fetchError) -> () in
                if let sharedBoards = boards
                {
                    boardRecordsToSave += sharedBoards
                }
                dispatch_group_leave(dispatchGroupForBoards)
            }
        }
        
        dispatch_group_wait(dispatchGroupForBoards, timeout)
        
        
        let localDatabaseGroup = dispatch_group_create()
        
        let dbTimeout:dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 30.0))
        
        
        dispatch_group_enter(localDatabaseGroup)
        
        for aRecord in boardRecordsToSave
        {
            do{
                let boardToSaveToCoreData = try createBoardFromRecord(aRecord)
                anAppDelegate()?.coreDatahandler?.insert(boardToSaveToCoreData, saveImmediately: false)
            }
            catch{
                
            }
        }
        
        anAppDelegate()?.coreDatahandler?.saveMainContext()
        
        dispatch_group_leave(localDatabaseGroup)
        
        
        dispatch_group_wait(localDatabaseGroup, dbTimeout)
        
        print("didLoad boards: \(boardRecordsToSave.count) ")
        
        objc_sync_enter(self)
        syncing = false
        objc_sync_exit(self)
        
        NSNotificationCenter.defaultCenter().postNotificationName(DataSyncronizerDidStopSyncronyzingNotificationName, object: DataSyncronizer.sharedSyncronizer)
    }
    
}