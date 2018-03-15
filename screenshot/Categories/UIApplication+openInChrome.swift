//
//  UIApplication+openInChrome.swift
//  screenshot
//
//  Created by Jonathan Rose on 2/15/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation
import UIKit

extension UIApplication {
    
    static let kGoogleChromeHTTPScheme = "googlechrome:"
    static let kGoogleChromeHTTPSScheme = "googlechromes:"
    func isChromeInstalled() -> Bool{
        if let simpleURL = URL.init(string: UIApplication.kGoogleChromeHTTPScheme) {
            return self.canOpenURL(simpleURL)
        }
        return false
    }
    
    func chomeURLFor(url:URL) -> URL? {
        let scheme = url.scheme?.lowercased()
        
        let chromeScheme:String? = {
            if (scheme == "http") {
                return  UIApplication.kGoogleChromeHTTPScheme
            } else if (scheme == "https") {
                return UIApplication.kGoogleChromeHTTPSScheme
            }
            return nil
        }()
        
        if let chromeScheme = chromeScheme {
            let rangeForScheme = url.absoluteString.range(of: ":")
            if let endOfColon = rangeForScheme?.upperBound {
                let urlNoScheme = url.absoluteString.substring(from: endOfColon)
                let chromeURLString = chromeScheme.appending(urlNoScheme)
                let chromeURL = URL.init(string: chromeURLString)
                return chromeURL
            }
        }
        return nil
    }
    
    func openInChrome(url:URL ){
        if self.isChromeInstalled() {
            if let chromeURL = self.chomeURLFor(url:url){
                 self.open(chromeURL, options: [:], completionHandler: nil)
            }
        }
    }
    
    func canOpenInChrome(url:URL ) -> Bool{
        if self.isChromeInstalled() {
            if let url = self.chomeURLFor(url:url){
                return self.canOpenURL(url)
            }
        }
        return false
    }
}
