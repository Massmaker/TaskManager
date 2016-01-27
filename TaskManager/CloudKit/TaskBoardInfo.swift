//
//  TaskBoardInfo.swift
//  TaskCloud
//
//  Created by CloudCraft on 1/14/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//
import CloudKit
import Foundation

let BoardCreatorIDKey = "boardCreator"
let BoardTitleKey = "boardTitle"
let BoardDetailsKey = "boardDetails"


struct TaskBoardInfo {
   
    var sortOrderIndex:Int = 1
    var recordId:CKRecordID?{
        set(newValue){
            self._boardId = newValue
            print("board Id: \(self._boardId?.recordName)")
        }
        get{
            print("reading board id: \(self._boardId?.recordName)")
            return self._boardId
        }
    }
    
    
    private var _boardId:CKRecordID?
    var title:String
    var details:String = ""
    var creatorId:String?
    
    init(title:String)
    {
        self.title = title
    }
    
    /**
     initializes instance with `boardTitle` as empty string
     */
    init(details:String)
    {
        self.title = ""
        self.details = details
    }
    
    init(title:String, details:String)
    {
        self.title = title
        self.details = details
    }
    
    init?(boardRecord:CKRecord?)
    {
        guard let record = boardRecord else
        {
            return nil
        }
        
        self.title = record[BoardTitleKey] as! String
        self.details = record[BoardDetailsKey] as! String
        self.recordId = record.recordID
        
        if let index = record[SortOrderIndexIntKey] as? NSNumber
        {
            self.sortOrderIndex = index.integerValue
        }
        
        if let creatorId = record[BoardCreatorIDKey] as? String
        {
            self.creatorId = creatorId
        }
    }
    
    mutating func setCreatorId(string:String?)
    {
        self.creatorId = string
    }
}

//MARK: - Extension
extension TaskBoardInfo:SortableByIndex{
    
}