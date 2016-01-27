//
//  TaskCloudHandlerDelegate.swift
//  TaskManager
//
//  Created by CloudCraft on 1/19/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import Foundation

protocol TaskCloudHandlerDelegate:class {
    
    func taskCloudHandlerWillStartFetchingTasks()
    func taskCloudHandlerDidLoadTasks(tasks:[TaskInfo])
    func taskCloudHandlerDidFailToLoadTasks(error:ErrorType)
    
    func taskCloudHandlerWillStartSubmittingNewTask()
    func taskCloudHandlerDidFailToSubmitNewTask(task:TaskInfo, error:ErrorType)
    func taskCloudHandlerDidSubmitNewTask(task:TaskInfo)
    
    func taskCloudHandlerWillStartEditingTask()
    func taskCloudHandlerDidEditTask(editedTask:TaskInfo)
    func taskCloudHandlerDidFailToEditTask(taskToEdit:TaskInfo, error:ErrorType)
    func cancelEditingTask()
    
    func taskCloudHandlerWillStartDeletingTask()
    func taskCloudHandlerDidDeleteTask(task:TaskInfo)
    func taskCloudHandlerDidFailToDeleteTask(task:TaskInfo, error:ErrorType)
}