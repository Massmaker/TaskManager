//
//  TasksViewController+TasksHoldingDelegate.swift
//  TaskManager
//
//  Created by CloudCraft on 1/19/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import UIKit

extension TasksViewController:TasksHoldingDelegate {
    
    func tasksHolderWillStartUpdatingHandledTasks() {
        
        networkingIndicator(true)
        
        dispatch_async(dispatch_get_main_queue()){[unowned self] in
            
            self.tableView.userInteractionEnabled = false
        }
    }
    
    func tasksHolderDidFinishUpdatingHandledTasks() {
        networkingIndicator(false)
        dispatch_async(dispatch_get_main_queue()){[unowned self] in
            
            if let presentedEditor = self.presentedViewController
            {
                presentedEditor.dismissViewControllerAnimated(true, completion: { () -> Void in
                    self.tableView.userInteractionEnabled = true
                    self.tableView.reloadSections(NSIndexSet(index: 1), withRowAnimation: .Automatic)
                })
            }
            else
            {
                self.tableView.userInteractionEnabled = true
                self.tableView.reloadSections(NSIndexSet(index: 1), withRowAnimation: .Automatic)
            }
            
        }
    }
    
    func tasksHolderWillInsertNewTaskAtIndex(index: Int) {
        dispatchMain(){[weak self] in
            self?.tableView.userInteractionEnabled = false
        }
    }
    
    func tasksHolderDidInsertNewTaskAtIndex(index:Int)
    {
        dispatchMain(){[weak self] in
            self?.tableView.userInteractionEnabled = false
            self?.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 1)], withRowAnimation: .Automatic)
            self?.tableView.userInteractionEnabled = true
            
            if let presentedEditor = self?.presentedViewController
            {
                presentedEditor.dismissViewControllerAnimated(true, completion: nil)
            }
        }
    }
    
    func tasksHolderDidFailFetchingTasksWithError(error:ErrorType)
    {
        dispatchMain(){[weak self] in
            print("error fetching tasks:")
            print(error)
                self?.showAlertController("Could not load tasks", text: (error as NSError).domain, closeButtonTitle: "Close")
        }
    }
}
