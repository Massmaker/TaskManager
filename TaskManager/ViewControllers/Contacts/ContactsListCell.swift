//
//  ContactsListCell.swift
//  TaskManager
//
//  Created by CloudCraft on 3/10/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import UIKit

class ContactsListCell: UITableViewCell {

    
    @IBOutlet weak var nameLabel: UILabel!
    //@IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var avatarHolderView: UIView!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var currentTaskTitleLabel:UILabel!
    var taskTapRecognizer:UITapGestureRecognizer?
    
    weak var delegate:ContactCellTaskTapDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        guard let _ = self.taskTapRecognizer else {
            self.taskTapRecognizer = UITapGestureRecognizer(target: self, action: "taskTitleTapped:")
            self.currentTaskTitleLabel.addGestureRecognizer(self.taskTapRecognizer!)
            return
        }
        
        
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func drawRect(rect: CGRect) {
        avatarHolderView.layer.masksToBounds = true
        avatarHolderView.layer.cornerRadius = avatarHolderView.bounds.size.height / 2.0
        //avatarHolderView.layer.borderWidth = 2.0
        
        avatarImageView.layer.masksToBounds = true
        avatarImageView.layer.cornerRadius =  avatarImageView.bounds.size.height / 2.0
        
    }
    
    func setRegistered(boolValue :Bool)
    {
        if boolValue
        {
            avatarHolderView.backgroundColor = UIColor.appThemeColorBlue
            taskTapRecognizer?.enabled = true
        }
        else
        {
            avatarHolderView.backgroundColor = UIColor.grayColor()
            taskTapRecognizer?.enabled = false
        }
    }
    
    func taskTitleTapped(recognizer:UITapGestureRecognizer){
        
        delegate?.handleTapForTaskTitleLabel(recognizer.view as? UILabel, recognizer: self.taskTapRecognizer)
    }

}

protocol ContactCellTaskTapDelegate: class{
    func handleTapForTaskTitleLabel(label:UILabel?, recognizer:UITapGestureRecognizer?)
}
