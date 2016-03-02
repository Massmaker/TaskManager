//
//  RadioChechbox.swift
//  TaskManager
//
//  Created by CloudCraft on 3/1/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import UIKit

class RadioCheckbox: UIView {

    //@IBInspectable
    var backGroundColor:UIColor?{
        didSet{
            self.backgroundColor = backGroundColor ?? UIColor.appThemeColorBlue
        }
    }
    
    //@IBInspectable
    var dotBackgroundColor:UIColor?{
        didSet{
            self.dotView?.backgroundColor = dotBackgroundColor ?? UIColor.whiteColor()
        }
    }
    
    @IBOutlet var dotView:UIView?
    
    var selected:Bool = false{
        didSet{
            dotView?.hidden = !selected
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.layer.masksToBounds = true
        self.dotView?.layer.masksToBounds = true
        
        if let bounds = dotView?.bounds{
            self.dotView?.layer.cornerRadius = bounds.size.height / 2.0
        }
        
        self.layer.cornerRadius = self.bounds.size.height / 2.0
    }

}
