//
//  TasksHolder.swift
//  TaskManager
//
//  Created by CloudCraft on 1/19/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import UIKit
import CloudKit

class TasksHolder:NSObject {
    
    override init() {
        super.init()
    }
    
    
    //MARK: - TasksHolding
    private weak var table:UITableView?
    
    private lazy var currentTasks:[Task] = [Task]()
    
    weak var delegate:TasksHolderDelegate?
    weak var board:Board?{
        didSet{
            
            let _ = currentTasks.count
            
            if let tasks = board?.orderedTasks
            {
                self.currentTasks = tasks
                print("\n - \(self.currentTasks.count) tasks for board in DB")
            }
            
            if self.currentTasks.isEmpty && self.board != nil
            {
                let bgQueue = dispatch_queue_create("tasks_syncing_queue", DISPATCH_QUEUE_SERIAL)
                dispatch_async(bgQueue){
                    DataSyncronizer.sharedSyncronizer.startSyncingTasksFor(self.board!)
                }
            }
        }
    }
    
    required init(tableView: UITableView) {
        self.table = tableView
    }
    
    
    func setTasks(tasks:[Task])
    {
        delegate?.tasksWillStartUpdating()
        
        currentTasks.removeAll(keepCapacity: false)
        currentTasks += tasks
        self.table?.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
        delegate?.tasksDidFinishUpdating()
    }
    
    func getTasks() -> [Task]
    {
        return self.currentTasks
    }
    
    func taskForRow(row: Int) -> Task?
    {
        if row >= 0 && row < currentTasks.count
        {
            return currentTasks[row]
        }
        return nil
    }
    
    func deleteTask(task:Task)
    {
        if let index = self.currentTasks.indexOf(task)
        {
            task.toBeDeleted = true
            anAppDelegate()?.coreDatahandler?.saveMainContext()
            self.currentTasks.removeAtIndex(index)
            self.table?.reloadSections(NSIndexSet(index: 0), withRowAnimation: .None)
        }
    }
    
    func removeTaskAtIndex(index:Int) throws -> Task
    {
        if index >= currentTasks.count
        {
            throw TaskBoardError.NotFound
        }
        
        return currentTasks.removeAtIndex(index)
    }
    
    func insertTask(task:Task,  atIndex index:Int) throws {
        if index > currentTasks.count
        {
            throw TaskBoardError.NotFound
        }
        currentTasks.insert(task, atIndex: index)
    }
    
    //MARK: - 
    
    ///Iterates through all tasks in current array and updates **sortOrder** from zero to last index.
    /// - Does not call `"save context"`.
    func updateTasksSortIndexes() {
        
        if currentTasks.isEmpty{
            return
        }
        
        let notDeletedTasks = currentTasks.filter(){
            return $0.toBeDeleted != true
        }
        
        if notDeletedTasks.isEmpty{
            return
        }
        
        var index:Int64 = 0
        
        for aTask in notDeletedTasks {
            
            aTask.sortOrder = index
            index += 1
        }
        
        
        
        var taskRecordsToModify = [CKRecord]()
        for aTask in notDeletedTasks{
            guard let recId = aTask.recordId else{
                continue
            }
            
            do{
                let taskRec = try createTaskRecordFrom(aTask, recordID: recId)
                print("New Sotr Order: \(taskRec[SortOrderIndexIntKey] as? NSNumber)")
                taskRecordsToModify.append(taskRec)
                
            }catch{
                
            }
        }
        
        if !taskRecordsToModify.isEmpty{
            
            anAppDelegate()?.cloudKitHandler.editManyTasks(taskRecordsToModify) { (edited, failed, error) -> () in
                dispatchMain(){
                    if edited.count != taskRecordsToModify.count{
                        anAppDelegate()?.coreDatahandler?.undoChangesInContext()
                    }
                    else{
                        anAppDelegate()?.coreDatahandler?.saveMainContext()
                    }
                }
            }
        }
    }
    
    ///Marks task as toBeDeleted - for deletion from CloudDatabase  and removes task from current tasks array - to be invisible for table view
    func deleteTaskAtIndex(indexOfTask:Int) -> Bool
    {
        guard indexOfTask >= 0 else
        {
            return false
        }
        
        var deletionHappened = false
        
        if currentTasks.count > indexOfTask
        {
            do{
                let toDelete = try removeTaskAtIndex(indexOfTask)
                toDelete.toBeDeleted = true
                anAppDelegate()?.coreDatahandler?.saveMainContext()
                deletionHappened = true
            }
            catch{
                
            }

        }
        
        return deletionHappened
    }
    
    func editTask(taskToEdit:Task){
        
        do{
            let taskRec = try createTaskRecordFrom(taskToEdit)
        
            self.delegate?.tasksWillStartUpdating()
            
            anAppDelegate()?.cloudKitHandler.editTask(taskRec){ (editedRecord, editError) -> () in
                if let editedRecord = editedRecord
                {
                    dispatchMain(){
                        taskToEdit.fillInfoFrom(editedRecord)
                        anAppDelegate()?.coreDatahandler?.saveMainContext()
                        self.delegate?.tasksDidFinishUpdating()
                    }
                }
                else if let error = editError
                {
                    print("\n -  Error updating task in CLoudKit: ")
                    print("\(error)")
                    
                    dispatchMain(){
                        anAppDelegate()?.coreDatahandler?.undoChangesInContext()
                        anAppDelegate()?.coreDatahandler?.saveMainContext()
                        self.delegate?.tasksDidFinishUpdating()
                    }
                }
            }
        }
        catch{
            self.delegate?.tasksDidFinishUpdating()
        }
    }
    
    func insertNewTaskWithInfo(taskToInsert:TempTaskInfo)
    {
        networkingIndicator(true)
        guard let coreDataHandler = anAppDelegate()?.coreDatahandler else
        {
            return
        }
        
        if let newTask = coreDataHandler.insertNewTaskFrom(taskToInsert), let board = newTask.board
        {
            self.delegate?.tasksWillStartUpdating()
            anAppDelegate()?.cloudKitHandler.submitTask(newTask) {[unowned self] (taskRecord, savingError) -> () in
                dispatchMain(){
                    if let record = taskRecord
                    {
                        //coreDataHandler.insertTaskRecords([record], forBoard: board, saveImmediately: true)
                        newTask.fillInfoFrom(record)
                       
                        board.addTasksObject(newTask)
                        
                        self.setTasks(board.orderedTasks)
                        board.checkTaskIDsToBeEqualToTasks()
                        
                        coreDataHandler.saveMainContext()
                        
                        self.delegate?.tasksDidFinishUpdating()
                        
                        anAppDelegate()?.cloudKitHandler.editBoard(board) {[unowned self] (editedRecord, editError) -> () in
                            dispatchMain(){
                                if let record = editedRecord
                                {
                                    board.fillInfoFromRecord(record)
                                    if let ids = board.taskIDs as? [String]
                                    {
                                        coreDataHandler.pairTasksByIDs(ids, to: board)
                                        coreDataHandler.saveMainContext()
                                        self.setTasks(board.orderedTasks)
                                    }
                                    else{
                                        assert(false)
                                    }
                                }
                                else
                                {
                                    
                                }
                                networkingIndicator(false)
                            }
                        }
                    }
                    else
                    {
                        networkingIndicator(false)
                    }
                }
            }
        }
    }
    
    //MARK: - Task DELETE - TAKE - CANCEL  actions
    func handleTakingTask(task:Task, byUserID userID:String) -> Bool {
        
        guard let recordID = task.recordId else
        {
            return false
        }
        
        var toReturn = true
        
        do{
            var tasksToCancel:[Task]?
            if let tasksCurrentlyTaken = anAppDelegate()?.coreDatahandler?.findActiveTasksForUserById(userID) where !tasksCurrentlyTaken.isEmpty {
                print("currently taken tasks:")
                
                tasksToCancel = [Task]()
                
                for aTask in tasksCurrentlyTaken{
                    print(aTask.title!)
                    aTask.dateTaken = 0.0
                    aTask.currentOwnerId = nil
                    tasksToCancel?.append(aTask)
                }
            }
            
            if let taskObjectsToCancel = tasksToCancel {
                var cancelledTaskRecords = [CKRecord]()
                for aTask in taskObjectsToCancel {
                    do{
                        guard let recId = aTask.recordId else{
                            continue
                        }
                        let taskRec = try createTaskRecordFrom(aTask, recordID: recId)
                        cancelledTaskRecords.append(taskRec)
                    }
                }
                if !cancelledTaskRecords.isEmpty{
                    print("\n - Starting cancelling tasks: \(cancelledTaskRecords.count)")
                    anAppDelegate()?.cloudKitHandler.editManyTasks(cancelledTaskRecords, priority: .Default) { (edited, failed, error) -> () in
                        
                    }
                }
            }
            
            let taskRecord = try createTaskRecordFrom(task, recordID: recordID)
            
            self.delegate?.tasksWillStartUpdating()
            
            let bgQueue = dispatch_queue_create("Task_Taking_queue", DISPATCH_QUEUE_SERIAL)
            dispatch_async(bgQueue){
                taskRecord[DateTakenDateKey] = NSDate()
                taskRecord[CurrentOwnerStringKey] = userID
                taskRecord[DateFinishedDateKey] = nil
                
                anAppDelegate()?.cloudKitHandler.editTask(taskRecord) {[weak self] (editedRecord, editError) -> () in
                    if let edited = editedRecord
                    {
                        dispatchMain(){
                            task.fillInfoFrom(edited)
                            anAppDelegate()?.coreDatahandler?.saveMainContext()
                            self?.table?.reloadData()
                            self?.delegate?.tasksDidFinishUpdating()
                        }
                    }
                }
            }            
        }
        catch let error{
            print("\n - Error creating TaskRecord From current TASK:")
            print(error)
            toReturn = false
        }
        
        return toReturn
    }
    
    func handleCancellingTask(task:Task, byUsedID userID:String) -> Bool
    {
        guard let recordID = task.recordId else
        {
            return false
        }
        
        var toReturn = true
        
        do{
            
            let taskRecord = try createTaskRecordFrom(task, recordID: recordID)
            
            self.delegate?.tasksWillStartUpdating()
            
            let bgQueue = dispatch_queue_create("Task_Cancelling_queue", DISPATCH_QUEUE_SERIAL)
            dispatch_async(bgQueue){
                taskRecord[DateFinishedDateKey] = nil
                taskRecord[CurrentOwnerStringKey] = nil
                taskRecord[DateTakenDateKey] = nil
                
                anAppDelegate()?.cloudKitHandler.editTask(taskRecord) {[weak self] (editedRecord, editError) -> () in
                    if let edited = editedRecord
                    {
                        dispatchMain(){
                            task.fillInfoFrom(edited)
                            anAppDelegate()?.coreDatahandler?.saveMainContext()
                            self?.table?.reloadData()
                            self?.delegate?.tasksDidFinishUpdating()
                        }
                    }
                }
            }
        }
        catch let error{
            print("\n - Error creating TaskRecord From current TASK:")
            print(error)
            toReturn = false
        }
        
        return toReturn
    }
    
    func handleFinishingTask(task:Task, byUserID userID:String) -> Bool
    {
        guard let recordID = task.recordId else
        {
            return false
        }
        
        var toReturn = true
        
        do{
            
            let taskRecord = try createTaskRecordFrom(task, recordID: recordID)
            
            self.delegate?.tasksWillStartUpdating()
            
            let bgQueue = dispatch_queue_create("Task_Finishing_queue", DISPATCH_QUEUE_SERIAL)
            dispatch_async(bgQueue){
                taskRecord[DateFinishedDateKey] = NSDate()
                taskRecord[CurrentOwnerStringKey] = nil
                
                anAppDelegate()?.cloudKitHandler.editTask(taskRecord) {[weak self] (editedRecord, editError) -> () in
                    if let edited = editedRecord
                    {
                        dispatchMain(){
                            task.fillInfoFrom(edited)
                            anAppDelegate()?.coreDatahandler?.saveMainContext()
                            self?.table?.reloadData()
                            self?.delegate?.tasksDidFinishUpdating()
                        }
                    }
                }
            }
        }
        catch let error{
            print("\n - Error creating TaskRecord From current TASK:")
            print(error)
            toReturn = false
        }
        
        return toReturn
    }
    
    //MARK: - Sync NSNotification
    func handleSyncNotification(note:NSNotification)
    {
        switch note.name
        {
        case DataSyncronizerDidStartSyncronyzingNotificationName:
            self.delegate?.tasksWillStartUpdating()
        case DataSyncronizerDidStopSyncronyzingNotificationName:
            self.setTasks(board!.orderedTasks)
            self.table?.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
            self.delegate?.tasksDidFinishUpdating()
        default:
            break
        }
    }
}
