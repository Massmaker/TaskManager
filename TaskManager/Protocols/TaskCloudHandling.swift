//
//  TaskCloudHandler.swift
//  TaskManager
//
//  Created by CloudCraft on 1/19/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//


import CloudKit

protocol TaskCloudHandling:class {
    
    var delegate:TaskCloudHandlerDelegate?{get set}
    init(delegate:TaskCloudHandlerDelegate)
    func submitTask(task:TaskInfo)
    func editTask(taskInfo:TaskInfo)
    func deleteTask(task:TaskInfo)
    func fetchTasksForBoardId(boardId:CKRecordID)
    func cancelEditingTask()
    
}