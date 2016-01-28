//
//  Extensions+NSDate.swift
//  TaskManager
//
//  Created by CloudCraft on 1/28/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import Foundation
extension NSDate {
    
    func dateTimeCustomString() -> String
    {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "DD.MM.YY HH:MM"
        let string = formatter.stringFromDate(self)
        return string
    }
}