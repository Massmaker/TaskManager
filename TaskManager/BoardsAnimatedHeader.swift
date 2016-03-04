//
//  BoardsAnimatedHeader.swift
//  TaskManager
//
//  Created by CloudCraft on 2/24/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import UIKit

class BoardsAnimatedHeader: UIView {
    
    @IBOutlet weak var headerLocalizedTitleLabel:UILabel!  //"My task"
    @IBOutlet weak var userNameLabel:UILabel!
    @IBOutlet weak var taskTitleLabel:UILabel!
    @IBOutlet weak var userAvatarImageView:UIImageView!
    //theese will be hidden, when there is no current active task for user
    @IBOutlet weak var startTaskIconImageView:UIImageView!
    @IBOutlet weak var startTaskDateTimeLabel:UILabel!
    @IBOutlet weak var titleLabelTapRecognizer:UITapGestureRecognizer!
  
    
    
    weak var delegate:BoardsHeaderViewDelegate?
    
    var currentUserId:String?{
        didSet{
            self.refreshUserData()
        }
    }
    
    
    var currentActiveTask:Task?{
        didSet{
            if let task = self.currentActiveTask{
                
                taskTitleLabel.userInteractionEnabled = true
                taskTitleLabel.text = task.title
                startTaskIconImageView.hidden = false
                startTaskDateTimeLabel.hidden = false
                startTaskDateTimeLabel.text = task.takenDate?.dateTimeCustomString()
            }
            else{
                startTaskDateTimeLabel.text = nil
                startTaskDateTimeLabel.hidden = true
                startTaskIconImageView.hidden = true
                taskTitleLabel.userInteractionEnabled = false
                taskTitleLabel.text = nil//NSLocalizedString("No active task", comment: "string to display when there is no active task for current user")
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.userAvatarImageView.layer.masksToBounds = true
        self.userAvatarImageView.layer.cornerRadius = self.userAvatarImageView.layer.bounds.size.height / 2.0
    }
    
    @IBAction func titleTapRecognised(sender:UITapGestureRecognizer){
        guard let userId = currentUserId else{
            return 
        }
        
        delegate?.openCurrentTaskFor(userId)
    }
    
    private func refreshUserData() {
        
        //assign user name
        var userData = [String]()
        if let firstName = UserDefaultsManager.getUserNameFromDefaults(){
            userData.append(firstName)
        }
        if let lastName = UserDefaultsManager.getUserLastNameFromDefaults(){
            userData.append(lastName)
        }
            
        userNameLabel.text = spaceConcatenatedStrings(userData)
        
        if userNameLabel.text!.characters.count < 2{
        
            userNameLabel.text = NSLocalizedString("No user name", comment: "Default user name if no user name is present in user defaults")
        }
        
        //start assigning task info
        guard let anId = currentUserId else{
            self.currentActiveTask = nil
            return
        }
        
        if let image = DocumentsFolderFileHandler().getAvatarImageFromDocumentsForUserId(anId){
            userAvatarImageView.image = image
        }
        else{
            userAvatarImageView.image = testAvatarImage
        }
        
        if let tasksByUser = anAppDelegate()?.coreDatahandler?.findActiveTasksForUserById(anId){
            self.currentActiveTask = tasksByUser.first
        }
        else{
            self.currentActiveTask = nil
        }
    }
}
