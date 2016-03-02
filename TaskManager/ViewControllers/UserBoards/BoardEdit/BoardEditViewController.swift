//
//  ViewController.swift
//  TaskCloud
//
//  Created by CloudCraft on 1/14/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import UIKit
import Eureka
import CloudKit

class BoardEditViewController: FormViewController, BoardDetailsHeaderDelegate {
    
    weak var boardsHolder:BoardsHolder?
    
    private var editingType:BoardEditingType = .CreateNew{
        didSet{
            switch editingType
            {
                case .CreateNew:
                    self.title = NSLocalizedString("New Board", comment:"")
                    populateTableViewWithBoard(nil)
                case .EditCurrent(let board):
                    self.title = NSLocalizedString("Edit Board", comment: "")
                    self.initialParticipantIDs = board.participantIDsSet
                    self.tempParticimantIDs = board.participantIDsSet
                    populateTableViewWithBoard(board)
            }
        }
    }
    
    private var currentBoard:Board?
    private lazy var initialTitle = ""
    private lazy var initialDetails = ""
    
    private var tempParticimantIDs = Set<String>()
    
    private var initialParticipantIDs = Set<String>()

    private var editingDisabledForBoard:Condition = true
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    func setEditingType(type:BoardEditingType)
    {
        self.editingType = type
    }
    
    private func populateTableViewWithBoard(board:Board?)
    {
        let titleSectionTitle = NSLocalizedString("Board Title", comment: "board title header text")
        let detailsSectionTitle = NSLocalizedString( "Board Details", comment: "board details header text")
        let headerHeight = CGFloat(30.0)
        
        //prepare Title header
        var titleHeader = HeaderFooterView<TaskActionsSectionTitleHeader>(.NibFile(name:"TaskActionsSectionTitleHeader", bundle:nil))
        
        titleHeader.onSetupView = {titleHeader, _, _ in
            
            titleHeader.titleLabel.text = titleSectionTitle
        }
        
        titleHeader.height = {headerHeight}
        
        
        // prepare Details header
        var detailsHeader = HeaderFooterView<TaskActionsSectionTitleHeader>(.NibFile(name:"TaskActionsSectionTitleHeader", bundle:nil))
        
        detailsHeader.onSetupView = {header, _, _ in
            
            header.titleLabel.text = detailsSectionTitle
        }
        
        detailsHeader.height = {headerHeight}
        
        
        guard let editableBoard = board else
        {
            form +++
                Section(){titleSection in
                    titleSection.header = titleHeader
                }
                <<< TextAreaRow(){ $0.placeholder = "Enter board title"}.onChange(){ [unowned self](row) -> () in
                        if let title = row.value
                        {
                            if let _ = self.currentBoard //update board title
                            {
                                self.currentBoard?.title = title
                            }
                            else //create new board with board title set
                            {
                                if let new = anAppDelegate()?.coreDatahandler?.insertEmpty()
                                {
                                    self.currentBoard = new
                                    self.currentBoard?.creatorId = anAppDelegate()?.cloudKitHandler.publicCurrentUser?.recordID.recordName
                                }
                                self.currentBoard?.title = title
                            }
                        }
                        else
                        {
                            self.currentBoard?.title = row.value
                        }
                        self.checkSaveButtonEnabled()
                    }//onChange end
                
                +++ Section(){ detailsSection in
                    detailsSection.header = detailsHeader
                }
                
                <<< TextAreaRow(){ $0.placeholder = "Enter board description"}.onChange(){[unowned self] (row) -> () in
                        if let details = row.value
                        {
                            if let _ = self.currentBoard //update board details
                            {
                                self.currentBoard?.details = details
                                self.checkSaveButtonEnabled()
                            }
                            else //create new board with boardDetails set
                            {
                                if let new = anAppDelegate()?.coreDatahandler?.insertEmpty()
                                {
                                    self.currentBoard = new
                                    self.currentBoard?.creatorId = anAppDelegate()?.cloudKitHandler.publicCurrentUser?.recordID.recordName
                                }
                                self.currentBoard?.details = details                                
                            }
                        }
                        self.checkSaveButtonEnabled()
                    }//onChange end
            return
        }
        
        self.currentBoard = editableBoard
        
        setupInitialValuesWithBoard(editableBoard)
        checkEditingEnabled()
        
        
        form +++
            Section(){ section in
                var header = HeaderFooterView<BoardDetailsHeader>(.NibFile(name:"BoardDetailsHeader", bundle:nil))
        
                header.onSetupView = {view, section, formController in
                    view.nameLabel.text = "name"
                    view.dateLabel.text = editableBoard.shortDateString
                    view.avatarView.image = testAvatarImage
                    
                    if let creatorId = board?.creatorId
                    {
                        if creatorId == anAppDelegate()!.cloudKitHandler.publicCurrentUser!.recordID.recordName
                        {
                            view.avatarView.image = anAppDelegate()!.cloudKitHandler.currentUserAvatar
                            let lvContact = DeviceContact(phoneNumber: creatorId)!
                            lvContact.firstName = UserDefaultsManager.getUserNameFromDefaults()
                            lvContact.lastName = UserDefaultsManager.getUserLastNameFromDefaults()
                            
                            view.nameLabel.text = lvContact.displayName
                            //we can delete own boards
                            view.headerDelegate = self
                            view.deleteButton.hidden = false
                        }
                        else if let foundUser = ContactsHandler.sharedInstance.contactByPhone(creatorId)
                        {
                            view.nameLabel.text = foundUser.displayName
                            view.avatarView.image = foundUser.avatarImage
                            
                            //we cannot delete boards created by other users
                            view.deleteButton.hidden = true
                            view.headerDelegate = nil
                        }
                        else{
                            view.deleteButton.hidden = true
                            view.headerDelegate = nil
                        }
                    }
                    else{
                        view.deleteButton.hidden = true
                        view.headerDelegate = nil
                    }
                }
                
                header.height = { 120.0 }
                section.header = header
                section.tag = "BoardUserInfo"
            }
        
            +++
            Section(){ titleSection in
                titleSection.header = titleHeader
            }
            <<< TextAreaRow(){
                
                    $0.disabled = editingDisabledForBoard
                    $0.value = editableBoard.title
                
                    }.onChange(){[unowned self] (textAreaRow) -> () in
                        
                    if let titleText = textAreaRow.value
                    {
                        self.currentBoard?.title = titleText
                        self.checkSaveButtonEnabled()
                    }
                }.cellSetup { (cell, _) -> () in
                    cell.textView.textContainerInset = UIEdgeInsetsMake(0, 48.0, 0, 0)
                }
            
            +++
            
            Section(){ detailsSection in
                detailsSection.header = detailsHeader
            }
            
            <<< TextAreaRow(){
                
                    $0.value = editableBoard.details
                    $0.disabled = editingDisabledForBoard
                
                    }.onChange(){ [unowned self](textAreaRow) -> () in
                        
                    if let detailsText = textAreaRow.value
                    {
                        self.currentBoard?.details = detailsText
                    }
                    else
                    {
                        self.currentBoard?.details = ""
                    }
                    self.checkSaveButtonEnabled()
                }.cellSetup { (cell, _) -> () in
                    cell.textView.textContainerInset = UIEdgeInsetsMake(0, 48.0, 0, 0)
                }
        
        addContactsSection()
    }

    private func setupInitialValuesWithBoard(board:Board)
    {
        self.initialTitle = board.title ?? ""
        self.initialDetails = board.details ?? ""
    }
    
    private func checkEditingEnabled() -> Bool
    {
        if let creatorId = self.currentBoard?.creatorId, currentUserId = anAppDelegate()?.cloudKitHandler.publicCurrentUser?.recordID.recordName
        {
            editingDisabledForBoard = (creatorId == currentUserId) ? false : true
            //print("editing: \(editingDisabledForBoard)")
            return creatorId == currentUserId
        }
        return false
    }
    
    private func checkSaveButtonEnabled()
    {
        guard let currentBoard = self.currentBoard, title = currentBoard.title where !title.isEmpty else
        {
            self.navigationItem.rightBarButtonItem = nil
            return
        }
        
        
        if initialTitle == currentBoard.title && initialDetails == currentBoard.details && initialParticipantIDs == tempParticimantIDs
        {
            self.navigationItem.rightBarButtonItem = nil
        }
        else if currentBoard.title == ""
        {
            self.navigationItem.rightBarButtonItem = nil
        }
        else //set SAVE button visible
        {
            if self.navigationItem.rightBarButtonItem == nil
            {
                let saveBarButton = UIBarButtonItem(barButtonSystemItem: .Save, target: self, action: "saveEdits:")
                self.navigationItem.rightBarButtonItem = saveBarButton
            }
        }
    }
    
    private func addContactsSection()
    {
        guard let registered = anAppDelegate()?.coreDatahandler?.registeredContacts() else
        {
            return
        }
        
        let contactsSectionTitle = NSLocalizedString("Participants", comment:"")
        
        //prepare Title header
        var titleHeader = HeaderFooterView<TaskActionsSectionTitleHeader>(.NibFile(name:"TaskActionsSectionTitleHeader", bundle:nil))
        
        titleHeader.onSetupView = {titleHeader, _, _ in
            
            titleHeader.titleLabel.text = contactsSectionTitle
        }
        
        titleHeader.height = {30.0}
        
        let aSection =  Section(){ section in
            section.header = titleHeader
        }
        
        form +++ aSection
        
        addRegisteredContacts(registered, toSection: aSection)
    }
    
    private func addRegisteredContacts(contacts:[User], toSection section:Section){
        let editable = checkEditingEnabled()
        
        for aUser in contacts{
            let phone = aUser.phone!
            
            let contactCheckRow = CheckRowSubclass().cellSetup(){ (cell, row) in
                
                row.value = self.tempParticimantIDs.contains(phone)
                let taskTitle = anAppDelegate()?.coreDatahandler?.findActiveTasksForUserById(aUser.phone!)?.first?.title
                cell.info = (aUser, taskTitle)
                cell.selectionStyle = .None
                cell.radioCheckView?.backGroundColor = (editable) ? UIColor.appThemeColorBlue : UIColor.appThemeColorBlue.colorWithAlphaComponent(0.7)
                cell.editingEnabled = editable
            }
            
            if editable{
                contactCheckRow.onChange(){(row) in
                    
                    if row.value == true
                    {
                        self.tempParticimantIDs.insert(phone)
                    }
                    else
                    {
                        self.tempParticimantIDs.remove(phone)
                    }
                    
                    self.checkSaveButtonEnabled()
                }
            }
            
            section <<< contactCheckRow
        }
    }
    
    //MARK: -
    @IBAction func cancelBarButtonAction(sender:AnyObject?)
    {
        switch editingType{
            case BoardEditingType.CreateNew:
            if let tempNewBoard = self.currentBoard
            {
                anAppDelegate()?.coreDatahandler?.deleteSingle(tempNewBoard, deleteimmediately: true, saveImmediately: true)
            }
            case .EditCurrent( _ ):
            currentBoard?.title = initialTitle
            currentBoard?.details = initialDetails
            currentBoard?.assignParticipants(initialParticipantIDs)
            anAppDelegate()?.coreDatahandler?.saveMainContext()
        }
        
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
        return

    }
    
    func saveEdits(sender:UIBarButtonItem){
        
        if let board = self.currentBoard {
            switch self.editingType
            {
                case .EditCurrent(  _  ):
                    board.assignParticipants(self.tempParticimantIDs)
                    self.boardsHolder?.updateBoard(board)
                    print("\n - Editing board info")
                case .CreateNew:
                    guard let currentUserID = anAppDelegate()?.cloudKitHandler.publicCurrentUser?.recordID.recordName else
                    {
                        self.cancelBarButtonAction(nil)
                        return
                    }
                    board.creatorId = currentUserID
                    print("\n - Creating new board")
                    self.boardsHolder?.addNew(board)
            }
            self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
        }
        else
        {
            self.cancelBarButtonAction(nil)
        }
    }
    
    func deleteBoard(){
        guard let board = self.currentBoard else{
            return
        }
        
        self.boardsHolder?.handleDeletingBoard(board)
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //MARK: - BoardDetailsHeaderDelegate
    func boardsHeaderDeleteButtonTapped(sender:UIButton?) {
    
        let alertController = UIAlertController(title: "Confirm deletion", message: "Sure to delete board and all tasks in it?", preferredStyle: UIAlertControllerStyle.ActionSheet)
        let action = UIAlertAction(title: "Delete", style: .Destructive) {[weak self] _ in
            self?.deleteBoard()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)
        alertController.addAction(action)
        
        if UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.Pad{
            alertController.modalPresentationStyle = UIModalPresentationStyle.Popover
            guard let popPresenter = alertController.popoverPresentationController else{
                return
            }

            popPresenter.sourceView = sender
            self.presentViewController(alertController, animated: true, completion: nil)
        }
        else{
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
}
