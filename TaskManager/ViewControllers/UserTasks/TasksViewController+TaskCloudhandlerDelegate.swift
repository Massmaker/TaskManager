//
//  TasksViewController+TaskCloudhandlerDelegate.swift
//  TaskManager
//
//  Created by CloudCraft on 1/19/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import UIKit

extension TasksViewController:TaskCloudHandlerDelegate {
    
    func taskCloudHandlerWillStartFetchingTasks()
    {
        networkingIndicator(true)
    }
    
    func taskCloudHandlerDidLoadTasks(tasks:[TaskInfo])
    {
        
    }
    
    func taskCloudHandlerDidFailToLoadTasks(error:ErrorType) {
    
        
    }
    
    func taskCloudHandlerWillStartSubmittingNewTask()
    {
        networkingIndicator(true)
    }
    
    func taskCloudHandlerDidFailToSubmitNewTask(task:TaskInfo, error:ErrorType)
    {
        
    }
    
    func taskCloudHandlerDidSubmitNewTask(task:TaskInfo)
    {
        networkingIndicator(false)
        dispatchMain { [weak self] in
            self?.tasksSource?.addTask(task)
        }
    }
    
    func taskCloudHandlerWillStartEditingTask()
    {
        networkingIndicator(true)
    }
    
    func taskCloudHandlerDidEditTask(editedTask:TaskInfo)
    {
        //reload tableview or particular row
        self.tasksSource?.updateTask(editedTask)
    }
    
    func taskCloudHandlerDidFailToEditTask(taskToEdit:TaskInfo, error:ErrorType)
    {
        dispatchMain(){ [weak self] in
            if let presentedEditor = self?.presentedViewController
            {
                presentedEditor.dismissViewControllerAnimated(true, completion: {
                    self?.showAlertController("Could not save task edits", text: "\(error)", closeButtonTitle: "Close")
                    })
            }
        }
        
    }
    
    func taskCloudHandlerWillStartDeletingTask()
    {
        networkingIndicator(true)
    }
    
    func cancelEditingTask()
    {
        if let presentedEditor = self.presentedViewController
        {
            presentedEditor.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    func taskCloudHandlerDidDeleteTask(task:TaskInfo)
    {
        
    }
    
    func taskCloudHandlerDidFailToDeleteTask(task:TaskInfo, error:ErrorType)
    {
        
    }
    
}