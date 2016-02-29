//
//  TasksViewController+TasksHolderDelegate.swift
//  TaskManager
//
//  Created by CloudCraft on 2/2/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import UIKit
extension TasksViewController : TasksHolderDelegate {
    
    func tasksWillStartUpdating()
    {
        setLoadingIndicatorVisible(true)
    }
    
    func tasksDidFinishUpdating()
    {
        setLoadingIndicatorVisible(false)
        if let editorVC_Holder = self.presentedViewController as? UINavigationController, _ = editorVC_Holder.viewControllers.first as? TaskEditViewController{
            editorVC_Holder.dismissViewControllerAnimated(true, completion: nil)
        }
    }
}