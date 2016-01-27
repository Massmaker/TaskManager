//
//  UserAuthenticating.swift
//  TaskCloud
//
//  Created by CloudCraft on 1/15/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import Foundation
import UIKit

protocol UserAuthenticating : PublicUserRecordHandling {
    var delegate:UserAuthenticatorDelegate?{get}
    var hostViewController:UIViewController?{get set}
    var phoneAuthenticationStatus:PhoneAuthenticationStatus{get set}
    func checkPhoneCredentials()
    func startAuthenticatingByPhone()

    func checkICloudAccountAvailability()
}