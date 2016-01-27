//
//  LoginViewController+UserAuthenticatorDelegate.swift
//  TaskManager
//
//  Created by CloudCraft on 1/18/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import CloudKit

extension LoginViewController : UserAuthenticatorDelegate {
    
    //MARK: - PhoneAuthenticatorDelegate
    func userPhoneRegistrationStatusFound(status: PhoneAuthenticationStatus) {
        
        switch status
        {
        case .Registered(let phoneNumber):
            print("found phone number: \(phoneNumber)")
            
            let applicationDelegate = anAppDelegate()
            applicationDelegate?.cloudKitHandler.currentUserPhoneNumber = phoneNumber
            
            self.setupAuthButtons(false)
            self.userDidEndRegisteringWithPhoneNumber(status)
        case .NotRegistered:
            self.setupAuthButtons(true)
           
            //clean if any old user info found
            dispatchBackground(){
                let defaultsManager = UserDefaultsManager()
                defaultsManager.clearUserDefaults()
                
                let documentsManager = DocumentsFolderFileHandler()
                if let userId = anAppDelegate()?.cloudKitHandler.currentUserPhoneNumber
                {
                    documentsManager.deleteAvatarImageForUserId(userId)
                }
            }
        case .InProcess:
            print("Registration by phone is in process")
        case .Failed(let possibleErrorMessage):
            self.showAlertController("Registration Error", text: possibleErrorMessage, closeButtonTitle: "Ok")
        }
    }
    
    func userDidStartRegisteringWithPhoneNumber() {
        print(" - \n - userDidStartRegisteringWithPhoneNumber - ")
    }
    
    func userDidEndRegisteringWithPhoneNumber(result: PhoneAuthenticationStatus) {
        switch result
        {
        case .Registered(_):
            self.authenticator?.checkICloudAccountAvailability()
        case .Failed(let errorMessage):
            if let message = errorMessage
            {
                self.showAlertController("Error", text: message, closeButtonTitle: "Ok")
            }
            fallthrough
        case .NotRegistered:
            self.setLoadingIndicatorVisible(false)
            self.setupAuthButtons(true)
        case .InProcess:
            break
        }
        
    }

    //MARK: - CloudAuthenticatorDelegate
    func userICloudAccountStatusFetchingDidStart()
    {
        //print("Started fetching iCloud account status on device....")
    }
    
    func userICloudAccountStatusFetchingDidComplete(status:CKAccountStatus, iCloudError:NSError?)
    {
        //print("iCloud account status = \" \(status.rawValue) \" ")
        switch status
        {
            case .Restricted:
                
                self.showAlertController("Warning", text: "iCloud account access is Restricted. Check Parental Control or Your Mobile Device Management program. The app`s functionality is limited.", closeButtonTitle: "Ok", closeAction: {[weak self] () -> () in
                        self?.showMainTabBarController()
                    }, presentationCompletion: nil)
            case .NoAccount:
                self.showAlertController("Warning", text: "iCloud account is not set up in Settings. The app`s functionality is limited. To gain full access, please set up the iCloud on your mobile device. ", closeButtonTitle: "Ok", closeAction: {[weak self] () -> () in
                    //show MainTab bar controller when user dismisses the alert
                        self?.showMainTabBarController()
                    }, presentationCompletion: nil)
            case .CouldNotDetermine:
                self.showAlertController("Warning", text: "iCloud account access is Not Determined. The app`s functionality is limited.", closeButtonTitle: "Ok", closeAction: {[weak self] () -> () in
                    //show MainTab bar controller when user dismisses the alert
                    self?.showMainTabBarController()
                    }, presentationCompletion: nil)
                if let anError = iCloudError
                {
                    NSLog(" - - Error fetching User iCLOUD account status: \n %@", anError)
                }
            case .Available:
                
                self.authenticator?.startFetchingPublicUserByPhoneNumberId()
        }
        
    }

    //MARK: - PublicUserRecordHandlerDelegate
    func publicUserFetchingDidStart() {
        self.setLoadingIndicatorVisible(true)
    }
    
    func publicUserFetchingDidFinish(record: CKRecord?, error: NSError?) {
        self.setLoadingIndicatorVisible(false)
        //print("\n - publicUserFetchingDidFinish\n")
        if let _ = record
        {
            //print("user record found: ", userRecord.recordID.recordName)
            self.showMainTabBarController() // full access to database, user has iCloud, and user record is in public database
        }
        else
        {
            let existingUserError = error!
            //let userInfo = existingUserError.userInfo
            //print(" - \n - \n")
            //NSLog("%@", userInfo)
            if let reason = existingUserError.localizedFailureReason where reason == "UnknownItem"
            {
                self.authenticator?.startCreatingNewPublicUserByPhoneNumber()
            }
            else
            {
                self.showAlertController("Could not find user :", text: existingUserError.localizedFailureReason, closeButtonTitle: "Ok")
            }
        }
    }
    
    func publicUserRecordCreatingDidStart()
    {
        self.setLoadingIndicatorVisible(true)
    }
    func publicUserRecordCreatingDidFinish(record:CKRecord?, error:NSError?)
    {
        self.setLoadingIndicatorVisible(false)
        
        self.showMainTabBarController()
    }
}
