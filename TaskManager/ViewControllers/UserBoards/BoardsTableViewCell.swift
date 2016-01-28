//
//  BoardsTableViewCell.swift
//  TaskManager
//
//  Created by CloudCraft on 1/26/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import UIKit

class BoardsTableViewCell: UITableViewCell {

    @IBOutlet weak var avatarView:UIImageView!
    @IBOutlet weak var boartTitlelabel:UILabel!
    @IBOutlet weak var boardDetailsLabel:UILabel!
    @IBOutlet weak var dateLabel:UILabel!
    
    
//    override func awakeFromNib() {
//        super.awakeFromNib()
//        // Initialization code
//    }
//
//    override func setSelected(selected: Bool, animated: Bool) {
//        super.setSelected(selected, animated: animated)
//
//        // Configure the view for the selected state
//    }
    
    
    override func layoutSubviews() {
        
        self.avatarView.layer.cornerRadius = self.avatarView.bounds.size.height / 2.0
        self.avatarView.layer.masksToBounds = true
        super.layoutSubviews()
    }
    

}
