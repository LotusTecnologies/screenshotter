//
//  OpenProductPageInSetting.swift
//  screenshot
//
//  Created by Jonathan Rose on 2/20/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation
import FBSDKCoreKit
import SafariServices


enum OpenProductPage : String {
    case embededSafari
    case safari
    case chrome
    
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
    
    static func fromSystemInfo() -> OpenProductPage{
        let defaultValue:OpenProductPage = .embededSafari
        let stringValue = UserDefaults.standard.value(forKey: UserDefaultsKeys.openProductPageInSetting) as? String ?? defaultValue.rawValue
        return OpenProductPage(rawValue: stringValue) ?? defaultValue
    }
    
    func saveToUserDefaults() {
        UserDefaults.standard.set(self.rawValue, forKey: UserDefaultsKeys.openProductPageInSetting)
    }
    
    func canOpen(url:URL) -> Bool{
        switch self {
        case .embededSafari:
            return true
        case .safari:
            return UIApplication.shared.canOpenURL(url)
        case .chrome:
            return  UIApplication.shared.canOpenInChrome(url: url)
        }
    }
    
    static func present(product:Product, fromViewController:UIViewController, analyticsKey:String){
        
        if var urlString = product.offer {
            if urlString.hasPrefix("//") {
                urlString = "https:".appending(urlString)
            }
            if let url = URL(string: urlString){
                var openInSetting = OpenProductPage.fromSystemInfo()
                
                if !openInSetting.canOpen(url: url) {
                    openInSetting = .embededSafari
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
        
        AnalyticsTrackers.standard.trackTappedOnProduct(product, onPage: analyticsKey)
        
        let email = UserDefaults.standard.string(forKey: UserDefaultsKeys.email) ?? ""
        
        if email.lengthOfBytes(using: .utf8) > 0 {
            let uploadedImageURL = product.screenshot?.uploadedImageURL ?? ""
            let merchant = product.merchant ?? ""
            let brand = product.brand ?? ""
            let displayTitle = product.displayTitle ?? ""
            let offer = product.offer ?? ""
            let imageURL = product.imageURL ?? ""
            let price = product.price ?? ""
            let name =  UserDefaults.standard.string(forKey: UserDefaultsKeys.name) ?? ""
            
            let properties = ["screenshot": uploadedImageURL,
                              "merchant": merchant,
                              "brand": brand,
                              "title": displayTitle,
                              "url": offer,
                              "imageUrl": imageURL,
                              "price": price,
                              "email": email,
                              "name": name ]
            AnalyticsTrackers.standard.track("Product for email", properties:properties)
        }
        
        product.recordViewedProduct()
        AnalyticsTrackers.branch.track("Tapped on product - \(analyticsKey)")
        FBSDKAppEvents.logEvent(FBSDKAppEventNameViewedContent, parameters:[FBSDKAppEventParameterNameContentID: product.imageURL ?? ""])
    }
}
