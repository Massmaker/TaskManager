//
//  ContactsCollectionViewController+ContactsHandlerDelegate.swift
//  TaskManager
//
//  Created by CloudCraft on 1/26/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import UIKit
extension ContactsCollectionViewController : ContactsHandlerDelegate{
    //MARK: - ContactsHandlerDelegate
    func contactshandlerWillStartFetchingContacts() {
        dispatch_async(dispatch_get_main_queue()){ [weak self] in
            print("will start   START")
            self?.setLoadingIndicatorVisible(true)
            print("will start  FINISH")
        }
        
    }
    
    func contactsHandlerDidStartFetchingContacts() {
        dispatch_async(dispatch_get_main_queue()){
            print("did start")
        }
    }
    
    func contactsHandlerDidFinishFetchingContacts(error: ErrorType?) {
        
        print("did finish")
        
        
        dispatch_async(dispatch_get_main_queue()) { [weak self] in
            
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
                self?.collectionView?.reloadSections(NSIndexSet(index: 0))
            }
        }
    }
    
    func contactsWillUpdate()
    {
        self.collectionView?.scrollEnabled = false
    }
    
    func contactsDidUpdate() {
        self.collectionView?.scrollEnabled = true
        
        self.collectionView?.reloadSections(NSIndexSet(index: 0))
    }

}