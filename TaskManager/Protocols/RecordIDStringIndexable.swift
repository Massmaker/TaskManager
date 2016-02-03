//
//  RecordIDStringIndexable.swift
//  TaskManager
//
//  Created by CloudCraft on 2/2/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import Foundation
protocol RecordIDStringIndexable {
    var recordId:String?{get set}
}


///compares CoreData  Boards and Tasks by **recordId** field
func < <T:RecordIDStringIndexable>(lhs:T, rhs:T) -> Bool
{
    if let leftRecordID = lhs.recordId, rightRecordID = rhs.recordId
    {
        return leftRecordID < rightRecordID
    }
    
    if let _ = lhs.recordId
    {
        return false
    }
    
    if let _ = rhs.recordId
    {
        return true
    }
    
    return true
    
}

func == <T:RecordIDStringIndexable> (lhs:T, rhs:T) -> Bool
{
    if let leftID = lhs.recordId, rightID = rhs.recordId
    {
        return leftID == rightID
    }
    
    return false
}