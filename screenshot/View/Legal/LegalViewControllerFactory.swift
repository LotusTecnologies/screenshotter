//
//  LegalViewControllerFactory.swift
//  screenshot
//
//  Created by Corey Werner on 1/21/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import UIKit

class LegalViewControllerFactory : NSObject {
    static func termsOfServiceViewController() -> UIViewController? {
        guard let url = URL(string: "https://screenshopit.com/terms-of-use/") else {
            return nil
        }
        
        let title = "legal.terms_of_service".localized
        
        return webViewController(withTitle: title, url: url)
    }
    
    static func privacyPolicyViewController() -> UIViewController? {
        guard let url = URL(string: "https://screenshopit.com/privacy-policy/") else {
            return nil
        }
        
        let title = "legal.privacy_policy".localized
        
        return webViewController(withTitle: title, url: url)
    }
    
    private static func webViewController(withTitle title: String, url: URL) -> UIViewController? {
        let viewController = WebViewController()
        viewController.rebaseURL(url)
        viewController.isToolbarEnabled = false
        viewController.navigationItem.title = title
        
        let navigationController = ModalNavigationController(rootViewController: viewController)
        navigationController.topViewController?.navigationItem.leftBarButtonItem?.title = "generic.done".localized
        return navigationController
    }
}
