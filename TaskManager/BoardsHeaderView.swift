//
//  BoardsHeaderView.swift
//  TaskManager
//
//  Created by CloudCraft on 2/12/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import UIKit

class BoardsHeaderView: UIView, UITextViewDelegate {

    @IBOutlet weak var titleLabel:UILabel!
    @IBOutlet weak var textView:UITextView!
    @IBOutlet weak var avatarImageView:UIImageView!

    weak var delegate:BoardsHeaderViewDelegate?
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
            textView.attributedText = nil
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
            textView.text = tasksByUser.first!.title
            if let title = tasksByUser.first?.title, boardTitle = tasksByUser.first?.board?.title{
                textView.attributedText = attributedTitleForTask(title, inBboard: boardTitle)
                self.textView.delegate = self
            }
        }
        else{
            textView.attributedText = nil
            textView.text = "No current task"

            self.textView.delegate = nil
        }
    }
    
    private func attributedTitleForTask(taskTitle:String, inBboard boardTitle:String) -> NSAttributedString {
        
        let boardTitleAttributes = [NSFontAttributeName:UIFont.systemFontOfSize(15.0), NSForegroundColorAttributeName: UIColor.blackColor().colorWithAlphaComponent(0.8)]
        let taskTitleAttributes = [NSFontAttributeName: UIFont.systemFontOfSize(16.0), NSUnderlineColorAttributeName:UIColor.redColor().colorWithAlphaComponent(0.8)]
        
        let mutableAttributed = NSMutableAttributedString()
        let attributedBoardTitle = NSAttributedString(string: boardTitle, attributes: boardTitleAttributes)
        let attributedSlash = NSAttributedString(string: " / ")
        let attributedTaskTitle = NSMutableAttributedString(string: taskTitle, attributes: taskTitleAttributes)

        let nsRange = NSMakeRange(0, attributedTaskTitle.string.characters.count)
        attributedTaskTitle.addAttribute(  NSLinkAttributeName, value:"opentask://\(boardTitle)", range: nsRange)
        
        mutableAttributed.appendAttributedString(attributedBoardTitle)
        mutableAttributed.appendAttributedString(attributedSlash)
        mutableAttributed.appendAttributedString(attributedTaskTitle)
        
        return mutableAttributed
    }
    
    func textView(textView: UITextView, shouldInteractWithURL URL: NSURL, inRange characterRange: NSRange) -> Bool{
        guard let userId = currentUserId else{
            return false
        }
        
        delegate?.openCurrentTaskFor(userId)
       
        return false
    }
}
