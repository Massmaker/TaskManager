//
//  ContactCollectionViewCell.swift
//  StoryBoardTableView
//
//  Created by CloudCraft on 12/29/15.
//  Copyright © 2015 CloudCraft. All rights reserved.
//

import UIKit

class ContactCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView:UIImageView!
    @IBOutlet weak var elementLabel:UILabel!
    
    
    override func drawRect(rect: CGRect) {
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = imageView.bounds.size.height / 2.0
    }
}
