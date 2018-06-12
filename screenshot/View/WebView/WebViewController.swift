//
//  WebViewController.swift
//  screenshot
//
//  Created by Corey Werner on 12/20/17.
//  Copyright (c) 2017 crazeapp. All rights reserved.
//

import UIKit
import WebKit
import Appsee

@objc protocol WebViewControllerDelegate : NSObjectProtocol {
    func webViewController(_ viewController: WebViewController, declinedInvalidURL url: URL)
}

class WebViewController : BaseViewController {
    let webView = WebView()
    fileprivate var loader: Loader?
    var failLabel:UILabel?
    var tryAgainButton:MainButton?
    weak var delegate: WebViewControllerDelegate?
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        setupBarButtonItems()
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
        
        syncToolbar()
        setBarButtonItemsToToolbarIfPossible()
        
        
        let loader = Loader()
        loader.translatesAutoresizingMaskIntoConstraints = false
        loader.color = .crazeRed
        loader.activityView.hidesWhenStopped = true
        self.view.addSubview(loader)
        loader.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        loader.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        self.loader = loader
        loader.startAnimation()
        
        loadURL(url)
        
    }
    
   
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Appsee.startScreen("WebView")
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
        
        webView.load(URLRequest(url: url))
    }
    
    func rebaseURL(_ url: URL?) {
        webView.removeAllBackForwardListItems()
        loadURL(url)
    }
    
    // MARK: Toolbar
    
    var isToolbarEnabled = true {
        didSet {
            syncToolbar()
        }
    }
    
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
    
    fileprivate func syncToolbar() {
        if isViewLoaded {
            // Don't lazy load the toolbar when initially setting to false
            if !isToolbarEnabled && view.subviews.first(where: { $0 is UIToolbar }) == nil {
                return
            }
            
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
        
        Analytics.trackRefreshedWebpage(url: url?.absoluteString)
    }
    
    @objc fileprivate func shareAction() {
        guard let url = url else {
            return
        }
        
        isShorteningURL = true
        updateShareItem()
        
        NetworkingPromise.sharedInstance.shorten(url: url) { shortenedURL in
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
}

extension WebViewController : WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = webView.url {
            if UIApplication.shared.canOpenURL(url) {
                decisionHandler(.allow)
            }
            else {
                decisionHandler(.cancel)
                Analytics.trackWebViewInvalidUrl(url: url.absoluteString)
                self.delegate?.webViewController(self, declinedInvalidURL: url)
            }
        }
        else {
            decisionHandler(.cancel)
        }
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
       
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        self.loader?.stopAnimation()
        decisionHandler(.allow)
    }
   
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.loader?.stopAnimation()
    }
   
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        self.failedToLoad()
    }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self.failedToLoad()
    }
    func failedToLoad() {
        self.loader?.stopAnimation()
        
        if let label = self.failLabel {
            label.removeFromSuperview()
        }
        if let button = self.tryAgainButton{
            button.removeFromSuperview()
        }
        let failLabel = UILabel()
        failLabel.translatesAutoresizingMaskIntoConstraints = false
        failLabel.text = "products.related_looks.error.connection".localized
        failLabel.textColor = .gray3
        failLabel.textAlignment = .center
        failLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        failLabel.numberOfLines = 0
        failLabel.adjustsFontForContentSizeCategory = true
        self.view.addSubview(failLabel)
        failLabel.bottomAnchor.constraint(equalTo: self.view.centerYAnchor, constant:-.padding).isActive = true
        failLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor, constant: -.padding).isActive = true
        
        let button = MainButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .crazeGreen
        button.setTitle("generic.retry".localized, for: .normal)
        button.addTarget(self, action: #selector(tryAgain(_:)), for: .touchUpInside)
        self.view.addSubview(button)
        button.topAnchor.constraint(equalTo: self.view.centerYAnchor, constant:.padding).isActive = true
        button.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.tryAgainButton = button
        self.failLabel = failLabel

    }
    
    @objc func tryAgain(_ sender:Any) {
        self.tryAgainButton?.removeFromSuperview()
        self.tryAgainButton = nil
        
        self.failLabel?.removeFromSuperview()
        self.failLabel = nil
        self.loader?.startAnimation()
        
        loadURL(url)

    }
    
}

