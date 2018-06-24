//
//  UIApplication+openInChrome.swift
//  screenshot
//
//  Created by Jonathan Rose on 2/15/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import Foundation
import UIKit
import MessageUI

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
        let chromeScheme: String?
        if let scheme = url.scheme?.lowercased() {
            switch scheme {
            case "http":
                chromeScheme = UIApplication.kGoogleChromeHTTPScheme
            case "https":
                chromeScheme = UIApplication.kGoogleChromeHTTPSScheme
            default:
                chromeScheme = nil
            }
        } else {
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

extension UIViewController :MFMailComposeViewControllerDelegate{
    func presentMail(recipient:String, gmailMessage:String, subject:String, message:String, isHTML:Bool = false, delegate:MFMailComposeViewControllerDelegate? = nil ){
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = delegate ?? self
            mail.setSubject(subject)
            mail.setMessageBody(message, isHTML: isHTML)
            mail.setToRecipients([recipient])
            present(mail, animated: true, completion: nil)
            
        } else if let url = URL.googleMailUrl(to: recipient, body: gmailMessage, subject: subject), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            
        } else {
            let alertController = UIAlertController(title: "email.setup.title".localized, message: "email.setup.message".localized, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "generic.later".localized, style: .cancel, handler: nil))
            
            if let mailURL = URL(string: "message://"), UIApplication.shared.canOpenURL(mailURL) {
                alertController.addAction(UIAlertAction(title: "generic.setup".localized, style: .default, handler: { action in
                    UIApplication.shared.open(mailURL, options: [:], completionHandler: nil)
                }))
            }
            
            present(alertController, animated: true, completion: nil)
        }
        
    }
    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        dismiss(animated: true, completion: nil)
    }
}
