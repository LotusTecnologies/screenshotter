//
//  DiscoverDeepLinkHandler.swift
//  screenshot
//
//  Created by Jacob Relkin on 11/23/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation
import DeepLinkKit

class DiscoverDeepLinkHandler : DPLRouteHandler {
    var mainTabBarController:MainTabBarController? {
        return (UIApplication.shared.delegate as? AppDelegate)?.window?.rootViewController as? MainTabBarController
    }
    
    override func shouldHandle(_ deepLink: DPLDeepLink!) -> Bool {
        return deepLink.discoverURL != nil
    }
    
    override func targetViewController() -> UIViewController! {
        return mainTabBarController!.discoverNavigationController.viewControllers.first(where: { $0 is DPLTargetViewController })!
    }
    
    override func presentTargetViewController(_ targetViewController: UIViewController!, in presentingViewController: UIViewController!) {
        mainTabBarController?.selectedViewController = mainTabBarController?.discoverNavigationController
    }
}

extension DPLDeepLink {
    var discoverURL: URL? {
        guard let urlString = (queryParameters["url"] as? String)?.removingPercentEncoding else {
            return nil
        }
        
        return URL(string: urlString)
    }
}
