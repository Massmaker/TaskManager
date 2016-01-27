//
//  BoardsHolder.swift
//  TaskCloud
//
//  Created by CloudCraft on 1/15/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import Foundation

protocol BoardsHolding {
    
    var delegate:BoardsHolderDelegate?{get set}
    var boardsCount:Int{get}
    func boardForRow(row:Int) -> TaskBoardInfo?
    func boardIndexes() -> [Int]
    func setBoards(boards:[TaskBoardInfo])
    func getBoards() -> [TaskBoardInfo]
    
    //these should be used for animatable table view Deletions, Insertions and Movings
    func removeBoardAtIndex(index:Int) throws -> TaskBoardInfo
    func insertBoard(board:TaskBoardInfo, atIndex:Int) throws
    func updateBoard(board:TaskBoardInfo)
}