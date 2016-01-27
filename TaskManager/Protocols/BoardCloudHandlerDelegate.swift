//
//  BoardCloudHandlerDelegate.swift
//  TaskManager
//
//  Created by CloudCraft on 1/18/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import Foundation
import CloudKit

protocol BoardCloudHandlerDelegate : class {
    //recieving
    func boardCloudHandlerDidStartQueryingForBoards()
    func boardsCloudHandlerDidFinishQueryingForBoards(boards:[CKRecord], queryError:NSError?)
    //sending
    func boardCloudHandlerDidStartSubmittingToICloud()
    func boardCloudHandlerDidFinishSubmitingToIcloud(board:CKRecord?, submitError:NSError?)
    func boardCloudHandlerDidFinishEditingBoard(board:TaskBoardInfo, error:NSError?)
    //deleting
    func boardCloudHandlerDidStartDeletingBoard()
    func boardCloudHandlerDidFinishDeletingBoard(boardObject:TaskBoardInfo, deletingError:NSError?)
    
    //cancell editing
    func boardCloudHandlerDidCancel()
}