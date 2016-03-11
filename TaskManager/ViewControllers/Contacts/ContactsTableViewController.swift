//
//  ContactsTableViewController.swift
//  TaskManager
//
//  Created by CloudCraft on 3/10/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import UIKit
import CoreData

class ContactsTableViewController: UIViewController, UITableViewDataSource , UITableViewDelegate, NSFetchedResultsControllerDelegate{

    static let kContactListCellIdentifier = "ContactListCell"
    
    @IBOutlet weak var contactsTableView:UITableView!
    
    @IBOutlet weak var contactsSwitch:UISegmentedControl!
    
    lazy var contactsHandler:ContactsHandler = ContactsHandler.sharedInstance
    lazy var refreshControl = UIRefreshControl()
    
    var currentFetchedController:NSFetchedResultsController?
    
    lazy var regContactsFetchedController:NSFetchedResultsController? = {
        
        guard let mainContext = anAppDelegate()?.coreDatahandler?.getMainContext() else{
            return nil
        }
        
        let controller = NSFetchedResultsController(fetchRequest: CoreDataManager.registeredContactsFetchRequest, managedObjectContext:mainContext , sectionNameKeyPath: "lastName", cacheName: nil)
        
        return controller
    }()
    
    lazy var unregContactsFetchedController:NSFetchedResultsController? = {
        
        guard let mainContext = anAppDelegate()?.coreDatahandler?.getMainContext() else{
            return nil
        }
        
        let controller = NSFetchedResultsController(fetchRequest: CoreDataManager.unregisteredContactsFetchRequest, managedObjectContext:mainContext , sectionNameKeyPath: "lastName", cacheName: nil)
        
        return controller
    }()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let frame = CGRectMake(0, 0, 60, 60)
        refreshControl = UIRefreshControl(frame: frame)
        refreshControl.addTarget(self, action: "rescanContacts:", forControlEvents: .ValueChanged)
        self.contactsTableView.addSubview(refreshControl)
        
        self.contactsHandler.delegate = self //lazyly initialize and set the delegate
        
        self.contactsSwitch.selectedSegmentIndex = 0
        self.contactsSwitchDidSwitch(self.contactsSwitch) // to perform initial fetch
        self.contactsTableView.estimatedRowHeight = 74.0
        self.contactsTableView.rowHeight = UITableViewAutomaticDimension
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - 
    @IBAction func contactsSwitchDidSwitch(sender:UISegmentedControl){
        let currentSelectedIndex = sender.selectedSegmentIndex
        
        switch currentSelectedIndex{
        case 0:
            currentFetchedController = self.regContactsFetchedController
        case 1:
            currentFetchedController = self.unregContactsFetchedController
        default:
            break
        }
        
        currentFetchedController?.delegate = self
        do{
            try currentFetchedController?.performFetch()
            self.contactsTableView.reloadData()
        }
        catch let fetchError{
            print(fetchError)
        }
    }
    
    func refreshContactsTable(){
        self.contactsSwitchDidSwitch(self.contactsSwitch)
    }
    
    //MARK: -
    func rescanContacts(sender:UIRefreshControl)
    {
        self.unregContactsFetchedController?.delegate = nil
        self.regContactsFetchedController?.delegate = nil
        
        contactsHandler.delegate = self
        contactsHandler.configureAllOperations()
        
        let timeout:dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 30.0))
        dispatch_after(timeout, dispatch_get_main_queue()) {[weak self] () -> Void in
            if let refresher = self?.refreshControl where refresher.refreshing
            {
                refresher.endRefreshing()
            }
        }
    }

    func contactForIndexPath(indexPath:NSIndexPath) -> User? {
        
        return self.currentFetchedController?.objectAtIndexPath(indexPath) as? User
        //let contacts = contactsHandler.allContacts
        
        //return contacts[row]
    }
    
    //MARK: - UITableViewDataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let controller = self.currentFetchedController, let sectionsInfo = controller.sections{
            print("Contacts SectionInfo: \(sectionsInfo.count) ")
            return sectionsInfo.count
        }
        return 0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = currentFetchedController?.sections where sections.count > section{
            let count = sections[section].numberOfObjects
            print("Users count: \(count)")
            return count
        }
        return 0
        
        //let contacts = contactsHandler.allContacts
        //return contacts.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        guard let contactCell = tableView.dequeueReusableCellWithIdentifier(ContactsTableViewController.kContactListCellIdentifier, forIndexPath: indexPath) as? ContactsListCell else{
            return UITableViewCell(style: .Default, reuseIdentifier: "Cell")
        }
        
        guard let contact = contactForIndexPath(indexPath) else{
            return contactCell
        }
        
        contactCell.delegate = self
        
        let blueView = UIView(frame: CGRectMake(0,0,50,50))
        blueView.backgroundColor = UIColor.appThemeColorBlue
        contactCell.selectedBackgroundView = blueView
        
        contactCell.nameLabel.text = contact.displayName
        //contactCell.phoneLabel.text = contact.phone
        
        
        if contactsSwitch.selectedSegmentIndex < 1{
            contactCell.setRegistered(true)
            if let phone = contact.phone{
                contactCell.currentTaskTitleLabel.text = anAppDelegate()?.coreDatahandler?.findActiveTasksForUserById(phone)?.first?.title
            }
            else{
                contactCell.currentTaskTitleLabel.text = nil
            }
        }
        else{
            contactCell.setRegistered(false)
            contactCell.currentTaskTitleLabel.text = nil
        }
        
        
        contactCell.avatarImageView.image = contact.avatarImage ?? testAvatarImage
        
        return contactCell
    }
    
    //MARK: - UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let contact = contactForIndexPath(indexPath)
        self.performSegueWithIdentifier("ShowSelectedContactSegue", sender: contact)
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let contact = self.contactForIndexPath(NSIndexPath(forRow: 0, inSection: section)){
            if let displayName = contact.lastName where displayName.characters.count > 0{
                return displayName.substringToIndex(contact.displayName.startIndex.advancedBy(1))
            }
        }
        return nil
    }
    
    func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
        return nil
    }
 
    //MARK: - NSFetchedResultsControllerDelegate
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.contactsTableView.beginUpdates()
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.contactsTableView.endUpdates()
        //self.contactsTableView.reloadData()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type{
        case .Update:
            if let inPath = indexPath{
                self.contactsTableView.reloadRowsAtIndexPaths([inPath], withRowAnimation: .Fade)
            }
            if let newPath = newIndexPath{
                self.contactsTableView.reloadRowsAtIndexPaths([newPath], withRowAnimation: .None)
            }
        case .Insert:
            if let inPath = indexPath{
                self.contactsTableView.insertRowsAtIndexPaths([inPath], withRowAnimation: .None)
            }
            if let newPath = newIndexPath{
                self.contactsTableView.insertRowsAtIndexPaths([newPath], withRowAnimation: .None)
            }
        default:
            break
        }
        
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type{
        case .Delete:
            self.contactsTableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .None)
        case .Insert:
            self.contactsTableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .None)
        default:
            break
        }
    }
    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let cProfileVC = segue.destinationViewController as? ContactProfileViewController else
        {
            return
        }
        
        guard let contact = sender as? User else
        {
            return
        }
        
        cProfileVC.contact = contact
    }
    
    func showTaskEditFor(task:Task){
        guard let editNavVC = self.storyboard?.instantiateViewControllerWithIdentifier("TaskEditNavigationController") as? TaskEditNavigationController, editVC = editNavVC.viewControllers.first as? TaskEditViewController  else {
            return
        }
        
        editVC.taskEditingType = TaskEditType.EditCurrent(task: task)
        
        self.presentViewController(editNavVC, animated: true) { () -> Void in
            
        }
    }
    
}

