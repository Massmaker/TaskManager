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
    }
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    //MARK: -
    func showImagePickerForUserAvatar()
    {
        imagePickerController.delegate = self
        imagePickerController.sourceType = .PhotoLibrary
        imagePickerController.allowsEditing = true
        
        self.presentViewController(imagePickerController, animated: true, completion: nil)
    }
    
    func logoutBarButtonAction(sender:AnyObject?)
    {
        UserDefaultsManager.clearUserDefaults()
        
        if let userId = currentProfileInfo?.phoneNumber
        {
            documentsFileHandler.deleteAvatarImageForUserId(userId)
        }
        
        Digits.sharedInstance().logOut()
            
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
            
            //<<< emailRowWith(self.currentProfileInfo?.email)
    }
    
//    private func emailRowWith(email:String?) -> EmailRow
//    {
//        let emailRow =   EmailRow(){
//            $0.title = "Email:"
//            $0.placeholder = optionalPlaceholder
//            $0.value = email
//            }.onCellHighlight(){ (_, _) -> () in
//                //if onHighLight is not implemented - "onUnHighLight" is not called
//            }.onCellUnHighlight(){[weak self] ( _ , row) -> () in
//                self?.currentProfileInfo?.email = row.value
//                UserDefaultsManager.setEmailToDefaults(self?.currentProfileInfo?.email)
//        }
//        
//        return emailRow
//    }
    
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
}
