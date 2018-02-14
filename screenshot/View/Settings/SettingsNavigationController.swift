//
//  SettingsNavigationController.swift
//  screenshot
//
//  Created by Corey Werner on 1/31/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation

class SettingsNavigationController : UINavigationController {
    let settingsViewController = SettingsViewController()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        restorationIdentifier = String(describing: type(of: self))
        
        viewControllers = [settingsViewController]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .background
    }
}