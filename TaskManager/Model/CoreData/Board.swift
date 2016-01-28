//
//  Board.swift
//  TaskCloud
//
//  Created by CloudCraft on 1/15/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import Foundation
import CoreData


class Board: NSManagedObject {

// Insert code here to add functionality to your managed object subclass
    
    func fillBasicInfoFrom(boardInfo:TaskBoardInfo)
    {
        self.creatorId = boardInfo.creatorId
        self.recordId = boardInfo.recordId?.recordName
        self.details = boardInfo.details
        self.title = boardInfo.title
        self.dateCreated = boardInfo.dateCreated
        self.sortOrder = NSNumber(integer: boardInfo.sortOrderIndex)
    }

}
