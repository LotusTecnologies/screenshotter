//
//  WebViewController.swift
//  screenshot
//
//  Created by Corey Werner on 12/20/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation
import WebKit
import Appsee

class _WebViewController : BaseViewController {
    var isToolbarEnabled = true
    var loaderLabelText = "Loading..." // TODO: localize
    
    let webView = WebView()
    
    fileprivate var loadingCoverView: UIImageView?
    fileprivate var loader: Loader?
    
    // MARK: Life Cycle
    
    private var didLoadInitialPage = false
    private var didViewAppear = false
    fileprivate var isShowingGame = false
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
//        setupBarButtonItems()
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground(_:)), name: .UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground(_:)), name: .UIApplicationWillEnterForeground, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        view.addSubview(webView)
        webView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        webView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        webView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        webView.addObserver(self, forKeyPath: #keyPath(WebView.canGoBack), options: .new, context: nil)
        webView.addObserver(self, forKeyPath: #keyPath(WebView.canGoForward), options: .new, context: nil)
        
//        setBarButtonItemsToToolbarIfPossible()
        
        if let url = url {
            loadRequestURL(url)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !didLoadInitialPage {
            showLoadingView()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        didViewAppear = true
        
        if !didLoadInitialPage {
            loader?.startAnimation()
        }
        
        Appsee.startScreen("WebView")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if isShowingGame {
            AnalyticsTrackers.standard.track("Game Interrupted", properties: [
                "From": "User Navigating"
                ])
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        didViewAppear = false
        
        hideLoadingView()
    }
    
    @available(iOS 11.0, *)
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        
        updateLoadingCoverLayoutMargins()
    }
    
    func applicationDidEnterBackground(_ notification: Notification) {
        if view.window != nil {
            loader?.stopAnimation()
            
            if isShowingGame {
                AnalyticsTrackers.standard.track("Game Interrupted", properties: [
                    "From": "App Backgrounding"
                    ])
            }
        }
    }
    
    func applicationWillEnterForeground(_ notification: Notification) {
        if view.window != nil {
            loader?.startAnimation()
            
            if isShowingGame {
                AnalyticsTrackers.standard.track("Game Resumed", properties: [
                    "From": "App Backgrounding"
                    ])
            }
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        var shouldCallSuper = true
        
        if let object = object as? WebView, object == webView {
            if keyPath == #keyPath(WebView.canGoBack) || keyPath == #keyPath(WebView.canGoForward) {
                shouldCallSuper = false
                
//                syncToolbarNavigationItems()
            }
        }
        
        if shouldCallSuper {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        
        if isViewLoaded {
            webView.removeObserver(self, forKeyPath: #keyPath(WebView.canGoBack))
            webView.removeObserver(self, forKeyPath: #keyPath(WebView.canGoForward))
        }
    }
    
    // MARK: URL
    
    var url: URL? {
        didSet {
            if let url = url, isViewLoaded {
                webView.removeAllBackForwardListItems()
                loadRequestURL(url)
            }
        }
    }
    
    fileprivate func loadRequestURL(_ url: URL) {
        didLoadInitialPage = false
        webView.load(URLRequest(url: url))
    }
    
    // MARK: Toolbar
    
    
    
    // MARK: Loading
    
    fileprivate func showLoadingView() {
        guard self.loadingCoverView == nil else {
            return
        }
        
        let loadingCoverView = UIImageView(image: UIImage(named: "LoaderBackground"))
        loadingCoverView.translatesAutoresizingMaskIntoConstraints = false
        loadingCoverView.isUserInteractionEnabled = true
        loadingCoverView.contentMode = .scaleAspectFill
        view.addSubview(loadingCoverView)
        loadingCoverView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        loadingCoverView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        loadingCoverView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        loadingCoverView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        self.loadingCoverView = loadingCoverView
        
        updateLoadingCoverLayoutMargins()
        
        let loader = Loader()
        loader.translatesAutoresizingMaskIntoConstraints = false
        loader.color = .crazeRed
        loadingCoverView.addSubview(loader)
        loader.centerXAnchor.constraint(equalTo: loadingCoverView.centerXAnchor).isActive = true
        NSLayoutConstraint(item: loader, attribute: .centerY, relatedBy: .equal, toItem: loadingCoverView, attribute: .centerY, multiplier: 0.8, constant: 0).isActive = true
        self.loader = loader
        
        let loaderLabel = UILabel()
        loaderLabel.translatesAutoresizingMaskIntoConstraints = false
        loaderLabel.text = self.loaderLabelText
        loaderLabel.textColor = .gray3
        loaderLabel.textAlignment = .center
        loaderLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        loaderLabel.numberOfLines = 0
        loaderLabel.adjustsFontForContentSizeCategory = true
        loadingCoverView.addSubview(loaderLabel)
        loaderLabel.topAnchor.constraint(equalTo: loader.bottomAnchor, constant: .padding).isActive = true
        loaderLabel.leadingAnchor.constraint(equalTo: loadingCoverView.leadingAnchor, constant: .padding).isActive = true
        loaderLabel.trailingAnchor.constraint(equalTo: loadingCoverView.trailingAnchor, constant: -.padding).isActive = true
        
        let button = MainButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .crazeGreen
        button.setTitle("Get More Coins", for: .normal)
        button.addTarget(self, action: #selector(showLoadingGame), for: .touchUpInside)
        loadingCoverView.addSubview(button)
        button.bottomAnchor.constraint(lessThanOrEqualTo: loadingCoverView.layoutMarginsGuide.bottomAnchor, constant: -.extendedPadding).isActive = true
        button.bottomAnchor.constraint(lessThanOrEqualTo: bottomLayoutGuide.topAnchor, constant: -.extendedPadding).isActive = true
        button.centerXAnchor.constraint(equalTo: loadingCoverView.centerXAnchor).isActive = true
    }
    
    fileprivate func hideLoadingView() {
        loadingCoverView?.removeFromSuperview()
        loadingCoverView = nil
        
        loader?.stopAnimation()
        loader = nil
        
        if isShowingGame {
            isShowingGame = false
            
            AnalyticsTrackers.standard.track("Game Interrupted", properties: [
                "From": "Page Loading"
                ])
        }
    }
    
    fileprivate func updateLoadingCoverLayoutMargins() {
        if #available(iOS 11.0, *) {
            loadingCoverView?.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: view.window?.safeAreaInsets.bottom ?? 0, right: 0)
        }
    }
    
    // MARK: Game
    
    @objc fileprivate func showLoadingGame() {
        
    }
}

extension _WebViewController : WKNavigationDelegate {
    
}






