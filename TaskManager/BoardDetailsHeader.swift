//
//  BoardDetailsHeader.swift
//  TaskManager
//
//  Created by CloudCraft on 1/28/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import UIKit

class BoardDetailsHeader: UIView {

    @IBOutlet weak var avatarView:UIImageView!
    @IBOutlet weak var dateLabel:UILabel!
    @IBOutlet weak var nameLabel:UILabel!
    @IBOutlet weak var deleteButton:UIButton!
    weak var headerDelegate:BoardDetailsHeaderDelegate?
    
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        self.avatarView.layer.cornerRadius = self.avatarView.layer.bounds.size.height / 2.0
        self.avatarView.layer.masksToBounds = true
    }


    @IBAction func deleteAction(sender:UIButton){
        self.headerDelegate?.boardsHeaderDeleteButtonTapped(sender)
    }
}
