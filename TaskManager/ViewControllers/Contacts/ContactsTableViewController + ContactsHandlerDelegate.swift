//
//  ContactsTableViewController + ContactsHandlerDelegate.swift
//  TaskManager
//
//  Created by CloudCraft on 3/10/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import UIKit

extension ContactsTableViewController: ContactsHandlerDelegate{
    
    
    func contactshandlerWillStartFetchingContacts() {
        dispatchMain(){[weak self] in
            self?.setLoadingIndicatorVisible(true)
        }
    }
    
    func contactsHandlerDidStartFetchingContacts() {
        
    }
    
    func contactsHandlerDidFinishFetchingContacts(error: ErrorType?) {
        dispatchMain(){
            [weak self] in
            
            let timeout:dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 0.5))
            dispatch_after(timeout, dispatch_get_main_queue()) {
                self?.setLoadingIndicatorVisible(false)
            }
            
            if let errorFetchingDeviceContacts = error
            {
                var errorMessage = ""
                if let anError = errorFetchingDeviceContacts as? ErrorContacts, contactsErrorMessage = anError.getErrorMessage()
                {
                    errorMessage = contactsErrorMessage
                }
                else
                {
                    let nsError = errorFetchingDeviceContacts as NSError
                    errorMessage = nsError.localizedDescription
                }
                self?.showAlertController("Warning", text: errorMessage, closeButtonTitle: "Ok", closeAction: nil, presentationCompletion: nil)
            }
            else
            {
                self?.contactsTableView.reloadSections(NSIndexSet(index:0), withRowAnimation: .Automatic)
            }
        }
    }
    
    func contactsWillUpdate()
    {
        self.contactsTableView.scrollEnabled = false
    }
    
    func contactsDidUpdate() {
        self.contactsTableView.scrollEnabled = true
        
        self.contactsTableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic) //(NSIndexSet(index: 0))
        
        if self.refreshControl.refreshing
        {
            self.refreshControl.endRefreshing()
        }
    }
}