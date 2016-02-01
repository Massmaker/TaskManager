//
//  SubscriptionsHandler.swift
//  TaskManager
//
//  Created by CloudCraft on 2/1/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import Foundation
import CloudKit

class SubscriptionsHandler:SubscriptionsHandling {
    
    private var syncing:Bool = false
    
    var isSyncing:Bool {
        return syncing
    }
    
    
    //MARK: - SubscriptionsHandling
    func loadAll()
    {
        //TODO: dfkjnf kjasdflh
    }
    
    func deleteAll()
    {
        //TODO: dfkjnf kjasdflh
    }
    
    func subscriptionsForBoard(boardId:String) -> [CKSubscription]
    {
        //TODO: dfkjnf kjasdflh
        return[CKSubscription]()
    }
    
    func subscriptionsForTask(taskId:String) -> [CKSubscription]
    {//TODO: dfkjnf kjasdflh
        return [CKSubscription]()
    }
    
    func deleteSingle(subscription:CKSubscription)
    {
        //TODO: dfkjnf kjasdflh
    }
    
    func deleteMany(subscriptions:[CKSubscription])
    {
        //TODO: - fdsg g  f
    }
    
    func addSingle(subscription:CKSubscription)
    {
        //TODO: - asdd fd
    }
    
    func addMany(subscriptions:[CKSubscription])
    {
        //TODO: - adff sdfd sa
    }
}