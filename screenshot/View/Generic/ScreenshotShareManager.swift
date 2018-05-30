//
//  ScreenshotShareManager.swift
//  screenshot
//
//  Created by Jonathan Rose on 5/27/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation
import UIKit

fileprivate extension UIViewController {
    @objc func dismissWithSender(_ sender:Any){
        self.dismiss(animated: true, completion: nil)
    }
}



class ScreenshotShareManager {
    
    static func share(product:Product, in viewController:UIViewController){
    
        guard let o = product.offer, let offersURL = URL.init(string: o) else {
            return
        }
        
        
        
        let introductoryText = "products.share.title".localized
        
        
        let productObjectId = product.objectID
        
        // iOS 11.1 has a bug where copying to clipboard while sharing doesn't put a space between activity items.
        let space = " "

        let items:[Any] = [introductoryText, space, offersURL]
        let activityViewController = UIActivityViewController.init(activityItems: items, applicationActivities: [])
        activityViewController.excludedActivityTypes = [UIActivityType.addToReadingList, UIActivityType.airDrop, UIActivityType.init("com.apple.reminders.RemindersEditorExtension"), UIActivityType.init("com.apple.mobilenotes.SharingExtension")]
        activityViewController.completionWithItemsHandler = { (activityType, completed, returnedItems, activityError) in
            let product = DataModel.sharedInstance.mainMoc().productWith(objectId: productObjectId)
            if (completed) {
                Analytics.trackProductShareSocial(product: product)
            }
        }
        activityViewController.popoverPresentationController?.sourceView = viewController.view
        viewController.present(activityViewController, animated: true, completion: nil)
    }

    
    static func share(screenshot:Screenshot, in viewController:UIViewController){
        
        let screenshotObjectId = screenshot.objectID
        let alert = UIAlertController.init(title: "share_to_discover.action_sheet.title".localized, message: "share_to_discover.action_sheet.message".localized, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction.init(title: "share_to_discover.action_sheet.discover".localized, style: .default, handler: { (a) in
            if let screenshot = DataModel.sharedInstance.mainMoc().screenshotWith(objectId: screenshotObjectId) {
                if !screenshot.canSubmitToDiscover {
                    let alert = UIAlertController.init(title: nil, message: "share_to_discover.action_sheet.error.alread_shared".localized, preferredStyle: .alert)
                    
                    alert.addAction(UIAlertAction.init(title: "generic.ok".localized, style: .cancel, handler: { (a) in
                        
                    }))
                    viewController.present(alert, animated: true, completion: nil)
                    Analytics.trackShareError(screenshot: screenshot, errorTpye: .alreadyShared)
                }else {
                    screenshot.submitToDiscover()
                    let thankYou = ThankYouForSharingViewController()
                    thankYou.closeButton.addTarget(viewController, action: #selector(UIViewController.dismissWithSender(_:)), for: .touchUpInside)
                    viewController.present(thankYou, animated: true, completion: nil)
                    
                    Analytics.trackShareDiscover(screenshot: screenshot, page: .screenshotList)
                    
                }
            }
            
        }))
        alert.addAction(UIAlertAction.init(title: "share_to_discover.action_sheet.social".localized, style: .default, handler: { (a) in
            if let screenshot = DataModel.sharedInstance.mainMoc().screenshotWith(objectId: screenshotObjectId) {

                let introductoryText = "screenshots.share.title".localized
                
                let screenshotObjectId = screenshot.objectID
                var items:[Any]? = nil
                
                // iOS 11.1 has a bug where copying to clipboard while sharing doesn't put a space between activity items.
                let space = " "
                
                if let shareLink = screenshot.shareLink, let shareURL = URL.init(string: shareLink) {
                    items = [introductoryText, space, shareURL]
                }else{
                    if let url = URL.init(string: "https://getscreenshop.com/") {
                        let screenshotActivityItemProvider = ScreenshotActivityItemProvider.init(screenshot: screenshot, placeholderURL:url)
                        items = [introductoryText, space, screenshotActivityItemProvider]
                    }
                }
                if let items =  items {
                    let activityViewController = UIActivityViewController.init(activityItems: items, applicationActivities: [])
                    activityViewController.excludedActivityTypes = [UIActivityType.addToReadingList, UIActivityType.airDrop, UIActivityType.init("com.apple.reminders.RemindersEditorExtension"), UIActivityType.init("com.apple.mobilenotes.SharingExtension")]
                    activityViewController.completionWithItemsHandler = { (activityType, completed, returnedItems, activityError) in
                        let screenshot = DataModel.sharedInstance.mainMoc().screenshotWith(objectId: screenshotObjectId)
                        if (completed) {
                            Analytics.trackShareSocial(screenshot: screenshot)
                        }
                    }
                    activityViewController.popoverPresentationController?.sourceView = viewController.view
                    viewController.present(activityViewController, animated: true, completion: nil)
                }
            }
        }))
        alert.addAction(UIAlertAction.init(title: "generic.cancel".localized, style: .cancel, handler: { (a) in
            
        }))
        alert.popoverPresentationController?.sourceView = viewController.view
        viewController.present(alert, animated: true, completion: nil)
        
        Analytics.trackSharedScreenshotStarted(screenshot: screenshot)
    }
    
}

