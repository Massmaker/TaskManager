//
//  SubscriptionsHandling.swift
//  TaskManager
//
//  Created by CloudCraft on 2/1/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//


import CloudKit

protocol SubscriptionsHandling {

    var isSyncing:Bool { get }
    
    func loadAll()
    func deleteAll()
    
    func subscriptionsForBoard(boardId:String) -> [CKSubscription]
    func subscriptionsForTask(taskId:String) -> [CKSubscription]
    
    func deleteSingle(subscription:CKSubscription)
    func deleteMany(subscriptions:[CKSubscription])
    
    func addSingle(subscription:CKSubscription)
    func addMany(subscriptions:[CKSubscription])
    
    func addSubscriptionFor(recordID:String, objectType:CloudRecordTypes, changeType:CKSubscriptionOptions)
}