//
//  TaskInfoObjectHolder.swift
//  TaskManager
//
//  Created by CloudCraft on 1/20/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import Foundation

//this class is created to pass task object as AnyObject, e.g. when performing segues
class TaskInfoObjectHolder{
    let taskInfo:TaskInfo
    init(taskInfo:TaskInfo)
    {
        self.taskInfo = taskInfo
    }
}