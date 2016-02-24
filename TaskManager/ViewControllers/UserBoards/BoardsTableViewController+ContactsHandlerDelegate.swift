//
//  BoardsTableViewController+ContactsHandlerDelegate.swift
//  TaskManager
//
//  Created by CloudCraft on 2/2/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import Foundation

extension BoardsTableViewController:ContactsHandlerDelegate{
    
    func contactsWillUpdate() {
        
    }
    
    func contactsDidUpdate() {
        self.tableView.reloadSections(NSIndexSet(index: 1), withRowAnimation: .Automatic)
    }
    
    func contactshandlerWillStartFetchingContacts() {
        
    }
    
    func contactsHandlerDidStartFetchingContacts() {
        
    }
    
    func contactsHandlerDidFinishFetchingContacts(error: ErrorType?) {
        
        if let visibleRowsIndexPaths = self.tableView.indexPathsForSelectedRows
        {
            self.tableView.reloadRowsAtIndexPaths(visibleRowsIndexPaths, withRowAnimation: .Automatic)
        }
        else
        {
            self.tableView.reloadSections(NSIndexSet(index: 1), withRowAnimation: .Automatic)
        }
    }
}