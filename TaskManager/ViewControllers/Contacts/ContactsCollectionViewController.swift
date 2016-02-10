//
//  ContactsCollectionViewController.swift
//  StoryBoardTableView
//
//  Created by CloudCraft on 12/29/15.
//  Copyright © 2015 CloudCraft. All rights reserved.
//

import UIKit

private let reuseIdentifier = "ContactCollectionCell"

class ContactsCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {

    private var pCellSize:CGSize = CGSizeZero
    
    lazy var contactsHandler:ContactsHandler = ContactsHandler.sharedInstance
    lazy var refreshControl = UIRefreshControl()
    
    var cellSize:CGSize{
        get
        {
            if pCellSize == CGSizeZero
            {
                guard let collectionView = self.collectionView else
                {
                    return CGSizeMake(60, 72)
                }
            
                let width:CGFloat = floor(collectionView.bounds.size.width / 4.0)
                pCellSize = CGSizeMake(width, floor(width * 1.4))
                return pCellSize
            }
            else
            {
                return pCellSize
            }
        }
        set
        {
            collectionView?.reloadSections(NSIndexSet(index: 0))
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let frame = CGRectMake(0, 0, 60, 60)
        refreshControl = UIRefreshControl(frame: frame)
        refreshControl.addTarget(self, action: "rescanContacts:", forControlEvents: .ValueChanged)
        self.collectionView?.addSubview(refreshControl)
        
        
        self.contactsHandler.delegate = self //lazyly initialize and set the delegate
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        if refreshControl.refreshing{
            refreshControl.endRefreshing()
        }
    }
    
    //MARK: -
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - UICollectionViewDelegateFlowLayout
    func collectionView(collectionView: UICollectionView,
            layout collectionViewLayout: UICollectionViewLayout,
            sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        return cellSize
    }
    
//    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
//        return 10
//    }
//    
//    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
//        return 10
//    }
    
    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        let contacts = contactsHandler.allContacts
        return contacts.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as? ContactCollectionViewCell else
        {
            return UICollectionViewCell()
        }
    
        let contactFound = contactForItem(indexPath.item)
        
        cell.imageView.image = contactFound.avatarImage ?? testAvatarImage
        cell.elementLabel.text = contactFound.displayName
        cell.setRegistered(contactFound.isRegistered)
        
        return cell
    }

    internal func contactForItem(item:Int) -> User
    {
        let contacts = contactsHandler.allContacts
        
        return contacts[item]
    }
    
    // MARK: - UICollectionViewDelegate

    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        //show contact profile VC
        
        let contact = contactForItem(indexPath.item)
        
        self.performSegueWithIdentifier("ShowSelectedContactSegue", sender: contact)
    }
    
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
