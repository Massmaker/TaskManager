//
//  TasksViewController.swift
//  TaskManager
//
//  Created by CloudCraft on 1/19/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import UIKit
import CloudKit

class TasksViewController:UIViewController {
    
    @IBOutlet var tableView:UITableView!
    weak var weakBoard:Board!
    lazy var tasksSource:TasksHolder = TasksHolder(tableView: self.tableView)
    
    var addButtonControl:FloatingButtonControl?
    
    private var userRecordId:CKRecordID?
    
    private var editingDidHappen = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.rightBarButtonItem = self.editButtonItem() //enable deleting of Take/Finish tasks, rearranging tasks
        tasksSource.board = weakBoard
    }
    
    override func viewWillAppear(animated: Bool) {
        startObservingDataSyncronizerNotifications()
        super.viewWillAppear(animated)
  
        tasksSource.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    
        displayAddButton(checkAddTaskButtonEnabled())
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    override func viewDidDisappear(animated: Bool) {
        stopObservingDataSyncronizerNotifications()
        super.viewDidAppear(animated)
    }
    
    //MARK: - 
    func startObservingDataSyncronizerNotifications()
    {
        let center = NSNotificationCenter.defaultCenter()
        center.addObserver(self.tasksSource, selector: "handleSyncNotification:", name: DataSyncronizerDidStartSyncronyzingNotificationName, object: nil)
        center.addObserver(self.tasksSource, selector: "handleSyncNotification:", name: DataSyncronizerDidStopSyncronyzingNotificationName, object: nil)
    }
    
    func stopObservingDataSyncronizerNotifications()
    {
        let center = NSNotificationCenter.defaultCenter()
        center.removeObserver(self.tasksSource, name: DataSyncronizerDidStartSyncronyzingNotificationName, object: nil)
        center.removeObserver(self.tasksSource, name: DataSyncronizerDidStopSyncronyzingNotificationName, object: nil)
    }
    
    //MARK: - UITableVIewDataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1 //2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section
        {
        case 0:
//            return 1
//        case 1:
            return self.tasksSource.getTasks().count
        default:
            return 0
        }
        
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.section
        {
        case 0:
//            if let addTaskCell = tableView.dequeueReusableCellWithIdentifier("AddTaskCell", forIndexPath: indexPath) as? AddTaskTableViewCell
//            {
//                return addTaskCell
//            }
//            let defaultCell = UITableViewCell(style: .Value1, reuseIdentifier: "DummyCell")
//            defaultCell.detailTextLabel?.text = "Add Task"
//            return defaultCell
//        case 1:
            
            let targetTask = self.tasksSource.taskForRow(indexPath.row)
            
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
    
    
    //MARK: - 
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        self.tableView.setEditing(editing, animated: animated)
        
        if !editing{
            
            if editingDidHappen{
                editingDidHappen = false
                
                
                self.tasksSource.updateTasksSortIndexes()
                
                anAppDelegate()?.coreDatahandler?.startTasksDeletionToCloudKit()
            }
        }
    }
 
    //MARK: - 
    private func displayAddButton(display:Bool){
        
        if display{
            
            let image = UIImage(named: "Plus_Icon")
            let button = UIButton(type: .System)
            button.frame = CGRectMake(0, 0, 40, 40)
            button.imageEdgeInsets = UIEdgeInsetsMake(0, 5, 0, 5)
            button.backgroundColor = UIColor.clearColor()
            button.setImage(image, forState: .Normal)
            button.addTarget(self, action: "startAddingNewTask", forControlEvents: .TouchUpInside)
            
            self.navigationItem.titleView = button
        }
        else{
            
            self.navigationItem.titleView = nil
        }
    }
    
    func startAddingNewTask()
    {
        self.showTaskEditViewCntroller(nil)
    }
    
    //MARK: - UITableViewDelegate
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
//        switch indexPath.section{
//        case 1:
            return 96.0
//        default:
//            return 44.0
//        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
//        switch indexPath.section{
//        case 1:
            return 96.0
//        default:
//            return 44.0
//        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
//        switch indexPath.section
//        {
//        case 0:
//            if checkAddTaskButtonEnabled()
//            {
//                self.showTaskEditViewCntroller(nil) //start adding new task
//            }
//        case 1:
            if let selectedTask = self.tasksSource.taskForRow(indexPath.row)
            {
                self.showTaskEditViewCntroller(selectedTask)
            }
//        default:
//            break
//        }
    }
    
    func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        guard section == 1 else
//        {
//            return nil
//        }
        return "Tasks"
    }
    
    //to disable editing or deleting the "AddTAskButton" cell
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {

        if !self.editing{
            return false
        }
        
        guard let currentUserID = anAppDelegate()?.cloudKitHandler.publicCurrentUser?.recordID.recordName else{
            return false
        }
        
        if self.editing{
            if let task = tasksSource.taskForRow(indexPath.row){
                return task.creator == currentUserID
            }
            
        }
        return false
    }
    
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        
        if !editingDidHappen{
            editingDidHappen = true
        }
        
        do{
            let removed = try self.tasksSource.removeTaskAtIndex(sourceIndexPath.row)
            do{
                try self.tasksSource.insertTask(removed, atIndex: destinationIndexPath.row)
            }
            catch{
                print(" Could not insert task at index: \(destinationIndexPath.row)")
            }
        }
        catch{
            print(" Could not remove task at index: \(sourceIndexPath.row)")
        }
    }
    
//    func tableView(tableView: UITableView, targetIndexPathForMoveFromRowAtIndexPath sourceIndexPath: NSIndexPath, toProposedIndexPath proposedDestinationIndexPath: NSIndexPath) -> NSIndexPath {
//        // disallow user to move TASK cells into the first section (AddTaskButton  cell section)
//        if proposedDestinationIndexPath.section == 0
//        {
//            return NSIndexPath(forRow: 0, inSection: 1)
//        }
//        return proposedDestinationIndexPath
//    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        switch editingStyle{
        case .Insert:
            print(" Committing Insert")
        case .None:
            print(" Committing None")
        case .Delete:
            print(" Comitting Delete")
            if self.tasksSource.deleteTaskAtIndex(indexPath.row)
            {
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            }
            else
            {
                tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Right)
            }
        }
    }
    
    //MARK: -
    /// if current user id is nil returns false
    private func checkAddTaskButtonEnabled() -> Bool
    {
        //checks "Plus" button on the NavBar right
        self.userRecordId = anAppDelegate()?.cloudKitHandler.publicCurrentUser?.recordID
        return self.userRecordId != nil
    }
    
    
    
    private func showTaskEditViewCntroller(task:Task?)
    {
        if let taskToEdit = task
        {
            self.performSegueWithIdentifier("StartEditTask", sender: taskToEdit)
        }
        else if self.tasksSource.board?.recordId != nil
        {
            self.performSegueWithIdentifier("StartEditTask", sender: self.tasksSource.board!)
        }
        else
        {
            showAlertController("Error", text: "Can not start adding task without board", closeButtonTitle: "Close")
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
                    rootEditVC.weakTasksHolder = self.tasksSource
                    
                    if let taskToEdit = sender as? Task
                    {
                        rootEditVC.taskEditingType = .EditCurrent(task:taskToEdit)
                    }
                    else if let board = sender as? Board
                    {
                        rootEditVC.taskEditingType = .CreateNew
                        rootEditVC.taskBoard = board
                    }
                }
            default:
                break
            }
        }
    }
    
    
}