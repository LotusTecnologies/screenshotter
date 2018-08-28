//
//  ScreenshotDisplayNavigationController.swift
//  screenshot
//
//  Created by Corey Werner on 1/3/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import Foundation
import UIKit

class ScreenshotDisplayNavigationController : UINavigationController {
    let screenshotDisplayViewController = ScreenshotDisplayViewController()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init() {
        self.init(nibName: nil, bundle: nil)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.shadowImage = UIImage()
        navigationBar.isTranslucent = true
        navigationBar.tintColor = .white
        
        screenshotDisplayViewController.navigationItem.titleView = UIImageView(image: UIImage(named: "BrandLogoWhite20h"))
        screenshotDisplayViewController.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "ControlX"), style: .plain, target: self, action: #selector(closeAction))
//        screenshotDisplayViewController.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareAction))
        
        viewControllers = [screenshotDisplayViewController]
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    @objc fileprivate func closeAction() {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @objc fileprivate func shareAction() {
        // TODO:
    }
}
