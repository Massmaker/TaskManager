//
//  ContactSelectableTableCell.swift
//  TaskManager
//
//  Created by CloudCraft on 3/1/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import UIKit
import Eureka


class ContactSelectableTableCell: CheckCell {
    
    static let className = "ContactSelectableTableCell"
    
    @IBOutlet weak var avatarImageView:UIImageView?
    @IBOutlet weak var nameLabel:UILabel?
    @IBOutlet weak var taskTitleLabel:UILabel?
    @IBOutlet weak var radioCheckView:RadioCheckbox?
    
    
    var info:(user:User?, taskTitle:String?)
    var editingEnabled = false
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let bounds = avatarImageView?.bounds{
            
            avatarImageView?.layer.cornerRadius = bounds.size.height / 2.0
            avatarImageView?.layer.masksToBounds = true
            avatarImageView?.layer.borderColor = UIColor.appThemeColorBlue.CGColor
            avatarImageView?.layer.borderWidth = 2.0
        }
    }
    
    required  init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    override func setup() {
        super.setup()
//        selectionStyle = .None
//        accessoryView = nil
//        accessoryType = .None
//        editingAccessoryType = accessoryType
//        self.avatarImageView?.image = info.user?.avatarImage ?? testAvatarImage
//        self.nameLabel?.text = info.user?.displayName
//        self.taskTitleLabel?.text = info.taskTitle
    }
    
    override func update() {
        super.update()
        selectionStyle = .None
        accessoryView = nil
        accessoryType = .None
        editingAccessoryType = accessoryType
        
        if(editingEnabled){
            radioCheckView?.selected = row.value ?? false
        }
        
        self.avatarImageView?.image = info.user?.avatarImage ?? testAvatarImage
        self.nameLabel?.text = info.user?.displayName
        self.taskTitleLabel?.text = info.taskTitle
    }
}

final
class CheckRowSubclass: Row<Bool, ContactSelectableTableCell>, RowType{
    required init(tag: String?) {
        super.init(tag: tag)
        displayValueFor = nil
        cellProvider = CellProvider<ContactSelectableTableCell>(nibName: ContactSelectableTableCell.className)
    }
}
