//
//  ContactsFetcherIOS9.swift
//  TaskCloud
//
//  Created by CloudCraft on 1/12/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import Foundation
import Contacts
import UIKit

@available(iOS 9.0, *)
class ContactsFetcherIOS9:DeviceContactReading {
    
    func checkPermissionContactsAccess(completion: (granted: Bool, error: ErrorType?) -> ()) {
        let authorizationStatus = CNContactStore.authorizationStatusForEntityType(CNEntityType.Contacts)
        let contactStore = CNContactStore()
        
        switch authorizationStatus
        {
            case .Authorized:
                completion(granted: true, error: nil)
            case .Denied:
                completion(granted: false, error: ErrorContacts.AccessDenied(message: "You have denied access to the contacts, please check the Settings"))
            case .Restricted:
                completion(granted: false, error: ErrorContacts.AccessDenied(message:"The access to contacts is restricted, possibly because of parental control"))
            case .NotDetermined:
                contactStore.requestAccessForEntityType(CNEntityType.Contacts) { (access, accessError) in
                    if access
                    {
                        completion(granted: access, error:nil)
                    }
                    else
                    {
                        let newStatus = CNContactStore.authorizationStatusForEntityType(CNEntityType.Contacts)
                        if newStatus == CNAuthorizationStatus.Denied
                        {
                            let error = ErrorContacts.AccessDenied(message:"You have denied access to the contacts, please check the Settings")
                            completion(granted: false, error: error)
                        }
                        else
                        {
                            
                        }
                    }
                }//end of completion handler
            
         }//switch end

    }
    
    func readContactsFromCurrentDevice(completion: (contacts: [DeviceContact]?) -> ()) {
        do{
            let cnContacts = try findContacts()
            if cnContacts.isEmpty
            {
                completion(contacts: nil)
                return
            }
            var deviceContacts = [DeviceContact]()
            for aCNcontactInstance in cnContacts
            {
                if let phoneValue = aCNcontactInstance.phoneNumbers.first?.value as? CNPhoneNumber,
                    appContact = DeviceContact(phoneNumber: phoneValue.stringValue)
                {
                    appContact.firstName = aCNcontactInstance.givenName
                    appContact.lastName = aCNcontactInstance.familyName
                    if let thumbnailImageData = aCNcontactInstance.thumbnailImageData, avatarThumb = UIImage(data:thumbnailImageData)
                    {
                        appContact.avatarImage = avatarThumb
                    }
                    
                    deviceContacts.append(appContact)
                }
            }
            
            completion(contacts: deviceContacts)

        }
        catch {
            completion(contacts: nil)
        }
    }
    
    private func findContacts() throws -> [CNContact]
    {
        let store = CNContactStore()
        let nameDescriptor = CNContactFormatter.descriptorForRequiredKeysForStyle(CNContactFormatterStyle.FullName)
        let keysToFetch = [nameDescriptor, CNContactPhoneNumbersKey, CNContactImageDataKey, CNContactThumbnailImageDataKey]
        let contactsRequest = CNContactFetchRequest(keysToFetch: keysToFetch)
        
        var lvContacts = [CNContact]()
        do{
            try store.enumerateContactsWithFetchRequest(contactsRequest) { (contact, stop) -> Void in
                lvContacts.append(contact)
            }
        }
        catch let error{
            print(" -> iOS 9 contact fetcher error: \n \(error)")
            throw error
        }
        
        return lvContacts
    }

    
}