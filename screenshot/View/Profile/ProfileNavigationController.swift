//
//  ProfileNavigationController.swift
//  screenshot
//
//  Created by Corey Werner on 6/6/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class ProfileNavigationController: UINavigationController {
    let profileViewController = ProfileViewController()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init() {
        self.init(nibName: nil, bundle: nil)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        restorationIdentifier = String(describing: type(of: self))
        
        // TODO: use icon, not title
        profileViewController.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Settings", style: .plain, target: self, action: #selector(pushSettingsViewController))
        
        viewControllers = [profileViewController]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .background
    }
    
    @objc private func pushSettingsViewController() {
        let viewController = SettingsViewController()
        pushViewController(viewController, animated: true)
    }
}
