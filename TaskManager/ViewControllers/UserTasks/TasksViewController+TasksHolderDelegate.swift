//
//  TasksViewController+TasksHolderDelegate.swift
//  TaskManager
//
//  Created by CloudCraft on 2/2/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import Foundation
extension TasksViewController : TasksHolderDelegate {
    
    func tasksWillStartUpdating()
    {
        setLoadingIndicatorVisible(true)
    }
    
    func tasksDidFinishUpdating()
    {
        setLoadingIndicatorVisible(false)
    }
}