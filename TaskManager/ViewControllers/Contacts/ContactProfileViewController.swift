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
                        view.delegate = self
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
        
        checkFinishedTasksSection()
        
    }
    
    private func checkFinishedTasksSection(){
        
        //display section with finished tasks
        if let userId = contact?.phone,  let finishedTasks = anAppDelegate()?.coreDatahandler?.findFinishedTasksByUserId(userId){
            
            let finishedTasksSectionTitle = NSLocalizedString("Finished tasks", comment: "header title for finished tasks by user or contact")
            let headerHeight = CGFloat(30.0)
            
            //prepare Title header
            var titleHeader = HeaderFooterView<TaskActionsSectionTitleHeader>(.NibFile(name:"TaskActionsSectionTitleHeader", bundle:nil))
            
            titleHeader.onSetupView = {titleHeader, _, _ in
                
                titleHeader.titleLabel.text = finishedTasksSectionTitle
            }
            
            titleHeader.height = {headerHeight}
            
            let finishedTasksSection = Section(){ section in
                section.header = titleHeader
            }
            
            for aTask in finishedTasks{
                let taskRow = self.finishedTaskRowFor(aTask.title!, date: aTask.finishedDate)
                
                taskRow.onCellSelection(){[weak self] (cell, row) -> () in
                    self?.showTaskEditFor(aTask)
                }
                
                finishedTasksSection <<< taskRow
            }
            
            form[1] = finishedTasksSection
        }
        else{
            if form.endIndex > 1{
                form.removeAtIndex(1)
            }
        }
    }
    
    private func finishedTaskRowFor(taskTitle:String, date:NSDate?) -> LabelRow {
        let taskRow = LabelRow(){
            $0.title = taskTitle
            $0.value = date?.todayTimeOrDateStringRepresentation()
            //$0.disabled = Condition(booleanLiteral: true)
            $0.cell.detailTextLabel?.textColor = UIColor.appThemeColorBlue
        }
        
        return taskRow
    }
    
    func showTaskEditFor(task:Task){
        guard let editNavVC = self.storyboard?.instantiateViewControllerWithIdentifier("TaskEditNavigationController") as? TaskEditNavigationController, editVC = editNavVC.viewControllers.first as? TaskEditViewController  else {
            return
        }
        
        editVC.taskEditingType = TaskEditType.EditCurrent(task: task)
        
        self.presentViewController(editNavVC, animated: true) { () -> Void in
            
        }
    }

}



