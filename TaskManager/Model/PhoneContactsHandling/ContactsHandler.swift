//
//  ContactsHandler.swift
//  TaskCloud
//
//  Created by CloudCraft on 1/12/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import Foundation
import CloudKit

class ContactsHandler {
    
    static let sharedInstance = ContactsHandler()
    
    private let contactsReader:DeviceContactReading
    
    private var pContacts:[DeviceContact]?
    private var dbContacts:[User]?
    
    private var phoneBookPermissionGranted = false
    private var phoneBookError:ErrorContacts?
    
    let bgQueue = NSOperationQueue()
    let mainQueue = NSOperationQueue.mainQueue()
    
    private lazy var permissionsCheckOperation = NSOperation()
    private lazy var fetchingFromDeviceOperation = NSOperation()
    private lazy var fetchingFromCoreDataOperation = NSOperation()
    private var fetchingFromICLoudOperation:CloudRegisteredUsersRequestOperation?
    
    weak var delegate:ContactsHandlerDelegate?
    
    var allContacts:[User]{
        if let nonEmptyUsers = self.dbContacts where !nonEmptyUsers.isEmpty
        {
            return nonEmptyUsers
        }
        return [User]()
    }
    
    init(){
        if #available (iOS 9.0, *)
        {
            self.contactsReader = ContactsFetcherIOS9()
        }
        else
        {
            self.contactsReader = ContactsFetcherPreIOS9()
        }
        
        self.configureAllOperations()
    }
    
    //MARK: -
    /**
    use this to get **User** instance
    - Returns: nil if user is not found in local database or if local database writing operation is in progress
    */
    func contactByPhone(phone:String) -> User?
    {
        if fetchingFromCoreDataOperation.executing
        {
            return nil
        }
        if let fetchingFromICLoudOperation = self.fetchingFromICLoudOperation
        {
            if fetchingFromICLoudOperation.executing
            {
                return nil
            }
        }
        
        guard let _ = self.dbContacts else
        {
            return nil
        }
        
        let foundContacts = self.dbContacts!.filter { (aUser) -> Bool in
            
            guard let aPhone = aUser.phone else
            {
                return false
            }
            
            if aPhone == phone
            {
                return true
            }
            return false
        }
        
        return foundContacts.first
        
        //return anAppDelegate()?.coreDatahandler?.findContactByPhone(phone)
    }
    
    //MARK: - private configuring methods
    func configureAllOperations()
    {
        configurePermissionsOp()
        configureDeviceContactsFetchOp()
        configureCoreDataFetchingOp()
        
        self.bgQueue.addOperations([self.permissionsCheckOperation, self.fetchingFromDeviceOperation], waitUntilFinished: false)
        self.mainQueue.addOperation(self.fetchingFromCoreDataOperation)
        
    }
    
    private func configurePermissionsOp()
    {
        self.permissionsCheckOperation = NSBlockOperation() { [unowned self] in
            
            let waiter = dispatch_semaphore_create(0)
            
            self.contactsReader.checkPermissionContactsAccess() {[weak self] (granted, error) in
                self?.phoneBookPermissionGranted = granted
                if let contactsError = error as? ErrorContacts
                {
                    self?.phoneBookError = contactsError
                }
                dispatch_semaphore_signal(waiter)
            }
            
            dispatch_semaphore_wait(waiter, DISPATCH_TIME_FOREVER)
        }
        
        self.permissionsCheckOperation.name = "ChekUserContactsPermission"
        self.permissionsCheckOperation.qualityOfService = .UserInitiated
    }
    
    private func configureDeviceContactsFetchOp()
    {
        self.fetchingFromDeviceOperation = NSBlockOperation() { [unowned self] in
            
            if !self.phoneBookPermissionGranted
            {
                self.pContacts = nil
                
                self.delegate?.contactsHandlerDidFinishFetchingContacts(nil)
                return
            }
            
            self.delegate?.contactshandlerWillStartFetchingContacts() //give a view or a view controller a chance to display some loading indicator
            
            self.delegate?.contactsHandlerDidStartFetchingContacts()
            
            self.contactsReader.readContactsFromCurrentDevice { (contacts) -> () in
                
                self.pContacts = contacts
                
                if let _ = self.pContacts, coreDataHandler = anAppDelegate()?.coreDatahandler
                {
                    do
                    {
                        let failedContacts = try coreDataHandler.insert(self.pContacts!)
                        
                        print(" - Inserted \(contacts!.count - failedContacts.count )")
                    }
                    catch let savingError {
                        self.delegate?.contactsHandlerDidFinishFetchingContacts(savingError)
                        return
                    }
                }
                
                self.delegate?.contactsHandlerDidFinishFetchingContacts(nil)
            }
        }
        
        self.fetchingFromDeviceOperation.name = "FetchContactsFromDevice"
        self.fetchingFromDeviceOperation.qualityOfService = .UserInitiated
        
        self.fetchingFromDeviceOperation.addDependency(self.permissionsCheckOperation)
    }
    
    private func configureCoreDataFetchingOp()
    {
        self.fetchingFromCoreDataOperation = NSBlockOperation(){ [unowned self] in
            
            guard let coreDataHandler = anAppDelegate()?.coreDatahandler else
            {
                return
            }
            
            self.delegate?.contactsWillUpdate()
            
            let allContactsFromDB = coreDataHandler.allContacts()
            
            self.dbContacts = allContactsFromDB
            
            
            self.delegate?.contactsDidUpdate()
            
            self.confgureiCloudRegisteredContactsFetchingOp()
            
            if let iCloudRegisteredContactsFetchingOp = self.fetchingFromICLoudOperation
            {
                self.bgQueue.addOperation(iCloudRegisteredContactsFetchingOp)
            }
        }
        
        self.fetchingFromCoreDataOperation.name = "FetchContactsFromCoreData"
        self.fetchingFromCoreDataOperation.qualityOfService = .UserInitiated
        
        self.fetchingFromCoreDataOperation.addDependency(self.fetchingFromDeviceOperation)
    }
    
    private func confgureiCloudRegisteredContactsFetchingOp()
    {
        guard let allDBContacts = self.dbContacts else
        {
            print("\n - ERROR: CloudRegisteredUsersRequestOperation was not configured:\n No device contacts - \n")
            return
        }
        
        var allPhoneNumbers = [String]()
        
        for aUser in allDBContacts
        {
            if aUser.registered!.boolValue
            {
                continue
            }
            
            if let fixedPhoneString = aUser.phone
            {
                allPhoneNumbers.append(fixedPhoneString)
            }
        }
        
        if allPhoneNumbers.isEmpty{
            print(" WILL NOT  start fetching registered contacts: all contacts are \"registered\" in localDB")
            return
        }
        
        func updateUsersInCoreDataWithRegistered(registered:[String])
        {
            guard let contacts = self.getContactsByNumbers(registered) else
            {
                return
            }
            
            for aContact in contacts
            {
                aContact.registered = true
            }
            dispatchMainSync(){
                do{
                    let _ = try anAppDelegate()?.coreDatahandler?.insert(contacts)
                }
                catch{
                    
                }
            }
        }
        
        let fetchRegisteredUserOp = CloudRegisteredUsersRequestOperation(phoneNumbers: allPhoneNumbers)
        fetchRegisteredUserOp.name = "FetchingRegisteredContactsFromICLoud"
        fetchRegisteredUserOp.addDependency(self.fetchingFromCoreDataOperation)
        fetchRegisteredUserOp.qualityOfService = .Utility
        
        self.fetchingFromICLoudOperation = fetchRegisteredUserOp
        
        self.fetchingFromICLoudOperation?.requestCompletionBlock = {[weak self] (registeredPhones) in
            if registeredPhones.isEmpty
            {
                return
            }
            
            dispatchMainSync(){
                self?.delegate?.contactsWillUpdate()
            }
            
            updateUsersInCoreDataWithRegistered(registeredPhones)
            
            dispatchMain(){
                self?.delegate?.contactsDidUpdate()
            }
        }
    }
    //MARK: - helper methods
    private func getContactsByNumbers(let phoneNumbers:[String]) -> [DeviceContact]?
    {
        guard phoneNumbers.count > 0 else
        {
            return nil
        }
        
        guard var toSearch = self.pContacts else
        {
            return nil
        }
        
        var lvNumbers = phoneNumbers.filter { (phone) -> Bool in
            if phone.isEmpty
            {
                return false
            }
            return true
        }
        
        var toReturnContacts = [DeviceContact]()
        
        while !lvNumbers.isEmpty
        {
            InternalLoop: for aContact in toSearch
            {
                let firstNumber =  lvNumbers.first!
                if aContact.fixedPhoneNumber == firstNumber
                {
                    toReturnContacts.append(aContact)
                    lvNumbers.removeFirst()
                    break InternalLoop
                }
            }
            
            if let lastAppandedContact = toReturnContacts.last, let indexOfContact = toSearch.indexOf(lastAppandedContact)
            {
                toSearch.removeAtIndex(indexOfContact)
            }
            
        }
        
        if toReturnContacts.isEmpty
        {
            return nil
        }
        
        return toReturnContacts
    }

    
} //class end

