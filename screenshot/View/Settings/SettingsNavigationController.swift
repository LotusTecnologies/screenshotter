//
//  SettingsNavigationController.swift
//  screenshot
//
//  Created by Corey Werner on 1/31/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import Foundation
import UIKit

class SettingsNavigationController : UINavigationController {
    let settingsViewController = SettingsViewController()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    convenience init() {
        self.init(nibName: nil, bundle: nil)
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
