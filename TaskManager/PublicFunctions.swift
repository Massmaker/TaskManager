//
//  PublicFunctions.swift
//  TaskCloud
//
//  Created by CloudCraft on 1/14/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import Foundation
import UIKit

func anAppDelegate() -> AppDelegate?
{
    guard let delegate = UIApplication.sharedApplication().delegate as? AppDelegate else
    {
        return nil
    }
    return delegate
}

func networkingIndicator(visible:Bool)
{
    UIApplication.sharedApplication().networkActivityIndicatorVisible = visible
}

func dispatchMain(closure:dispatch_block_t)
{
    dispatch_async(dispatch_get_main_queue(),closure)
}

func dispatchMainSync(closure:dispatch_block_t)
{
    dispatch_sync(dispatch_get_main_queue(), closure)
}

func dispatchBackground(closure:dispatch_block_t)
{
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), closure)
}

//MARK: -  sort Tasks or Boards by "sortOrderIndex"

func == <T: SortableByIndex> (lhs: T, rhs: T) -> Bool {
    return lhs.sortOrderIndex == rhs.sortOrderIndex
}

func < <T: SortableByIndex> (lhs: T, rhs: T) -> Bool {
    return lhs.sortOrderIndex < rhs.sortOrderIndex
}

func > <T:SortableByIndex> (lhs: T, rhs: T) -> Bool {
    return lhs.sortOrderIndex > rhs.sortOrderIndex
}

//MARK: - find index in array of values that conform to "RecordIdIndexable"
func indexOf <T:RecordIdIndexable> (target:T, inArray:[T]) -> Int?
{
    if target.recordId == nil
    {
        return nil
    }
    
    for (index, value) in inArray.enumerate()
    {
        if let recordId = value.recordId where recordId.recordName == target.recordId!.recordName
        {
            return index
        }
    }
    
    return nil
}