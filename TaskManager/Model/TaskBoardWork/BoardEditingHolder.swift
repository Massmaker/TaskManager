//
//  BoardEditingHolder.swift
//  TaskCloud
//
//  Created by CloudCraft on 1/14/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import Foundation
/**
 this is a workaround class to pass enum value " `BoardEditingType` " into `*prepareForSegue:sender:*` method as "sender" parameter
*/
class BoardEditingHolder{
    let boardEditingType:BoardEditingType
    init(boardType:BoardEditingType)
    {
        self.boardEditingType = boardType
    }
}