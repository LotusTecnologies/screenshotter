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
    fileprivate let searchBar = UISearchBar()
    
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
        
        webView.scrollView.delegate = self
        webView.scrollView.keyboardDismissMode = .onDrag
        
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.delegate = self
        searchBar.barTintColor = .white
        
        searchBar.setImage(UIImage(named: "InviteGoogleIcon"), for: .search, state: .normal)
        
        
        view.addSubview(searchBar)
        searchBar.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true

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
                url = potentialURL
                break
            }
        }
    }

    private func randomURL() -> URL? {
        var url: URL?

        if let urls = AppDelegate.shared.settings.discoverURLs {
            let randomIndex = Int(arc4random_uniform(UInt32(urls.count)))
            let randomURL = urls[randomIndex]
            
            // Check the URL's validity
            if let randomURL = randomURL {
                if UIApplication.shared.canOpenURL(randomURL) {
                    url = randomURL
                    
                } else {
                    AnalyticsTrackers.segment.error(withDescription: "Invalid fetched URL \(randomURL.absoluteString)")
                }
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
    
    @objc override func refreshAction() {
        reloadURL()
        AnalyticsTrackers.standard.track("Refreshed Discover webpage")
    }
}

extension DiscoverWebViewController : UISearchBarDelegate {
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let text = searchBar.text, !text.isEmpty {
            url = googleSearchURL(text)
            
            searchBar.resignFirstResponder()
        }
    }
    
    private func googleSearchURL(_ query: String) -> URL? {
        return URL(string: "https://google.com/search?q=\(query)")
    }
}

extension DiscoverWebViewController : UIScrollViewDelegate {
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
