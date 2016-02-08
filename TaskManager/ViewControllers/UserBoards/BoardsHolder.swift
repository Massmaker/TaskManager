//
//  BoardsHolder.swift
//  TaskCloud
//
//  Created by CloudCraft on 1/15/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import Foundation

class BoardsHolder : NSObject { 
    
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
        currentBoards.insert(board, atIndex: index)
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
        
        anAppDelegate()?.coreDatahandler?.saveMainContext()
        
        delegate?.boardsDidFinishUpdating()
        
        anAppDelegate()?.cloudKitHandler.editBoard(board) { (editedRecord, editError) -> () in
            if let error = editError
            {
                print("\n - Error updating board in CloudKit database:")
                print(error)
            }
            else{
                dispatchMain(){
                    self.delegate?.boardsDidFinishUpdating()
                }
            }
        }
    }
    
    func addNew(board:Board) -> Bool
    {
        guard let coreDataHandler = anAppDelegate()?.coreDatahandler else
        {
            return false
        }
        
        //start submitting new board to cloud
        
        self.delegate?.boardsDidStartUpdating()
        let result =  anAppDelegate()!.cloudKitHandler.submitNewBoardWithInfo(board) { (createdBoard, error) -> () in
            dispatchMain(){
                if let error = error
                {
                    print("\n Did not submit new board to CloudKit:")
                    print(error)
                    coreDataHandler.deleteSingle(board)
                    coreDataHandler.saveMainContext()
                }
                else if let recordSaved = createdBoard
                {
                    board.fillInfoFromRecord(recordSaved)
                    coreDataHandler.saveMainContext()
                    self.fetchBoardsFromCoreData()
                }
                
                self.delegate?.boardsDidFinishUpdating()
            }
        }
        
        
        return result
    }
    
    func updateBoardsSortIndexes()
    {
        var index:Int64 = 0
        for aBoard in currentBoards
        {
            aBoard.sortOrder = index
            index += 1
        }
        
        anAppDelegate()?.coreDatahandler?.saveMainContext()
        
        anAppDelegate()?.cloudKitHandler.editMany(currentBoards) { (edited, deleted, error) -> () in
            
            dispatchMain(){
                
                if let edited = edited
                {
                    for editedBoardRecord in edited
                    {
                        do{
                            try anAppDelegate()?.coreDatahandler?.createBoardFromRecord(editedBoardRecord)
                        }
                        catch{
                            
                        }
                    }
                }
                
                if let deletedIDs = deleted
                {
                    var boardIDs = [String]()
                    for anID in deletedIDs
                    {
                       boardIDs.append(anID.recordName)
                    }
                    do{
                        try anAppDelegate()?.coreDatahandler?.deleteBoardsByIDs(boardIDs, saveImmediately: false)
                    }
                    catch let error{
                        print("\n - ERROR: Could not delete boards by board IDs")
                        print(error)
                    }
                }
                
                if let error = error
                {
                    print(" - error updating Boards in CloudKit:")
                    print(error)
                }
                
                anAppDelegate()?.coreDatahandler?.saveMainContext()
                
                self.fetchBoardsFromCoreData()
            }
        }
    }
    
    ///fetches boards and sets result to current Boards
    func fetchBoardsFromCoreData()
    {
        if let coreDatahandler = anAppDelegate()?.coreDatahandler
        {
            let boardsFromCoreData = coreDatahandler.allBoards(false)
            
            self.currentBoards = boardsFromCoreData
        }
    }
    
    func removeAllBoardsFromSelf()
    {
        self.currentBoards.removeAll()
    }
 
}