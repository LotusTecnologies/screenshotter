//
//  WebView.swift
//  screenshot
//
//  Created by Corey Werner on 10/23/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation
import WebKit

class WebView: WKWebView {
    public func removeAllBackForwardListItems() {
        let selector = Selector(("_removeAllItems"))
        
        if backForwardList.responds(to: selector) {
            backForwardList.perform(selector)
        }
    }
}
