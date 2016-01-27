//
//  Extensions+String.swift
//  TaskManager
//
//  Created by CloudCraft on 1/27/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import Foundation
extension String {
    var fixedPhoneNumber:String?{
        guard !self.isEmpty else
        {
            return nil
        }
        
        let numbersSet = NSCharacterSet.decimalDigitCharacterSet().invertedSet
        let fixed = self.componentsSeparatedByCharactersInSet(numbersSet)
        var joined = ""
        for aString in fixed
        {
            joined += aString
        }
        
        if joined.characters.count < 12
        {
            return nil
        }
        
        let plusChar = Character("+")
        joined.insert(plusChar, atIndex: joined.startIndex)
        
        return joined
    }
}