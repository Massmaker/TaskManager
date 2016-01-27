//
//  PreIOS9ContactsFetcher.swift
//  TaskCloud
//
//  Created by CloudCraft on 1/12/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import Foundation
import AddressBook
import UIKit

class ContactsFetcherPreIOS9:DeviceContactReading {
    
    func checkPermissionContactsAccess(completion: (granted: Bool, error: ErrorType?) -> ()) {
        guard let anAddressBook = ABAddressBookCreateWithOptions(nil, nil)?.takeRetainedValue() else
        {
            completion(granted: false, error: ErrorContacts.UnknownError(message: "Could not get AddressBook reference"))
            return
        }
        
        var granted = false
        let currentAuthStatus = ABAddressBookGetAuthorizationStatus()
        
        switch currentAuthStatus
        {
            case .Authorized:
                granted = true
                completion(granted: granted, error: nil)
            case .Denied:
                completion(granted: false, error: ErrorContacts.AccessDenied(message: "You have denied access to the contacts, please check the Settings"))
            case .Restricted:
                completion(granted: false, error: ErrorContacts.AccessDenied(message: "The access to contacts is restricted, possibly because of parental control"))
            case .NotDetermined:
                ABAddressBookRequestAccessWithCompletion(anAddressBook) { (accessGranted, error) in
                    if accessGranted
                    {
                        granted = accessGranted
                        completion(granted: granted, error: nil)
                    }
                    else
                    {
                        let errorNS = error as NSError
                        completion(granted: granted, error: errorNS)
                    }
                }
        }
        
    }
    
    func readContactsFromCurrentDevice(completion: (contacts: [DeviceContact]?) -> ()) {
        
        guard let anAddressBook = ABAddressBookCreateWithOptions(nil, nil)?.takeRetainedValue() else
        {
            completion(contacts: nil)
            return
        }
        
        let allContacts : NSArray = ABAddressBookCopyArrayOfAllPeople(anAddressBook).takeRetainedValue()
        var allContactDatas = [DeviceContact]()
        for contactRef:ABRecordRef in allContacts
        {
            //we need contacts with phone numbers only! ( as I understand, at least for test version of the app)
            if let phoneNumbers = ABRecordCopyValue(contactRef, kABPersonPhoneProperty)
            {
                let phones:ABMultiValueRef = Unmanaged.fromOpaque(phoneNumbers.toOpaque()).takeRetainedValue() as AnyObject as ABMultiValueRef
                
                let countOfPhones = ABMultiValueGetCount(phones)
                if countOfPhones > 0
                {
                    let firstPersonsPhoneUnmanaged = ABMultiValueCopyValueAtIndex(phones, 0)
                    if let
                        phone = Unmanaged.fromOpaque(firstPersonsPhoneUnmanaged.toOpaque()).takeUnretainedValue() as AnyObject as? String
                    {
                        if let lvContact = DeviceContact(phoneNumber: phone)
                        {
                            if let firstName = ABRecordCopyValue(contactRef, kABPersonFirstNameProperty)?.takeUnretainedValue() as? String
                            {
                                lvContact.firstName = firstName
                            }
                            
                            if let lastName = ABRecordCopyValue(contactRef, kABPersonLastNameProperty)?.takeUnretainedValue() as? String
                            {
                                lvContact.lastName = lastName
                            }
                            
                            if let imageData:NSData = ABPersonCopyImageDataWithFormat(contactRef, kABPersonImageFormatThumbnail)?.takeRetainedValue(), thumbNail = UIImage(data: imageData)
                            {
                                lvContact.avatarImage = thumbNail
                            }
                            
                            allContactDatas.append(lvContact)
                        }
                    }
                }
            }
        }
        
        if allContactDatas.isEmpty
        {
            completion(contacts: [DeviceContact]())
            return
        }
        else
        {
            completion(contacts: allContactDatas)
        }
    }
}