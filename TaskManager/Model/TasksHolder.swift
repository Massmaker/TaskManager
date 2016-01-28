//
//  TasksHolder.swift
//  TaskManager
//
//  Created by CloudCraft on 1/19/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import UIKit
import CloudKit

class TasksHolder:TasksHolding {
    
    
    //MARK: - TasksHolding
    private weak var table:UITableView?
    
    private lazy var currentTasks:[TaskInfo] = [TaskInfo]()
    
    weak var delegate:TasksHoldingDelegate?
    
    required init(tableView: UITableView) {
        self.table = tableView
    }
    
    func setTasks(tasks:[TaskInfo])
    {
        delegate?.tasksHolderWillStartUpdatingHandledTasks()
        
        currentTasks.removeAll(keepCapacity: false)
        currentTasks += tasks
        
        delegate?.tasksHolderDidFinishUpdatingHandledTasks()
    }
    
    func getTasks() -> [TaskInfo]
    {
        return self.currentTasks
    }
    
    func taskForRow(row: Int) -> TaskInfo?
    {
        if row >= 0 && row < currentTasks.count
        {
            return currentTasks[row]
        }
        return nil
    }
    
    func addTask(taskInfo:TaskInfo)
    {
        currentTasks.append(taskInfo)
        delegate?.tasksHolderDidInsertNewTaskAtIndex(currentTasks.count - 1)
    }
    
    func updateTask(taskInfo:TaskInfo)
    {
        if let hasIndex = indexOf(taskInfo, inArray: self.currentTasks)
        {
            //update
            dispatch_sync(dispatch_get_main_queue()){
                self.delegate?.tasksHolderWillStartUpdatingHandledTasks()
            }
            
            self.currentTasks.removeAtIndex(hasIndex)
            self.currentTasks.insert(taskInfo, atIndex: hasIndex)
            
            self.delegate?.tasksHolderDidFinishUpdatingHandledTasks()
            
        }
        else
        {
            //insert
            let index = self.currentTasks.count
            dispatch_sync(dispatch_get_main_queue()){
                self.delegate?.tasksHolderWillInsertNewTaskAtIndex(index)
            }
            
            self.currentTasks.insert(taskInfo, atIndex: index)
            
            self.delegate?.tasksHolderDidInsertNewTaskAtIndex(index)
        }
    }
    
    func deleteTaskAtIndex(index:Int) -> Bool
    {
        guard index >= 0 && index < currentTasks.count else
        {
            return false
        }
        
        self.delegate?.tasksHolderWillStartUpdatingHandledTasks()
        let taskToDelete = currentTasks.removeAtIndex(index)
        
        anAppDelegate()?.cloudKitHandler.deleteTask(taskToDelete){ (deletedId, deletionError) -> () in
            if let _ = deletionError
            {
                self.currentTasks.insert(taskToDelete, atIndex: index)
            }
            
            self.delegate?.tasksHolderDidFinishUpdatingHandledTasks()
        }
        
        return true
    }
    
    func deleteTask(task: TaskInfo)
    {
        if let index = indexOf(task, inArray: self.currentTasks)
        {
            self.delegate?.tasksHolderWillStartUpdatingHandledTasks()
            self.currentTasks.removeAtIndex(index)
            self.delegate?.tasksHolderDidFinishUpdatingHandledTasks()
        }
    }
    
    //MARK: - 
    func tryFetchingTasksForBoard(boardId:CKRecordID)
    {
        
        guard let aDelegate = anAppDelegate() else
        {
            delegate?.tasksHolderDidFinishUpdatingHandledTasks()
            return
        }
        
        delegate?.tasksHolderWillStartUpdatingHandledTasks()
        
        aDelegate.cloudKitHandler.loadTasksForBoardId(boardId) {[weak self] (tasks, error) -> () in

            //self?.delegate?.tasksHolderDidFinishUpdatingHandledTasks()
            
            //warning - here is not MainQueue
            if let records = tasks
            {
                self?.setTasks(records)
            }
            else if let anError = error
            {
                self?.delegate?.tasksHolderDidFailFetchingTasksWithError(anError)
            }
        }
    }
}
