//
//  ErrorContacts.swift
//  TaskCloud
//
//  Created by CloudCraft on 1/12/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import Foundation

enum ErrorContacts:ErrorType
{
    case NotFound(message:String?)
    case AccessDenied(message:String?)
    case UnknownError(message:String?)
    func getErrorMessage() -> String?
    {
        switch self
        {
        case .NotFound(let message):
            return message
        case .AccessDenied(let message):
            return message
        case .UnknownError(let message):
            return message
        }
    }
}