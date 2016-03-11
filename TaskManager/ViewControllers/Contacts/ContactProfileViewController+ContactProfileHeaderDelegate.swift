//
//  ContactProfileViewController+ContactProfileHeaderDelegate.swift
//  TaskManager
//
//  Created by CloudCraft on 3/10/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import Foundation
import MessageUI

extension ContactProfileViewController: UserProfileHeaderDelegate{
    
    func userProfileHeaderTapped() {
        //self.showImagePickerForUserAvatar()
    }
    
    func startCall(){
        
        guard let phoneNumber = contact?.phone else{
            return
        }
        
        guard let callUrl = NSURL(string: "telprompt:\(phoneNumber)") else{
            return
        }
        
        if UIApplication.sharedApplication().canOpenURL(callUrl){
            UIApplication.sharedApplication().openURL(callUrl)
        }
        else{
            self.showAlertController("Warning", text: "Call cannot be started", closeButtonTitle: "Ok")
        }
    }
    
    func startSms(){
        
        guard let phoneNumber = contact?.phone else{
            return
        }
        
        if MFMessageComposeViewController.canSendText(){
            let messageVC = MFMessageComposeViewController()
            messageVC.recipients = [phoneNumber]
            messageVC.messageComposeDelegate = self
            self.presentViewController(messageVC, animated: false, completion: nil)
        }
        else{
            self.showAlertController("Warning", text: "SMS sending cannot be started", closeButtonTitle: "Ok")
        }
    }
    
}

extension ContactProfileViewController:MFMessageComposeViewControllerDelegate, UINavigationControllerDelegate{
    func messageComposeViewController(controller: MFMessageComposeViewController, didFinishWithResult result: MessageComposeResult) {
        switch result{
        case MessageComposeResultCancelled:
            controller.dismissViewControllerAnimated(true, completion: nil)
        case MessageComposeResultSent:
            controller.dismissViewControllerAnimated(false, completion: nil)
        case MessageComposeResultFailed:
            controller.dismissViewControllerAnimated(true, completion: {[weak self]  in
                self?.showAlertController("Error", text: "Did not send message", closeButtonTitle: "Ok")
                })
        default:
            controller.dismissViewControllerAnimated(false, completion: nil)
        }
    }
}