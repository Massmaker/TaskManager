//
//  BoardsTableViewController+BoardsHeaderViewDelegate.swift
//  TaskManager
//
//  Created by CloudCraft on 2/16/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import Foundation
import UIKit

extension BoardsTableViewController : BoardsHeaderViewDelegate{
    func openCurrentTaskFor(userId:String) {
        if let taskFound = anAppDelegate()?.coreDatahandler?.findActiveTasksForUserById(userId)?.first {
            self.presentTaskEditingVCFor(taskFound)
        }
    }
}