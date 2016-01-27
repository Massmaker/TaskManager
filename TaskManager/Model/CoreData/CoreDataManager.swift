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
        
        completion?(true)
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
    
    func allContacts() -> [User]
    {
        var usersToReturn = [User]()
        
        let allFetchRequest = NSFetchRequest(entityName: "User")
        let sortByFirstName = NSSortDescriptor(key: "firstName", ascending: true)
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
    
    
    
    
}//class end

