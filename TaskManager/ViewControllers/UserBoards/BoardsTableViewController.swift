//
//  TableViewController.swift
//  StoryBoardTableView
//
//  Created by CloudCraft on 12/29/15.
//  Copyright © 2015 CloudCraft. All rights reserved.
//

import UIKit
import CloudKit
class BoardsTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate , UINavigationControllerDelegate{

    //@IBOutlet weak var headerView:BoardsHeaderView!
    @IBOutlet var tableView:UITableView!
     var refreshControl:UIRefreshControl?
    lazy var contactsHandler:ContactsHandler = ContactsHandler()
    
    lazy var boardsHolder:BoardsHolder = BoardsHolder()
    
    private var didSubscribeForBoardsSyncNotification = false
    private var editingDidHappen = false
    var taskToEdit:Task?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        self.tableView.estimatedRowHeight = 82
        
        let headerNib = UINib(nibName: "BoardsAnimatedHeader", bundle: nil)
        self.tableView.registerNib(headerNib, forHeaderFooterViewReuseIdentifier: "BoardsAnimatedHeader")
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        ///----
        //headerView.delegate = self
        
        ///----
        boardsHolder.delegate = self
        boardsHolder.getBoards()
        let frame = CGRectMake(0, 0, 200, 60)
        self.refreshControl = UIRefreshControl(frame: frame)
        
        self.refreshControl?.addTarget(self, action: "pullLatestBoardsFromCloud:", forControlEvents: .ValueChanged)
        self.tableView.addSubview(self.refreshControl!)
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
            
          
            SubscriptionsHandler.sharedInstance.subscriptForBoardsForMe()
        }
        

//        guard let userId = anAppDelegate()?.cloudKitHandler.publicCurrentUser?.recordID.recordName else{
//            return
//        }
//        self.headerView.currentUserId = userId
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        ContactsHandler.sharedInstance.delegate = self
        
        //reload header
        self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
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
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0{
            return 0
        }
        return boardsHolder.boardsCount
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCellWithIdentifier("AllBoardsCell", forIndexPath: indexPath) as? BoardsTableViewCell
        {
            let board = boardsHolder.boardForRow(indexPath.row)
            let dateString = NSAttributedString(string: board!.createDate.todayTimeOrDateStringRepresentation(), attributes: [NSForegroundColorAttributeName:UIColor.appThemeColorBlue, NSFontAttributeName:UIFont.systemFontOfSize(13)])
            
            let attributedDetails = NSMutableAttributedString(attributedString: dateString)
            
            if let details = board?.details{
                
                let attributedSpace = NSAttributedString(string: " ", attributes:[NSFontAttributeName:UIFont.systemFontOfSize(14)])
                
                let attributed = NSAttributedString(string: details, attributes: [NSForegroundColorAttributeName:UIColor.lightGrayColor(), NSFontAttributeName:UIFont.systemFontOfSize(13)])
                attributedDetails.appendAttributedString(attributedSpace)
                attributedDetails.appendAttributedString(attributed)
            }
            
            cell.boartTitlelabel?.text = board?.title
            
            cell.boardDetailsLabel?.attributedText = attributedDetails
            
            //cell.dateLabel.text = board?.shortDateString
            
            cell.accessoryType = .DetailButton
            
            if let creator = board?.creatorId, currentUserPhone = anAppDelegate()!.cloudKitHandler.publicCurrentUser?.recordID.recordName
            {
                if creator == currentUserPhone
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

            let bgView = UIView(frame: CGRectMake(0,0,300,80))
            bgView.opaque = true
            bgView.backgroundColor = UIColor.appThemeColorBlue
            cell.selectedBackgroundView = bgView
        
            return cell
        }
        else
        {
            return UITableViewCell(style: .Value1, reuseIdentifier: "DefaultCell")
        }
    }
    
    // Override to support conditional editing of the table view.
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {

        if self.editing == false{
            return false
        }
        
        guard let currentUserID = anAppDelegate()?.cloudKitHandler.publicCurrentUser?.recordID.recordName else{
            return false
        }
        
        guard let board = boardsHolder.boardForRow(indexPath.row),
        let creatorID = board.creatorId where creatorID == currentUserID else {
            return false
        }
        
        return self.editing
    }
    
    // Override to support editing the table view.
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            if !editingDidHappen{
                editingDidHappen = true
            }
            
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
    func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

        if !editingDidHappen{
            editingDidHappen = true
        }
        
        do{
            let movingBoard = try boardsHolder.removeBoardAtIndex(fromIndexPath.row)
            
            do{
                try boardsHolder.insertBoard(movingBoard, atIndex: toIndexPath.row)
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
    

    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return false
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        if let board = boardsHolder.boardForRow(indexPath.row)
        {
            self.performSegueWithIdentifier("ShowTasksList", sender: board) // selected board
        }
    }
    
    func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        if let board = boardsHolder.boardForRow(indexPath.row)
        {
                
            self.performSegueWithIdentifier("PresentBoardEditing", sender: BoardEditingHolder(boardType: BoardEditingType.EditCurrent(board: board))  )
        }
    }
    
    //MARK: - UITableViewDelegate
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0{
            return 160.0
        }
        return 20.0
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0{
            
            guard let headerAnimatedView = UIView.loadFromNibNamed("BoardsAnimatedHeader") as? BoardsAnimatedHeader else{
                return nil
            }
            
            let width = self.tableView.bounds.size.width
            let height = CGFloat(160.0)
            let frame = CGRectMake(0, 0, width, height)
            headerAnimatedView.frame = frame
            headerAnimatedView.delegate = self
            
            //start assigning data to view
            headerAnimatedView.currentUserId = anAppDelegate()?.cloudKitHandler.publicCurrentUser?.recordID.recordName
            
            return headerAnimatedView
        }
        
        let holderView = UIView(frame: CGRectMake(0.0, 0.0, 80.0, 20.0))
        holderView.opaque = true
        holderView.backgroundColor = UIColor.whiteColor()
        
        let titleSectionLabel = UILabel(frame: CGRectMake(20,0,60.0, 20.0))
        titleSectionLabel.opaque = true
        titleSectionLabel.backgroundColor = UIColor.clearColor()
        titleSectionLabel.text = "Boards"
        titleSectionLabel.font = UIFont(name: "Verdana", size: 17.0)
        titleSectionLabel.textColor = UIColor.appThemeColorBlue
        titleSectionLabel.sizeToFit()
        
        holderView.addSubview(titleSectionLabel)
        
        return holderView
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 82.0
    }
    
    //MARK: -
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        self.tableView.setEditing(editing, animated: animated)
        
        if !editing && editingDidHappen{
            
            editingDidHappen = false
            
            boardsHolder.updateBoardsSortIndexes()
            
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
        
        self.tableView.reloadData()
        //self.tableView.reloadSections(NSIndexSet(indexesInRange: NSMakeRange(0,1)), withRowAnimation: .Automatic)
      
        
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
        anAppDelegate()?.coreDatahandler?.deleteAllTasks()
        
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
                    if let
                        editingNavController = segue.destinationViewController as? BoardEditNavigationController,
                        rootVC = editingNavController.viewControllers.first as? BoardEditViewController {
                            
                        rootVC.boardsHolder = self.boardsHolder
                        
                        if let senderType = sender as? BoardEditingHolder {
                            rootVC.setEditingType(senderType.boardEditingType)
                        }
                        else {
                            rootVC.setEditingType(BoardEditingType.CreateNew)
                        }
                    }
                case "ShowTasksList":
                    if let boardForTasks = sender as? Board, tasksListVC = segue.destinationViewController as? TasksViewController {
                        tasksListVC.weakBoard = boardForTasks
                    }
                default:
                    break
            }
        }
    }
    
    func presentTaskEditingVCFor(taskToEdit:Task){
        if let board = taskToEdit.board{
            self.navigationController?.delegate = self
            self.taskToEdit = taskToEdit
            self.performSegueWithIdentifier("ShowTasksList", sender: board)
            
        }
    }
    
    func navigationController(navigationController: UINavigationController, didShowViewController viewController: UIViewController, animated: Bool) {
        navigationController.delegate = nil
        if let tasksVC = viewController as? TasksViewController{
            tasksVC.showTaskEditViewCntroller(self.taskToEdit)
            
            self.taskToEdit = nil
        }
    }
    
}//BoardsTableViewController class end




