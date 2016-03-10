//
//  Extensions-UIViewController.swift
//  MailTravel
//
//  Created by CloudCraft on 12/30/15.
//  Copyright © 2015 MT. All rights reserved.
//

import UIKit

extension UIViewController
{
    func setLoadingIndicatorVisible(visible:Bool)
    {
        if visible
        {
            if let indicator = self.view.viewWithTag(0x70AD) as? UIActivityIndicatorView
            {
                if indicator.isAnimating()
                {
                    return //already showing
                }
                else
                {
                    indicator.startAnimating()
                }
                return
            }
            
            let indicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
            indicatorView.tag = 0x70AD
            let frame = CGRectMake(0, 0, 200.0, 200.0)
            indicatorView.frame = frame
            indicatorView.layer.cornerRadius = 7.0
            indicatorView.backgroundColor = UIColor.clearColor()
            indicatorView.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds))
            indicatorView.autoresizingMask =  [.FlexibleLeftMargin , .FlexibleRightMargin , .FlexibleTopMargin , .FlexibleBottomMargin]
            self.view.addSubview(indicatorView)
            indicatorView.startAnimating()
        }
        else
        {
            if let indicator = self.view.viewWithTag(0x70AD) as? UIActivityIndicatorView
            {
                indicator.stopAnimating()
            }
        }
    }
    
    func showAlertController(title:String?, text:String?, closeButtonTitle:String?, closeAction:(()->())? = nil, presentationCompletion:(()->())? = nil)
    {
        var closeButtonTitleString = "Ok"
        let alertController = UIAlertController(title: title, message: text, preferredStyle: .Alert)
        
        if let closeTitle = closeButtonTitle
        {
            closeButtonTitleString = closeTitle
        }
        
        let closeButtonAction = UIAlertAction(
            title: closeButtonTitleString,
            style: .Default,
            handler: { (alertAction) in closeAction?() })
        
        alertController.addAction(closeButtonAction)
        
        self.presentViewController(alertController, animated: true, completion: presentationCompletion)
    }
}