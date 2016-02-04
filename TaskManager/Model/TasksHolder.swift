//
//  TasksHolder.swift
//  TaskManager
//
//  Created by CloudCraft on 1/19/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import UIKit
import CloudKit

class TasksHolder:NSObject {
    
    override init() {
        super.init()
    }
    
    
    //MARK: - TasksHolding
    private weak var table:UITableView?
    
    private lazy var currentTasks:[Task] = [Task]()
    
    weak var delegate:TasksHolderDelegate?
    weak var board:Board?{
        didSet{
            
            let _ = currentTasks.count
            
            if let tasks = board?.orderedTasks
            {
                self.currentTasks = tasks
            }
            
            if self.currentTasks.isEmpty && self.board != nil
            {
                DataSyncronizer.sharedSyncronizer.startSyncingTasksFor(self.board!)
            }
        }
    }
    
    required init(tableView: UITableView) {
        self.table = tableView
    }
    
    
    func setTasks(tasks:[Task])
    {
        delegate?.tasksWillStartUpdating()
        
        currentTasks.removeAll(keepCapacity: false)
        currentTasks += tasks
        
        delegate?.tasksDidFinishUpdating()
    }
    
    func getTasks() -> [Task]
    {
        return self.currentTasks
    }
    
    func taskForRow(row: Int) -> Task?
    {
        if row >= 0 && row < currentTasks.count
        {
            return currentTasks[row]
        }
        return nil
    }
    
    func deleteTask(task:Task)
    {
        if let index = self.currentTasks.indexOf(task)
        {
            task.toBeDeleted = true
            anAppDelegate()?.coreDatahandler?.saveMainContext()
            
            self.currentTasks.removeAtIndex(index)
        }
    }
    
    func deleteTaskAtIndex(indexOfTask:Int) -> Bool
    {
        guard indexOfTask >= 0 else
        {
            return false
        }
        
        var deletionHappened = false
        
        if currentTasks.count < indexOfTask
        {
            let toDelete = currentTasks.removeAtIndex(indexOfTask)
            toDelete.toBeDeleted = true
            anAppDelegate()?.coreDatahandler?.saveMainContext()
            if let toBeDeletedTaskIDs = anAppDelegate()?.coreDatahandler?.findTasksToDelete()
            {
                anAppDelegate()?.cloudKitHandler.deleteTasks(toBeDeletedTaskIDs) { (deletedCount, deletionError) -> () in
                    
                }
            }
            deletionHappened = true
        }
        
        return deletionHappened
    }
    
    func editTask(taskToEdit:Task)
    {
        
    }
    
    func insertNewTask(taskToInsert:Task)
    {
        
    }
    
    
    func handleSyncNotification(note:NSNotification)
    {
        switch note.name
        {
        case DataSyncronizerDidStartSyncronyzingNotificationName:
            self.delegate?.tasksWillStartUpdating()
        case DataSyncronizerDidStopSyncronyzingNotificationName:
            self.setTasks(board!.orderedTasks)
            self.table?.reloadSections(NSIndexSet(index: 1), withRowAnimation: .Automatic)
            self.delegate?.tasksDidFinishUpdating()
        default:
            break
        }
    }
}
