//
//  BoardsTableViewController+BoardsHolderDelegate.swift
//  TaskManager
//
//  Created by CloudCraft on 2/2/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import Foundation
extension BoardsTableViewController : BoardsHolderDelegate{
    
    func boardsDidStartUpdating() {
        networkingIndicator(true)
        dispatchMain(){
            self.tableView.scrollEnabled = false
        }
        print(" disabled user scrolling in BOARDS")
    }
    
    func boardsDidFinishUpdating() {
        
        // perform on main queue
        var currentExecutingQueue:NSOperationQueue?
        
        if let currentQueue = NSOperationQueue.currentQueue() where currentQueue == NSOperationQueue.mainQueue()
        {
            currentExecutingQueue = currentQueue
        }
        else
        {
            currentExecutingQueue = NSOperationQueue.mainQueue()
        }
        
        currentExecutingQueue!.addOperationWithBlock(){ [weak self] in
            networkingIndicator(false)
            if let visibleIndexPaths = self?.tableView.indexPathsForVisibleRows
            {
                self?.tableView.reloadRowsAtIndexPaths(visibleIndexPaths, withRowAnimation: .Automatic)
            }
            else
            {
                self?.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
            }
            
            self?.tableView.scrollEnabled = true
            print(" enabled user scrolling in BOARDS")
        }
    }
}