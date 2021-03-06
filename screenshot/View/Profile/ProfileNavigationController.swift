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
                
        profileViewController.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "NavigationBarGear"), style: .plain, target: self, action: #selector(pushSettingsViewController))
        
        viewControllers = [profileViewController]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .background
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UniversalSearchController.shared.updateInboxBadgeCount()
    }
    
    @objc private func pushSettingsViewController() {
        let viewController = SettingsViewController()
        pushViewController(viewController, animated: true)
    }
}
