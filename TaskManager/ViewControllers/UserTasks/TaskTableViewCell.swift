//
//  TaskTableViewCell.swift
//  TaskManager
//
//  Created by CloudCraft on 1/29/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import UIKit

class TaskTableViewCell: UITableViewCell {
    
    @IBOutlet weak var avatarView:UIImageView!
    @IBOutlet weak var startDateLabel:UILabel!
    @IBOutlet weak var finishDateLabel:UILabel!
    @IBOutlet weak var indicatorView:UIView!
    @IBOutlet weak var titleLabel:UILabel!
    @IBOutlet weak var detailsLabel:UILabel!
    
    override func awakeFromNib() {
        avatarView.layer.masksToBounds = true
    }
    
    func setCurrentTask(taskInfo :Task?)
    {
        if let task = taskInfo
        {
            if task.takenDate != nil && task.finishedDate == nil
            {
                indicatorView.backgroundColor = UIColor.greenColor()
                if let currentOwner = task.currentOwner
                {
                    avatarView.image = currentOwner.avatarImage ?? testAvatarImage
                }
                else if let currentTaskOwnerID = task.currentOwnerId
                {
                    
                    if currentTaskOwnerID == anAppDelegate()?.cloudKitHandler.publicCurrentUser?.recordID.recordName
                    {
                        avatarView.image = anAppDelegate()?.cloudKitHandler.currentUserAvatar ?? testAvatarImage
                    }
                    else if let foundContact = anAppDelegate()?.coreDatahandler?.findContactByPhone(currentTaskOwnerID)
                    {
                        avatarView.image = foundContact.avatarImage ?? testAvatarImage
                    }
                    else
                    {
                        avatarView.image = testAvatarImage
                    }
                }
            }
            else if task.finishedDate != nil && task.takenDate != nil
            {
                indicatorView.backgroundColor = UIColor.blueColor()
                if let creatorID = task.creator
                {
                    if creatorID == anAppDelegate()?.cloudKitHandler.publicCurrentUser?.recordID.recordName
                    {
                        avatarView.image = anAppDelegate()?.cloudKitHandler.currentUserAvatar ?? testAvatarImage
                    }
                    else if let user = anAppDelegate()?.coreDatahandler?.findContactByPhone(creatorID)
                    {
                        avatarView.image = user.avatarImage ?? testAvatarImage
                    }
                }
            }
            else
            {
                indicatorView.backgroundColor = UIColor.whiteColor()
                if let creatorID = task.creator
                {
                    if creatorID == anAppDelegate()?.cloudKitHandler.publicCurrentUser?.recordID.recordName
                    {
                        avatarView.image = anAppDelegate()?.cloudKitHandler.currentUserAvatar ?? testAvatarImage
                    }
                    else if let user = anAppDelegate()?.coreDatahandler?.findContactByPhone(creatorID)
                    {
                        avatarView.image = user.avatarImage ?? testAvatarImage
                    }
                }
            }
            
            finishDateLabel.text = task.finishedDate?.dateTimeCustomString()
            
            
            startDateLabel.text = task.takenDate?.dateTimeCustomString()
            
            
            titleLabel.text = task.title
            detailsLabel.text = task.details
        }
        else
        {
            finishDateLabel.text = nil
            startDateLabel.text = nil
            indicatorView.backgroundColor = UIColor.whiteColor()
            titleLabel.text = nil
            detailsLabel.text = nil
            avatarView.image = testAvatarImage
        }
    }
    
    override func layoutSubviews() {
        avatarView.layer.cornerRadius = avatarView.layer.bounds.size.height / 2.0
        super.layoutSubviews()
    }

}
