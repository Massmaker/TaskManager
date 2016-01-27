//
//  TaskSource.swift
//  TaskManager
//
//  Created by CloudCraft on 1/19/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import UIKit
import CloudKit

protocol TasksHolding:class {
    
    var delegate:TasksHoldingDelegate?{get set}
    init(tableView:UITableView)
    
    func taskForRow(row:Int) -> TaskInfo?
    func setTasks(tasks:[TaskInfo])
    func getTasks() -> [TaskInfo]
    func addTask(taskInfo:TaskInfo)
    func updateTask(taskInfo:TaskInfo)
    func deleteTaskAtIndex(index:Int) -> Bool
    
    func tryFetchingTasksForBoard(boardId:CKRecordID)
}
