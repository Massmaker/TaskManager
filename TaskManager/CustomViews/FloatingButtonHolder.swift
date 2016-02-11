//
//  FloatingButtonHolder.swift
//  TaskManager
//
//  Created by CloudCraft on 2/11/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import UIKit
/**
 *Currently instance is to be created from code by invoking **init(frame:CGRect)**
 
 *You use it as target-action sender(UIButton-, UISwitch- like)
- Note: currently only `"UIControlEvent .TouchUpInside"` is used (all you need for handling button behaviour)
 */
class FloatingButtonControl: UIControl {

    //MARK: - properties to customize
    var buttonColor:UIColor = UIColor(red: 57.0/255.0, green: 186.0/255.0, blue: 127.0/255.0, alpha: 1.0){
        didSet{
            self.button.backgroundColor = buttonColor ?? UIColor(red: 57.0/255.0, green: 186.0/255.0, blue: 127.0/255.0, alpha: 1.0)
            
        }
    }
    
    var buttonImage:UIImage?{
        didSet{
            self.button.setBackgroundImage(buttonImage, forState: .Normal)
        }
    }
    
    var buttonTintColor:UIColor = UIColor.whiteColor(){
        didSet{
            self.button.tintColor = buttonTintColor
            self.tintColor = buttonColor
        }
    }
    
    var buttonInsets:UIEdgeInsets = UIEdgeInsetsZero{
        didSet{
            self.button.contentEdgeInsets = buttonInsets
        }
    }
    
    var showsShadow:Bool = true
    
    
    //MARK: - private
    private var button:UIButton
    
    //MARK: - initializers
    required init?(coder aDecoder: NSCoder) {
        
        self.button = UIButton(type: .System)
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        
        self.button = UIButton(type: .Custom)
        super.init(frame: frame)
    }
    
    //MARK: - displaying
    override func layoutSubviews() {
        if button.superview == nil
        {
            self.addSubview(button)
        }
        
        if let _ = button.layer.mask as? CAShapeLayer
        {
            
        }
        else
        {
            self.tintColor = button.tintColor
            let bounds = self.bounds
            let minValue = floor( min(bounds.size.height, bounds.size.width))
            let bFrame = CGRectMake(0, 0, minValue * 0.7, minValue * 0.7)
            button.frame = bFrame
            button.backgroundColor = buttonColor
            button.maskToCircle(withShadow: self.showsShadow)
//            self.button.layer.shadowColor = UIColor.blackColor().colorWithAlphaComponent(0.5).CGColor
//            self.button.layer.shadowOpacity = 1.0
//            self.button.layer.shadowRadius = 5.0
//            self.button.layer.shadowOffset = CGSizeMake(3.0, 3.0)
        }
        
        if button.allTargets().isEmpty
        {
            button.addTarget(self, action: "handleTap", forControlEvents: .TouchUpInside)
        }
        
        super.layoutSubviews()
    }

    //UIControl stuff
    func handleTap() {
        //а где-то кто-то [myFloatingButtonControl addTarget:self action:@selector(твой метод) forControlEvents:UIControlEventTouchUpInside];
        
        ///посылка сообщения по нажатию на кнопку внутри нас
        self.sendActionsForControlEvents(.TouchUpInside)
    }
}
