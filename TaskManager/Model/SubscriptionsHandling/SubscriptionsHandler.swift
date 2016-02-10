//
//  SubscriptionsHandler.swift
//  TaskManager
//
//  Created by CloudCraft on 2/1/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import Foundation
import CloudKit

class SubscriptionsHandler {
    
    static let sharedInstance = SubscriptionsHandler()
    
    private var syncing:Bool = false
    private lazy var subscriptions = [CKSubscription]()
     //MARK: - SubscriptionsHandling
    
    var isSyncing:Bool {
        return syncing
    }
    
    /// starts query to load all curren subscriptions
    func loadAll()
    {
        syncing = true
        
        guard let cloudKitHandler = anAppDelegate()?.cloudKitHandler else
        {
            syncing = false
            return
        }
        
        cloudKitHandler.queryAllSubscriptions { [unowned self] (subscriptions) -> () in
            
            guard let result = subscriptions else
            {
                self.syncing = false
                return
            }
            
            self.subscriptions = result.sort(){ (subscr1, subscr2) -> Bool in
                return subscr1.subscriptionID < subscr2.subscriptionID
            }
            
            self.syncing = false
        }
    }
    
    func deleteAll()
    {
        guard let cloudKitHandler = anAppDelegate()?.cloudKitHandler else {
            return
        }
        
        guard !subscriptions.isEmpty else {
            return
        }
        
        var strings = [String]()
        
        for aSubsc in subscriptions {
            strings.append(aSubsc.subscriptionID)
        }
        
        syncing = true
        
        cloudKitHandler.deleteSubscriptions(strings) {[unowned self] (deletedIDs) -> () in
            if let deleted = deletedIDs {
                
                let deletedCount = deleted.count
                
                if deletedCount == self.subscriptions.count {
                    self.subscriptions.removeAll()
                    print("\n deleted all subscriptions... OK \n")
                }
                else{
                    print("\n deleted only \(deletedCount) of \(self.subscriptions.count) subscriptions \n")
                    
                    self.subscriptions = self.subscriptions.filter(){ (subsc) -> Bool in
                        return  !deleted.contains(subsc.subscriptionID)
                    }
                }
            }
            
            self.syncing = false
        }
    }
    
    func subscriptionsForBoard(boardId:String) -> [CKSubscription]
    {
        //TODO: dfkjnf kjasdflh
        return[CKSubscription]()
    }
    
    func subscriptionsForTask(taskId:String) -> [CKSubscription]
    {
        //TODO: -dfsf  bdfs
        return [CKSubscription]()
    }
    
    func deleteSingle(subscription:CKSubscription)
    {
        guard let cloudKitHandler = anAppDelegate()?.cloudKitHandler else
        {
            return
        }
        
        syncing = true
        
        cloudKitHandler.deleteSubscriptions([subscription.subscriptionID]) {[unowned self] (deletedIDs) -> () in
            if let index = self.subscriptions.indexOf(subscription)
            {
                self.subscriptions.removeAtIndex(index)
            }
            self.syncing = false
        }
    }
    
    func deleteMany(subscriptions:[CKSubscription])
    {
        guard let cloudKitHandler = anAppDelegate()?.cloudKitHandler else {
            return
        }
        
        guard subscriptions.isEmpty else {
            return
        }
        
        syncing = true
        
        var subscriptionIDs = [String]()
        for aSubscr in subscriptions{
            subscriptionIDs.append(aSubscr.subscriptionID)
        }
        
        cloudKitHandler.deleteSubscriptions(subscriptionIDs) {[unowned self] (deletedIDs) in
            
            if let deletedSubscriptionIDs = deletedIDs where !deletedSubscriptionIDs.isEmpty{
                self.removeLocalySavedSubscriptionsByIDs(deletedSubscriptionIDs)
            }
            self.syncing = false
        }
    }
    
    func addSingle(subscription:CKSubscription)
    {
        //TODO: - asdd fd
    }
    
    func addMany(subscriptions:[CKSubscription])
    {
        //TODO: - adff sdfd sa
    }
    
    
    private func removeLocalySavedSubscriptionsByIDs(var subscriptionIDs:[String]) {
        if subscriptionIDs.isEmpty
        {
            return
        }
        
        repeat{
            let firstId = subscriptionIDs.removeFirst()
            let filtered = self.subscriptions.filter(){ $0.subscriptionID != firstId }
            
            self.subscriptions = filtered
            
        }
        while !subscriptionIDs.isEmpty
    }
    
    
    //MARK: - Task subscriptions
    func addTaskChangedSubscriptionFor(recordId:String) {
        self.addTaskSubscription(recordId, objectType: CloudRecordTypes.Task, changeType: CKSubscriptionOptions.FiresOnRecordUpdate)
    }
    
    func addTaskDeletedSubscriptionFor(recordId:String) {
        
    }
    
    private func addTaskSubscription(recordID:String, objectType:CloudRecordTypes, changeType:CKSubscriptionOptions) {
        
        guard let _ = anAppDelegate()?.cloudKitHandler.publicCurrentUser?.recordID.recordName else
        {
            return
        }
        
        //let subscrID = recordID + currentUserID
        
        let predicate = NSPredicate(format: "recordID = %@", CKRecordID(recordName: recordID))
        let desiredKeys = [TitleStringKey, DetailsStringKey, CurrentOwnerStringKey, DateFinishedDateKey, DateTakenDateKey]
        let notifInfo = CKNotificationInfo()
        notifInfo.desiredKeys = desiredKeys
        
        let aSubscription = CKSubscription(recordType: objectType.rawValue, predicate: predicate/*, subscriptionID:subscrID */,options: changeType)
        aSubscription.notificationInfo = notifInfo
        //let type = aSubscription.subscriptionType
        
        
        syncing = true
        anAppDelegate()!.cloudKitHandler.submitSubscription(aSubscription) { [unowned self] (subscription, errorMessage) -> () in
            if let successSubscription = subscription
            {
                self.subscriptions.append(successSubscription)
            }
            else if let errorMsg = errorMessage
            {
                print("\n - Could not submit new subscription: \(errorMsg) \n")
            }
            self.syncing = false
        }
    }
    
    
    
    
}