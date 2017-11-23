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
    
    var discoverURL: URL?
    
    override func shouldHandle(_ deepLink: DPLDeepLink!) -> Bool {
        discoverURL = deepLink.discoverURL
        
        return discoverURL != nil
    }
    
    override func targetViewController() -> UIViewController! {
        return mainTabBarController?.discoverNavigationController.topViewController!
    }
    
    override func presentTargetViewController(_ targetViewController: UIViewController!, in presentingViewController: UIViewController!) {
        mainTabBarController?.setNeedsDiscoverNavigationTo(discoverURL)
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
