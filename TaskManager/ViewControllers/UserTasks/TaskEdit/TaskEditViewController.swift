//
//  TaskEditViewController.swift
//  TaskManager
//
//  Created by CloudCraft on 1/19/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import UIKit
import CloudKit
import Eureka

class TaskEditViewController: FormViewController {

    var boardRecordId:CKRecordID?
    var creatorId:CKRecordID?
    
    private var currentTask:TaskInfo?
    
    weak var weakCloudHandler:TaskCloudHandling?
    
    var taskEditingType:TaskEditType = .CreateNew{
        didSet{
            switch taskEditingType{
                case .EditCurrent(let task):
                    self.currentTask = task
                    self.initialDetails = task.details
                    self.initialTitle = task.title
                    self.boardRecordId = task.taskBoardId
                
                default:
                    break
            }
        }
    }
    
    private var initialTitle = ""
    private var initialDetails = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.setupTableViewWithCurrentTask()
        switch taskEditingType
        {
            case .EditCurrent(_):
                self.setupTakeOrFinishButtonCell()
            default:
                break
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - 
    func setupTableViewWithCurrentTask()
    {
        let titleSectionTitle = "task title"
        let detailsSectionTitle = "task details"
        
        guard let task = self.currentTask else
        {
            form +++ Section(titleSectionTitle)
                 <<< TextAreaRow(){
                        $0.placeholder = "enter task title"
                    }.onChange{ [unowned self] (titlewRow) in
                        if let _ = self.currentTask //update board title
                        {
                            self.currentTask?.title = titlewRow.value ?? self.initialTitle
                            self.checkSaveButtonEnabled()
                        }
                        else
                        {
                            if let changedTitle = titlewRow.value,
                                let boardRecId = self.boardRecordId,
                                let creator = self.creatorId,
                                let newTask = TaskInfo(taskBoardRecordId: boardRecId, creatorRecordId: creator, title: changedTitle, details: "")
                            {
                                self.currentTask = newTask
                            }
                            self.checkSaveButtonEnabled()
                        }
                    }
                +++ Section(detailsSectionTitle)
                <<< TextAreaRow() {
                        $0.placeholder = "enter task details"
                    }.onChange{ [unowned self] (detailsRow) in
                        if let _ = self.currentTask //update board title
                        {
                            self.currentTask?.details = detailsRow.value ?? self.initialDetails
                            self.checkSaveButtonEnabled()
                        }
                        else
                        {
                            if  let changedDetails = detailsRow.value,
                                let boardRecId = self.boardRecordId,
                                let creator = self.creatorId,
                                let newTask = TaskInfo(taskBoardRecordId: boardRecId, creatorRecordId: creator, title: self.initialTitle, details: changedDetails)
                            {
                                self.currentTask = newTask
                            }

                            self.checkSaveButtonEnabled()
                        }
                    }
            return
        }
        
        form +++ Section(titleSectionTitle)
            //add single cell in section
            <<< TextAreaRow() {
                    $0.value = task.title
                }.onChange{ [unowned self] (titlewRow) in
                   
                    self.currentTask?.title = titlewRow.value ?? self.initialTitle
                    self.checkSaveButtonEnabled()
                }
            
            +++ Section(detailsSectionTitle)
            //add single cell in section
            <<< TextAreaRow() {
                    $0.value = task.details
                }.onChange{[unowned self] (detailsRow) in
                    
                    self.currentTask?.details = detailsRow.value ?? self.initialDetails
                    self.checkSaveButtonEnabled()
                }
    }
    
    //MARK: - Task Actions setup
    private func setupTakeOrFinishButtonCell()
    {
        setupActionsSection()
        
        setupDeleteSection()
    }
    
    private func setupActionsSection()
    {
        let actionsSection = Section("Actions")
       
        form[2] = actionsSection // 0 - Task title, 1 - Task details, 2 - Task actions(Take or Finish+Cancel)
        
        if let _ = currentTask?.currentOwner
        {
            setupFinishCancelButtons(actionsSection)
        }
        else
        {
            setupTakeSection(actionsSection)
        }
    }
    
    private func setupTakeSection(section:Section)
    {
        let takeButtonRow = ButtonRow("Take task").cellSetup(){ (cell, row) -> () in
                    cell.textLabel?.font = UIFont.boldSystemFontOfSize(17)
                    cell.tintColor = UIColor.greenColor()
                    row.title = "Take"
                }.onCellSelection(){[weak self] (cell, row) -> () in
                    cell.setSelected(false, animated: false)
                    self?.takeTaskPressed()
                }
        
        section.removeAll() //in case there are 2 buttons before inserting (Finish and Cancel actions)
        section.append(takeButtonRow)
    }
    
    private func setupFinishCancelButtons(section:Section)
    {
        let finishTaskButton = ButtonRow("Finish Task").cellSetup{(cell, row) in
                    cell.textLabel?.font = UIFont.boldSystemFontOfSize(17)
                    cell.tintColor = UIColor.blueColor()
                    row.title = "Finish"
                }.onCellSelection {[weak self] (cell, row) -> () in
                    cell.setSelected(false, animated: false)
                    self?.finishTaskPressed()
                }
        
        let cancelTaskButton = ButtonRow("Cancel Task").cellSetup(){ (cell, row) -> () in
                    cell.tintColor = UIColor.purpleColor()
                    row.title = "Cancel"
                }.onCellSelection(){[weak self] (cell, row) -> () in
                    cell.setSelected(false, animated: false)
                    self?.cancelTaskPressed()
                }
    
        section.removeAll()// in case there is Take button (Take button action)
        section[0] = finishTaskButton
        section[1] = cancelTaskButton
    }
    
    func setupDeleteSection()
    {
        let deleteButtonRow = ButtonRow().cellSetup(){ (cell, row) -> () in
                cell.tintColor = UIColor.redColor()
                row.title = "Delete"
                }.onCellSelection {[weak self] (cell , _) -> () in
                   
                    cell.setSelected(false, animated: false)
                    self?.deleteTaskPressed()
                }

        
        form[3] = Section("Danger Zone") <<<  deleteButtonRow
    }
    
    //MARK: -
    private func checkSaveButtonEnabled()
    {
        guard let task = self.currentTask else
        {
            self.navigationItem.rightBarButtonItem = nil
            return
        }
        
        if initialTitle == task.title && initialDetails == task.details
        {
            self.navigationItem.rightBarButtonItem = nil
        }
        else if task.title == ""
        {
            self.navigationItem.rightBarButtonItem = nil //there is no reason to create a task without at least a title
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
    
    //MARK: - Cancel and Save nivigation button actions
    @IBAction func cancelBarButtonAction(sender:AnyObject?)
    {
        guard let aHandler = self.weakCloudHandler else
        {
            self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
            return
        }
        
        aHandler.cancelEditingTask()
    }
    
    func saveEdits(sender:UIBarButtonItem)
    {
        if let task = self.currentTask{
            
            
            switch self.taskEditingType
            {
                case .EditCurrent( _ ):
                    self.weakCloudHandler?.editTask(task)
                case .CreateNew:
                    self.weakCloudHandler?.submitTask(task)
            }
        }
        else
        {
            self.cancelBarButtonAction(nil)
        }
    }
    
    //MARK: - Action buttons methods
    func deleteTaskPressed()
    {
        guard let task = currentTask, _ = anAppDelegate()?.cloudKitHandler.publicCurrentUser else
        {
            return
        }
        self.weakCloudHandler?.deleteTask(task)
    }
    
    func takeTaskPressed()
    {
        guard var task = self.currentTask, let currentUser = anAppDelegate()?.cloudKitHandler.publicCurrentUser else
        {
            return
        }
        
        task.currentOwner = currentUser.recordID.recordName // phoneNumber is stored both in Record name and currentUser["phoneNumberID"]  String value
        task.dateTaken = NSDate()
        task.dateFinished = nil
        self.weakCloudHandler?.editTask(task)
    }
    
    func finishTaskPressed()
    {
        guard var task = self.currentTask, let _ = anAppDelegate()?.cloudKitHandler.publicCurrentUser else
        {
            return
        }
        
        task.currentOwner = nil // phoneNumber is stored both in Record name and currentUser["phoneNumberID"]  String value
        task.dateFinished = NSDate()
        self.weakCloudHandler?.editTask(task)
    }
    
    func cancelTaskPressed()
    {
        guard var task = self.currentTask, let _ = anAppDelegate()?.cloudKitHandler.publicCurrentUser else
        {
            return
        }

        task.currentOwner = nil
        task.dateFinished = nil
        task.dateTaken = nil
        
        self.weakCloudHandler?.editTask(task)
    }
}
