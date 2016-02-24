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
        formatter.dateFormat = "dd.MM.YY HH:MM"
        let string = formatter.stringFromDate(self)
        return string
    }
    
    func todayTimeOrDateStringRepresentation() -> String {
        
        let calendar = NSCalendar.currentCalendar()

        let isToday = calendar.isDate(self, inSameDayAsDate: NSDate())
        
        let formatter = NSDateFormatter()
        
        if isToday{
            formatter.dateFormat = "HH:MM"
        }
        else{
            formatter.dateFormat = "dd.MM.YY"
        }
        
        let dateString = formatter.stringFromDate(self)
        
        return dateString
    }
}