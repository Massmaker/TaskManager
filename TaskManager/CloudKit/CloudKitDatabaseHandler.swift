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
    
    private var currentUserRecord:CKRecord?
    
    var currentUserPhoneNumber:String?{
        didSet{
            print("new phone number is set in cloudKitDatabaseHandler : \n \(currentUserPhoneNumber)")
            print(currentUserPhoneNumber)
        }
    }
    
    private lazy var pCurrentUserAvatar = UIImage()
    
    var publicCurrentUser:CKRecord?{
        return self.currentUserRecord
    }
    
    var currentUserAvatar:UIImage?{
        
        if let recordID = self.currentUserRecord?.recordID.recordName
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

    func resetCurrentUserAvatarImage(){
        pCurrentUserAvatar = UIImage()
    }
   
    //MARK: - 
    func deleteCurrentUserRecord()
    {
        self.currentUserRecord = nil
    }
    
   
    //MARK: -
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
        guard let _ = anAppDelegate()?.cloudKitHandler.publicCurrentUser else{
            completion(subscriptions: nil)
            return
        }
        
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
        self.publicDB.fetchAllSubscriptionsWithCompletionHandler { (subs, error) in
            let result = CloudKitErrorParser.handleCloudKitErrorAs(error)
            switch result
            {
            case .Success:
                if let subsiptions = subs where !subsiptions.isEmpty
                {
                    completion(subscriptions: subsiptions)
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
        //self.publicDB.addOperation(allSubsOp)
    }
    
    
    func querySubscriptionsByIDs(subscriptionIDs:[String], completion:( (subscriptions:[String:CKSubscription]?, errors:[String:NSError]?)->()) ){
        
        let op = CKFetchSubscriptionsOperation()
        op.subscriptionIDs = subscriptionIDs
        op.qualityOfService = .Utility
        
        op.fetchSubscriptionCompletionBlock = {(fetchedDict, error) in
            if let errorFetching = error
            {
                
            }
            else
            {
                completion(subscriptions: fetchedDict!, errors: nil)
            }
        }
        
        self.publicDB.addOperation(op)
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
    
    func submitSubscription(subscription:CKSubscription, completion:((subscription:CKSubscription?, errorMessage:String?, error:NSError?)->()) )
    {
        networkingIndicator(true)
        
        let completionBlock : (([CKSubscription]?, [String]?, NSError?) -> Void) = {newSubscriptions, _ , error in
            let result = CloudKitErrorParser.handleCloudKitErrorAs(error, retryAttempt: 10.0)
            switch result {
            case .Success:
                if let savedSubscriptions = newSubscriptions where !savedSubscriptions.isEmpty
                {
                    completion(subscription:savedSubscriptions.first!, errorMessage:nil , error:error)
                }
                else
                {
                    completion(subscription: nil, errorMessage: "Empty succeeded subscriptions", error:error)
                }
            
            case .Fail(let message):
                completion(subscription: nil, errorMessage: message, error:error)
            
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
                    completion(subscription: nil, errorMessage: "failed to subscript after timeout", error: error)
                }
            
            case .RecoverableError:
                completion(subscription: nil, errorMessage: "Try later", error: error)
            }
            
            networkingIndicator(false)
        }
        
        let modifyToInsertOp = CKModifySubscriptionsOperation(subscriptionsToSave: [subscription], subscriptionIDsToDelete: nil)
        modifyToInsertOp.qualityOfService = .Utility
        modifyToInsertOp.modifySubscriptionsCompletionBlock = completionBlock
        
        networkingIndicator(true)
        publicDB.addOperation(modifyToInsertOp)
    }
    
    func submitManySubscriptions(subscriptions:[CKSubscription], completion:((succeeded:[CKSubscription], failed:[CKSubscription], error:NSError?)->()))
    {
        networkingIndicator(true)
        
        let completionBlock : (([CKSubscription]?, [String]?, NSError?) -> Void) = {newSubscriptions, _ , error in
            
            var succeeded = [CKSubscription]()
            var failed = [CKSubscription]()
            
            if let new = newSubscriptions
            {
                succeeded += new
            }
            
            if let error = error{
                
                let result = CloudKitErrorParser.handleCloudKitErrorAs(error)
                switch result
                {
                case .Retry(let afterSeconds):
                
                    if afterSeconds <= 20 {
                        
                        let timeout:dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * afterSeconds))
                        let bgQueue = dispatch_queue_create("Retry_Subscriptions_queue", DISPATCH_QUEUE_SERIAL)
                        dispatch_after(timeout,bgQueue) { () -> Void in
                            self.submitManySubscriptions(subscriptions, completion: completion)
                        }
                    }
                    else{
                        completion(succeeded: succeeded, failed: subscriptions, error: error)
                    }
                case .RecoverableError: //partial failure
                    let ckCode =  CKErrorCode(rawValue: error.code)!
                    switch ckCode
                    {
                    case .PartialFailure:
                        if let info = error.userInfo[CKPartialErrorsByItemIDKey] as? [NSObject:AnyObject] {
                            print("\n ---- Failed subscriptions:")
                            for (key, value) in info{
                                print("\n ----")
                                print(key)
                                print(value)
                                
                            }
                        }
                    default:
                        break
                    }
                    completion(succeeded: [CKSubscription](), failed: subscriptions, error: error)
                default:
                    completion(succeeded: succeeded, failed: subscriptions, error: error)
                }
            }
            else{
               completion(succeeded: succeeded, failed: failed, error: nil) //success
            }
            networkingIndicator(false)
        }
        
        let modifyToInsertOp = CKModifySubscriptionsOperation(subscriptionsToSave: subscriptions, subscriptionIDsToDelete: nil)
        modifyToInsertOp.qualityOfService = .Utility
        modifyToInsertOp.modifySubscriptionsCompletionBlock = completionBlock
        
        networkingIndicator(true)
        publicDB.addOperation(modifyToInsertOp)
        
        
        //
//        publicDB.saveSubscription(subscriptions.first!) { (saved, error) -> Void in
//            if let subscription = saved{
//                
//            }
//            else if let errorSubs = error{
//                
//            }
//        }
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
                    if afterSeconds > 0 && afterSeconds < 20.0 {
                        let timeout:dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * afterSeconds))
                        let semaphore = dispatch_semaphore_create(0)
                        dispatch_semaphore_wait(semaphore, timeout)
                        self?.queryForLoggedUserByPhoneNumber(phoneNumber, completion: completion)
                    }else{
                        completion(currentUserRecord: nil, error: nil)
                }
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
                    //print(errorResult)
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
        findOperation.perRecordCompletionBlock = {record, recordId, error in
            if let _ = record
            {
                print("  --  found user: \(record!.recordID.recordName)")
            }
        }
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
        
        let predicate = NSPredicate(format: "%K = %@", BoardCreatorIDKey, user.recordID.recordName)
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
    
    func editMany(boards:[Board], completion:((edited:[CKRecord]?, deleted:[CKRecordID]?, error:NSError?)->()))
    {
        if boards.isEmpty
        {
            completion(edited: nil, deleted:nil,  error: nil)
            return
        }
        
        var boardRecordsToSave:[CKRecord]? = [CKRecord]()
        var boardIDsToDelete:[CKRecordID]? = [CKRecordID]()
        
        for aBoard in boards
        {
            do{
                let record = try createBoardRecordFrom(aBoard)
                if aBoard.toBeDeleted
                {
                    boardIDsToDelete?.append(record.recordID)
                }
                else
                {
                    boardRecordsToSave?.append(record)
                }
            }
            catch{
                continue
            }
        }
        
        if boardIDsToDelete!.isEmpty
        {
            boardIDsToDelete = nil
        }
        if boardRecordsToSave!.isEmpty
        {
            boardRecordsToSave = nil
        }
        
        
        if boardIDsToDelete == nil && boardRecordsToSave == nil
        {
            completion(edited: nil, deleted:nil, error: nil)
            return
        }
        
        print("\n - will edit boards: \(boardRecordsToSave?.count)")
        print("\n - will deleteBoards: \(boardIDsToDelete?.count)")
        
        let editOperation = CKModifyRecordsOperation(recordsToSave: boardRecordsToSave, recordIDsToDelete: boardIDsToDelete)
        editOperation.qualityOfService = .Utility
        editOperation.savePolicy = .ChangedKeys
        editOperation.modifyRecordsCompletionBlock = completion
        
        self.publicDB.addOperation(editOperation)
        
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
    
    func deleteBoards(boardIDs:[CKRecordID], withPriority priority:NSQualityOfService, completion:((deletedIDs:[CKRecordID]?, error:NSError?)->()))
    {
        guard !boardIDs.isEmpty else
        {
            completion(deletedIDs: boardIDs, error: nil)
            return
        }
        
        let batchDeleteOp = CKModifyRecordsOperation()
        batchDeleteOp.recordIDsToDelete = boardIDs
        batchDeleteOp.qualityOfService = priority
        batchDeleteOp.savePolicy = .ChangedKeys
        
        batchDeleteOp.modifyRecordsCompletionBlock = { _ , deletedBoardIDs, error in
            completion(deletedIDs: deletedBoardIDs, error: error)
        }
        
        publicDB.addOperation(batchDeleteOp)
    }
    
    /**
     postpones an CKFetchRecordsOperation in public database
     - parameter recordID: a record Id to fetch CKRecord object
     - parameter qualityOfService: If this parameter is not set, - default value is NSQualityOfService.Background
     - parameter completion: completion handler with found record or error
     */
    func findRecordWithID(recordID:CKRecordID, qualityOfService:NSQualityOfService = .Background, completion:((record:CKRecord?, error:NSError?)->()))
    {
        let fetchSingleRecordOp = CKFetchRecordsOperation(recordIDs: [recordID])
        fetchSingleRecordOp.qualityOfService = qualityOfService
        
        
        ///use here `perRecord` completion block instead of `fetchRecordsCompletionBlock` is because we fetch single record
        fetchSingleRecordOp.perRecordCompletionBlock = { record, recordId, error in
            if let record = record{
                completion(record: record, error: nil)
            }
            else if let anError = error{
                print("\n Error fetching single record by recordID: \n recordID: \(recordID)\n\(anError)")
                completion(record: nil, error: anError)
            }
        }
        
        self.publicDB.addOperation(fetchSingleRecordOp)
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
            
            record[TitleStringKey] = editing[TitleStringKey]
            record[DetailsStringKey] = editing[DetailsStringKey]
            record[CurrentOwnerStringKey] = editing[CurrentOwnerStringKey]
            record[DateTakenDateKey] = editing[DateTakenDateKey]
            record[DateFinishedDateKey] = editing[DateFinishedDateKey]
            
            self?.publicDB.saveRecord(record) { (savedRecord, saveError)  in
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
    
    
    /**
     - Parameter priority: default value is .Utility
     */
    func editManyTasks(records:[CKRecord], priority:NSQualityOfService = .Utility, completion:((edited:[CKRecord], failed:[CKRecordID]?, error:NSError?) -> () ) ){
        
        if records.isEmpty{
            completion(edited: records, failed: nil, error: nil)
           return
        }
        
        var succeededRecords = [CKRecord]()
        
        let editOp = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
        editOp.qualityOfService = priority
        
        editOp.perRecordCompletionBlock = {record, error in
            if let _ = record{
                succeededRecords.append(record!)
            }
        }
        
        editOp.modifyRecordsCompletionBlock = {records, errorIDs, error in
            completion(edited: succeededRecords, failed: errorIDs, error: error)
        }
        
        publicDB.addOperation(editOp)
    }
    
    func deleteTasks(recordIDs:[String], completion:((deletedIDs:[String]?, deletionError:NSError?)->())) -> Bool
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
                    var recordIDs = [String]()
                    for aRecId in deletedIds
                    {
                        recordIDs.append(aRecId.recordName)
                    }
                    completion(deletedIDs: recordIDs, deletionError: error)
                }
                else
                {
                    completion(deletedIDs: nil, deletionError: error)
                }
            }
            
            deleteOp.modifyRecordsCompletionBlock = completionBlock
            
            lvPubliDB.addOperation(deleteOp)
        }
        
        self.privateOperationQueue.addOperation(bgQueueDeleteOperation)
        
        return true
    }
    
    func findTasksByTaskIDs(taskIDs:[CKRecordID], qualityOfService:NSQualityOfService = .Background, completion:((tasks:[CKRecord], error:NSError?)->())){
        guard !taskIDs.isEmpty else{
            completion(tasks: [CKRecord](), error: nil)
            return
        }
        
        let fetchTaskRecordsOp = CKFetchRecordsOperation(recordIDs: taskIDs)
        fetchTaskRecordsOp.qualityOfService = qualityOfService
        
        fetchTaskRecordsOp.fetchRecordsCompletionBlock = {recordsDict, error in
            if let info = recordsDict{
                if info.isEmpty{
                    completion(tasks: [CKRecord](), error: nil)
                    return
                }
                
                var toReturn = [CKRecord]()
                for ( _ , record) in info{
                    toReturn.append(record)
                }
                
                completion(tasks: toReturn, error: error)
            }
            else if let anError = error{
                completion(tasks: [CKRecord](), error: anError)
            }
        }
        
        self.publicDB.addOperation(fetchTaskRecordsOp)
    }
    
}//class end


//MARK: - Helpers

func updateOwnerForTaskRecord(inout record:CKRecord, ownerId:String?, dates:(taken:NSDate?, finished:NSDate?))
{
    record[CurrentOwnerStringKey] = ownerId
    record[DateTakenDateKey] = dates.0
    record[DateFinishedDateKey] = dates.1
}

