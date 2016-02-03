//
//  CoreDataManager.swift
//  TaskManager
//
//  Created by CloudCraft on 1/26/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import CoreData
import CloudKit

class CoreDataManager
{
    private let mainQueueManagedObjectContext:NSManagedObjectContext
    private let persistentStoreCoordinator:NSPersistentStoreCoordinator
    
    //MARK: - Initialization stuff
    class func getManagedObjectModel() -> NSManagedObjectModel?
    {
        guard let dataModelUrl = NSBundle.mainBundle().URLForResource("TasksHandlerDataModel", withExtension: "momd") else{
            return nil
        }
        
        if let dataModel = NSManagedObjectModel(contentsOfURL:dataModelUrl)
        {
            return dataModel
        }
        
        return nil
    }
    
    class func getPersistentStoreCoordinatorForModel(model:NSManagedObjectModel) throws -> NSPersistentStoreCoordinator?
    {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        let aFileHandler = DocumentsFolderFileHandler()
        
        let dbURL = aFileHandler.documentsDirectoryUrl().URLByAppendingPathComponent("TaskManager.sqlite")
        
        do
        {
            let mOptions = [NSMigratePersistentStoresAutomaticallyOption: true,
                NSInferMappingModelAutomaticallyOption: true]
            let _ =  try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: dbURL, options: mOptions)
            
            return coordinator
        }
        catch let error
        {
            print(error)
            throw error
        }
    }
    
    init(storeCoordinator:NSPersistentStoreCoordinator, completion:((Bool)->())?)
    {
        self.persistentStoreCoordinator = storeCoordinator
        self.mainQueueManagedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        self.mainQueueManagedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator
        let timeout:dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 0.2))
        dispatch_after(timeout, dispatch_get_main_queue(), { () -> Void in
             completion?(true)
        })
       
    }
    //MARK: - 
    func saveMainContext()
    {
        let context = self.mainQueueManagedObjectContext
        context.performBlockAndWait(){
            if context.hasChanges
            {
                do{
                    try context.save()
                }
                catch{
                    print("\n - did not save managed object context - \n")
                }
            }
            else
            {
                print("Context does not have any changes")
            }
        }
    }
    
    //MARK: - CurrentUser
    func getCurrentUserById(recordID:String) -> CurrentUser?
    {
        var toReturn:CurrentUser?
        
        let fetchRequest = NSFetchRequest(entityName: "CurrentUser")
        let predicate = NSPredicate(format: "phone = %@", recordID)
        fetchRequest.predicate = predicate
        
        let mainContext = self.mainQueueManagedObjectContext
        
        mainContext.performBlockAndWait(){
            do
            {
                if var foundUsers = try mainContext.executeFetchRequest(fetchRequest) as? [CurrentUser] where foundUsers.count > 0
                {
                    //
                    toReturn = foundUsers.removeFirst()
                    
                    //clear database for duplicates
                    if !foundUsers.isEmpty
                    {
                        for aUser in foundUsers
                        {
                            mainContext.deleteObject(aUser)
                        }
                    }
                }
            }
            catch let fetchError
            {
                print(" - Error fetching current user:")
                print(fetchError)
            }
        }
        
        return toReturn
    }
    
    func setCurrentUser(user:CurrentUser)
    {
        guard let _ = user.phone else
        {
            return
        }
        
        if let existing = getCurrentUserById(user.phone!)
        {
            existing.firstName = user.firstName
            existing.lastName = user.lastName
            existing.avatarData = user.avatarData
        }
        else
        {
            self.mainQueueManagedObjectContext.insertObject(user)
        }
        
        saveMainContext()
    }
    
    /// used when user presses
    func deleteCurrentUser()
    {
        let fetch = NSFetchRequest(entityName: "CurrentUser")
        if #available(iOS 9.0, *) {
            let batchDeletion = NSBatchDeleteRequest(fetchRequest: fetch)
            do
            {
                try self.mainQueueManagedObjectContext.executeRequest(batchDeletion)
            }
            catch let batchDeletionError
            {
                print("Error batch deleting CurrentUser entities:")
                print(batchDeletionError)
            }
        }
        else
        {
            do{
                let entities = try self.mainQueueManagedObjectContext.executeFetchRequest(fetch) as! [NSManagedObject]
                for anEntity in entities
                {
                    mainQueueManagedObjectContext.deleteObject(anEntity)
                }
            }
            catch {
                
            }
        }
        
    }
    
    //MARK: - Contacts
    
    /**
    Inserts an array of `DeviceContact` into local core data database
    - Throws: If managed object context did fail to save and an error was caught - this error is thown further
    - Returns: an array of contacts, which could not be inserted into managedObjectContext as `User`.  On success this array is empty
    */
    @warn_unused_result
    func insert(contacts:[DeviceContact]) throws -> [DeviceContact]
    {
        var failedUsers = [DeviceContact]()
        var errorToThrow:ErrorType? = nil
        
        self.mainQueueManagedObjectContext.performBlockAndWait(){ [unowned self] in
         
            for aContact in contacts
            {
                if let existingDBUser = self.findContactByPhone(aContact.fixedPhoneNumber)
                {
                    print("Updating User ...")
                    existingDBUser.fillInfoFrom(aContact)
                }
                else
                {
                    print("Inserting User ...")
                    guard let dbContact = NSEntityDescription.insertNewObjectForEntityForName("User", inManagedObjectContext: self.mainQueueManagedObjectContext) as? User else
                    {
                        failedUsers.append(aContact)
                        continue
                    }
                    
                    dbContact.fillInfoFrom(aContact)
                }
            }
            
            if self.mainQueueManagedObjectContext.hasChanges
            {
                do{
                    try self.mainQueueManagedObjectContext.save()
                    print("Context saved after inserting Contacts.....")
                }
                catch let saveError{
                    print("Context saving vailed: ")
                    print(saveError)
                    errorToThrow = saveError
                }
            }
        }
        
        if let _ = errorToThrow
        {
            throw errorToThrow!
        }
        
        return failedUsers
    }
    
    func deleteAllContacts()
    {
        if #available(iOS 9.0, *)
        {
            let fetchRequest = NSFetchRequest(entityName: "User")
            let batchDelete = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            do
            {
                try persistentStoreCoordinator.executeRequest(batchDelete, withContext: self.mainQueueManagedObjectContext)
            }
            catch let error
            {
                NSLog("\n -  Deletion All USERs from local databale failure: \n \(error) \n -----")
            }
        }
        else
        {
            let allContacts = self.allContacts()
            for aContact in allContacts
            {
                self.mainQueueManagedObjectContext.deleteObject(aContact)
            }
            
            do
            {
                try self.mainQueueManagedObjectContext.save()
            }
            catch let saveContextError
            {
                NSLog("\n - Deletion All USERs from local databale failure:\n - Save Context Error:\n \(saveContextError) \n -----")
            }
        }
    }
    
    @warn_unused_result
    func findContactByPhone(phoneNumber:String) -> User?
    {
        let userRequest = NSFetchRequest(entityName: "User")
        let predicate = NSPredicate(format: "phone = %@", phoneNumber)
        userRequest.fetchLimit = 1
        userRequest.predicate = predicate
        
        do{
            guard let usersFound = try self.mainQueueManagedObjectContext.executeFetchRequest(userRequest) as? [User] else
            {
                return nil
            }
            
            return usersFound.first
        }
        catch {
            return nil
        }
    }
    
    @warn_unused_result
    func allContacts() -> [User]
    {
        return self.fetchContacts(false)
    }
    
    @warn_unused_result
    func registeredContacts() -> [User]
    {
        return self.fetchContacts(true)
    }
    
    private func fetchContacts(registeredOnly:Bool) -> [User]
    {
        var usersToReturn = [User]()
        
        let allFetchRequest = NSFetchRequest(entityName: "User")
        allFetchRequest.returnsObjectsAsFaults = false
        let sortRegistered = NSSortDescriptor(key: "registered", ascending: false)
        let sortByFirstName = NSSortDescriptor(key: "firstName", ascending: false)
        if registeredOnly
        {
            allFetchRequest.predicate = NSPredicate(format: "registered = YES")
        }
        allFetchRequest.sortDescriptors = [sortRegistered, sortByFirstName]
        
        do{
            guard let usersFound = try self.mainQueueManagedObjectContext.executeFetchRequest(allFetchRequest) as? [User] else
            {
                return usersToReturn
            }
            
            usersToReturn += usersFound
        }
        catch{
            
        }
        
        return usersToReturn
    }
    
    
    
    //MARK: - Boards
    func allBoards() -> [Board]
    {
        let fetchRequest = NSFetchRequest(entityName: "Board")
        let sort = NSSortDescriptor(key: "sortOrder", ascending: true)
        fetchRequest.sortDescriptors = [sort]
        
        do
        {
            if let boardsFound = try self.mainQueueManagedObjectContext.executeFetchRequest(fetchRequest) as? [Board]
            {
                return boardsFound
            }
            return [Board]()
        }
        catch
        {
            
        }
        
        return [Board]()
    }
    
    func findBoardByRecordId(recordIdString:String) -> Board?
    {
        let fetchRequest = NSFetchRequest(entityName: "Board")
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "recordId = \(recordIdString)")
        
        do
        {
            if let boardsFound = try self.mainQueueManagedObjectContext.executeFetchRequest(fetchRequest) as? [Board] where !boardsFound.isEmpty
            {
                return boardsFound.first!
            }
            //else the bottom 'return nil' will be executed
        }
        catch let fetchError
        {
            NSLog(" - findBoardByRecordId fetch error: \n \(fetchError)")
        }
        
        return nil
    }
    
    func insert(boards:[TaskBoardInfo]) throws -> [TaskBoardInfo]
    {
        var failedBoards = [TaskBoardInfo]()
        var errorToThrow:ErrorType? = nil
        
        let saveOperation = NSBlockOperation(){
            for aBoardInfo in boards
            {
                guard let recordIdString = aBoardInfo.recordId?.recordName else
                {
                    failedBoards.append(aBoardInfo)
                    continue
                }
                
                if let foundBoard = self.findBoardByRecordId(recordIdString)
                {
                    foundBoard.fillBasicInfoFrom(aBoardInfo)
                    //foundBoard.recordId = recordIdString
                }
                else
                {
                    guard let _ = aBoardInfo.creatorId else  // we have to know exactly the board`s creator
                    {
                        failedBoards.append(aBoardInfo)
                        continue
                    }
                    
                    guard let newBoard = NSEntityDescription.insertNewObjectForEntityForName("Board", inManagedObjectContext: self.mainQueueManagedObjectContext) as? Board else
                    {
                        failedBoards.append(aBoardInfo)
                        continue
                    }
                    
                    newBoard.fillBasicInfoFrom(aBoardInfo)
                    newBoard.recordId = recordIdString
                }
            }
            
            if self.mainQueueManagedObjectContext.hasChanges
            {
                do
                {
                    try self.mainQueueManagedObjectContext.save()
                }
                catch let saveError
                {
                    errorToThrow = saveError
                }
            }
        }
        
        saveOperation.qualityOfService = .UserInteractive //highest priority
        
        NSOperationQueue.mainQueue().addOperations([saveOperation], waitUntilFinished: true)
        
        if let anError = errorToThrow
        {
            throw anError
        }
        //else
        return failedBoards
    }
    
    func insert(board:Board, saveImmediately:Bool)
    {
        if let found = findBoardByRecordId(board.recordId!)
        {
            found.recordId = board.recordId
            found.title = board.title
            found.details = board.details
            found.participants = board.participants
            found.dateCreated = board.dateCreated
            found.sortOrder = board.sortOrder
            found.toBeDeleted = board.toBeDeleted
        }
        else
        {
            self.mainQueueManagedObjectContext.insertObject(board)
        }
        
        if saveImmediately{
            do{
                try self.mainQueueManagedObjectContext.save()
            }
            catch let saveError {
                print("  Could not save after straight insertion of Board entity: \n")
                print(saveError)
            }
        }
    }
    
    func updateTasks(tasks:[Task], forBoard board:Board, saveImmediately:Bool)
    {
        board.setValue(nil, forKey: "tasks")
        
        board.addTasks(tasks)
        
//        for aTask in tasks
//        {
//            aTask.board = board
//        }
        
        if saveImmediately {
            do{
                try self.mainQueueManagedObjectContext.save()
            }
            catch let saveError {
                print("  Could not save after straight insertion of Board entity: \n")
                print(saveError)
            }
        }
    }
    
    func deleteBoardsByIDs(boardIDs:[String]) throws
    {
        var toDelete = [Board]()
        for anID in boardIDs
        {
            if let foundBoard = self.findBoardByRecordId(anID)
            {
                toDelete.append(foundBoard)
            }
        }
        
        var toThrow:ErrorType?
        
        defer{
            print("deleteBoardsByIDs  did finish")
        }
        
        if !toDelete.isEmpty
        {
            let lvContext = self.mainQueueManagedObjectContext
            mainQueueManagedObjectContext.performBlockAndWait(){
                if #available (iOS 9.0, *)
                {
                    var managedIDs = [NSManagedObjectID]()
                    for aBoard in toDelete
                    {
                        managedIDs.append(aBoard.objectID)
                    }
                    let batchDeleteRequest = NSBatchDeleteRequest(objectIDs: managedIDs)
                    
                    do
                    {
                        try lvContext.executeRequest(batchDeleteRequest)
                    }
                    catch let batchDeleteError
                    {
                        toThrow = batchDeleteError
                    }
                }
                else
                {
                    for aBoard in toDelete
                    {
                        lvContext.deleteObject(aBoard)
                    }
                }
                
                if lvContext.hasChanges
                {
                    do{
                        try lvContext.save()
                    }
                    catch let saveError
                    {
                        toThrow =  saveError
                    }
                }
            }
        }
        
        if let _ = toThrow
        {
            print("error while saving context after deleting boards")
            throw toThrow!
        }
    }

    //MARK: - Tasks
    func insertTaskRecords(records:[CKRecord])
    {
        for aRecord in records
        {
            let task = Task()
            
        }
    }
    
    func updateTask(taskToUpdate:Task)
    {
        guard let recordId = taskToUpdate.recordId else
        {
            return
        }
        
        if let found = findTaskById(recordId)
        {
            self.mainQueueManagedObjectContext.deleteObject(found)
        }
        
        self.mainQueueManagedObjectContext.insertObject(taskToUpdate)
        
        if self.mainQueueManagedObjectContext.hasChanges
        {
            self.saveMainContext()
        }
        
        
    }
    
    func insertSingle(task:Task)
    {
        guard let recordId = task.recordId else
        {
            return
        }
        
        if let _ = findTaskById(recordId)
        {
            return
        }
        
        let context = self.mainQueueManagedObjectContext
        
        context.performBlock(){
            
            context.insertObject(task)
            
            do{
                try context.save()
                print("inserted single task to main context (saved) ")
            }
            catch let error{
                print("could not save private context when inserting new task")
                print(error)
            }
        }
    }
    
    func insertMany(tasks:[Task])
    {
        let aContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        aContext.parentContext = self.mainQueueManagedObjectContext
        aContext.performBlock(){
            for aTask in tasks
            {
                aContext.insertObject(aTask)
            }
            
            if aContext.hasChanges
            {
                do{
                    try aContext.save()
                    print("\n - did insert Tasks into mainContext (not saved) ")
                }
                catch let privateError{
                    print("\n - Could not save private context after inserting several tasks:")
                    print("\(privateError)")
                }
            }
        }
    }
    
    func findTaskById(recordId:String) -> Task?
    {
        let predicate = NSPredicate(format: "recordId = %@", recordId)
        let fetchRequest = NSFetchRequest(entityName: "Task")
        fetchRequest.predicate = predicate
        
        let context = self.mainQueueManagedObjectContext
        var taskToReturn:Task?
        
        context .performBlockAndWait(){
            do{
                if var foundTasks = try context.executeFetchRequest(fetchRequest) as? [Task] where foundTasks.count > 0
                {
                    taskToReturn = foundTasks.removeFirst()
                    
                    for aTask in foundTasks //remove possible duplicate entries
                    {
                        context.deleteObject(aTask)
                    }
                }
                
            }catch let fetchError {
                print(" - Could not fetch task by ID:")
                print(fetchError)
            }
        }
        
        return taskToReturn
    }
    
    func findTasksToDelete() -> [String]?
    {
        var toReturn = [String]()
        
        let fetchDeleted = NSFetchRequest(entityName: "Task")
        fetchDeleted.resultType = .DictionaryResultType
        fetchDeleted.propertiesToFetch = ["recortId"]
        let predicate = NSPredicate(format: "toBeDeleted = YES AND recordId != nil")
        fetchDeleted.predicate = predicate
        
        do
        {
            if let result = try mainQueueManagedObjectContext.executeFetchRequest(fetchDeleted) as? [[String:String]]
            {
                print("Found tasks to delete: \(result.count)")
                for aDict in result
                {
                    for (_ , value) in aDict
                    {
                        toReturn.append(value)
                    }
                }
            }
            else
            {
                assertionFailure("Did not fetch deleted tasks.")
            }
        }
        catch
        {
            
        }
        
        if !toReturn.isEmpty
        {
            return toReturn
        }
        return nil
    }
    
    
}//class end

