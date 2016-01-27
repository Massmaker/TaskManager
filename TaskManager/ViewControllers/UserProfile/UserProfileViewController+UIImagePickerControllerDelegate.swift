//
//  UserProfileViewController+UIImagePickerControllerDelegate.swift
//  TaskManager
//
//  Created by CloudCraft on 1/25/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import UIKit
extension UserProfileViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
       // print("user info: \(info.description)")
        
        guard let editedImage = info[UIImagePickerControllerEditedImage] as? UIImage else
        {
            picker.dismissViewControllerAnimated(true, completion: nil)
            return
        }
        
        guard let userPhone = self.currentProfileInfo?.phoneNumber else
        {
            picker.dismissViewControllerAnimated(true, completion: nil)
            return
        }
        
        self.currentProfileInfo?.avatarImage = editedImage
        picker.dismissViewControllerAnimated(true, completion: {[unowned self] in
            
            self.documentsFileHandler.saveAvatarImageToDocuments(editedImage, forUserId: userPhone)
        })
        
        
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        imagePickerController.dismissViewControllerAnimated(true, completion: nil)
    }
}