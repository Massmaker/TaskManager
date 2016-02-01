//
//  TasksCloudHandler.swift
//  TaskManager
//
//  Created by CloudCraft on 1/20/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import Foundation
import CloudKit

class TasksCloudHandler:TaskCloudHandling
{
    weak var delegate:TaskCloudHandlerDelegate?
    
    required init(delegate: TaskCloudHandlerDelegate) {
        self.delegate = delegate
    }
    
    func submitTask(task: TaskInfo) {
        
        var editableTask = task
        
        self.delegate?.taskCloudHandlerWillStartSubmittingNewTask()
        
        anAppDelegate()?.cloudKitHandler.submitTask(editableTask) { (taskRecord, savingError) -> () in
            guard let record = taskRecord else
            {
                if let anError = savingError
                {
                    self.delegate?.taskCloudHandlerDidFailToSubmitNewTask(task, error: TaskError.CloudKit(cloudError: anError) )
                    return
                }
                
                self.delegate?.taskCloudHandlerDidFailToSubmitNewTask(task, error: TaskError.Unknown)
                return
            }
            
            editableTask.setRecordId(record.recordID)
            
            self.delegate?.taskCloudHandlerDidSubmitNewTask(editableTask)
        }
        
    }
    
    func editTask(taskInfo: TaskInfo) {
        
        guard let apDelegate = anAppDelegate() else
        {
            
            return
        }
        
        self.delegate?.taskCloudHandlerWillStartEditingTask()
        
        apDelegate.cloudKitHandler.editTask(taskInfo) { [weak self] (editedRecord, editError) in
            if let _ = editedRecord
            {
                self?.delegate?.taskCloudHandlerDidEditTask(taskInfo)
            }
            else if let anError = editError
            {
                self?.delegate?.taskCloudHandlerDidFailToEditTask(taskInfo, error: anError)
            }
        }
        
    }
    func deleteTask(task: TaskInfo) {
        anAppDelegate()?.cloudKitHandler.deleteTask(task) {[weak self] (deletedId, deletionError) -> () in
            
            dispatchMain(){
                if let _ = deletedId
                {
                    self?.delegate?.taskCloudHandlerDidDeleteTask(task)
                }
                else
                {
                    self?.delegate?.taskCloudHandlerDidFailToDeleteTask(task, error: deletionError!)
                }
            }
        }
    }
    
    func fetchTasksForBoardId(boardId: CKRecordID) {
        
    }
    
    func cancelEditingTask()
    {
        self.delegate?.cancelEditingTask()
    }
}