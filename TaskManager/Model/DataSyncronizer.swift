//
//  DataSyncronizer.swift
//  TaskManager
//
//  Created by CloudCraft on 2/2/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

let DataSyncronizerDidStartSyncronyzingNotificationName = "DataSyncronizerDidStartSyncronizyngNotification"
let DataSyncronizerDidStopSyncronyzingNotificationName = "DataSyncronizerDidStopSyncronyzingNotification"

import UIKit
import CoreData
import CloudKit

class DataSyncronizer {
    
    static let sharedSyncronizer = DataSyncronizer()
    var isSyncing:Bool {
        return syncing
    }
    
    lazy var center = NSNotificationCenter.defaultCenter()
    
    private var syncing = false

    func requestForRemoteChanges() {
        
        guard let anAppDelegate  = anAppDelegate() else
        {
            return
        }
        
        objc_sync_enter(self)
        syncing = true
        objc_sync_exit(self)
        
        NSNotificationCenter.defaultCenter().postNotificationName(DataSyncronizerDidStartSyncronyzingNotificationName, object: DataSyncronizer.sharedSyncronizer)
        
        let group = dispatch_group_create()
        dispatch_group_enter(group)
        
        SubscriptionsHandler.sharedInstance.loadAll()
        
        anAppDelegate.cloudKitHandler.requestChanges { (notifications) -> () in
            
            if !notifications.isEmpty
            {
                NotificationsHandler.sharedInstance.handleNotes(notifications)
            }
            
            dispatch_group_leave(group)
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
        
        NSNotificationCenter.defaultCenter().postNotificationName(DataSyncronizerDidStartSyncronyzingNotificationName, object: DataSyncronizer.sharedSyncronizer)

        
        
        var boardRecordsToSave = [CKRecord]()
        
       
        let waiterGroup = dispatch_group_create()
      
        dispatch_group_enter(waiterGroup)
        anAppDelegate()?.cloudKitHandler.queryForBoardsByCurrentUser(){ (boards, error) -> () in
            if let boards = boards
            {
                boardRecordsToSave += boards
            }
            
            dispatch_group_leave(waiterGroup)
        }
        
        dispatch_group_enter(waiterGroup)
        anAppDelegate()?.cloudKitHandler.queryForBoardsSharedWithMe(){ (boards, fetchError) -> () in
            if let sharedBoards = boards{
                boardRecordsToSave += sharedBoards
            }
            
            dispatch_group_leave(waiterGroup)
        }
        
        
        
        let timeout:dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 40.0))
        
        dispatch_group_wait(waiterGroup, timeout)
       
        self.saveInMainThread(boardRecordsToSave){
            print("didLoad boards: \(boardRecordsToSave.count) ")
            
            objc_sync_enter(self)
            self.syncing = false
            objc_sync_exit(self)
            
            postNotificationInMainThread(DataSyncronizerDidStopSyncronyzingNotificationName, object: DataSyncronizer.sharedSyncronizer)
        }
    }
    
    func startSyncingTasksFor(board:Board)
    {
        if !self.syncing
        {
            objc_sync_enter(self)
            self.syncing = true
            objc_sync_exit(self)

            center.postNotificationName(DataSyncronizerDidStartSyncronyzingNotificationName, object: DataSyncronizer.sharedSyncronizer)
            
            var boardRecord = CKRecord(recordType: "TaskBoard")
            
            do{
                boardRecord = try createBoardRecordFrom(board)
            }
            catch{
                
                objc_sync_enter(self)
                self.syncing = false
                center.postNotificationName(DataSyncronizerDidStopSyncronyzingNotificationName, object: DataSyncronizer.sharedSyncronizer)
                objc_sync_exit(self)
                
                return
            }
            
            
            var taskRecords = [CKRecord]()
            
            let group = dispatch_group_create()
            let timeout30Sec = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 30.0))
            
            dispatch_group_enter(group)
            print("\n - tasks for board did start loading")
            let wait = anAppDelegate()!.cloudKitHandler.loadTasksForBoard(boardRecord) { (tasks, error) -> () in
                if let tasksRecs = tasks
                {
                    taskRecords = tasksRecs
                }
                print("\n - tasks for board did finish loading")
                dispatch_group_leave(group)
            }
            
            if !wait
            {
                dispatch_group_leave(group)
            }
            
            print("\n - waiting for tasks finished")
            dispatch_group_wait(group, timeout30Sec)
            print("\n - waited for tasks finished")
            
            
            dispatch_group_notify(group, dispatch_get_main_queue()) {[unowned self] in
                
                self.saveInMainThreadTasks(taskRecords, forBoard: board)
                objc_sync_enter(self)
                self.syncing = false
                objc_sync_exit(self)
                
                NSNotificationCenter.defaultCenter().postNotificationName(DataSyncronizerDidStopSyncronyzingNotificationName, object: DataSyncronizer.sharedSyncronizer)
            }
            
        }
    }
    
    private func saveInMainThread(records:[CKRecord], completion:(()->())? = nil)
    {
        guard let coreDataHandler = anAppDelegate()?.coreDatahandler else
        {
            completion?()
            return
        }
     
        dispatchMain(){
            for aRecord in records
            {
                do{
                    let _ = try coreDataHandler.createBoardFromRecord(aRecord)
                    //coreDataHandler.insert(boardToSaveToCoreData, saveImmediately: false)
                }
                catch{
                    
                }
            }
            
            let allBoards = coreDataHandler.allBoards(true)
            
//            if allBoards.count != records.count
//            {
                //fill recordIDs recieved from CloudKit
                var ckRecordIDs = Set<String>()
                for aRecord in records
                {
                    ckRecordIDs.insert(aRecord.recordID.recordName)
                }
                
                //fill current boardIDs in CoreData
                var boardRecordIDs = Set<String>()
                for aBoard in allBoards
                {
                    if let recId = aBoard.recordId
                    {
                        boardRecordIDs.insert(recId)
                    }
                    else
                    {
                        anAppDelegate()?.coreDatahandler?.deleteSingle(aBoard, deleteimmediately: true, saveImmediately: false)
                    }
                }
                
                let boardIdsToDeleteSet = boardRecordIDs.subtract(ckRecordIDs)
                
                if !boardRecordIDs.isEmpty
                {
                    //delete old boards info from local DB (also will delete tasks, connected to boards)
                    do{
                        try anAppDelegate()?.coreDatahandler?.deleteBoardsByIDs(Array(boardIdsToDeleteSet), saveImmediately: false)
                    }
                    catch let error{
                        assertionFailure("Could not perform boards cleanup after pulling from CloudKit: \nError:\n \(error)")
                    }
                }
//            }
            
            coreDataHandler.saveMainContext()
            
            completion?()
        }
    }
    
    private func saveInMainThreadTasks(tasks:[CKRecord], forBoard board:Board)
    {
        guard let coreDataHandler = anAppDelegate()?.coreDatahandler else
        {
            return
        }
        
        guard !tasks.isEmpty else{
            return
        }
        
        coreDataHandler.insertTaskRecords(tasks, forBoard: board, saveImmediately: false)
        coreDataHandler.saveMainContext()
    }
    
}