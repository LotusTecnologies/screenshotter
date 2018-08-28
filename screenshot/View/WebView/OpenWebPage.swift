//
//  OpenWebPage.swift
//  screenshot
//
//  Created by Jonathan Rose on 2/20/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import Foundation
import FBSDKCoreKit
import SafariServices

enum OpenWebPage : String {
    case embededSafari
    case safari
    case chrome
    
    func analyticsString() -> String {
        switch self {
        case .embededSafari:
            return "embededSafari"
        case .safari:
            return "safari"
        case .chrome:
            return "chrome"
        }
    }
    
    func localizedDisplayString() -> String{
        switch self {
        case .embededSafari:
            return "settings.open_in.option.embeded".localized
        case .safari:
            return "settings.open_in.option.safari".localized
        case .chrome:
            return "settings.open_in.option.chrome".localized
        }
    }
    
    static func fromSystemInfo() -> OpenWebPage{
        var defaultValue:OpenWebPage = .safari

        if let appSettingsDefaultString = AppDelegate.shared.appSettings.openWebPageDefault, let appSettingsDefault = OpenWebPage.init(rawValue:appSettingsDefaultString){
            defaultValue = appSettingsDefault
        }

        let stringValue = UserDefaults.standard.value(forKey: UserDefaultsKeys.openWebPage) as? String ?? defaultValue.rawValue
        return OpenWebPage(rawValue: stringValue) ?? defaultValue
    }
    
    func saveToUserDefaults() {
        UserDefaults.standard.set(self.rawValue, forKey: UserDefaultsKeys.openWebPage)
    }
    
    func canOpen(url:URL) -> Bool{
        switch self {
        case .embededSafari:
            return true
        case .safari:
            return UIApplication.shared.canOpenURL(url)
        case .chrome:
            return UIApplication.shared.canOpenInChrome(url: url)
        }
    }
    
    static func using(url:URL) ->OpenWebPage {
        var openInSetting = OpenWebPage.fromSystemInfo()
        
        for fallbackSetting in [.safari, chrome, .embededSafari] {  //Fallbacks are in this order particularly!
            if !openInSetting.canOpen(url: url) {
                openInSetting = fallbackSetting
            }
        }
        return openInSetting
    }
    
    static func present(urlString: String?, fromViewController: UIViewController) {
        guard var urlString = urlString else {
            return
        }
        
        if urlString.hasPrefix("//") {
            urlString = "https:".appending(urlString)
        }
        
        if let url = URL(string: urlString){
            var openInSetting = OpenWebPage.fromSystemInfo()
            
            for fallbackSetting in [.safari, chrome, .embededSafari] {  //Fallbacks are in this order particularly!
                if !openInSetting.canOpen(url: url) {
                    openInSetting = fallbackSetting
                }
            }
            
            switch openInSetting {
            case .embededSafari:
                let svc = SFSafariViewController(url: url)
                if #available(iOS 11.0, *) {
                    svc.dismissButtonStyle = .done
                }
                fromViewController.present(svc, animated: true, completion: nil)
            case .safari:
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            case .chrome:
                UIApplication.shared.openInChrome(url: url) //returns success
            }
        }
    }
    
    static func presentProduct(_ product: Product, fromViewController: UIViewController) {
        present(urlString: product.offer, fromViewController: fromViewController)
    }
}
