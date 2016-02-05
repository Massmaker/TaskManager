//
//  TempTaskInfo.swift
//  TaskManager
//
//  Created by CloudCraft on 2/5/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import Foundation
struct TempTaskInfo{
    
    let boardID:String
    
    var creator:String = ""
    var title:String = ""
    var details:String = ""
    
    init?(boardRecord:String?)
    {
        if boardRecord == nil
        {
            return nil
        }
        if boardRecord!.isEmpty
        {
            return nil
        }
        
        self.boardID = boardRecord!
    }
    
    mutating func setTitle(title:String)
    {
        self.title = title
    }
    
    mutating func setDetails(details:String)
    {
        self.details = details
    }
    
    mutating func setCreator(id:String)
    {
        self.creator = id
    }
    
}