//
//  ScreenshotDisplayNavigationController.swift
//  screenshot
//
//  Created by Corey Werner on 1/3/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation
import UIKit

class ScreenshotDisplayNavigationController : UINavigationController {
    let screenshotDisplayViewController = ScreenshotDisplayViewController()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.shadowImage = UIImage()
        navigationBar.isTranslucent = true
        navigationBar.tintColor = .white
        
        screenshotDisplayViewController.navigationItem.titleView = UIImageView(image: UIImage(named: "LogoWhite20h"))
        screenshotDisplayViewController.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "ControlX"), style: .plain, target: self, action: #selector(closeAction))
//        screenshotDisplayViewController.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareAction))
        
        viewControllers = [screenshotDisplayViewController]
    }
    
    @objc fileprivate func closeAction() {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @objc fileprivate func shareAction() {
        // TODO:
    }
}
