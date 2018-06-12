//
//  CheckoutWhatIsCVVWebViewController.swift
//  screenshot
//
//  Created by Corey Werner on 5/1/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import UIKit
import WebKit

class CheckoutWhatIsCVVWebViewController: WebViewController {
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        loadURL(URL(string: "https://www.cvvnumber.com/cvv.html"))
        isToolbarEnabled = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.scrollView.delegate = self
    }
    
    deinit {
        webView.scrollView.delegate = nil
    }
}

extension CheckoutWhatIsCVVWebViewController: UIScrollViewDelegate {
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        let javascript = """
            var meta = document.createElement('meta');
            meta.setAttribute('name', 'viewport');
            meta.setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no');
            document.getElementsByTagName('head')[0].appendChild(meta);
        """
        
        webView.evaluateJavaScript(javascript, completionHandler: nil)
    }
}
