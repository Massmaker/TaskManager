//
//  TaskActionsView.swift
//  TaskManager
//
//  Created by CloudCraft on 2/25/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import UIKit

class TaskActionsView: UIView {

    @IBOutlet weak var bottomLabel:UILabel!
    @IBOutlet weak var actionButtonImageView:UIImageView!
    @IBOutlet weak var startArrowImageView:UIImageView!
    @IBOutlet weak var startDatelabel:UILabel!
    @IBOutlet weak var finishDateLabel:UILabel!
    @IBOutlet weak var finishCheckmarkImageView:UIImageView!
    @IBOutlet weak var actionTapRecognizer:UITapGestureRecognizer!
    
    weak var delegate:TaskActionsViewDelegate?
    
    @IBAction func actionTapRecognized(recognizer:UITapGestureRecognizer){
        self.delegate?.taskActionButtonTapped(recognizer.view)
    }
}
