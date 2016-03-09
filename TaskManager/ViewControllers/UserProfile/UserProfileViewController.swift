//
//  UserProfileViewController.swift
//  TaskManager
//
//  Created by CloudCraft on 1/25/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import UIKit
import Eureka
import DigitsKit
import Fabric

class UserProfileViewController: FormViewController {
    
    var shouldSaveImage = false
    var currentProfileInfo:DeviceContact?
    lazy var imagePickerController = UIImagePickerController()
    lazy var documentsFileHandler = DocumentsFolderFileHandler()

    let optionalPlaceholder = "optional"
    //MARK: -
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.readUserDefaultsDataIntoMemory()
        
        setupProfileTableView()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadUserData:", name: UserDefaultsWereUpdatedAfteriCloudSyncNotification, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView?.reloadData()
        
        self.checkFinishedTasksSection()
    }
    
    //MARK: -
    func showImagePickerForUserAvatar()
    {
        imagePickerController.delegate = self
        imagePickerController.sourceType = .PhotoLibrary
        //imagePickerController.allowsEditing = true
        
        self.presentViewController(imagePickerController, animated: true, completion: nil)
    }
    
    @IBAction func logoutBarButtonAction(sender:AnyObject?)
    {
        UserDefaultsManager.clearUserDefaults()
        
        if let userId = currentProfileInfo?.phoneNumber
        {
            documentsFileHandler.deleteAvatarImageForUserId(userId)
        }
        
        Digits.sharedInstance().logOut()
        
        anAppDelegate()?.cloudKitHandler.currentUserPhoneNumber = nil
        anAppDelegate()?.cloudKitHandler.deleteCurrentUserRecord()
        anAppDelegate()?.coreDatahandler?.deleteAllContacts()
        anAppDelegate()?.coreDatahandler?.deleteAllBoards()
        anAppDelegate()?.coreDatahandler?.deleteAllTasks()
        
        if let loginVC = self.storyboard?.instantiateViewControllerWithIdentifier("LoginViewController") as? LoginViewController,  let delegate = anAppDelegate(), window = delegate.window
        {
            window.rootViewController = loginVC
        }
    }
    
    func reloadUserData(note:NSNotification)
    {
        readUserDefaultsDataIntoMemory()
        
        //reload tableview
        if let sectionWithInfo = form.sectionByTag("UserTextInfo")
        {
            sectionWithInfo.removeAll()
            
            sectionWithInfo[0] = firstNameRowWith(self.currentProfileInfo?.firstName)
            
            sectionWithInfo[1] = lastNameRowWith(self.currentProfileInfo?.lastName)
            
            //sectionWithInfo[2] = emailRowWith( self.currentProfileInfo?.email)
        }
    }
    
    private func readUserDefaultsDataIntoMemory()
    {
        guard let contactPhone = anAppDelegate()?.cloudKitHandler.publicCurrentUser?.recordID.recordName else
        {
            return
        }
        
        let image = documentsFileHandler.getAvatarImageFromDocumentsForUserId(contactPhone)
        
        if self.currentProfileInfo == nil
        {
            self.currentProfileInfo = DeviceContact()
        }
        self.currentProfileInfo?.phoneNumber = contactPhone
        self.currentProfileInfo?.avatarImage = image
        
        self.currentProfileInfo?.firstName = UserDefaultsManager.getUserNameFromDefaults()
        self.currentProfileInfo?.lastName = UserDefaultsManager.getUserLastNameFromDefaults()
    }
    
    private func setupProfileTableView()
    {
        form +++ Section(){ section in
                var header = HeaderFooterView<UserProfileHeader>(.NibFile(name:"UserProfileHeader", bundle:nil))
                header.onSetupView = {[unowned self] view, section, formController in
                    view.avatar.image = self.currentProfileInfo?.avatarImage
                    view.phoneLabel.text = self.currentProfileInfo?.phoneNumber
                    view.delegate = self
                }
            
                header.height = { 120.0 }
                section.header = header
                section.tag = "UserTextInfo"
            }
            
            <<< firstNameRowWith(self.currentProfileInfo?.firstName)
            <<< lastNameRowWith(self.currentProfileInfo?.lastName)
    }
    
    private func lastNameRowWith(lastName:String?) -> NameRow
    {
        let lastNameRow = NameRow(){
            $0.title = "Last name:"
            $0.placeholder = optionalPlaceholder
            $0.value = lastName
            }.onCellHighlight(){ (_, _) -> () in
                //if onHighLight is not implemented - "onUnHighLight" is not called
            }.onCellUnHighlight(){[weak  self] (_ , lastNameRow) -> () in
                self?.currentProfileInfo?.lastName = lastNameRow.value
                UserDefaultsManager.setUserLastNameToDefaults(self?.currentProfileInfo?.lastName)
        }
        
        return lastNameRow
    }
    
    private func firstNameRowWith(name:String?) -> NameRow
    {
        let nameRow = NameRow(){
            $0.title = "Name:"
            $0.placeholder = optionalPlaceholder
            $0.value = name
            }.onCellHighlight(){ (_, _) -> () in
                //if onHighLight is not implemented - "onUnHighLight" is not called
            }.onCellUnHighlight(){[weak self] (_ , nameRow) -> () in
                self?.currentProfileInfo?.firstName = nameRow.value
                UserDefaultsManager.setUserNameToDefaults(self?.currentProfileInfo?.firstName)
        }
        
        return nameRow
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
    
    private func checkFinishedTasksSection(){
        
        //display section with finished tasks
        if let userId = anAppDelegate()?.cloudKitHandler.publicCurrentUser?.recordID.recordName,  let finishedTasks = anAppDelegate()?.coreDatahandler?.findFinishedTasksByUserId(userId){
            
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
    
    
}
