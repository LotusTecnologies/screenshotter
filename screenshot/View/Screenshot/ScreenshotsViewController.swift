//
//  ScreenshotsViewController.swift
//  screenshot
//
//  Created by Jonathan Rose on 2/18/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation
import CoreData
import SafariServices
import FBSDKCoreKit


extension ScreenshotsViewController : FetchedResultsControllerManagerDelegate {
    func managerDidChangeContent(_ controller: NSObject, change: FetchedResultsControllerManagerChange) {
        change.shiftIndexSections(by: 2)
        change.applyChanges(collectionView: self.collectionView)
        self.syncHelperViewVisibility()

    }
    
    @objc func setupFetchedResultsController(){
        self.screenshotFrcManager = DataModel.sharedInstance.screenshotFrc(delegate: self)
        
    }
    @objc func screenshotFrc() -> NSFetchedResultsController<Screenshot>? {
        return (self.screenshotFrcManager as? FetchedResultsControllerManager<Screenshot>)?.fetchedResultsController
        
    }
}

extension ScreenshotsViewController : ProductsBarControllerDelegate {
    func productBarShouldHide(_ controller: ProductsBarController) {
        if self.collectionView.numberOfItems(inSection: ScreenshotsSection.product.rawValue) == 1{
            self.collectionView.deleteItems(at: [IndexPath.init(row: 0, section: ScreenshotsSection.product.rawValue)])
        }
    }
    
    func productBarShouldShow(_ controller: ProductsBarController) {
        if self.collectionView.numberOfItems(inSection: ScreenshotsSection.product.rawValue) == 0{
            self.collectionView.insertItems(at: [IndexPath.init(row: 0, section: ScreenshotsSection.product.rawValue)])
        }
    }
    
    func productBar(_ controller: ProductsBarController, didTap product: Product) {
        
        if var urlString = product.offer {
            if urlString.hasPrefix("//") {
                urlString = "https:".appending(urlString)
            }
            if let url = URL(string: urlString){
                var openInSetting = OpenProductPageInSetting.fromSystemInfo()
                
                if !openInSetting.canOpen(url: url) {
                    openInSetting = .embededSafari
                }
                
                switch openInSetting {
                case .embededSafari:
                    let svc = SFSafariViewController(url: url)
                    if #available(iOS 11.0, *) {
                        svc.dismissButtonStyle = .done
                    }
                    self.present(svc, animated: true, completion: nil)
                case .safari:
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                case .chrome:
                    UIApplication.shared.openInChrome(url: url) //returns success
                    
                }
            }
        }
        
        AnalyticsTrackers.standard.trackTappedOnProduct(product, onPage: "ProductBar")
        
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
        AnalyticsTrackers.branch.track("Tapped on productBar")
        FBSDKAppEvents.logEvent(FBSDKAppEventNameViewedContent, parameters:[FBSDKAppEventParameterNameContentID: product.imageURL ?? ""])
    }
}
