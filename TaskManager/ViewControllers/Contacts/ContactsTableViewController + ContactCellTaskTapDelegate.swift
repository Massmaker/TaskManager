//
//  ContactsTableViewController+ContactCellTaskTapDelegate.swift
//  TaskManager
//
//  Created by CloudCraft on 3/11/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import UIKit

extension ContactsTableViewController: ContactCellTaskTapDelegate{
    
    func handleTapForTaskTitleLabel(label: UILabel?, recognizer:UITapGestureRecognizer?) {
        
        guard let _ = label?.text else{
            return
        }
        
        if let recognizer = recognizer {
            
            let point = recognizer.locationInView(self.contactsTableView)
            if let indexPath = self.contactsTableView.indexPathForRowAtPoint(point){
                if let contact = self.contactForIndexPath(indexPath), phone = contact.phone{
                    if let task = anAppDelegate()?.coreDatahandler?.findActiveTasksForUserById(phone)?.first{
                        self.showTaskEditFor(task)
                    }
                }
            }
        }
    }
}