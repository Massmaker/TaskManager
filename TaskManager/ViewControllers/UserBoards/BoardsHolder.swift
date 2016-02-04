//
//  BoardsHolder.swift
//  TaskCloud
//
//  Created by CloudCraft on 1/15/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import Foundation
class BoardsHolder {
    
    //MARK: -
    convenience init(delegate:BoardsHolderDelegate)
    {
        self.init()
        self.delegate = delegate
    }
    
    //MARK: - BoardsHolding
    weak var delegate:BoardsHolderDelegate?{
        didSet{
            if let _ = self.delegate
            {
                self.fetchBoardsFromCoreData()
            }
        }
    }
    private var currentBoards:[Board] = [Board]()
    
    var boardsCount:Int{
        return currentBoards.count
    }
    func boardForRow(row: Int) -> Board? {
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
                indexes.append(Int(aTaskBoard.sortOrder))
            }
            return indexes
        }
        else
        {
            return [Int]() //empty array
        }
    }
    
    func setBoards(boards: [Board]) {
        delegate?.boardsDidStartUpdating()
        self.currentBoards.removeAll(keepCapacity: false)

        for aBoard in boards
        {
            anAppDelegate()?.coreDatahandler?.insert(aBoard, saveImmediately: false)
        }
        
        anAppDelegate()?.coreDatahandler?.saveMainContext()
        
        delegate?.boardsDidFinishUpdating()
    }
    
    func getBoards() -> [Board] {
        if self.currentBoards.isEmpty
        {
            self.fetchBoardsFromCoreData()
        }
        return self.currentBoards
    }
    
    func removeBoardAtIndex(index:Int) throws -> Board
    {
        if index >= currentBoards.count
        {
            throw TaskBoardError.NotFound
        }
        
        return currentBoards.removeAtIndex(index)
    }
    
    func insertBoard(board:Board, atIndex index:Int) throws
    {
        if index > currentBoards.count
        {
            throw TaskBoardError.NotFound
        }
    }
    
    func deleteFromDatabase(board:Board)
    {
        board.toBeDeleted = true
        anAppDelegate()?.coreDatahandler?.saveMainContext()
    }
    
    func updateBoard(board:Board)
    {
        guard let _ = board.recordId else
        {
            return
        }
        
        delegate?.boardsDidStartUpdating()
        
        var foundBoard:Board?
        
        if let indexOfBoard = self.currentBoards.indexOf(board)
        {
            foundBoard = self.currentBoards[indexOfBoard]
        }
        
        if let toInsert = foundBoard
        {
            toInsert.title = board.title
            toInsert.details = board.details
            toInsert.sortOrder = board.sortOrder
            toInsert.participants = board.participants
        }
        else
        {
            anAppDelegate()?.coreDatahandler?.insert(board, saveImmediately: false)
           
            self.currentBoards.append(board)
        }
        anAppDelegate()?.coreDatahandler?.saveMainContext()
        
        delegate?.boardsDidFinishUpdating()
    }
    
    func fetchBoardsFromCoreData()
    {
        if let coreDatahandler = anAppDelegate()?.coreDatahandler
        {
            let boardsFromCoreData = coreDatahandler.allBoards()
            
            self.currentBoards = boardsFromCoreData
        }
    }
 
}