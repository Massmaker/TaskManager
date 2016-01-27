//
//  TaskErrors.swift
//  TaskManager
//
//  Created by CloudCraft on 1/20/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import Foundation
enum TaskError:ErrorType
{
    case Unknown
    case CloudKit(cloudError:NSError)
}