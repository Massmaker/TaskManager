//
//  ContactsTableViewController.swift
//  TaskManager
//
//  Created by CloudCraft on 3/10/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import UIKit

class ContactsTableViewController: UIViewController, UITableViewDataSource , UITableViewDelegate{

    static let kContactListCellIdentifier = "ContactListCell"
    
    @IBOutlet weak var contactsTableView:UITableView!
    
    lazy var contactsHandler:ContactsHandler = ContactsHandler.sharedInstance
    lazy var refreshControl = UIRefreshControl()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let frame = CGRectMake(0, 0, 60, 60)
        refreshControl = UIRefreshControl(frame: frame)
        refreshControl.addTarget(self, action: "rescanContacts:", forControlEvents: .ValueChanged)
        self.contactsTableView.addSubview(refreshControl)
        
        self.contactsHandler.delegate = self //lazyly initialize and set the delegate
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func rescanContacts(sender:UIRefreshControl)
    {
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

    func contactForRow(row:Int) -> User {
        
        let contacts = contactsHandler.allContacts
        
        return contacts[row]
    }
    
    //MARK: - UITableViewDataSource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let contacts = contactsHandler.allContacts
        return contacts.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        guard let contactCell = tableView.dequeueReusableCellWithIdentifier(ContactsTableViewController.kContactListCellIdentifier, forIndexPath: indexPath) as? ContactsListCell else{
            return UITableViewCell(style: .Default, reuseIdentifier: "Cell")
        }
        
        let contact = contactForRow(indexPath.row)
        
        let blueView = UIView(frame: CGRectMake(0,0,50,50))
        blueView.backgroundColor = UIColor.appThemeColorBlue
        contactCell.selectedBackgroundView = blueView
        
        contactCell.nameLabel.text = contact.displayName
        contactCell.phoneLabel.text = contact.phone
        contactCell.setRegistered(false)
        contactCell.avatarImageView.image = contact.avatarImage ?? testAvatarImage
        
        return contactCell
    }
    
    //MARK: - UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let contact = contactForRow(indexPath.row)
        self.performSegueWithIdentifier("ShowSelectedContactSegue", sender: contact)
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
    
}

