//
//  TableViewController.swift
//  StoryBoardTableView
//
//  Created by CloudCraft on 12/29/15.
//  Copyright © 2015 CloudCraft. All rights reserved.
//

import UIKit
import CloudKit
class BoardsTableViewController: UITableViewController {

    lazy var contactsHandler:ContactsHandler = ContactsHandler()
    
    lazy var boardsHolder:BoardsHolder = BoardsHolder()
    
    private var didSubscribeForBoardsSyncNotification = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.estimatedRowHeight = 69

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        ///----
        boardsHolder.delegate = self
        boardsHolder.getBoards()
        let frame = CGRectMake(0, 0, 200, 60)
        self.refreshControl = UIRefreshControl(frame: frame)
        
        self.refreshControl?.addTarget(self, action: "pullLatestBoardsFromCloud:", forControlEvents: .ValueChanged)
        
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if !didSubscribeForBoardsSyncNotification
        {
            
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "dataSyncronizerDidStartSyncing", name: DataSyncronizerDidStartSyncronyzingNotificationName, object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "dataSyncronizerDidFinishSyncing", name: DataSyncronizerDidStopSyncronyzingNotificationName, object: nil)
            
            didSubscribeForBoardsSyncNotification = true
            
            DataSyncronizer.sharedSyncronizer.startSyncingBoards()
            
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        ContactsHandler.sharedInstance.delegate = self
    }

    //MARK: -
    private func reloadNavigationTitleViewWithCurrentUserInfo() -> Bool
    {
        if let anAppDelegate = anAppDelegate(), currentUser = anAppDelegate.cloudKitHandler.publicCurrentUser
        {
            dispatch_async(dispatch_get_main_queue()){[unowned self] in
                self.navigationItem.title = currentUser.recordID.recordName
            }
            
            return true
        }
        return false
    }
    
    // MARK: - Table view data source
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return boardsHolder.boardsCount
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCellWithIdentifier("AllBoardsCell", forIndexPath: indexPath) as? BoardsTableViewCell
        {
            let board = boardsHolder.boardForRow(indexPath.row)
            cell.boartTitlelabel?.text = board?.title
            cell.boardDetailsLabel?.text = board?.details
            
            cell.dateLabel.text = board?.shortDateString
            
            cell.accessoryType = .DetailButton
            
            if let creator = board?.creatorId
            {
                if creator == anAppDelegate()!.cloudKitHandler.publicCurrentUser!.recordID.recordName
                {
                    cell.avatarView.image = anAppDelegate()?.cloudKitHandler.currentUserAvatar ?? testAvatarImage
                }
                else if let foundUser = ContactsHandler.sharedInstance.contactByPhone(creator), userAvatar = foundUser.avatarImage
                {
                    cell.avatarView.image = userAvatar
                }
                else
                {
                    cell.avatarView?.image = testAvatarImage
                }
            }
            else
            {
                cell.avatarView?.image = testAvatarImage
            }

        
            return cell
        }
        else
        {
            return UITableViewCell(style: .Value1, reuseIdentifier: "DefaultCell")
        }
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            do{
                let deletedBoard = try boardsHolder.removeBoardAtIndex(indexPath.row)
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                boardsHolder.deleteFromDatabase(deletedBoard)
            }
            catch
            {
                
            }
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
        else if editingStyle == .None{
            
        }
    }
    
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

        do{
            let movingBoard = try boardsHolder.removeBoardAtIndex(fromIndexPath.row)
            
            do{
                try boardsHolder.insertBoard(movingBoard, atIndex: toIndexPath.row)
                //start rearranging logic for TaskBoard "sortOrderIndex" inside the app and submit changes to iCloud
                boardsHolder.updateBoardsSortIndexes()
            }
            catch
            {
                print("Could not insert")
            }
        }
        catch
        {
            print("Could not remove")
        }
    }
    

    
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        if let board = boardsHolder.boardForRow(indexPath.row)
        {
            self.performSegueWithIdentifier("ShowTasksList", sender: board) // selected board
        }
    }
    
    override func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        if let board = boardsHolder.boardForRow(indexPath.row)
        {
                
            self.performSegueWithIdentifier("PresentBoardEditing", sender: BoardEditingHolder(boardType: BoardEditingType.EditCurrent(board: board))  )
        }
    }
    //MARK: - 
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        if editing
        {
            
        }
        else
        {
            //delete boards if any present (toBeDeleted)
            anAppDelegate()?.coreDatahandler?.startBoardsDeletionToCloudKit()
        }
        
    }
    
    //MARK: - actions
    @IBAction func addBoard(sender:AnyObject?)
    {
        presentNewBoardCreatingInterface()
    }
    
    private func presentNewBoardCreatingInterface()
    {
        self.performSegueWithIdentifier("PresentBoardEditing", sender: nil)
    }
    
    func dataSyncronizerDidStartSyncing()
    {
        self.tableView.scrollEnabled = false
    }
    
    func dataSyncronizerDidFinishSyncing()
    {
        self.tableView.scrollEnabled = true
        
        boardsHolder.removeAllBoardsFromSelf()
        
        boardsHolder.fetchBoardsFromCoreData()
        
        self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
      
        
        if let control = self.refreshControl
        {
            if control.refreshing
            {
                self.refreshControl?.endRefreshing()
            }
        }
    }
    
    func pullLatestBoardsFromCloud(sender:UIRefreshControl)
    {
        DataSyncronizer.sharedSyncronizer.startSyncingBoards()
        let timeout:dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 20.0))
        
        dispatch_after(timeout, dispatch_get_main_queue(), { () -> Void in
            if let control = self.refreshControl
            {
                if control.refreshing
                {
                    control.endRefreshing()
                }
            }
        })
    }
    
    //MARK: - Segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier
        {
            switch identifier
            {
                case "PresentBoardEditing" :
                    if let editingNavController = segue.destinationViewController as? BoardEditNavigationController, rootVC = editingNavController.viewControllers.first as? BoardEditViewController
                    {
                        rootVC.boardsHolder = self.boardsHolder
                        
                        if let senderType = sender as? BoardEditingHolder
                        {   
                            rootVC.setEditingType(senderType.boardEditingType)
                        }
                        else
                        {
                            rootVC.setEditingType(BoardEditingType.CreateNew)
                        }
                    }
                case "ShowTasksList":
                    if let boardForTasks = sender as? Board, tasksListVC = segue.destinationViewController as? TasksViewController
                    {
                        tasksListVC.tasksSource.board = boardForTasks
                    }
                default:
                    break
            }
        }
    }
    
}//BoardsTableViewController class end




