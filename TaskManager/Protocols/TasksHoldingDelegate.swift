//
//  TasksHoldingDelegate.swift
//  TaskManager
//
//  Created by CloudCraft on 1/19/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import Foundation

protocol TasksHoldingDelegate:class {
    
    func tasksHolderWillStartUpdatingHandledTasks()
    func tasksHolderDidFinishUpdatingHandledTasks()
    func tasksHolderWillInsertNewTaskAtIndex(index:Int)
    func tasksHolderDidInsertNewTaskAtIndex(index:Int)
    func tasksHolderDidFailFetchingTasksWithError(error:ErrorType)
}