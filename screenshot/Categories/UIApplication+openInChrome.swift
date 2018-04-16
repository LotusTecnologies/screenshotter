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
        guard let scheme = url.scheme?.lowercased() else {
            return nil
        }
        
        let chromeScheme:String?
        switch scheme {
        case "http":
            chromeScheme = UIApplication.kGoogleChromeHTTPScheme
        case "https":
            chromeScheme = UIApplication.kGoogleChromeHTTPSScheme
        default:
            chromeScheme = nil
        }
        
        if let chromeScheme = chromeScheme,
          let rangeForScheme = url.absoluteString.range(of: ":") {
            let endOfColon = rangeForScheme.upperBound
            let urlNoScheme = url.absoluteString[endOfColon...]
            let chromeURLString = chromeScheme.appending(urlNoScheme)
            let chromeURL = URL.init(string: chromeURLString)
            return chromeURL
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

extension URL {
    static func googleMailUrl(to:String?, body:String?, subject:String? ) -> URL? {
        var components = URLComponents(string: "googlegmail://co")
        components?.scheme = "googlegmail"
        
        var queryItems: [URLQueryItem] = []
        
        if let to = to {
            queryItems.append(URLQueryItem(name: "to", value:to))
        }
        
        if let subject = subject{
            queryItems.append(URLQueryItem(name: "subject", value:subject))
        }
        
        if let body = body{
            queryItems.append(URLQueryItem(name: "body", value:body))
        }
        
        if queryItems.isEmpty == false {
            components?.queryItems = queryItems
        }
        
        return components?.url
    }
}
