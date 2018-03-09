//
//  CheckoutWebViewController.swift
//  screenshot
//
//  Created by Corey Werner on 3/8/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit
import WebKit

class CheckoutWebViewController: WebViewController {
    
}

extension CheckoutWebViewController {
    override func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        super.webView(webView, didStartProvisionalNavigation: navigation)
        
        if let url = webView.url, url.path == "/yourthankyoupage",
            let components = URLComponents(string: url.absoluteString)
        {
            let remoteIdQueryItem = components.queryItems?.first { $0.name == "remoteId" }
            let fromQueryItem = components.queryItems?.first { $0.name == "from" }
            
            if let remoteId = remoteIdQueryItem?.value {
                ShoppingCartModel.shared.hostedCompleted(remoteId: remoteId, from: fromQueryItem?.value ?? "")
            }
        }
    }
}

