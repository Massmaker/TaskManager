//
//  ContactProfileViewController.swift
//  TaskCloud
//
//  Created by CloudCraft on 1/12/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import UIKit
import Eureka
import CloudKit

class ContactProfileViewController: FormViewController {

    var contact:User?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupTableView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupTableView()
    {
        guard let contact = self.contact else
        {
            return
        }
        
        form +++=
            
            Section() { section in
                    var header = HeaderFooterView<UserProfileHeader>(.NibFile(name:"UserProfileHeader", bundle:nil))
                    header.onSetupView = {[unowned self] view, section, formController in
                        view.avatar.image = self.contact?.avatarImage ?? testAvatarImage
                    }
                
                    header.height = { 120.0 }
                    section.header = header
            }

            
            <<< LabelRow(){
                    $0.title = "name"
                    $0.value = contact.firstName
                    $0.disabled = true
                }
            <<< LabelRow(){
                    $0.title = "last name"
                    $0.value = contact.lastName
                    $0.disabled = true
                }
            <<< PhoneRow(){
                $0.title = "phone"
                $0.value = contact.phone
                $0.disabled = true
            }
//            <<< EmailRow(){
//                $0.title = "email"
//                $0.value = contact.email
//                $0.disabled = true
//            }
        
            if contact.isRegistered == false
            {
                form
                    +++
                    Section()
                    <<< ButtonRow(){
                            $0.value = "Invite"
                    }
            }
        
            if let taskTaken = contact.currentTask
            {
                form
                    +++
                    Section("Current task")
                    <<< LabelRow(){
                        $0.title = taskTaken.title
                    }.onCellSelection(){[weak self] (cell, row) -> () in
                        self?.displayCurrentContactTask()
                    }
            }
    }
    
    private func displayCurrentContactTask()
    {
        //TODO: show TaskEditView controller with current contact`s taken task
    }

}
