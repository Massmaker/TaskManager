//
//  BoardsHolder.swift
//  TaskCloud
//
//  Created by CloudCraft on 1/15/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import Foundation
class BoardsHolder:BoardsHolding {
    
    //MARK: -
    convenience init(delegate:BoardsHolderDelegate)
    {
        self.init()
        self.delegate = delegate
    }
    
    //MARK: - BoardsHolding
    weak var delegate:BoardsHolderDelegate?
    private var currentBoards:[TaskBoardInfo] = [TaskBoardInfo]()
    
    var boardsCount:Int{
        return currentBoards.count
    }
    func boardForRow(row: Int) -> TaskBoardInfo? {
        if row < currentBoards.count
        {
            return currentBoards[row]
        }
        return nil
    }
    
    func boardIndexes() -> [Int] {
        if !currentBoards.isEmpty
        {
            var indexes = [Int]()
            for aTaskBoard in currentBoards
            {
                indexes.append(aTaskBoard.sortOrderIndex)
            }
            return indexes
        }
        else
        {
            return [Int]() //empty array
        }
    }
    
    func setBoards(boards: [TaskBoardInfo]) {
        delegate?.boardsHolderWillUpdateBoards(self)
        self.currentBoards.removeAll(keepCapacity: false)
        self.currentBoards = boards
        delegate?.boardsHolderDidUpdateBoards(self)
    }
    
    func getBoards() -> [TaskBoardInfo] {
        return self.currentBoards
    }
    
    func removeBoardAtIndex(index:Int) throws -> TaskBoardInfo
    {
        if index >= currentBoards.count
        {
            throw TaskBoardError.NotFound
        }
        
        return currentBoards.removeAtIndex(index)
    }
    
    func insertBoard(board:TaskBoardInfo, atIndex index:Int) throws
    {
        if index > currentBoards.count
        {
            throw TaskBoardError.NotFound
        }
        delegate?.boardsHolderWillUpdateBoards(self)
        currentBoards.insert(board, atIndex: index)
        delegate?.boardsHolderDidUpdateBoards(self)
    }
    
    func updateBoard(board:TaskBoardInfo)
    {
        guard let boardId = board.recordId else
        {
            delegate?.boardsHolderDidUpdateBoards(self)
            return
        }
        
        delegate?.boardsHolderWillUpdateBoards(self)
        
        var foundBoard:TaskBoardInfo?
        
        var index:Int = 0
        
        InternalLoop: for aBoard in self.currentBoards
        {
            if let anId = aBoard.recordId where anId.recordName == boardId.recordName
            {
                //do{
                     if let lvIndex = self.currentBoards.indexOf({ (testBoard) -> Bool in
                        return testBoard.title == aBoard.title
                     })
                    {
                        index = lvIndex
                    }
                //}
                //catch{
                    
                //}
                
                foundBoard = aBoard
                break InternalLoop
            }
        }
        
        foundBoard?.title = board.title
        foundBoard?.details = board.details
        foundBoard?.sortOrderIndex = board.sortOrderIndex
        if let toInsert = foundBoard
        {
            self.currentBoards.removeAtIndex(index)
            self.currentBoards.insert(toInsert, atIndex: index)
        }
        else
        {
            self.currentBoards.append(board)
        }
        
        
        delegate?.boardsHolderDidUpdateBoards(self)
        
    }
    
 
}