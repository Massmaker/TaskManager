//
//  ViewController.swift
//  StoryBoardTableView
//
//  Created by CloudCraft on 12/28/15.
//  Copyright © 2015 CloudCraft. All rights reserved.
//

import UIKit
import Fabric
import DigitsKit

class LoginViewController: UIViewController {

    var authenticator:UserAuthenticating?
    
    @IBOutlet weak var customSignUpButton:UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        customSignUpButton.layer.borderColor = UIColor.whiteColor().CGColor
        customSignUpButton.layer.borderWidth = 1.0
        customSignUpButton.layer.cornerRadius = 8.0
        setupAuthButtons(false)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
       
        if authenticator == nil
        {
            authenticator = PhoneAndCloudAuthenticator(authenticatorDelegate: self)
            authenticator?.hostViewController = self
        }
        authenticator?.checkPhoneCredentials()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func setupAuthButtons(phoneAuthenticationRequired:Bool)
    {
        customSignUpButton.hidden = !phoneAuthenticationRequired
    }

    @IBAction func loginButtonAction(sender:UIButton)
    {
        if let authManager = authenticator
        {
            authManager.startAuthenticatingByPhone()
        }
    }
    
    func showMainTabBarController()
    {
        if let tabBarVC = self.storyboard?.instantiateViewControllerWithIdentifier("TabBarViewController") as? TabBarViewController,  let delegate = UIApplication.sharedApplication().delegate as? AppDelegate, window = delegate.window
        {
            window.rootViewController = tabBarVC
        }
    }
}

