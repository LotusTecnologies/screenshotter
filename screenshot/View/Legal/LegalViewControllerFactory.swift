//
//  LegalViewControllerFactory.swift
//  screenshot
//
//  Created by Corey Werner on 1/21/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class LegalViewControllerFactory : NSObject {
    static func termsOfServiceViewController(withDoneTarget target: Any?, action: Selector?) -> UIViewController? {
        guard let url = URL(string: "https://screenshopit.com/terms-of-use/") else {
            return nil
        }
        
        let title = "legal.terms_of_service".localized
        
        return webViewController(withTitle: title, url: url, doneTarget: target, action: action)
    }
    
    static func privacyPolicyViewController(withDoneTarget target: Any?, action: Selector?) -> UIViewController? {
        guard let url = URL(string: "https://screenshopit.com/privacy-policy/") else {
            return nil
        }
        
        let title = "legal.privacy_policy".localized
        
        return webViewController(withTitle: title, url: url, doneTarget: target, action: action)
    }
    
    private static func webViewController(withTitle title: String, url: URL, doneTarget target: Any?, action: Selector?) -> UIViewController? {
        let viewController = WebViewController()
        viewController.rebaseURL(url)
        viewController.isToolbarEnabled = false
        viewController.navigationItem.title = title
        viewController.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: target, action: action)
        
        return UINavigationController(rootViewController: viewController)
    }
}
