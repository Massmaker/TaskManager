//
//  AppDelegateError.swift
//  TaskManager
//
//  Created by CloudCraft on 1/18/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import Foundation

let noAppDelegateError = NSError(domain: "NoAppDelegate", code: -100, userInfo: [NSLocalizedFailureReasonErrorKey:"Could not recieve AppDelegate"])
let noUserPhoneNumberError = NSError(domain: "No User Phone Number", code: -10, userInfo: [NSLocalizedDescriptionKey:"No phone number found."])