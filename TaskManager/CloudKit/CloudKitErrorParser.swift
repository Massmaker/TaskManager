//
//  CloudKitErrorParser.swift
//  TaskManager
//
//  Created by CloudCraft on 1/20/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import Foundation
import CloudKit

class CloudKitErrorParser
{
    
    // code taken (and slightly modified) from here https://github.com/evermeer/EVCloudKitDao/tree/master/AppMessage/AppMessage/CloudKit

    /**
     Categorise CloudKit errors into a functional status that will tell you how it should be handled.
     
     - parameter error: The CloudKit error for which you want a functional status.
     - parameter retryAttempt: In case we are retrying a function this parameter has to be incremented each time.
     */
    static func handleCloudKitErrorAs(error:NSError?, retryAttempt:Double = 1) -> CloudKitResult {
        // There is no error
        if error == nil {
            return .Success
        }
        
        // Or if there is a retry delay specified in the error, then use that.
        if let userInfo = error?.userInfo {
            if let retry = userInfo[CKErrorRetryAfterKey] as? NSNumber {
                let seconds = Double(retry)
                NSLog("Debug: Should retry in \(seconds) seconds. \(error)")
                return .Retry(afterSeconds: seconds)
            }
        }
        
        let errorCode:CKErrorCode = CKErrorCode(rawValue: error!.code)!
        
        switch errorCode
        {
            case .NetworkUnavailable:
                return .Fail(message:error?.localizedFailureReason)
            case .NotAuthenticated,  .NetworkFailure, .ServiceUnavailable, .RequestRateLimited, .ZoneBusy, .ResultsTruncated:
                // Probably handled by the userInfo[CKErrorRetryAfterKey] but if not, then:
                // Use an exponential retry delay which maxes out at half an hour.
                var seconds = Double(pow(2, Double(retryAttempt)))
                if seconds > 1800
                {
                    seconds = 1800
                }
                NSLog("Debug: Should retry in \(seconds) seconds. \(error)")
                return .Retry(afterSeconds: seconds)
            case .UnknownItem:
                return .Fail(message:"UnknownItem")
            case  .InvalidArguments, .IncompatibleVersion, .BadContainer, .MissingEntitlement, .PermissionFailure, .BadDatabase, .AssetFileNotFound, .OperationCancelled, .AssetFileModified, .BatchRequestFailed, .ZoneNotFound, .UserDeletedZone, .InternalError, .ServerRejectedRequest, .ConstraintViolation:
                NSLog("Error: \(error)")
                return .Fail(message:nil);
            case .QuotaExceeded, .LimitExceeded:
                NSLog("Warning: \(error)")
                return .Fail(message:nil);
            case .ChangeTokenExpired,  .ServerRecordChanged:
                NSLog("Info: \(error)")
                return .RecoverableError
            default:
                NSLog("Error: \(error)") //New error introduced in iOS...?
                return .Fail(message:nil);
        }
    }


}