//
//  BoardsTableVIewController+BoardCloudHandlerDelegate.swift
//  TaskManager
//
//  Created by CloudCraft on 1/18/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import Foundation
import CloudKit

extension BoardsTableViewController : BoardCloudHandlerDelegate{
    
    func boardCloudHandlerDidStartQueryingForBoards() {
        self.setLoadingIndicatorVisible(true)
    }
    
    func boardsCloudHandlerDidFinishQueryingForBoards(boards: [CKRecord], queryError: NSError?) {
        //refresh or insert boards into in-memory (to implement later -> and into CoreData)
        self.setLoadingIndicatorVisible(false)
        if let _ = queryError
        {
            NSLog(" - Board TableViewController. Error querying user boards.  -----")
        }
        else
        {
            if !boards.isEmpty
            {
                var newBoardInfos = [TaskBoardInfo]()
                for aBoardRecord in boards
                {
                    if let board = TaskBoardInfo(boardRecord: aBoardRecord)
                    {
                        newBoardInfos.append(board)
                    }
                }
                boardsHolder.setBoards(newBoardInfos)
            }
            print(".loadCurrentUserBoards completion block.")
            
        }
        
    }
    
    
    func boardCloudHandlerDidStartSubmittingToICloud() {
        self.setLoadingIndicatorVisible(true)
    }
    
    func boardCloudHandlerDidFinishSubmitingToIcloud(board: CKRecord?, submitError: NSError?) {
        self.setLoadingIndicatorVisible(false)
        if let taskBoardRecord = board, let boardInfo = TaskBoardInfo(boardRecord: taskBoardRecord)
        {
            dispatch_async(dispatch_get_main_queue()){[unowned self] in
                var currentBoards = self.boardsHolder.getBoards()
                currentBoards.append(boardInfo)
                self.boardsHolder.setBoards(currentBoards)
            }
            
            //add subscription board deleted
            
        }
        else if let anError = submitError
        {
            dispatch_async(dispatch_get_main_queue()){[weak self] in
                self?.showAlertController("Could not add board", text: anError.localizedFailureReason, closeButtonTitle: "Ok")
                
            }
        }
    }
    
    func boardCloudHandlerDidStartDeletingBoard() {
        self.setLoadingIndicatorVisible(true)
    }
    
    func boardCloudHandlerDidFinishDeletingBoard(boardInfo:TaskBoardInfo, deletingError: NSError?) {
        self.setLoadingIndicatorVisible(false)
        
        guard let anError = deletingError else
        {
            print(" ... successfully deleted record from iCloud ... ")
            return
        }
        
        
        if anError.domain == noAppDelegateError.domain
        {
            print("Some weird stuff. No appDepelage.")
        }
        else
        {
            self.showAlertController("Warning", text: "Troubles deleting board", closeButtonTitle: "Ok", closeAction: {[weak self] in
                do{
                    try self?.boardsHolder.insertBoard(boardInfo, atIndex: 0)
                }
                catch{
                    
                }
                }, presentationCompletion: nil)
        }
    }
    
    
    func boardCloudHandlerDidCancel(){
        if let presentedEditor = self.presentedViewController as? BoardEditNavigationController
        {
            presentedEditor.dismissViewControllerAnimated(true) { () -> Void in
                
            }
        }
    }
    
    func boardCloudHandlerDidFinishEditingBoard(board: TaskBoardInfo, error: NSError?) {
        self.setLoadingIndicatorVisible(false)
        guard let anError = error else
        {
            self.boardsHolder.updateBoard(board)
            return
        }
        
        //TODO: handle error editing on iCloud
        print("error editing Board ", anError.localizedDescription)
        self.showAlertController("Error", text: anError.localizedDescription, closeButtonTitle: "Ok")
    }
}