//
//  TaskActionsConfirmView.swift
//  TaskManager
//
//  Created by CloudCraft on 2/26/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import UIKit

enum TaskActionType:Int{
    
    case IsFree = 0
    case TakenByMe = 1
    case TakenBySomebody = 2
    case Finished = 3
    
    func stringRepresentation() -> String{
        switch self{
        case .IsFree: return "Free"
        case .TakenByMe: return "TakenByMe"
        case .TakenBySomebody: return "TakenBySomebody"
        case .Finished: return "Finished"
        }
    }
}

enum TaskActionsConfirmViewState:Int{
    case MainAction = 1
    case AlternateAction = 2
    case Cancel = -1 // dismiss TaskActionsConfirmView  as a variant
}

public
class TaskActionsConfirmView : UIControl{
    
    private var _actionType:TaskActionType
    var activeActionState:TaskActionsConfirmViewState = .Cancel
    
    @IBOutlet weak var dismissButton:UIButton!
    @IBOutlet weak var actionButton:UIButton!
    @IBOutlet weak var alternateActionButton:UIButton!

    private var buttonTitleFont = UIFont.appSemiboldFontOfSize(18.0)
    
    var actionType:TaskActionType {
        return _actionType
    }
    @IBOutlet public weak var titleLabel:UILabel!
    
    required public init?(coder aDecoder: NSCoder) {
        
        self._actionType = .IsFree
        super.init(coder: aDecoder)
        self.backgroundColor = UIColor.appThemeColorBlue.colorWithAlphaComponent(0.75)
    }
    
    override init(frame: CGRect) {
        
        self._actionType = .IsFree
        super.init(frame: frame)
        self.backgroundColor = UIColor.appThemeColorBlue.colorWithAlphaComponent(0.75)
    }
    
    func setActionType(type:TaskActionType) {
        self._actionType = type
        setupCancelButtonWithTitle("Cancel")
        switch self._actionType{
        case .IsFree:
            setupTakeFinishButtonWithTitle("Take")
            setupAlternateButtonWithTitle(nil)
            
        case .TakenBySomebody, .TakenByMe:
            if type == .TakenByMe{
                setupTakeFinishButtonWithTitle("Finish")
                setupAlternateButtonWithTitle("Release")
                return
            }
            else if type == .TakenBySomebody{
                self.setupTakeFinishButtonWithTitle("Take to me")
                setupAlternateButtonWithTitle(nil)
            }
        case .Finished:
            setupTakeFinishButtonWithTitle("Take")
            setupAlternateButtonWithTitle(nil)
        }
        
        self.setNeedsLayout()
    }
    
    func showInView(hostView:UIView) {
        let bounds = hostView.bounds
        self.frame.size = CGSizeMake(bounds.size.width, 100.0)
        
        self.alpha = 0.0

        hostView.addSubview(self)
        
        UIView.animateWithDuration(0.2) { () -> Void in
            self.alpha = 1.0
        }
    }
    
    @IBAction func actionButtonTouchUpInside(button:UIButton) {
        
        if button == self.alternateActionButton{
            self.activeActionState = .AlternateAction //release task
        }
        else if button == self.actionButton{
            self.activeActionState = .MainAction // "take task" |or| "finish task"
        }
        
        self.sendActionsForControlEvents(.ValueChanged) // listener should detect our "activeActionName" and handle sent actions
        
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            self.alpha = 0.0
            }) { _ in
              self.removeFromSuperview()
        }
    }
    
    @IBAction func dismissButtonTouchUpInside() {
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            self.alpha = 0.0
            }) { _ in
                self.removeFromSuperview()
        }
    }
    
    private func setupCancelButtonWithTitle(title:String) {
        
        let attrs = [NSFontAttributeName:buttonTitleFont]//, NSForegroundColorAttributeName:UIColor.redColor()]
        
        self.dismissButton.setAttributedTitle(NSAttributedString(string: title, attributes: attrs), forState: .Normal)
    }
    
    private func setupTakeFinishButtonWithTitle(title:String) {

        let attrs = [NSFontAttributeName:buttonTitleFont]//, NSForegroundColorAttributeName:UIColor.appThemeColorBlue]
        
        self.actionButton.setAttributedTitle(NSAttributedString(string: title, attributes: attrs), forState: .Normal)
        //self.actionButton.tintColor = UIColor.appThemeColorBlue
    }
    
    private func setupAlternateButtonWithTitle(title:String?){
        guard let title = title else{
            self.alternateActionButton?.hidden = true
            return
        }
        
        let attrs = [/*NSForegroundColorAttributeName : UIColor.appThemeColorBlue,*/ NSFontAttributeName:buttonTitleFont]
        
        let attrTitle = NSAttributedString(string: title, attributes: attrs)
        self.alternateActionButton.hidden = false
        self.alternateActionButton.setAttributedTitle(attrTitle, forState: .Normal)        
    }
}
