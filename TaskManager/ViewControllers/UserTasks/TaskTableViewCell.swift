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
            }
            else if task.finishedDate != nil && task.takenDate != nil
            {
                indicatorView.backgroundColor = UIColor.blueColor()
            }
            else
            {
                indicatorView.backgroundColor = UIColor.whiteColor()
            }
            
            finishDateLabel.text = task.finishedDate?.dateTimeCustomString()
            startDateLabel.text = task.takenDate?.dateTimeCustomString()
            titleLabel.text = task.title
            detailsLabel.text = task.details
            avatarView.image = testAvatarImage //TODO:  set creator image if task is not set or current task oaner avatar if task in in process
            
            if let currentTaskOwner = task.currentOwner
            {
                if currentTaskOwner.phone! == anAppDelegate()!.cloudKitHandler.publicCurrentUser!.recordID.recordName
                {
                    avatarView.image = anAppDelegate()?.cloudKitHandler.currentUserAvatar
                }
                else
                {
                    avatarView.image = currentTaskOwner.avatarImage //ContactsHandler.sharedInstance.contactByPhone(currentTaskOwnerPhone)?.avatarImage
                }
            }
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
