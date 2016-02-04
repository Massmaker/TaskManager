//
//  TaskBoardInfo.swift
//  TaskCloud
//
//  Created by CloudCraft on 1/14/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//
import CloudKit
import Foundation


struct TaskBoardInfo {
   
    var sortOrderIndex:Int = 1
    var recordId:CKRecordID?{
        set(newValue){
            self._boardId = newValue
            //print("board Id: \(self._boardId?.recordName)")
        }
        get{
            //print("reading board id: \(self._boardId?.recordName)")
            return self._boardId
        }
    }
    
    
    private var _boardId:CKRecordID?
    var title:String
    var details:String = ""
    var creatorId:String?
    var dateCreated:NSDate?
    var participants = [String]()
    
    init(){
        self.title = ""
        self.details = ""
    }
    
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
        
        self.title = record[TitleStringKey] as! String
        self.details = record[DetailsStringKey] as! String
        self.recordId = record.recordID
        self.dateCreated = record.creationDate
        
        if let index = record[SortOrderIndexIntKey] as? NSNumber
        {
            self.sortOrderIndex = index.integerValue
        }
        
        if let creatorId = record[BoardCreatorIDKey] as? String
        {
            self.creatorId = creatorId
        }
        
        if let participants = record[BoardParticipantsKey] as? [String]
        {
            self.participants = participants
        }
    }
    
    mutating func setCreatorId(string:String?)
    {
        self.creatorId = string
    }
    
    mutating func setInfoFromBoard(board:Board)
    {
        self.title = board.title ?? ""
        self.details = board.details ?? ""
        self.sortOrderIndex = Int(board.sortOrder)
        self.creatorId = board.creatorId
        self.dateCreated = NSDate(timeIntervalSinceReferenceDate: board.dateCreated)

        if let _ = board.recordId
        {
            self.recordId = CKRecordID(recordName: board.recordId!)
        }
        
       
    }
    
    mutating func setNewParticipants(participants:[String])
    {
        self.participants = participants
    }
}

//MARK: - Extension
extension TaskBoardInfo:SortableByIndex{
    
}

extension TaskBoardInfo:RecordIdIndexable{
    
}

extension TaskBoardInfo {
    
    var shortDateString:String?{
        if let aDate = self.dateCreated
        {
            return aDate.dateTimeCustomString()
        }
        return nil
    }
}