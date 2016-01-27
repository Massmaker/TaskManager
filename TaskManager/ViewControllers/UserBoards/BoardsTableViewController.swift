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
    var cloudBoardsHandler:BoardCloudHandler?
    
    lazy var testAvatarImage = UIImage(named: "Test_Icon")
    private lazy var pCurrentUserAvatar = UIImage()
    var currentUserAvatar:UIImage?{
        
        if let recordID = anAppDelegate()?.cloudKitHandler.currentUserPhoneNumber
        {
            if self.pCurrentUserAvatar.size == CGSizeZero
            {
                if let image = DocumentsFolderFileHandler().getAvatarImageFromDocumentsForUserId(recordID)
                {
                    self.pCurrentUserAvatar = image
                    return self.pCurrentUserAvatar
                }
                return nil
            }
            else
            {
                return self.pCurrentUserAvatar
            }
        }
        return nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        self.tableView.estimatedRowHeight = 50.0
        
        self.navigationItem.rightBarButtonItem = self.editButtonItem()
        boardsHolder.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if self.cloudBoardsHandler == nil
        {
            self.cloudBoardsHandler = TaskBoardsHandler(delegate: self)
            cloudBoardsHandler?.requestUserBoards()
        }
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
    
    func reloadTableViewInMainThread()
    {
        dispatch_async(dispatch_get_main_queue()){[weak self] in
            self?.tableView.reloadData()
        }
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
            cell.accessoryType = .DetailButton
            
            if let creator = board?.creatorId
            {
                if creator == anAppDelegate()!.cloudKitHandler.publicCurrentUser!.recordID.recordName
                {
                    cell.avatarView.image = currentUserAvatar ?? testAvatarImage
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
                let boardToDelete = try boardsHolder.removeBoardAtIndex(indexPath.row)
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                self.cloudBoardsHandler?.deleteBoard(boardToDelete)
            }
            catch
            {
                
            }
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

        do{
            let movingBoard = try boardsHolder.removeBoardAtIndex(fromIndexPath.row)
            
            do{
                try boardsHolder.insertBoard(movingBoard, atIndex: toIndexPath.row)
                //start rearranging logic for TaskBoard "sortOrderIndex" inside the app and submit changes to iCloud
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
            self.performSegueWithIdentifier("ShowTasksList", sender: board.recordId) // selected board
        }
    }
    
    override func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        if let board = boardsHolder.boardForRow(indexPath.row)
        {
            self.performSegueWithIdentifier("PresentBoardEditing", sender: BoardEditingHolder(boardType: BoardEditingType.EditCurrent(board: board))  )
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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier
        {
            switch identifier
            {
                case "PresentBoardEditing" :
                    if let editingNavController = segue.destinationViewController as? BoardEditNavigationController
                    {
                        editingNavController.boardEditingHandler = self.cloudBoardsHandler
                        if let senderType = sender as? BoardEditingHolder
                        {
                            editingNavController.boardEditingType = senderType.boardEditingType
                        }
                        else
                        {
                            editingNavController.boardEditingType = BoardEditingType.CreateNew
                        }
                    }
                case "ShowTasksList":
                if let boardRecordId = sender as? CKRecordID, tasksListVC = segue.destinationViewController as? TasksViewController
                {
                    tasksListVC.boardRecordId = boardRecordId
                }
                default:
                    break
            }
        }
    }
    
}//BoardsTableViewController class end




