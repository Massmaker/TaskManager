//
//  BoardsHolderDelegate.swift
//  TaskManager
//
//  Created by CloudCraft on 2/2/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import Foundation
protocol BoardsHolderDelegate:class{
    func boardsDidStartUpdating()
    func boardsDidFinishUpdating()
}