//
//  BaseViewController.swift
//  screenshot
//
//  Created by Gershon Kagan on 2/11/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class BaseViewController: UIViewController {
    
    weak var lifeCycleDelegate: ViewControllerLifeCycle?
    var isStatusBarHidden = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.background
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        lifeCycleDelegate?.viewController?(self, willAppear: animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        lifeCycleDelegate?.viewController?(self, didAppear: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        lifeCycleDelegate?.viewController?(self, willDisappear: animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        lifeCycleDelegate?.viewController?(self, didDisappear: animated)
    }
    
    // MARK: - Status Bar
    
    

    func showStatusBar() {
        self.isStatusBarHidden = false
        self.setNeedsStatusBarAppearanceUpdate()
    }
    func hideStatusBar() {
        self.isStatusBarHidden = true
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    override var prefersStatusBarHidden: Bool {
        return isStatusBarHidden
    }
    
    // MARK: - Extra
    
    @objc func addNavigationItemLogo() {
        self.navigationItem.titleView = UIImageView(image: UIImage(named: "Logo20h"))
    }
    
}

