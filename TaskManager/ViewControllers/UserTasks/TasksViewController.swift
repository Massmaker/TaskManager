//
//  TasksViewController.swift
//  TaskManager
//
//  Created by CloudCraft on 1/19/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import UIKit
import CloudKit

class TasksViewController:UITableViewController {
    
    var tasksSource:TasksHolding?
    var boardRecordId:CKRecordID?
    var tasksCloudHandler:TaskCloudHandling?
    
    private var userRecordId:CKRecordID?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.rightBarButtonItem = self.editButtonItem() //enable deleting of Take/Finish tasks, rearranging tasks
        self.tasksCloudHandler = TasksCloudHandler(delegate: self)
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if tasksSource == nil
        {
            if let table = self.view as? UITableView
            {
                tasksSource = TasksHolder(tableView: table)
            }
        }
        
       
        
        checkAddTaskButtonEnabled()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        tasksSource?.delegate = self
        if let countTasks = self.tasksSource?.getTasks().count where countTasks == 0
        {
            if let boardId = self.boardRecordId
            {
                tasksSource?.tryFetchingTasksForBoard(boardId)
            }
            else
            {
                NSLog(" - TasksViewController will not start fetching tasks for current board: No \"boardRecordId\".\n")
            }
        }
    }
    
    //MARK: - IBAction
    @IBAction func addTaskButtonAction(sender:UIBarButtonItem)
    {
        showTaskEditViewCntroller(nil) //create new
    }
    
    //MARK: - UITableVIewDataSource
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section
        {
        case 0:
            return 1
        case 1:
            return self.tasksSource?.getTasks().count ?? 0
        default:
            return 0
        }
        
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.section
        {
        case 0:
            if let addTaskCell = tableView.dequeueReusableCellWithIdentifier("AddTaskCell", forIndexPath: indexPath) as? AddTaskTableViewCell
            {
                return addTaskCell
            }
            let defaultCell = UITableViewCell(style: .Value1, reuseIdentifier: "DummyCell")
            defaultCell.detailTextLabel?.text = "Add Task"
            return defaultCell
        case 1:
            
            let targetTask = self.tasksSource?.taskForRow(indexPath.row)
            
            if let taskCell = tableView.dequeueReusableCellWithIdentifier("TaskTableCell", forIndexPath: indexPath) as? TaskTableViewCell
            {                
                taskCell.setCurrentTask(targetTask!)
                return taskCell
            }
            let defaultTaskCell = tableView.dequeueReusableCellWithIdentifier("TaskCell", forIndexPath: indexPath)
            
            defaultTaskCell.textLabel?.text = targetTask?.title
            defaultTaskCell.detailTextLabel?.text = targetTask?.details
            
            return defaultTaskCell
        default:
            let taskCell = tableView.dequeueReusableCellWithIdentifier("TaskCell", forIndexPath: indexPath)
            return taskCell
        }
     
    }
    
    
    
    
    //MARK: - UITableViewDelegate
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch indexPath.section{
        case 1:
            return 96.0
        default:
            return 44.0
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch indexPath.section{
        case 1:
            return 96.0
        default:
            return 44.0
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        switch indexPath.section
        {
        case 0:
            if checkAddTaskButtonEnabled()
            {
                self.showTaskEditViewCntroller(nil) //start adding new task
            }
        case 1:
            if let selectedTask = self.tasksSource?.taskForRow(indexPath.row)
            {
                self.showTaskEditViewCntroller(selectedTask)
            }
        default:
            break
        }
    }
    
    override func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard section == 1 else
        {
            return nil
        }
        return "Tasks"
    }
    
    //to disable editing or deleting the "AddTAskButton" cell
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if indexPath.section == 0
        {
            return false
        }
        return true
    }
    
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if indexPath.section == 0
        {
            return false
        }
        return true
    }
    
    override func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        
    }
    
    override func tableView(tableView: UITableView, targetIndexPathForMoveFromRowAtIndexPath sourceIndexPath: NSIndexPath, toProposedIndexPath proposedDestinationIndexPath: NSIndexPath) -> NSIndexPath {
        // disallow user to move TASK cells into the first section (AddTaskButton  cell section)
        if proposedDestinationIndexPath.section == 0
        {
            return NSIndexPath(forRow: 0, inSection: 1)
        }
        return proposedDestinationIndexPath
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        switch editingStyle{
        case .Insert:
            print(" Committing Insert")
        case .None:
            print(" Committing None")
        case .Delete:
            print(" Comitting Delete")
            if let deletionWillStart = self.tasksSource?.deleteTaskAtIndex(indexPath.row) where deletionWillStart == true
            {
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            }
        }
    }
    
    //MARK: -
    private func checkAddTaskButtonEnabled() -> Bool
    {
        //checks "Plus" button on the NavBar right
        self.userRecordId = anAppDelegate()?.cloudKitHandler.publicCurrentUser?.recordID
        return self.userRecordId != nil
    }
    
    private func showTaskEditViewCntroller(task:TaskInfo?)
    {
        if let taskToEdit = task
        {
            self.performSegueWithIdentifier("StartEditTask", sender: TaskInfoObjectHolder(taskInfo: taskToEdit))
        }
        else
        {
            self.performSegueWithIdentifier("StartEditTask", sender: anAppDelegate()?.cloudKitHandler.publicCurrentUser?.recordID)
        }
    }
    
    //MARK: - Segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let segueId = segue.identifier
        {
            switch segueId
            {
            case "StartEditTask":
                if let
                    taskEditorNavVC = segue.destinationViewController as? TaskEditNavigationController,
                    rootEditVC = taskEditorNavVC.viewControllers.first as? TaskEditViewController
                {
                    rootEditVC.weakCloudHandler = self.tasksCloudHandler
                    
                    if let taskHoler = sender as? TaskInfoObjectHolder
                    {
                        rootEditVC.taskEditingType = .EditCurrent(task:taskHoler.taskInfo)
                    }
                    else if let recordId = sender as? CKRecordID, let boardId = self.boardRecordId
                    {
                        rootEditVC.taskEditingType = .CreateNew
                        rootEditVC.boardRecordId = boardId
                        rootEditVC.creatorId = recordId
                    }
                    
                }
                
            default:
                break
            }
        }
    }
    
    
}