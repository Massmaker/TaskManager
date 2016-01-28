//
//  CoreDataManager.swift
//  TaskManager
//
//  Created by CloudCraft on 1/26/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import CoreData

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
        return self.allContacts(false)
    }
    
    @warn_unused_result
    func registeredContacts() -> [User]
    {
        return self.allContacts(true)
    }
    
    private func allContacts(registeredOnly:Bool) -> [User]
    {
        var usersToReturn = [User]()
        
        let allFetchRequest = NSFetchRequest(entityName: "User")
        let sortByFirstName = NSSortDescriptor(key: "firstName", ascending: true)
        if registeredOnly
        {
            allFetchRequest.predicate = NSPredicate(format: "registered = YES")
        }
        allFetchRequest.sortDescriptors = [sortByFirstName]
        
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
    
    
    
}//class end

