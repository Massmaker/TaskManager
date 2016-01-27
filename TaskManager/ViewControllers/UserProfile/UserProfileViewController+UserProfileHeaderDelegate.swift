//
//  UserProfileViewController+UserProfileHeaderDelegate.swift
//  TaskManager
//
//  Created by CloudCraft on 1/25/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import Foundation
extension UserProfileViewController : UserProfileHeaderDelegate {
    func userProfileHeaderTapped() {
        self.showImagePickerForUserAvatar()
    }
}