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
    @IBOutlet weak var taskStatusImageView:UIImageView!
    @IBOutlet weak var startDateLabel:UILabel!
    @IBOutlet weak var finishDateLabel:UILabel!
    @IBOutlet weak var titleLabel:UILabel!
    @IBOutlet weak var detailsLabel:UILabel!
    @IBOutlet weak var startTaskImageView:UIImageView!
    @IBOutlet weak var finishTaskImageView:UIImageView!
    
    
    override func awakeFromNib() {
        avatarView.layer.masksToBounds = true
    }
    
    func setCurrentTask(taskInfo :Task?)
    {
        if let task = taskInfo{
            
            if task.takenDate != nil && task.finishedDate == nil{
                
                finishTaskImageView.hidden = true
                startTaskImageView.hidden = false
                self.taskStatusImageView.image = defaultTaskStatusBackground
                
                if let currentTaskOwnerID = task.currentOwnerId{
                    if currentTaskOwnerID == anAppDelegate()?.cloudKitHandler.publicCurrentUser?.recordID.recordName{
                        avatarView.image = anAppDelegate()?.cloudKitHandler.currentUserAvatar ?? testAvatarImage
                    }
                    else if let foundContact = anAppDelegate()?.coreDatahandler?.findContactByPhone(currentTaskOwnerID){
                        avatarView.image = foundContact.avatarImage ?? testAvatarImage
                    }
                    else{
                        avatarView.image = testAvatarImage
                    }
                }
                else{
                    avatarView.image = testAvatarImage
                }
            }
            else if task.finishedDate != nil && task.takenDate != nil{
                //task is finished
                finishTaskImageView.hidden = false
                startTaskImageView.hidden = false
                self.taskStatusImageView.image = finishedTaskStatusBackground
                
                if let currentTaskOwnerID = task.currentOwnerId{
                    
                    if currentTaskOwnerID == anAppDelegate()?.cloudKitHandler.publicCurrentUser?.recordID.recordName{
                        avatarView.image = anAppDelegate()?.cloudKitHandler.currentUserAvatar ?? testAvatarImage
                    }
                    else if let foundContact = anAppDelegate()?.coreDatahandler?.findContactByPhone(currentTaskOwnerID){
                        avatarView.image = foundContact.avatarImage ?? testAvatarImage
                    }
                    else{
                        avatarView.image = testAvatarImage
                    }
                }
                else{
                    avatarView.image = testAvatarImage
                }
            }
            else{
                
                self.taskStatusImageView?.image = defaultTaskStatusBackground
                avatarView.image = nil
                startTaskImageView.hidden = true
                finishTaskImageView.hidden = true
            }
            
            finishDateLabel.text = task.finishedDate?.todayTimeOrDateStringRepresentation()
            
            startDateLabel.text = task.takenDate?.todayTimeOrDateStringRepresentation()
            
            titleLabel.text = task.title
            detailsLabel.text = task.details
        }
        else{
            self.taskStatusImageView.image = defaultTaskStatusBackground
            finishDateLabel.text = nil
            startDateLabel.text = nil
            //indicatorView.backgroundColor = UIColor.whiteColor()
            titleLabel.text = nil
            detailsLabel.text = nil
            avatarView.image = testAvatarImage
            finishTaskImageView.hidden = true
            startTaskImageView.hidden = true
        }
    }
    
    override func layoutSubviews() {
        avatarView.layer.cornerRadius = avatarView.layer.bounds.size.height / 2.0
        super.layoutSubviews()
    }

}
