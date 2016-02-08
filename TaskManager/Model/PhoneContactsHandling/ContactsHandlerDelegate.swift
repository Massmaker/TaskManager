//
//  ContactsHandlerDelegate.swift
//  TaskCloud
//
//  Created by CloudCraft on 1/12/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import Foundation

protocol ContactsHandlerDelegate: class{
    
    func contactshandlerWillStartFetchingContacts()
    func contactsHandlerDidStartFetchingContacts()
    func contactsHandlerDidFinishFetchingContacts(error:ErrorType?)
    
    ///Called when some long CoreData operation is about to begin
    func contactsWillUpdate()
    
    ///Called after some long CoreData operation is finished
    func contactsDidUpdate()
}

//extension ContactsHandlerDelegate{
//    
//    func contactshandlerWillStartFetchingContacts()
//    {
//        print(" ContactsHandlerDelegate \"contactshandlerWillStartFetchingContacts\" extension method called.  Check implementation.")
//    }
//    
//    func contactsHandlerDidStartFetchingContacts()
//    {
//        print(" ContactsHandlerDelegate \"contactsHandlerDidStartFetchingContacts\" extension method called.  Check implementation.")
//    }
//    
//    func contactsHandlerDidFinishFetchingContacts(error:ErrorType?)
//    {
//          print(" ContactsHandlerDelegate \"contactsHandlerDidFinishFetchingContacts\" extension method called.  Check implementation.")
//    }
//    
//}