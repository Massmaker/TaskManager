//
//  BoardsHeaderView.swift
//  TaskManager
//
//  Created by CloudCraft on 2/12/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import UIKit

class BoardsHeaderView: UIView {

    @IBOutlet weak var taskTitleLabel:UILabel!
    @IBOutlet weak var avatarImageView:UIImageView!

    var currentUserId:String?{
        didSet{
            self.refreshUserData()
        }
    }
    
    override func layoutSubviews() {
        self.avatarImageView.maskToCircle()
        self.layer.shadowOpacity = 0.5
        self.layer.shadowOffset = CGSizeMake(0, 3)
        super.layoutSubviews()
    }
    
    private func refreshUserData(){
        guard let anId = currentUserId else{
            taskTitleLabel.text = nil
            avatarImageView.image = testAvatarImage
            return
        }
        
        if let image = DocumentsFolderFileHandler().getAvatarImageFromDocumentsForUserId(anId){
            avatarImageView.image = image
        }
        else{
            avatarImageView.image = testAvatarImage
        }
        
        if let tasksByUser = anAppDelegate()?.coreDatahandler?.findActiveTasksForUserById(anId){
            taskTitleLabel.text = tasksByUser.first!.title
        }
        else{
            taskTitleLabel.text = "No current task"
        }
    }
}
