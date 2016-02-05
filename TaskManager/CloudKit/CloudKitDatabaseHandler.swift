//
//  CloudKitDatabaseHandler.swift
//  TaskCloud
//
//  Created by CloudCraft on 1/11/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import Foundation
import CloudKit
import UIKit

let noUserError = NSError(domain: "No Logged User", code: -1, userInfo: [NSLocalizedDescriptionKey:"No current user found"])
let unknownError = NSError(domain: "UnknownError", code: -16, userInfo: [NSLocalizedDescriptionKey:"No error from CloudKit  recieved"])

class CloudKitDatabaseHandler{
    
    private let container: CKContainer
    private let publicDB:  CKDatabase
    private let privateDB: CKDatabase
    
    private var user:CurrentUser?
    var currentUser:CurrentUser? {
        if let user = self.user
        {
            return user
        }
        return nil
    }
    
    private var currentUserRecord:CKRecord? {
        didSet {
            if let record = currentUserRecord, let currentUser = anAppDelegate()?.coreDatahandler?.getCurrentUserById(record.recordID.recordName)
            {
                self.user = currentUser
            }
            else
            {
                self.user = nil
            }
        }
    }
    
    var currentUserPhoneNumber:String?{
        didSet{
            print("new phone number is set in cloudKitDatabaseHandler")
        }
    }
    
    private lazy var pCurrentUserAvatar = UIImage()
    
    var currentUserAvatar:UIImage?{
        
        if let recordID = anAppDelegate()?.cloudKitHandler.currentUserPhoneNumber
        {
            if self.pCurrentUserAvatar.size == CGSizeZero
            {
                if let image = DocumentsFolderFileHandler().getAvatarImageFromDocumentsForUserId(recordID)
                {
                    self.pCurrentUserAvatar = image
                    return self.pCurrentUserAvatar
                }
                return nil
            }
            else
            {
                return self.pCurrentUserAvatar
            }
        }
        return nil
    }
    
    lazy var privateOperationQueue = NSOperationQueue()
    
    init() {
        self.container = CKContainer.defaultContainer()
        self.publicDB = container.publicCloudDatabase
        self.privateDB = container.privateCloudDatabase
    }

    var publicCurrentUser:CKRecord?{
        return self.currentUserRecord
    }
    
    func checkAccountStatus(completion:(status:CKAccountStatus, error:NSError?)->())
    {
        self.container.accountStatusWithCompletionHandler { (accStatus, lvError) in
            if let anError = lvError
            {
                print(anError)
                completion(status: accStatus, error:  anError)
            }
            else
            {
                completion(status: accStatus, error: nil)
            }
        }
    }
    
    /**
     calls **statusForApplicationPermission: completion:** to check *UserDiscoverability*
     */
    func checkPermissions(completion:(status:CKApplicationPermissionStatus, error:NSError?)->())
    {
        self.container.statusForApplicationPermission(CKApplicationPermissions.UserDiscoverability) { (permissionStatus, error) in
            if let anError = error
            {
                completion(status:permissionStatus, error: anError)
            }
            else
            {
                completion(status: permissionStatus, error: nil)
            }
        }
    }
    //MARK: - Subscriptions
    func queryAllSubscriptions(completion:((subscriptions:[CKSubscription]?)->()))
    {
        let fetchCompletionBlock:(([String : CKSubscription]?, NSError?) -> Void) = {subscriptions, error in
            let result = CloudKitErrorParser.handleCloudKitErrorAs(error)
            switch result
            {
                case .Success:
                    if let subs = subscriptions where !subs.isEmpty
                    {
                        var toReturn = [CKSubscription]()
                        for (_,value) in subs
                        {
                            toReturn.append(value)
                        }
                        completion(subscriptions: toReturn)
                    }
                    else
                    {
                        completion(subscriptions: nil)
                    }
                case .Retry(let afterSeconds):
                    if afterSeconds < 5
                    {
                        print("retrying to fetch all subscriptions")
                        let timeout:dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * afterSeconds))
                        dispatch_after(timeout, dispatch_get_main_queue()){ () -> Void in
                            self.queryAllSubscriptions(completion)
                        }
                    }
                    else
                    {
                        completion(subscriptions: nil)
                    }
                case .RecoverableError:
                    completion(subscriptions: nil)
                case .Fail(_):
                    completion(subscriptions: nil)
            }
        }
        
        let allSubsOp = CKFetchSubscriptionsOperation.fetchAllSubscriptionsOperation()
        allSubsOp.qualityOfService = .Utility
        allSubsOp.fetchSubscriptionCompletionBlock = fetchCompletionBlock
        
        self.publicDB.addOperation(allSubsOp)
    }
    
    func deleteSubscriptions(toDelete:[String], completion:((deletedIDs:[String]?)->()))
    {
        if toDelete.isEmpty
        {
            completion(deletedIDs: nil)
            return
        }
        
        let completionBlock : (([CKSubscription]?, [String]?, NSError?) -> Void) = {_, deletedIDs, error in
            if let successDeleted = deletedIDs
            {
                completion(deletedIDs: successDeleted)
                return
            }
            
            completion(deletedIDs: nil)
        }
        
        let modifyToDeleteOp = CKModifySubscriptionsOperation(subscriptionsToSave: nil, subscriptionIDsToDelete: toDelete)
        modifyToDeleteOp.qualityOfService = .Utility
        modifyToDeleteOp.modifySubscriptionsCompletionBlock = completionBlock
        
        self.publicDB.addOperation(modifyToDeleteOp)
    }
    
    func submitSubscription(subscription:CKSubscription, completion:((subscription:CKSubscription?, errorMessage:String?)->()) )
    {
        networkingIndicator(true)
//        publicDB.saveSubscription(subscription) { (savedSubscription, error) -> Void in
//            
//            let result = CloudKitErrorParser.handleCloudKitErrorAs(error, retryAttempt: 10.0)
//            switch result
//            {
//            case .Success:
//                if let savedSubscription = savedSubscription
//                {
//                    completion(subscription:savedSubscription, errorMessage:nil)
//                }
//                else
//                {
//                    completion(subscription: nil, errorMessage: "Empty succeeded subscriptions")
//                }
//                
//            case .Fail(let message):
//                completion(subscription: nil, errorMessage: message)
//                
//            case .Retry(let afterSeconds):
//                
//                if afterSeconds < 10
//                {
//                    let timeout:dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * afterSeconds))
//                    dispatch_after(timeout, dispatch_get_main_queue()){ () -> Void in
//                        self.submitSubscription(subscription, completion: completion)
//                    }
//                }
//                else
//                {
//                    completion(subscription: nil, errorMessage: "failed to subscript after timeout")
//                }
//                
//            case .RecoverableError:
//                completion(subscription: nil, errorMessage: "Try later")
//            }
//
//            
//            networkingIndicator(false)
//        }
//        
//        return
        
        let completionBlock : (([CKSubscription]?, [String]?, NSError?) -> Void) = {newSubscriptions, _ , error in
            let result = CloudKitErrorParser.handleCloudKitErrorAs(error, retryAttempt: 10.0)
            switch result
            {
                case .Success:
                    if let savedSubscriptions = newSubscriptions where !savedSubscriptions.isEmpty
                    {
                        completion(subscription:savedSubscriptions.first!, errorMessage:nil)
                    }
                    else
                    {
                        completion(subscription: nil, errorMessage: "Empty succeeded subscriptions")
                    }
                
                case .Fail(let message):
                    completion(subscription: nil, errorMessage: message)
                
                case .Retry(let afterSeconds):
                 
                    if afterSeconds < 10
                    {
                        let timeout:dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * afterSeconds))
                        dispatch_after(timeout, dispatch_get_main_queue()){ () -> Void in
                            self.submitSubscription(subscription, completion: completion)
                        }
                    }
                    else
                    {
                        completion(subscription: nil, errorMessage: "failed to subscript after timeout")
                    }
                
                case .RecoverableError:
                    completion(subscription: nil, errorMessage: "Try later")
            }
            networkingIndicator(false)
        }
        
        let modifyToInsertOp = CKModifySubscriptionsOperation(subscriptionsToSave: [subscription], subscriptionIDsToDelete: nil)
        modifyToInsertOp.qualityOfService = .Utility
        modifyToInsertOp.modifySubscriptionsCompletionBlock = completionBlock
        
        networkingIndicator(true)
        publicDB.addOperation(modifyToInsertOp)
    }
    
    //MARK: - Notifications
    func sendNotidicationsRead(ids:[CKNotificationID], completion:((marked:[CKNotificationID], error:NSError?)->()) )
    {
        if ids.isEmpty
        {
            completion(marked: ids, error: nil)
            return
        }
        
        let completionBlock:(([CKNotificationID]?, NSError?) -> Void) = {succeededIDs, error in
            networkingIndicator(false)
            let result = CloudKitErrorParser.handleCloudKitErrorAs(error)
            switch result
            {
            case .Success:
                if let noteIDs = succeededIDs where noteIDs.isEmpty
                {
                    completion(marked: noteIDs, error: nil)
                }
                else
                {
                    completion(marked: [CKNotificationID](), error: nil)
                }
            default:
                completion(marked: [CKNotificationID](), error: error)
            }
        }
        
        let didReadOperation = CKMarkNotificationsReadOperation(notificationIDsToMarkRead: ids)
        didReadOperation.qualityOfService = .Utility
        didReadOperation.markNotificationsReadCompletionBlock = completionBlock
        
        networkingIndicator(true)
        NSOperationQueue().addOperation(didReadOperation)
    }
    
    //MARK: - syncing stuff
    func requestChanges( completion:(notifications:[CKQueryNotification])->() )
    {
        print("\n Cloud Kit handler requestChanges.....")
        
        var totalNotesRecieved = [CKQueryNotification]()
        
        var proceed = false
        
        repeat
        {
            let result = self.requestMoreChanges()
            proceed = result.moreComing
            
            if let notifs = result.changes
            {
                totalNotesRecieved += notifs
            }
        }
        while proceed == true
        
        completion(notifications: totalNotesRecieved)
    }
    
    private func requestMoreChanges() -> (moreComing:Bool, changes:[CKQueryNotification]?)
    {
        var optionalToken:CKServerChangeToken?
        
        if let optionalTokenData = UserDefaultsManager.getCloudKitChangeToken(), let token = NSKeyedUnarchiver.unarchiveObjectWithData(optionalTokenData) as? CKServerChangeToken
        {
            optionalToken = token
        }
        
        var optionalChangeNotifications:[CKQueryNotification]?
        
        let changesOp = CKFetchNotificationChangesOperation(previousServerChangeToken: optionalToken)
        
        var result:(moreComing:Bool, changes:[CKQueryNotification]?) = (moreComing:false, changes:nil)
        
        let perNoteCompletionBlock:((CKNotification) -> ()) = { note in
            if let queryNote = note as? CKQueryNotification
            {
                if var optionalChangeNotifications = optionalChangeNotifications
                {
                    optionalChangeNotifications.append(queryNote)
                }
                else
                {
                    optionalChangeNotifications = [CKQueryNotification]()
                    optionalChangeNotifications!.append(queryNote)
                }
            }
            else
            {
                
            }
        }
        
        let totalCompletion:((CKServerChangeToken?, NSError?) ->()) = {changesToken, error in
            
            
            if changesOp.moreComing{
                result.moreComing = true
            }
            
            if let newToken = changesToken
            {
                let tokenData = NSKeyedArchiver.archivedDataWithRootObject(newToken)
                UserDefaultsManager.setCloudKitChangeToken(tokenData)
            }
            print("Cloud kit handler fetchNotificationChangesCompletionBlock  fired\n")
        }
        
        
        changesOp.fetchNotificationChangesCompletionBlock = totalCompletion
        changesOp.notificationChangedBlock = perNoteCompletionBlock
        changesOp.qualityOfService = .UserInitiated
        
        privateOperationQueue.addOperations([changesOp], waitUntilFinished: true)
        print("Cloud kit handler did finish requesting changes\n")
        
        return result
    }
    
    //MARK: - current User
    func queryForLoggedUserByPhoneNumber(phoneNumber:String, completion:((currentUserRecord:CKRecord?, error:NSError?)->()))
    {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    
        let userRecordID = CKRecordID(recordName: phoneNumber)
        publicDB.fetchRecordWithID(userRecordID) {[weak self] (foundUser, errorFetch) -> Void in
            
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            
            let result = CloudKitErrorParser.handleCloudKitErrorAs(errorFetch, retryAttempt: 2.0)
            switch result
            {
                case .Retry(let afterSeconds):
                    print("Retrying to query existing user by phone number ID...")
                    print("Retry interval: \(afterSeconds) \n")
                case .Fail(let message):
                    if let _ = message
                    {
                        completion(currentUserRecord: nil, error: NSError(domain: "User Login Failure", code: -31, userInfo: [NSLocalizedFailureReasonErrorKey: message!]))
                    }
                    else
                    {
                        completion(currentUserRecord: nil, error: unknownError)
                    }
                case .RecoverableError:
                    completion(currentUserRecord: nil, error: unknownError)
                case .Success:
                    guard let existingUser = foundUser else
                    {
                        self?.currentUserRecord = nil
                        if let anError = errorFetch
                        {
                            //let ckMessageError = anError[CKErrorCode]
                            NSLog("- Error whine querying logged user by phone number:\n %@", anError.description)
                        }
                        else
                        {
                            completion(currentUserRecord: nil, error: unknownError)
                        }
                        return
                    }
                    //NSLog(" - CloudKitDatabaseHandler - Did found user in public DB: \n -recordId: %@\n -recordType: %@\n -phoneNumberField: %@\n", existingUser.recordID, existingUser.recordType, (existingUser["phoneID"] as? String) ?? "Not Found")
                    self?.currentUserRecord = existingUser
                    completion(currentUserRecord: existingUser, error: nil)
            }
        }
    }
    
    func insertNewPublicUserIntoCloudByPhoneNumber(phoneNumber:String, completion:((successUser:CKRecord?, error:NSError?)->()))
    {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        let userRecordId = CKRecordID(recordName: phoneNumber)
        let newRecord = CKRecord(recordType: "PublicUser", recordID: userRecordId)
        newRecord["phoneID"] = phoneNumber
        
        publicDB.saveRecord(newRecord) {[weak self] (userSaved, errorSaving) -> Void in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            
            if let anError = errorSaving
            {
                NSLog(" - Error while saving new PublicUser into iCloud:\n%@", anError)
                completion(successUser: nil, error: anError)
            }
            else if let user = userSaved
            {
                NSLog(" - Did save new PublicUser into iCloud with phone number: %@ ", phoneNumber)
                self?.currentUserRecord = user
                completion(successUser: user, error: nil)
            }
            else
            {
                NSLog(" - Did not recieve any saved user or error while \"saveRecord:\"  called")
                completion(successUser: nil, error: NSError(domain: "FetchNone", code: -14, userInfo: [NSLocalizedDescriptionKey:"Recieved empty response in completion block"]))
            }
        }
    }
    
    /**
     - Parameter phones: anarray of phone number strings to check for registered users
     - Parameter completion: completion handler after request finishes
     - Precondition: **phones** should not be empty, or the methow returns immediately with empty parameters
     */
    func startFetchingForRegisteredUsersByPhoneNumbers(phones:[String], completion:((foundNumbers:[String], error:NSError?)->()) )
    {
        if phones.isEmpty
        {
            completion(foundNumbers: [String](), error: nil)
            return
        }
        
        let completionBlock = { (recordInfo:[CKRecordID : CKRecord]?, error:NSError?) in
            
            let errorResult = CloudKitErrorParser.handleCloudKitErrorAs(error)
            switch errorResult
            {
                case .Success, .RecoverableError: //RecoverableError happens, when some PublicUser records found but not all
                    var numbersToReturn:[String]?
                    if let recInfo = recordInfo
                    {
                        var foundRecordIDs = [String]()
                        for ( _ , value) in recInfo
                        {
                            //print(key)
                            //print(":")
                            //print(value.recordID.recordName)
                            foundRecordIDs.append(value.recordID.recordName)
                        }
                        
                        numbersToReturn = foundRecordIDs
                    }
                    
                    if let _ = numbersToReturn
                    {//return emptyresponse
                        completion(foundNumbers: numbersToReturn!, error: nil)
                    }
                    else
                    {//return empty response
                        completion(foundNumbers: [String](), error: nil)
                    }                
                default:
                    print(errorResult)
                    completion(foundNumbers: [String()], error: error)
            }
        }
        
        var recordIDs = [CKRecordID]()
        for aPhone in phones
        {
            recordIDs.append( CKRecordID(recordName: aPhone) )
        }
        
        let findOperation = CKFetchRecordsOperation(recordIDs: recordIDs)
        
        findOperation.qualityOfService = .Utility

        findOperation.fetchRecordsCompletionBlock = completionBlock
        
        self.publicDB.addOperation(findOperation)
    }
    
    //MARK: - Boards
    func queryForBoardsByCurrentUser(completion:((boards:[CKRecord]?, error:NSError?)->()))
    {
        guard let user = self.publicCurrentUser else
        {
            completion(boards: nil, error: noUserError)
            return
        }
        
        let predicate = NSPredicate(format: "boardCreator = %@", user.recordID.recordName)
        let publicQuery = CKQuery(recordType: CloudRecordTypes.TaskBoard.rawValue, predicate: predicate)
        publicQuery.sortDescriptors = [NSSortDescriptor(key: "modificationDate", ascending: true)]
        
        publicDB.performQuery(publicQuery, inZoneWithID: nil) { (foundBoardRecords, queryError) -> Void in
            guard let error = queryError else
            {
                NSLog(" - Found user boards: %ld", foundBoardRecords!.count)
                completion(boards: foundBoardRecords, error: nil)
                return
            }
            NSLog(" - Error while querying user boards: \n%@", error.userInfo)
            completion(boards: nil, error: error)
        }
    }
    
    func queryForBoardsSharedWithMe(completion:((boards:[CKRecord]?, fetchError:NSError?)->()))
    {
        guard let user = self.publicCurrentUser else
        {
            completion(boards: nil, fetchError: noUserError)
            return
        }
        
        let predicate = NSPredicate(format: "SELF.participants CONTAINS %@", user.recordID.recordName)
        let publicQuery = CKQuery(recordType: CloudRecordTypes.TaskBoard.rawValue, predicate: predicate)
        publicQuery.sortDescriptors = [NSSortDescriptor(key: SortOrderIndexIntKey, ascending: true)]
        
        publicDB.performQuery(publicQuery, inZoneWithID: nil) { (sharedBoardRecords, fetchError) in
            let result = CloudKitErrorParser.handleCloudKitErrorAs(fetchError)
            switch result
            {
                case .Success, .RecoverableError:
                    completion(boards: sharedBoardRecords, fetchError: nil)
                case .Retry(let afterSeconds):
                    let timeout:dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * afterSeconds))
                    dispatch_after(timeout, dispatch_get_main_queue()) { _ in
                        self.queryForBoardsSharedWithMe(completion)
                    }
                case .Fail(let message):
                    completion(boards: nil, fetchError: NSError(domain: fetchError!.domain, code: fetchError!.code, userInfo: [NSLocalizedFailureReasonErrorKey:message ?? "no error reason"]))
                
            }
        }
    }
    
    func submitNewBoardWithInfo(boardInfo:Board, completion:((createdBoard:CKRecord?, error:NSError?)->())) -> Bool
    {
        guard let _ = publicCurrentUser else
        {
            return false
        }
     
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true

        do{
            
            let newBoardRecord = try createBoardRecordFrom(boardInfo)
            publicDB.saveRecord(newBoardRecord) { (savedNewBoard, saveError) -> Void in
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                
                guard let newBoard = savedNewBoard else
                {
                    if let anError = saveError
                    {
                        completion(createdBoard: nil, error: anError)
                    }
                    else
                    {
                        completion(createdBoard: nil, error:unknownError)
                    }
                    return
                }
                completion(createdBoard: newBoard, error: nil)
            }
            
            return true
        }
        catch
        {
            return false
        }
        
    }
    
    func editBoard(boardInfo:Board, completion:((editedRecord:CKRecord?, editError:NSError?)->())) -> Bool
    {
        guard let recordId = boardInfo.recordId else
        {
            return false
        }
    
        //fetch if there is existing board
        let recId = CKRecordID(recordName: recordId)
        publicDB.fetchRecordWithID(recId) {[unowned self] (foundRecord, error) -> Void in
            if let foundBoard = foundRecord
            {
                do{
                    let currentBoard = try createBoardRecordFrom(boardInfo)
                    //let boardToUpdate = foundBoard
                    foundBoard[SortOrderIndexIntKey] = NSNumber(integer: Int(boardInfo.sortOrder))
                    foundBoard[TitleStringKey] = boardInfo.title
                    foundBoard[DetailsStringKey] = boardInfo.details
                    foundBoard[BoardParticipantsKey] = currentBoard[BoardParticipantsKey]
                    foundBoard[BoardTasksReferenceListKey] = currentBoard[BoardTasksReferenceListKey]
                    print(" \n  - edited board participants: \((foundBoard[BoardParticipantsKey] as? [String])?.count) ")
                    
                    self.saveBoard(foundBoard) { (savedBoard, saveError) -> () in
                        completion(editedRecord: savedBoard, editError: saveError)
                    }
                }
                catch let boardRecordError {
                    completion(editedRecord: nil, editError: boardRecordError as NSError)
                }
                
            }
            else
            {
                self.submitNewBoardWithInfo(boardInfo) { (createdBoard, errorCreatingNewBoard) -> () in
                    completion(editedRecord: createdBoard, editError: errorCreatingNewBoard)
                }
            }
        }
        
        return true
    }
    
    func deleteBoardWithID(recordId:CKRecordID, completion:((deletedRecordId:CKRecordID?, error:NSError?)->()))
    {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        publicDB.deleteRecordWithID(recordId) { (deletedRecordId, deletionError) -> Void in
            
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            guard let dbError = deletionError else
            {
                NSLog(" - Deleted user Board SUCCESS")
                completion(deletedRecordId: deletedRecordId, error: nil)
                return
            }
            
            NSLog(" - Error while deleting user TaskBoard: \n%@", dbError.userInfo.description)
            completion(deletedRecordId: nil, error: dbError)
        }
    }
    
    func findBoardWithID(recordIDString:String, completion:((boardRecord:CKRecord?)->()))
    {
        
    }
    
    private func saveBoard(board:CKRecord, completionHandler:((savedBoard:CKRecord?, saveError:NSError?)->()))
    {
        self.publicDB.saveRecord(board) { (recordSaved, errorSaving) -> Void in
            completionHandler(savedBoard: recordSaved, saveError: errorSaving)
        }
    }
    
    //MARK: - Tasks
    func loadTasksForBoard(board:CKRecord, completion:((tasks:[CKRecord]?, error:ErrorType?)->())) -> Bool
    {
        guard let taskReferences = board[BoardTasksReferenceListKey] as? [CKReference] where !taskReferences.isEmpty else
        {
            return false
        }
        
        
        var taskRecordIDs = [CKRecordID]()
        for aReference in taskReferences
        {
            let recordId = aReference.recordID
            taskRecordIDs.append(recordId)
        }
        
        let fetchRecordsOp = CKFetchRecordsOperation(recordIDs: taskRecordIDs)

        fetchRecordsOp.qualityOfService = .UserInitiated
        
//        fetchRecordsOp.perRecordCompletionBlock = { record, recordId, error in
//            if let _ = record
//            {
//                print("fetched record per \(recordId!)")
//            }
//            else
//            {
//                print("error per \(recordId!) : \n \(error!)")
//            }
//        }
        
        fetchRecordsOp.fetchRecordsCompletionBlock = { (recordsDict, error) in
            if let fetchedTasks = recordsDict
            {
                var taskRecords = [CKRecord]()
                for ( _ , aTaskRec) in fetchedTasks
                {
                    taskRecords.append(aTaskRec)
                }
                completion(tasks: taskRecords, error: nil)
            }
            else if let error = error
            {
                let errorResult =  CloudKitErrorParser.handleCloudKitErrorAs(error)
                switch errorResult
                {
                case .Fail(let message):
                    print(message)
                default:break
                }
                completion(tasks: nil, error: error)
            }
        }
        
        self.publicDB.addOperation(fetchRecordsOp)

        return true
    }
    
    func submitTask(taskInfo:Task, completion:((taskRecord:CKRecord?, savingError:NSError?)->())) -> Bool
    {
        guard let user = self.currentUserRecord else
        {
            return false
        }
        
        if user.recordID.recordName != taskInfo.creator
        {
            return false
        }
        
        do{
            let newTaskRecord = try createTaskRecordFrom(taskInfo)
            
            publicDB.saveRecord(newTaskRecord) { (savedRecord, savingError) in
                if let record = savedRecord
                {
                    completion(taskRecord: record, savingError: nil)
                }
                else if let error = savingError
                {
                    NSLog(" - Error submitting new TASK record to iCloud: \n %@", error)
                    completion(taskRecord: nil, savingError: error)
                }
            }
        }
        catch{
            return false
        }
        
       return true
        
    }
    
    func editTask(taskRecord:CKRecord, completion:((editedRecord:CKRecord?, editError:NSError?)->()))
    {
        //0 declare editing workflow
        let editRecord:(record:CKRecord, editingInfo:CKRecord)->() = {[weak self] (let record:CKRecord, editing:CKRecord) in
            
            self?.publicDB.saveRecord(editing) { (savedRecord, saveError)  in
                completion(editedRecord: savedRecord, editError: saveError)
            }
        }
        
        //1 find record to edit
        let taskRecordId = taskRecord.recordID
        
        self.publicDB.fetchRecordWithID(taskRecordId) { (foundRecord, fetchError) in
            if let existingTaskRecord = foundRecord
            {
                //execute editing at position 0
                editRecord(record: existingTaskRecord, editingInfo: taskRecord)
            }
            else
            {   //execute saving new record into CloudKit
                self.publicDB.saveRecord(taskRecord) { (saved, errorSaving) -> Void in
                    completion(editedRecord: saved, editError: errorSaving)
                }
            }
        }
        
        //else
        //{
           // completion(editedRecord: nil, editError: NSError(domain: "TaskEditing", code: -2, userInfo: [NSLocalizedFailureReasonErrorKey:"Task recordID was not found", NSLocalizedDescriptionKey:"Could not edit task. Internal error."]))
        //}
    }
    
    func deleteTasks(recordIDs:[String], completion:((deletedCount:Int, deletionError:NSError?)->())) -> Bool
    {
        guard !recordIDs.isEmpty else
        {
            return false
        }
        
        let lvPubliDB = self.publicDB
        let bgQueueDeleteOperation = NSBlockOperation(){
            
            var taskRecordIDs = [CKRecordID]()
            for anID in recordIDs
            {
                let aRecordId = CKRecordID(recordName: anID)
                taskRecordIDs.append(aRecordId)
            }
            
            let deleteOp = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: taskRecordIDs)
            
            let completionBlock = { ( _:[CKRecord]?, deletedIDs:[CKRecordID]?, error:NSError?) in
                if let deletedIds = deletedIDs
                {
                    completion(deletedCount: deletedIds.count, deletionError: error)
                }
                else
                {
                    completion(deletedCount: -1, deletionError: error)
                }
            }
            
            deleteOp.modifyRecordsCompletionBlock = completionBlock
            
            lvPubliDB.addOperation(deleteOp)
        }
        
        self.privateOperationQueue.addOperation(bgQueueDeleteOperation)
        
        return true
    }
    
}//class end


//MARK: - Helpers

func updateOwnerForTaskRecord(inout record:CKRecord, ownerId:String?, dates:(taken:NSDate?, finished:NSDate?))
{
    record[CurrentOwnerStringKey] = ownerId
    record[DateTakenDateKey] = dates.0
    record[DateFinishedDateKey] = dates.1
}

