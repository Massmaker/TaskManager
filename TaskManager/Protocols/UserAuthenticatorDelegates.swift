//
//  UserAuthenticatorDelegate.swift
//  TaskCloud
//
//  Created by CloudCraft on 1/15/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import Foundation
import CloudKit

protocol PhoneAuthenticatorDelegate:class{
    func userPhoneRegistrationStatusFound(status:PhoneAuthenticationStatus)
    func userDidStartRegisteringWithPhoneNumber()
    func userDidEndRegisteringWithPhoneNumber(result:PhoneAuthenticationStatus)
}

protocol CloudAuthenticatorDelegate:class{
    func userICloudAccountStatusFetchingDidStart()
    func userICloudAccountStatusFetchingDidComplete(status:CKAccountStatus, iCloudError:NSError?)
}

protocol PublicUserRecordHandlerDelegate:class {
    
    func publicUserFetchingDidStart()
    func publicUserFetchingDidFinish(record:CKRecord?, error:NSError?)
    func publicUserRecordCreatingDidStart()
    func publicUserRecordCreatingDidFinish(record:CKRecord?, error:NSError?)
}

//MARK: - to use in LoginVIewController
protocol UserAuthenticatorDelegate: PhoneAuthenticatorDelegate, CloudAuthenticatorDelegate, PublicUserRecordHandlerDelegate{
    
}


