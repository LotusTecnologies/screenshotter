
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
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/61.0.3163.100 Safari/537.36"
        
        url = randomUrl()
        track("Loaded Discover Web Page", properties: ["url" : url])
    }
    
    // MARK: Random Url
    
    func randomUrl() -> URL? {
        var randomUrl = "https://screenshopit.tumblr.com"
        
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate, let urls = appDelegate.settings?.discoverUrls {
            let randomIndex = Int(arc4random_uniform(UInt32(urls.count)))
            randomUrl = urls[randomIndex]
        }
        
        return URL(string: randomUrl)
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
