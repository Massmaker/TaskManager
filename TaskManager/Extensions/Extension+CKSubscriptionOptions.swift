//
//  Extension+CKSubscriptionChangeType.swift
//  TaskManager
//
//  Created by CloudCraft on 2/1/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import CloudKit

extension CKSubscriptionOptions{
    var subscriptionIdStringPart:String {
        var toReturn = ""
        
        if self.contains(.FiresOnRecordUpdate)
        {
            toReturn += "_Update"
        }
        
        if self.contains(.FiresOnRecordDeletion)
        {
            toReturn += "_Delete"
        }
        
        if self.contains(.FiresOnRecordCreation)
        {
            toReturn += "_Create"
        }
        
        if self.contains(.FiresOnce)
        {
            return "_Once"
        }
        
        return toReturn
    }
}