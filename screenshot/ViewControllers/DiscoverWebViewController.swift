//
//  DiscoverWebViewController.swift
//  screenshot
//
//  Created by Jacob Relkin on 10/17/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import WebKit.WKWebView
import DeepLinkKit

class DiscoverWebViewController : WebViewController {
    override var title: String? {
        set {}
        get {
            return "Discover"
        }
    }
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        toolbarEnabled = false
        
        loaderLabelText = "Loading Discover..."
        
        navigationItem.leftBarButtonItems = leftBarButtonItems()
        navigationItem.rightBarButtonItems = rightBarButtonItems()
        
        addNavigationItemLogo()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.scrollView.delegate = self

        reloadURL()
        
        AnalyticsTrackers.standard.track("Loaded Discover Web Page", properties: ["url": url])
    }
    
    // MARK: URLs
    
    var deepLinkURL: URL? {
        didSet {
            reloadURL()
        }
    }

    func reloadURL() {
        url = deepLinkURL ?? (AppDelegate.shared.settings.forcedDiscoverURL ?? randomUrl())
    }

    private func randomUrl() -> URL? {
        var url = URL(string: "https://screenshopit.tumblr.com")

        if let urls = AppDelegate.shared.settings.discoverURLs {
            let randomIndex = Int(arc4random_uniform(UInt32(urls.count)))
            let randomUrl = urls[randomIndex]
            
            // Check the URL's validity
            if let randomUrl = randomUrl, UIApplication.shared.canOpenURL(randomUrl) {
                url = randomUrl
            }
        }

        return url
    }
    
    // MARK: Bar Button Item
    
    func leftBarButtonItems() -> [UIBarButtonItem] {
        return [backItem!, forwardItem!]
    }

    func rightBarButtonItems() -> [UIBarButtonItem] {
        return [shareItem!, refreshItem!]
    }

    override func updateShareItem() {
        super.updateShareItem()

        navigationItem.rightBarButtonItems = rightBarButtonItems()
    }

    // MARK: Bar Button Item Actions

    func refreshAction() {
        reloadURL()
        AnalyticsTrackers.standard.track("Refreshed Discover webpage")
    }
}

extension DiscoverWebViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return nil
    }
}

extension DiscoverWebViewController : DPLTargetViewController {
    func configure(with deepLink: DPLDeepLink!) {
        if let url = deepLink.discoverURL {
            deepLinkURL = url
        }
    }
}
