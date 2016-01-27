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
    
    var cellSize:CGSize{
        get
        {
            if pCellSize == CGSizeZero
            {
                //print("get cell size")
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
    
    let noContactImage = UIImage(named: "No-Contact")
    override func viewDidLoad() {
        super.viewDidLoad()

        // Register cell classes
        //self.collectionView!.registerClass(ContactCollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        // Do any additional setup after loading the view.
        
        self.contactsHandler.delegate = self //lazyly initialize and set the delegate
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: - UICollectionViewDelegateFlowLayout
    func collectionView(collectionView: UICollectionView,
            layout collectionViewLayout: UICollectionViewLayout,
            sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        return cellSize
    }
    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        
        return 1
    }


    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        
        let contacts = contactsHandler.allContacts
        return contacts.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as? ContactCollectionViewCell else
        {
            return UICollectionViewCell()
        }
    
        let contactFound = contactForItem(indexPath.item)
        
        cell.imageView.image = contactFound.avatarImage ?? noContactImage
        cell.elementLabel.text = contactFound.displayName
        
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
