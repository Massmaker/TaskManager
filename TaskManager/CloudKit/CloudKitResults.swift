//
//  CloudKitErrors.swift
//  TaskManager
//
//  Created by CloudCraft on 1/20/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import Foundation

enum CloudKitResult {
    case Success
    case Retry(afterSeconds:Double)
    case RecoverableError
    case Fail(message:String?)
}
