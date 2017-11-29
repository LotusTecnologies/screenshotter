
//
//  DiscoverWebViewController.swift
//  screenshot
//
//  Created by Jacob Relkin on 10/17/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import WebKit.WKWebView

class DiscoverWebViewController : WebViewController {
    override var title: String? {
        set {}
        get {
            return "Discover"
        }
    }
    
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
        
        url = randomUrl()
        
        // !!!: the properties value is creating a crash when building the app and immediatly going to the discover page
        AnalyticsTrackers.standard.track("Loaded Discover Web Page", properties: ["url": url])
    }
    
    // MARK: Random Url
    
    func randomUrl() -> URL? {
        var url = URL(string: "https://screenshopit.tumblr.com")
        
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate, let urls = appDelegate.settings.discoverURLs {
            let randomIndex = Int(arc4random_uniform(UInt32(urls.count)))
            url = urls[randomIndex]
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
        url = randomUrl()
        AnalyticsTrackers.standard.track("Refreshed Discover webpage")
    }
}

extension DiscoverWebViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return nil
    }
}
