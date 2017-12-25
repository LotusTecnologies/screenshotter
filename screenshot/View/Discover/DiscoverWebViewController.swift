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
    fileprivate let scrollRevealController = ScrollRevealController(edge: .top)
    fileprivate let searchBar = UISearchBar()
    fileprivate var previousWebViewURL: URL?
    
    override var title: String? {
        set {}
        get {
            return "discover.title".localized
        }
    }
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        isToolbarEnabled = false
        
        loaderLabelText = "discover.load".localized
        
        navigationItem.leftBarButtonItems = leftBarButtonItems()
        navigationItem.rightBarButtonItems = rightBarButtonItems()
        
        addNavigationItemLogo()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.delegate = self
        searchBar.barTintColor = .white
        searchBar.tintColor = .crazeRed
        searchBar.setImage(UIImage(named: "InviteGoogleIcon"), for: .search, state: .normal)
        scrollRevealController.view.addSubview(searchBar)
        searchBar.topAnchor.constraint(equalTo: scrollRevealController.view.topAnchor).isActive = true
        searchBar.leadingAnchor.constraint(equalTo: scrollRevealController.view.leadingAnchor).isActive = true
        searchBar.bottomAnchor.constraint(equalTo: scrollRevealController.view.bottomAnchor).isActive = true
        searchBar.trailingAnchor.constraint(equalTo: scrollRevealController.view.trailingAnchor).isActive = true
        
        scrollRevealController.isAutoShowingView = true
        scrollRevealController.adjustedContentInset = UIEdgeInsets(top: navigationController?.navigationBar.frame.maxY ?? 0, left: 0, bottom: 0, right: 0)
        scrollRevealController.insertAbove(webView.scrollView)
        
        webView.scrollView.delegate = self
        webView.scrollView.keyboardDismissMode = .onDrag
        
        reloadURL()
        
        AnalyticsTrackers.standard.track("Loaded Discover Web Page", properties: ["url": url ?? ""])
    }
    
    // MARK: URL
    
    var deepLinkURL: URL? {
        didSet {
            reloadURL()
        }
    }

    func reloadURL() {
        let potentialURLs = [
            deepLinkURL,
            AppDelegate.shared.settings.forcedDiscoverURL,
            randomURL(),
            URL(string: "https://screenshopit.tumblr.com")
        ]
        
        for potentialURL in potentialURLs {
            if let potentialURL = potentialURL, UIApplication.shared.canOpenURL(potentialURL) {
                loadURL(potentialURL)
                break
            }
        }
    }

    private func randomURL() -> URL? {
        var url: URL?

        if let urls = AppDelegate.shared.settings.discoverURLs {
            let randomIndex = Int(arc4random_uniform(UInt32(urls.count)))
            
            if let randomURL = urls[randomIndex] {
                if UIApplication.shared.canOpenURL(randomURL) {
                    url = randomURL
                    
                } else {
                    AnalyticsTrackers.segment.error(withDescription: "Invalid fetched URL \(randomURL.absoluteString)")
                }
            }
        }

        return url
    }
    
    fileprivate func isGoogleURL(_ url: URL?) -> Bool {
        let isHostGoogle = url?.host?.contains("google") ?? false
        let isAMP = url?.path.split(separator: "/").first == "amp"
        return isHostGoogle && !isAMP
    }
    
    fileprivate func googleSearchURL(_ query: String) -> URL? {
        return URL(string: "https://google.com/search?q=\(query)")
    }
    
    // MARK: Toolbar
    
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

    // MARK: Toolbar Actions
    
    @objc override func refreshAction() {
        reloadURL()
        AnalyticsTrackers.standard.track("Refreshed Discover webpage")
    }
}

extension DiscoverWebViewController : UISearchBarDelegate {
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .top
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let text = searchBar.text, !text.isEmpty {
            loadURL(googleSearchURL(text))
            syncSearchBarVisibility(url: webView.url)
            searchBar.resignFirstResponder()
        }
    }
    
    fileprivate func syncSearchBarVisibility(url: URL?) {
        scrollRevealController.isViewHidden = isGoogleURL(url)
    }
}

extension DiscoverWebViewController { // WKNavigationDelegate
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
        
        if view.window != nil {
            // Some featured links in Goolge will set the navigationAction.request.url
            // before setting the webView.url. Below should fix the search bar syncing
            // on those sites, such as Wikipedia
            let url: URL?
            
            if webView.url == previousWebViewURL {
                url = navigationAction.request.url
                
            } else {
                url = webView.url
            }
            
            syncSearchBarVisibility(url: url)
            previousWebViewURL = webView.url
        }
    }
}

extension DiscoverWebViewController : UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollRevealController.scrollViewWillBeginDragging(scrollView)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollRevealController.scrollViewDidScroll(scrollView)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        scrollRevealController.scrollViewDidEndDragging(scrollView, will: decelerate)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollRevealController.scrollViewDidEndDecelerating(scrollView)
    }
    
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
