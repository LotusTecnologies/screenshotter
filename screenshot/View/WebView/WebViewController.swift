//
//  WebViewController.swift
//  screenshot
//
//  Created by Corey Werner on 12/20/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation
import WebKit
import SpriteKit
import Appsee

class WebViewController : BaseViewController {
    let webView = WebView()
    
    // MARK: Life Cycle
    
    fileprivate var didLoadInitialPage = false
    fileprivate var didViewAppear = false
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        setupBarButtonItems()
        
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
        webView.addObserver(self, forKeyPath: #keyPath(WebView.canGoBack), options: [.new, .old], context: nil)
        webView.addObserver(self, forKeyPath: #keyPath(WebView.canGoForward), options: [.new, .old], context: nil)
        
        setBarButtonItemsToToolbarIfPossible()
        loadURL(url)
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
                
                syncToolbarNavigationItems()
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
    
    private var isShorteningURL = false
    
    private(set) var url: URL?
    
    func loadURL(_ url: URL?) {
        self.url = url
        
        guard let url = url, isViewLoaded else {
            return
        }
        
        didLoadInitialPage = false
        webView.load(URLRequest(url: url))
    }
    
    func rebaseURL(_ url: URL?) {
        webView.removeAllBackForwardListItems()
        loadURL(url)
    }
    
    // MARK: Toolbar
    
    fileprivate lazy var toolbar: UIToolbar = {
        let toolbar = UIToolbar()
        toolbar.frame = CGRect(x: 0, y: 0, width: 0, height: toolbar.intrinsicContentSize.height)
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.isHidden = !self.isToolbarEnabled
        self.view.addSubview(toolbar)
        toolbar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        toolbar.bottomAnchor.constraint(equalTo: self.view.layoutMarginsGuide.bottomAnchor).isActive = true
        toolbar.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        
        var insets = self.webView.scrollView.contentInset
        insets.bottom = toolbar.bounds.size.height
        self.webView.scrollView.contentInset = insets
        
        insets = self.webView.scrollView.scrollIndicatorInsets
        insets.bottom = toolbar.bounds.size.height
        self.webView.scrollView.scrollIndicatorInsets = insets
        
        return toolbar
    }()
    
    var isToolbarEnabled = true {
        didSet {
            toolbar.isHidden = !isToolbarEnabled
        }
    }
    
    private(set) var backItem: UIBarButtonItem!
    private(set) var forwardItem: UIBarButtonItem!
    private(set) var refreshItem: UIBarButtonItem!
    private(set) var shareItem: UIBarButtonItem!
    private(set) var safariItem: UIBarButtonItem!
    
    fileprivate func setupBarButtonItems() {
        backItem = UIBarButtonItem(image: UIImage(named: "Back"), style: .plain, target: self, action: #selector(backAction))
        
        forwardItem = UIBarButtonItem(image: UIImage(named: "Forward"), style: .plain, target: self, action: #selector(forwardAction))
        
        syncToolbarNavigationItems()
        
        refreshItem = UIBarButtonItem(image: UIImage(named: "Refresh"), style: .plain, target: self, action: #selector(refreshAction))
        
        shareItem = createShareItem()
        
        safariItem = UIBarButtonItem(image: UIImage(named: "Safari"), style: .plain, target: self, action: #selector(safariAction))
        
        backItem.tintColor = .crazeRed
        forwardItem.tintColor = .crazeRed
        refreshItem.tintColor = .crazeRed
        safariItem.tintColor = .crazeRed
    }
    
    private func createShareItem() -> UIBarButtonItem {
        let item: UIBarButtonItem
        
        if isShorteningURL {
            let activityView = UIActivityIndicatorView(activityIndicatorStyle: .white)
            activityView.color = .crazeRed
            activityView.startAnimating()
            
            // Resize the width to the share icon's size to prevent sibling views from jumping
            var rect = activityView.frame
            rect.size.width = 30
            activityView.frame = rect
            
            item = UIBarButtonItem(customView: activityView)
            
        } else {
            item = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareAction))
        }
        
        item.tintColor = .crazeRed
        return item
    }
    
    private func setBarButtonItemsToToolbarIfPossible() {
        if isToolbarEnabled {
            let fixed = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
            fixed.width = .padding
            
            let flexible = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            
            toolbar.items = [backItem, fixed, forwardItem, fixed, refreshItem, flexible, shareItem, fixed, safariItem]
        }
    }
    
    func updateShareItem() {
        shareItem = createShareItem()
        setBarButtonItemsToToolbarIfPossible()
    }
    
    fileprivate func syncToolbarNavigationItems() {
        backItem.isEnabled = webView.canGoBack
        forwardItem.isEnabled = webView.canGoForward
    }
    
    // MARK: Toolbar Actions
    
    @objc fileprivate func backAction() {
        webView.goBack()
    }
    
    @objc fileprivate func forwardAction() {
        webView.goForward()
    }
    
    @objc func refreshAction() {
        if webView.url == nil {
            let resetURL = url
            url = resetURL
            
        } else {
            webView.reload()
        }
        
        AnalyticsTrackers.standard.track("Refreshed webpage", properties: [
            "url": url?.absoluteString ?? ""
            ])
    }
    
    @objc fileprivate func shareAction() {
        guard let url = url else {
            return
        }
        
        isShorteningURL = true
        updateShareItem()
        
        NetworkingModel.shortenUrl(url) { shortenedURL in
            if let shortenedURL = shortenedURL {
                let controller = UIActivityViewController(activityItems: [shortenedURL], applicationActivities: nil)
                self.present(controller, animated: true, completion: nil)
            }
            
            self.isShorteningURL = false
            self.updateShareItem()
        }
    }
    
    @objc fileprivate func safariAction() {
        guard let url = url else {
            return
        }
        
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    // MARK: Loading
    
    var loaderLabelText = "webview.loading".localized
    
    fileprivate var loadingCoverView: UIImageView?
    fileprivate var loader: Loader?
    
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
        button.setTitle("game.enter".localized, for: .normal)
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
    
    fileprivate var isShowingGame = false
    
    @objc fileprivate func showLoadingGame() {
        guard let loadingCoverView = loadingCoverView,
            let scene = GameScene.unarchiveFromFile("GameScene") as? GameScene else {
            return
        }
        
        isShowingGame = true
        
        let gameView = SKView()
        gameView.translatesAutoresizingMaskIntoConstraints = false
        gameView.ignoresSiblingOrder = true
        loadingCoverView.addSubview(gameView)
        gameView.topAnchor.constraint(equalTo: loadingCoverView.topAnchor).isActive = true
        gameView.leadingAnchor.constraint(equalTo: loadingCoverView.leadingAnchor).isActive = true
        gameView.bottomAnchor.constraint(equalTo: loadingCoverView.layoutMarginsGuide.bottomAnchor).isActive = true
        gameView.trailingAnchor.constraint(equalTo: loadingCoverView.trailingAnchor).isActive = true
        
        scene.gameDelegate = self
        scene.scaleMode = .aspectFill
        gameView.presentScene(scene)
        
        loader?.stopAnimation()
    }
}

extension WebViewController : WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        if !didLoadInitialPage {
            showLoadingView()
            
            if didViewAppear {
                loader?.startAnimation()
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        didLoadInitialPage = true
        
        if !isShowingGame {
            hideLoadingView()
        }
    }
}

extension WebViewController : GameSceneDelegate {
    func gameSceneDidStartGame(_ gameScene: GameScene) {
        
    }
    
    func gameSceneDidEndGame(_ gameScene: GameScene) {
        if didLoadInitialPage {
            hideLoadingView()
        }
    }
}
