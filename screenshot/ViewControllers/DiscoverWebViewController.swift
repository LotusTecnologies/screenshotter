
//
//  DiscoverWebViewController.swift
//  screenshot
//
//  Created by Jacob Relkin on 10/17/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import WebKit.WKWebView

class DiscoverWebViewController : WebViewController {
    let backButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "Back"), style: .plain, target: self, action: #selector(backButtonTapped))
    let forwardButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "Forward"), style: .plain, target: self, action: #selector(forwardButtonTapped))
    
    override func viewDidLoad() {
        toolbarEnabled = false
        
        url = URL(string: UserDefaults.standard.string(forKey: UserDefaultsKeys.discoverUrl) ?? "https://screenshopit.tumblr.com")
        track("Loaded Discover Web Page", properties: ["url" : url])
        
        let refresh = UIBarButtonItem(image: #imageLiteral(resourceName: "Refresh"), style: .plain, target: self, action: #selector(refreshButtonTapped))
        let share = UIBarButtonItem(image: #imageLiteral(resourceName: "ScreenshotShare"), style: .plain, target: self, action: #selector(shareButtonTapped))
        let leftItems = [backButtonItem, forwardButtonItem]
        let rightItems = [share, refresh]
        
        navigationItem.titleView = UIImageView(image: UIImage(named: "Logo20h"))
        navigationItem.leftBarButtonItems = leftItems
        navigationItem.rightBarButtonItems = rightItems
        
        (leftItems + rightItems).forEach { $0.isEnabled = false }
        
        super.viewDidLoad()

        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/61.0.3163.100 Safari/537.36"
    }
    
    // MARK: - Actions
    
    @objc private func backButtonTapped() {
        webView.goBack()
    }

    @objc private func forwardButtonTapped() {
        webView.goForward()
    }
    
    @objc private func refreshButtonTapped() {
        webView.reload()
    }
    
    @objc private func shareButtonTapped() {
        guard let url = webView.url else {
            return
        }
        
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        present(activityViewController, animated: true, completion: nil)
    }
    
    // MARK: - Navigation Delegate
    
    override func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        super.webView(webView, didFinish: navigation)
        
        navigationItem.rightBarButtonItems?.forEach { $0.isEnabled = true }

        self.backButtonItem.isEnabled = webView.canGoBack
        self.forwardButtonItem.isEnabled = webView.canGoForward
    }
}

