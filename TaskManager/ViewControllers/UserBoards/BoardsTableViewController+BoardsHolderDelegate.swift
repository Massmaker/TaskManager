//
//  BoardsTableViewController+BoardsHolderDelegate.swift
//  TaskManager
//
//  Created by CloudCraft on 1/18/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import Foundation
import UIKit

extension BoardsTableViewController:BoardsHolderDelegate{
    func boardsHolderWillUpdateBoards(handler: BoardsHolding) {
        self.tableView.userInteractionEnabled = false
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    
    func boardsHolderDidUpdateBoards(handler: BoardsHolding) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        dispatch_async(dispatch_get_main_queue()){[weak self] in
            self?.tableView.reloadData()
            self?.tableView.userInteractionEnabled = true
            if let presentedEditor = self?.presentedViewController
            {
                presentedEditor.dismissViewControllerAnimated(true, completion: nil)
            }
        }
    }
}