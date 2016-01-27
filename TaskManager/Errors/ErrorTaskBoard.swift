//
//  ErrorTaskBoard.swift
//  TaskCloud
//
//  Created by CloudCraft on 1/15/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import Foundation

enum TaskBoardError:ErrorType
{
    case NotFound
}

let noBoardIdError = NSError(domain: "BoardError", code: -21, userInfo: [NSLocalizedDescriptionKey:"No board ID found"])