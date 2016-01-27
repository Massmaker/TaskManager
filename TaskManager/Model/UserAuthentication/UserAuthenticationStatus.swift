//
//  UserAuthenticationStatus.swift
//  TaskCloud
//
//  Created by CloudCraft on 1/15/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import Foundation

enum PhoneAuthenticationStatus {
    case NotRegistered
    case InProcess
    case Failed(error:String?)
    case Registered(phoneNumber:String)
}