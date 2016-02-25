//
//  ActionController.swift
//  TaskManager
//
//  Created by CloudCraft on 2/22/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import UIKit

typealias AlertActionHandler = ()->()

class ActionController: UIViewController {
    
    //MARK: - override stuff
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.modalTransitionStyle = .CrossDissolve
        self.modalPresentationStyle = .OverFullScreen
    }
    
    //MARK: - Convenience stuff
    convenience init(title:String, alertActionInfos:[String:AlertActionHandler], dismissButtonTitle:String, hostViewController:UIViewController?){
        self.init(nibName:"ActionController", bundle:nil)
        self.alertTitle = title
        self.alertActions = alertActionInfos
        self.dismissButtonTitle = dismissButtonTitle
        self.hostController = hostViewController
    }
    
    class func alertWith(title:String, actionButtonInfos:[String:AlertActionHandler], dismissButtonTitle:String, hostViewController:UIViewController?) -> ActionController {
        let controller = ActionController(title: title, alertActionInfos: actionButtonInfos, dismissButtonTitle: dismissButtonTitle, hostViewController: hostViewController)
        return controller
    }
    
    //MARK: -
    private static var currentController:ActionController?{
        willSet(newController){
            if currentController != nil{
                currentController?.dismissViewControllerAnimated(false, completion: nil)
            }
        }
        didSet(oldController){
            guard let nonNilALert = currentController else{
                oldController?.dismissViewControllerAnimated(true, completion: nil)
                return
            }
            nonNilALert.hostController?.presentViewController(nonNilALert, animated: true, completion: nil)
        }
    }
    
    class func dismiss(){
        ActionController.currentController = nil
    }
    
    func dismiss(){
        ActionController.currentController = nil
    }
    
    func show(){
        ActionController.currentController = self
    }
    
    private var alertTitle:String = "Warning"
    
    private var dismissButtonTitle:String = "Cancel"
    
    private var alertActions = [String:AlertActionHandler]()
    
    private var showsSingleCloseButton = false
    
    private weak var hostController:UIViewController?
    lazy var actionButtons = [UIButton]()
    //MARK: - IBOutlets
    @IBOutlet weak var titleLabel:UILabel!
    @IBOutlet weak var actionButtonsContainerView:UIView!
    
    //MARK: - UIViewController Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()


        showsSingleCloseButton = self.alertActions.isEmpty
        
        
        self.titleLabel.text = self.alertTitle
        self.addButtonsForHandlers(self.alertActions)
        
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        self.actionButtonsContainerView.setNeedsLayout()
        
        self.addCancelButton(self.dismissButtonTitle)
        
        if !actionButtons.isEmpty{
            for aButton in actionButtons{
                self.actionButtonsContainerView.addSubview(aButton)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func addCancelButton(title:String = ""){
        
        if self.showsSingleCloseButton{
            
            for aView in self.actionButtonsContainerView.subviews{
                aView.removeFromSuperview()
            }
        }
        
        let bounds = self.actionButtonsContainerView.bounds
        
        let width = bounds.size.width
            
        let cancelButtonFrame = CGRectMake(width - 90.0, 0, 72.0, 50.0)
        let cancelButton = UIButton(type: .System)
        cancelButton.frame = cancelButtonFrame
        let attributes = [NSForegroundColorAttributeName :UIColor.whiteColor(), NSFontAttributeName:UIFont.systemFontOfSize(20.0, weight: UIFontWeightBold)]
        let attributedString = NSAttributedString(string:title, attributes: attributes)
        cancelButton.setAttributedTitle(attributedString, forState: .Normal)
        
        cancelButton.addTarget(self, action: "cancelButtonTap:", forControlEvents: .TouchUpInside)
        cancelButton.autoresizingMask = [.FlexibleLeftMargin, .FlexibleTopMargin, .FlexibleBottomMargin] //align to left edge
        self.actionButtons.append(cancelButton)
    }
    
    private func addButtonsForHandlers(info:[String:AlertActionHandler]){
        if info.count > 2{
            print("\n - Warning! -> AlertController Will show only 2 action buttons before CANCEL button")
        }
        
        var leadingOffset = CGFloat(8.0)
        
        let attributesForActions = [NSFontAttributeName:UIFont.systemFontOfSize(20.0, weight: UIFontWeightRegular), NSForegroundColorAttributeName:UIColor.redColor()]
        
        for (title, _) in info {
            
            if actionButtons.count < 2 {
                
                let aButton = UIButton(type: .System)
                aButton.frame = CGRectMake(leadingOffset, 0, 72 , 50.0)
               
                let attributedString = NSAttributedString(string: title, attributes: attributesForActions)
                aButton.setAttributedTitle(attributedString, forState: .Normal)
                aButton.tintColor = UIColor.blueColor()
                
                aButton.autoresizingMask = [UIViewAutoresizing.FlexibleRightMargin, .FlexibleBottomMargin, .FlexibleTopMargin]
                aButton.addTarget(self, action: "actionButtonTap:", forControlEvents: .TouchUpInside)
                
                actionButtons.append(aButton)
                
                leadingOffset += aButton.frame.size.width + 8.0
            }
            else{
                break
            }
        }
        
        
    }
    
    func actionButtonTap(sender:UIButton){
        guard let buttonTitle = sender.titleLabel?.text else {
            return
        }
        
        guard let actionHandler = self.alertActions[buttonTitle] else{
            return
        }
        
        
        self.dismissViewControllerAnimated(true) {
            actionHandler()
        }
    }
    
    func cancelButtonTap(sender:UIButton){
        self.dismissViewControllerAnimated(true, completion: nil)
    }

}

class ActionButtonsContainer : UIView {
    
}
