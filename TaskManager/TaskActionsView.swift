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
    @IBOutlet weak var taskOwnerImageView:UIImageView!
    @IBOutlet weak var startArrowImageView:UIImageView!
    @IBOutlet weak var startDatelabel:UILabel!
    @IBOutlet weak var finishDateLabel:UILabel!
    @IBOutlet weak var finishCheckmarkImageView:UIImageView!
    @IBOutlet weak var actionTapRecognizer:UITapGestureRecognizer!
    @IBOutlet weak var arrowLeadingConstraint:NSLayoutConstraint!
    
    weak var delegate:TaskActionsViewDelegate?
    
    var taskStartDate:String?{
        didSet{
            startArrowImageView.hidden = (taskStartDate == nil)
            startDatelabel.text = taskStartDate
        }
    }
    
    var taskFinishDate:String?{
        didSet{
            finishDateLabel.text = taskFinishDate
            if let _ = taskFinishDate{
               finishCheckmarkImageView.hidden = false
                actionButtonImageView.image = UIImage(named:"icon_task_finished")
            }
            else{
                finishCheckmarkImageView.hidden = true
                actionButtonImageView.image = UIImage(named: "button_task_take")
            }
        }
    }
    var taskOwnerImage:UIImage?{
        didSet{
            taskOwnerImageView.image = taskOwnerImage
        }
    }
    
    @IBAction func actionTapRecognized(recognizer:UITapGestureRecognizer){
        self.delegate?.taskActionButtonTapped(recognizer.view)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
//        actionButtonImageView.layer.borderColor = UIColor.appThemeColorBlue.CGColor
//        actionButtonImageView.layer.borderWidth = 2.0
//        actionButtonImageView.layer.cornerRadius = actionButtonImageView.layer.bounds.size.height / 2.0
//        actionButtonImageView.layer.masksToBounds = true
        taskOwnerImageView.layer.masksToBounds = true
        taskOwnerImageView.layer.cornerRadius = taskOwnerImageView.bounds.size.height / 2.0
        
        if self.bounds.size.width < 330.0{
            self.arrowLeadingConstraint.constant = 24.0
        }
        else{
            self.arrowLeadingConstraint.constant = 61.0
        }
    }
}
