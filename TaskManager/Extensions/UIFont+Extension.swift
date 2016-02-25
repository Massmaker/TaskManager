//
//  UIFont+Extension.swift
//  TaskManager
//
//  Created by CloudCraft on 2/25/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import UIKit
extension UIFont {
    
    class func appRegularFontOfSize(fontSize:CGFloat) -> UIFont {
        let font = UIFont(name: "SegoeUI", size: fontSize)
        return font!
    }
    
    class func appSemiboldFontOfSize(fontSize:CGFloat)  -> UIFont {
        //Segoe UI Semibold
        let font = UIFont(name: "SegoeUI-Semibold", size: fontSize)
        return font!
    }
    
    class func appLightFontOfSize(fontSize:CGFloat) -> UIFont {

        let font = UIFont(name: "SegoeUI-Light", size: fontSize)
        
        return font!
    }
}