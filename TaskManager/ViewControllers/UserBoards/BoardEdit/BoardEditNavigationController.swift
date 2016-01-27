//
//  BoardEditNavigationController.swift
//  TaskCloud
//
//  Created by CloudCraft on 1/14/16.
//  Copyright © 2016 CloudCraft. All rights reserved.
//

import UIKit

class BoardEditNavigationController: UINavigationController {

    var boardEditingType:BoardEditingType = .CreateNew{
        didSet{
            //yes, I know this is bad
            (self.viewControllers.first! as! BoardEditViewController).setEditingType(boardEditingType)
        }
    }
    
    var boardEditingHandler:BoardCloudHandler?{
        didSet{
            //yes, I know this is bad
            (self.viewControllers.first! as! BoardEditViewController).setEditingHandler(boardEditingHandler)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
