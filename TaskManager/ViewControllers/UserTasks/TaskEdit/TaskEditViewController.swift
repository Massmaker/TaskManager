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

    var taskBoard:Board?
    var creatorId:String?
    weak var weakTasksHolder:TasksHolder?
    private var currentTask:Task?
    
    var taskEditingType:TaskEditType = .CreateNew{
        didSet{
            switch taskEditingType{
                case .EditCurrent(let task):
                    self.currentTask = task
                    self.initialDetails = task.details!
                    self.initialTitle = task.title!
                    //self.boardRecordId = task.board?.recordId
                
                default:
                    break
            }
        }
    }
    
    private var newTaskInfo:TempTaskInfo?
    
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
        
        self.creatorId = anAppDelegate()?.cloudKitHandler.publicCurrentUser?.recordID.recordName
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
                        if let _ = self.newTaskInfo //update board title
                        {
                            self.newTaskInfo?.title = titlewRow.value ?? self.initialTitle
                            self.checkSaveButtonEnabled()
                        }
                        else
                        {
                            if let changedTitle = titlewRow.value,
                                let taskInfo = TempTaskInfo(boardRecord: self.taskBoard?.recordId),
                                let creator = self.creatorId
                            {
                                self.newTaskInfo = taskInfo
                                self.newTaskInfo?.setTitle(changedTitle)
                                self.newTaskInfo?.setCreator(creator)
                            }
                            self.checkSaveButtonEnabled()
                        }
                    }
                
                +++ Section(detailsSectionTitle)
                <<< TextAreaRow() {
                        $0.placeholder = "enter task details"
                    }.onChange{ [unowned self] (detailsRow) in
                        if let _ = self.newTaskInfo //update board title
                        {
                            self.newTaskInfo?.setDetails(detailsRow.value ?? self.initialDetails)
                            self.checkSaveButtonEnabled()
                        }
                        else
                        {
                            if  let changedDetails = detailsRow.value,
                                let taskInfo = TempTaskInfo(boardRecord: self.taskBoard?.recordId),
                                let creatorId = self.creatorId
                                //let newTask = TaskInfo(taskBoardRecordId: boardRecId, creatorRecordId: creator, title: self.initialTitle, details: changedDetails)
                            {
                                self.newTaskInfo = taskInfo
                                self.newTaskInfo?.setDetails(changedDetails)
                                self.newTaskInfo?.setCreator(creatorId)
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
        guard let currentLoggedUserID = anAppDelegate()?.cloudKitHandler.publicCurrentUser?.recordID.recordName else
        {
            return
        }
        
        let actionsSection = Section("Actions")
       
         // 0 - Task title, 1 - Task details, 2 - Task actions(Take or Finish+Cancel)
        
        if let taskOwner = currentTask?.currentOwner where taskOwner == currentLoggedUserID
        {
            form[2] = actionsSection
            setupFinishCancelButtons(actionsSection)
        }
        else
        {
            form[2] = actionsSection
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

        
        form +++ Section("Danger Zone") <<<  deleteButtonRow
    }
    
    //MARK: -
    private func checkSaveButtonEnabled()
    {
        
        switch taskEditingType
        {
            case .CreateNew:
                if let tempTask = self.newTaskInfo where !tempTask.title.isEmpty
                {
                    enableSaveButton()
                }
                else
                {
                    disableSaveButton()
                }
            case .EditCurrent(_):
                guard let task = self.currentTask else
                {
                    disableSaveButton()
                    return
                }
                
                if initialTitle == task.title && initialDetails == task.details
                {
                    disableSaveButton()
                }
                else if task.title == ""
                {
                    disableSaveButton() //there is no reason to create a task without at least a title
                }
                else //set SAVE button visible
                {
                    enableSaveButton()
                }
        }
        
    }
    
    private func enableSaveButton()
    {
        if self.navigationItem.rightBarButtonItem == nil
        {
            let saveBarButton = UIBarButtonItem(barButtonSystemItem: .Save, target: self, action: "saveEdits:")
            self.navigationItem.rightBarButtonItem = saveBarButton
        }
    }
    
    private func disableSaveButton()
    {
        self.navigationItem.rightBarButtonItem = nil
    }
    
    //MARK: - Cancel and Save nivigation button actions
    @IBAction func cancelBarButtonAction(sender:AnyObject?)
    {
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
        return
    }
    
    func saveEdits(sender:UIBarButtonItem)
    {
        switch self.taskEditingType
        {
        case .EditCurrent( _ ):
            if let task = self.currentTask
            {
                self.weakTasksHolder?.editTask(task)
            }
            else
            {
                self.cancelBarButtonAction(nil)
            }
        case .CreateNew:
            if let taskInfo = self.newTaskInfo
            {
                self.weakTasksHolder?.insertNewTaskWithInfo(taskInfo)
                self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
            }
            else
            {
                self.cancelBarButtonAction(nil)
            }
        }
    }
    
    //MARK: - Action buttons methods
    func deleteTaskPressed()
    {
        guard let task = currentTask, _ = anAppDelegate()?.cloudKitHandler.publicCurrentUser else
        {
            return
        }
        self.weakTasksHolder?.deleteTask(task)
    }
    
    func takeTaskPressed()
    {
        guard let task = self.currentTask else
        {
            return
        }
        
        guard let currentUser = anAppDelegate()?.cloudKitHandler.currentUser else
        {
            return
        }
        
        task.currentOwner = currentUser // phoneNumber is stored both in Record name and currentUser["phoneNumberID"]  String value
        task.dateTaken = NSDate().timeIntervalSinceReferenceDate
        task.dateFinished = 0.0
    }
    
    func finishTaskPressed()
    {
        guard var task = self.currentTask, let _ = anAppDelegate()?.cloudKitHandler.publicCurrentUser else
        {
            return
        }
        
        task.currentOwner = nil // phoneNumber is stored both in Record name and currentUser["phoneNumberID"]  String value
        task.dateFinished = NSDate().timeIntervalSinceReferenceDate
    }
    
    func cancelTaskPressed()
    {
        guard var task = self.currentTask, let _ = anAppDelegate()?.cloudKitHandler.publicCurrentUser else
        {
            return
        }

        task.currentOwner = nil
        task.dateFinished = 0.0
        task.dateTaken = 0.0
    }
}
