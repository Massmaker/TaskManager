//
//  BoardCloudHandler.swift
//  TaskManager
//
//  Created by CloudCraft on 1/18/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import Foundation
import CloudKit

protocol BoardCloudHandler : class {
    var delegate:BoardCloudHandlerDelegate?{get}
    init(delegate:BoardCloudHandlerDelegate)
    func submitBoard(board:TaskBoardInfo?)
    func editBoard(board:TaskBoardInfo)
    func requestUserBoards()
    func deleteBoard(boardInfo:TaskBoardInfo)
    func cancelEditingBoard()
}