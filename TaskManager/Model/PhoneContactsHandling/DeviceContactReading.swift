//
//  DeviceContactReading.swift
//  TaskCloud
//
//  Created by CloudCraft on 1/12/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import Foundation

protocol DeviceContactReading{
    func checkPermissionContactsAccess(completion:(granted:Bool, error:ErrorType?)->())
    func readContactsFromCurrentDevice(completion:(contacts:[DeviceContact]?)->())
}