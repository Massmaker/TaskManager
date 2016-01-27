//
//  PhoneAndCloudAuthenticator.swift
//  TaskCloud
//
//  Created by CloudCraft on 1/18/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import Foundation
import Fabric
import DigitsKit
import CloudKit

class PhoneAndCloudAuthenticator : UserAuthenticating {
    
    //MARK: -
    init(authenticatorDelegate:UserAuthenticatorDelegate)
    {
        self.delegate = authenticatorDelegate
    }
    
    //MARK: - UserAuthenticating
    weak var delegate:UserAuthenticatorDelegate?
    weak var hostViewController:UIViewController?
    
    lazy var phoneAuthenticationStatus:PhoneAuthenticationStatus = .NotRegistered
    
    func startAuthenticatingByPhone() {
        print("startAuthenticatingByPhone called")
        guard let hostVC = hostViewController else
        {
            finishAuthenticatingUserByPhone()
            return
        }
        
        print("Showing Digits phone number registration workflow")
        let defaultConfig =  DGTAuthenticationConfiguration(accountFields:DGTAccountFields.None)
        
        Digits.sharedInstance().authenticateWithViewController(hostVC, configuration: defaultConfig ) {[unowned self] (session, error) -> Void in
            self.refreshPhoneCredentials()
            self.delegate?.userDidEndRegisteringWithPhoneNumber(self.phoneAuthenticationStatus)
        }
        
        delegate?.userDidStartRegisteringWithPhoneNumber()
    }
    
    private func finishAuthenticatingUserByPhone() {
              print("finishAuthenticatingUserByPhone called")
        delegate?.userDidEndRegisteringWithPhoneNumber(self.phoneAuthenticationStatus)
    }
    
    private func refreshPhoneCredentials()
    {
        let sharedDigits = Digits.sharedInstance()
        
        if let phoneNumber = sharedDigits.session()?.phoneNumber
        {
            phoneAuthenticationStatus = .Registered(phoneNumber:phoneNumber)
        }
        else
        {
            phoneAuthenticationStatus = .NotRegistered
        }
    }
    
    func checkPhoneCredentials() {
        print("Check credentials called")
        refreshPhoneCredentials()
        delegate?.userPhoneRegistrationStatusFound(phoneAuthenticationStatus)
    }
    
    func checkICloudAccountAvailability()
    {
        delegate?.userICloudAccountStatusFetchingDidStart()
        guard let appDelegateInstance = anAppDelegate() else
        {
            delegate?.userICloudAccountStatusFetchingDidComplete(CKAccountStatus.CouldNotDetermine, iCloudError:noAppDelegateError)
            return
        }
        
        let cloudKitHandler = appDelegateInstance.cloudKitHandler
        
        cloudKitHandler.checkAccountStatus { (status, iCloudError) -> () in
            dispatch_async(dispatch_get_main_queue()) {[weak self] in
                self?.delegate?.userICloudAccountStatusFetchingDidComplete(status, iCloudError: iCloudError)
            }
        }
    }
    
    //MARK: PublicUserRecordHandling
    
    func startFetchingPublicUserByPhoneNumberId() {
        
        self.delegate?.publicUserFetchingDidStart()
        guard let phone = getPhonenumberFromCloudKitHandler() else
        {
            return
        }
        
        anAppDelegate()?.cloudKitHandler.queryForLoggedUserByPhoneNumber(phone) {[unowned self] (currentUserRecord, error) -> () in
            dispatch_async(dispatch_get_main_queue()){
                self.delegate?.publicUserFetchingDidFinish(currentUserRecord, error: error)
            }
        }
    }
    
    func startCreatingNewPublicUserByPhoneNumber() {
        self.delegate?.publicUserRecordCreatingDidStart()
        guard let phone = getPhonenumberFromCloudKitHandler() else
        {
            self.delegate?.publicUserFetchingDidFinish(nil, error: noUserPhoneNumberError)
            return
        }
        
        anAppDelegate()?.cloudKitHandler.insertNewPublicUserIntoCloudByPhoneNumber(phone){[weak self] (ckRecordUser, errorInserting) in
            dispatch_async(dispatch_get_main_queue()){[weak self] in
                self?.delegate?.publicUserRecordCreatingDidFinish(ckRecordUser, error: errorInserting)
            }
        }
    }
    
    private func getPhonenumberFromCloudKitHandler() -> String?
    {
        guard let anDelegate = anAppDelegate() else
        {
            return nil
        }
        guard let foundCurrentPhoneNumber = anDelegate.cloudKitHandler.currentUserPhoneNumber else
        {
            return nil
        }
        
        return foundCurrentPhoneNumber
    }
    
}