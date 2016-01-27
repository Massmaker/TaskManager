//
//  BoardsHolderDelegate.swift
//  TaskCloud
//
//  Created by CloudCraft on 1/15/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import Foundation

protocol BoardsHolderDelegate : class {
    func boardsHolderWillUpdateBoards(handler:BoardsHolding)
    func boardsHolderDidUpdateBoards(handler:BoardsHolding)
}