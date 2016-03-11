//
//  UserProfileHeader.swift
//  TaskManager
//
//  Created by CloudCraft on 1/25/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import UIKit

class UserProfileHeader: UIView {


    override func drawRect(rect: CGRect) {
        // Drawing code
        avatar.layer.cornerRadius = avatar.bounds.size.height / 2.0
        avatar.layer.borderWidth = 1.0
        avatar.clipsToBounds = true
    }

    weak var delegate:UserProfileHeaderDelegate?
    
    @IBOutlet weak var avatar:UIImageView!
    @IBOutlet weak var phoneLabel:UILabel!
    
    @IBOutlet weak var phoneCallButton: UIButton!
    @IBOutlet weak var smsButton: UIButton!
    
    @IBAction func imageTappedRecognizerAction(sender:UITapGestureRecognizer){
        self.delegate?.userProfileHeaderTapped()
    }
    
    @IBAction func phoneButtonTap(sender:UIButton){
        delegate?.startCall()
    }
    
    @IBAction func smsButtonTap(sender:UIButton){
        delegate?.startSms()
    }
}
