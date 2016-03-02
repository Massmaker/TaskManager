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
        
        guard let originalImage = info[UIImagePickerControllerOriginalImage] as? UIImage else
        {
            picker.dismissViewControllerAnimated(true, completion: nil)
            return
        }
        
        guard let avatarThumbnail = originalImage.thumbnailImageSize(320, transparentBorder: 0, cornerRadius: 0, interpolationQuality: CGInterpolationQuality.High) else {
            
            picker.dismissViewControllerAnimated(true, completion: nil)
            return
        }
        
        guard let userPhone = self.currentProfileInfo?.phoneNumber else
        {
            picker.dismissViewControllerAnimated(true, completion: nil)
            return
        }
        
        self.currentProfileInfo?.avatarImage = avatarThumbnail
        picker.dismissViewControllerAnimated(true, completion: {[unowned self] in
            
            self.documentsFileHandler.saveAvatarImageToDocuments(avatarThumbnail, forUserId: userPhone)
            anAppDelegate()?.cloudKitHandler.resetCurrentUserAvatarImage()
        })
        
        
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        imagePickerController.dismissViewControllerAnimated(true, completion: nil)
    }
}