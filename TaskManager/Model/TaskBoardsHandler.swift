//
//  TaskBoardsHandler.swift
//  TaskManager
//
//  Created by CloudCraft on 1/18/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import Foundation
import CloudKit

class TaskBoardsHandler:BoardCloudHandling {
    
    //MARK: - BoardCloudHandler protocol conformance
    weak var delegate:BoardCloudHandlerDelegate?
    
    required init(delegate: BoardCloudHandlerDelegate)
    {
        self.delegate = delegate
    }
    
    func requestUserBoards()
    {
        self.delegate?.boardCloudHandlerDidStartQueryingForBoards()
        guard let _ = anAppDelegate() else
        {
            delegate?.boardsCloudHandlerDidFinishQueryingForBoards([CKRecord](), queryError: noAppDelegateError)
            return
        }
        
        var tempBoards = [CKRecord]()
        
        anAppDelegate()?.cloudKitHandler.queryForBoardsByCurrentUser(){[weak self] (boards, error) in
            if let boards = boards
            {
                tempBoards += boards
            }
            
            anAppDelegate()?.cloudKitHandler.queryForBoardsSharedWithMe(){ (boards, fetchError) -> () in
                if let sharedBoards = boards
                {
                    tempBoards += sharedBoards
                }
                
                dispatch_async(dispatch_get_main_queue()){
                    self?.delegate?.boardsCloudHandlerDidFinishQueryingForBoards(tempBoards, queryError: error)
                }
            }
            
            
        }
    }
    
    func submitBoard(board: TaskBoardInfo?)
    {
        if let aBoard = board
        {
            anAppDelegate()?.cloudKitHandler.submitNewBoardWithInfo(aBoard){[unowned self] (createdBoard, error) -> () in
                self.delegate?.boardCloudHandlerDidFinishSubmitingToIcloud(createdBoard, submitError: error)
            }
        }
        else
        {
            self.cancelEditingBoard()
        }
    }
    
    func editBoard(board: TaskBoardInfo)
    {
        self.delegate?.boardCloudHandlerDidStartDeletingBoard()
        guard let aDelegate = anAppDelegate() else
        {
            self.delegate?.boardCloudHandlerDidFinishDeletingBoard(board, deletingError: noAppDelegateError)
            return
        }
        
        guard let _ = board.recordId else
        {
            self.delegate?.boardCloudHandlerDidFinishDeletingBoard(board, deletingError: noBoardIdError)
            return
        }
        
        aDelegate.cloudKitHandler.editBoard(board) { (editedRecord, editError) -> () in
            dispatch_async(dispatch_get_main_queue()){[weak self] in
                if let _ = editedRecord
                {
                    self?.delegate?.boardCloudHandlerDidFinishEditingBoard(board, error: editError)
                }
            }
        }
    }
    
    func deleteBoard(boardInfo:TaskBoardInfo)
    {
        self.delegate?.boardCloudHandlerDidStartDeletingBoard()
        guard let aDelegate = anAppDelegate() else
        {
            self.delegate?.boardCloudHandlerDidFinishDeletingBoard(boardInfo, deletingError: noAppDelegateError)
            return
        }
        
        guard let boardId = boardInfo.recordId else
        {
           
            self.delegate?.boardCloudHandlerDidFinishDeletingBoard(boardInfo, deletingError: noBoardIdError)
            return
        }
        
        aDelegate.cloudKitHandler.deleteBoardWithID(boardId) { (deletedRecordId, error) -> () in
            if let _ = deletedRecordId
            {
                dispatch_async(dispatch_get_main_queue()){[weak self] in
                   self?.delegate?.boardCloudHandlerDidFinishDeletingBoard(boardInfo, deletingError: nil)
                }
            }
            else
            {
                dispatch_async(dispatch_get_main_queue()){[weak self] in
                    self?.delegate?.boardCloudHandlerDidFinishDeletingBoard(boardInfo, deletingError: error)
                }
            }
        }
    }
    
    func cancelEditingBoard()
    {
        self.delegate?.boardCloudHandlerDidCancel()
    }
    
    
    //MARK: -
}