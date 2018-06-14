//
//  RelatedLooksManager.swift
//  screenshot
//
//  Created by Jonathan Rose on 6/14/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit
import PromiseKit

protocol RelatedLooksManagerDelegate : class {
    func relatedLooksManagerReloadSection(_ relatedLooksManager:RelatedLooksManager)
    func relatedLooksManagerGetProducts(_ relatedLooksManager:RelatedLooksManager) -> [Product]?
    func relatedLooksManagerGetShoppable(_ relatedLooksManager:RelatedLooksManager) -> Shoppable?
    func relatedLooksManager(_ relatedLooksManager:RelatedLooksManager, present viewController:UIViewController)

}
class RelatedLooksManager: NSObject {
    var relatedLooks:Promise<[String]>?
    weak var delegate:RelatedLooksManagerDelegate?


    func hasRelatedLooksSection() -> Bool {
        if let error = self.relatedLooks?.error {
            let e = error as NSError
            if e.code == 0 && e.domain == "related_looks" {
                return false
            }
        }
        if let products =  self.delegate?.relatedLooksManagerGetProducts(self) {
            return products.count > 0
        }
        return false
    }
    func numberOfItems() -> Int {
        
        if self.hasRelatedLooksSection()  {
            // if product is not load then related looks does not appear at all
            if let relatedLooks = self.relatedLooks?.value {
                return relatedLooks.count
            }else {
                if let _ = self.delegate?.relatedLooksManagerGetProducts(self), let _ = self.delegate?.relatedLooksManagerGetShoppable(self)?.relatedImagesUrl() {
                    return 1 //loading or error
                }else{
                    return 0
                }
            }
        }
        return 0
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if self.hasRelatedLooksSection() && scrollView.contentSize.height > 0  {
            let scrollViewHeight = scrollView.frame.size.height;
            let scrollContentSizeHeight = scrollView.contentSize.height;
            let scrollOffset = scrollView.contentOffset.y;
            let startLoadingDistance:CGFloat = 500
            
            
            if (scrollOffset + scrollViewHeight + startLoadingDistance >= scrollContentSizeHeight){
                self.loadRelatedLooksIfNeeded()
            }
        }
    }
    func hasInset () -> Bool{
        if let _  = self.relatedLooks?.value {
           return true
        }
        return false
    }
    func relatedLook(at index:Int) -> String?{
        if let relatedLooks = self.relatedLooks?.value {
            if relatedLooks.count > index {
                return relatedLooks[index]
            }
        }
        return nil
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    
        func isErrorRetryable(error:Error) -> Bool {
            let nsError = error as NSError
            if let retryable = nsError.userInfo["retryable"] as? Bool {
                return retryable
            }else{
                return true
            }
        }
        
        
        if let relatedLooks = self.relatedLooks?.value, relatedLooks.count > indexPath.row {
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "relatedLooks", for: indexPath) as? RelatedLooksCollectionViewCell {
                let imageString = relatedLooks[indexPath.row]
                let url = URL.init(string: imageString)
                
                cell.imageView.sd_setImage(with: url, completed: nil)
                cell.flagButton.tag = indexPath.row
                cell.flagButton.addTarget(self, action: #selector(pressedFlagButton(_:)), for: .touchUpInside)
                
                return cell
            }
        }else if let error = self.relatedLooks?.error {
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "relatedLooks-error", for: indexPath) as? ErrorCollectionViewCell {
                if isErrorRetryable(error:error) {
                    cell.button.setTitle("generic.retry".localized, for: .normal)
                    cell.button.addTarget(self, action: #selector(didPressRetryRelatedLooks(_:)), for: .touchUpInside)
                    cell.label.text = "products.related_looks.error.connection".localized
                }else{
                    cell.button.setTitle("generic.dismiss".localized, for: .normal)
                    cell.button.addTarget(self, action: #selector(didPressDismissRelatedLooks(_:)), for: .touchUpInside)
                    cell.label.text = "products.related_looks.error.no_looks".localized
                }
                return cell
            }
            
        }else {
            //show spinner cell
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "relatedLooks-spinner", for: indexPath) as? SpinnerCollectionViewCell{
                cell.spinner.color = .gray3
                return cell
            }
        }
        return UICollectionViewCell.init()
    }
    
    @objc func didPressDismissRelatedLooks(_ sender:Any) {
        let error = NSError.init(domain: "related_looks", code: 0, userInfo: [NSLocalizedDescriptionKey:"don't show section", "retryable":false])
        self.relatedLooks = Promise.init(error: error)
        self.delegate?.relatedLooksManagerReloadSection(self)
    }
    
    @objc func didPressRetryRelatedLooks(_ sender:Any) {
        self.relatedLooks = nil
        self.loadRelatedLooksIfNeeded()

        self.delegate?.relatedLooksManagerReloadSection(self)
    }
    
    @objc fileprivate func pressedFlagButton(_ sender:Any) {
        if let button = sender as? UIView  {
            let index = button.tag
            if let relatedLooksArray = self.relatedLooks?.value {
                if relatedLooksArray.count > index {
                    let url = relatedLooksArray[index]
                    self.presentReportAlertController(url:url)
                }
            }
        }
    }
    
    func loadRelatedLooksIfNeeded() {
        if self.relatedLooks == nil {
            if let shoppabe = self.delegate?.relatedLooksManagerGetShoppable(self), let relatedlooksURL = shoppabe.relatedImagesUrl()  {
                Analytics.trackShoppableRelatedLooksLoaded(shoppable: shoppabe)
                let atLeastXSeconds = Promise.init(resolvers: { (fulfil, reject) in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: {
                        fulfil(true);
                    })
                })
                let loadRequest:Promise<[String]> = Promise.init(resolvers: { (fulfil, reject) in
                    
                    let objectId = shoppabe.objectID
                    if let arrayString = shoppabe.relatedImagesArray, let data = arrayString.data(using: .utf8), let array = try? JSONSerialization.jsonObject(with:data, options: []), let a = array as? [String]{
                        fulfil(a)
                    }else{
                        URLSession.shared.dataTask(with: URLRequest.init(url: relatedlooksURL)).asDictionary().then(execute: { (dict) -> Void in
                            
                            if let array = dict["related_looks"] as? [ String] {
                                if array.count > 0 {
                                    DataModel.sharedInstance.performBackgroundTask({ (context) in
                                        if let shopable = context.shoppableWith(objectId: objectId){
                                            if let data = try? JSONSerialization.data(withJSONObject: array, options: []),  let string =  String.init(data: data, encoding:.utf8) {
                                                shopable.relatedImagesArray = string
                                            }
                                        }
                                        context.saveIfNeeded()
                                        DispatchQueue.main.async {
                                            fulfil(array)
                                        }
                                        
                                    })
                                }else{
                                    let error = NSError.init(domain: "related_looks", code: 3, userInfo: [NSLocalizedDescriptionKey:"no results", "retryable":false])
                                    reject(error)
                                }
                                
                            }else{
                                let error = NSError.init(domain: "related_looks", code: 2, userInfo: [NSLocalizedDescriptionKey:"bad response", "retryable":true])
                                reject(error)
                                
                            }
                            
                        }).catch(execute: { (error) in
                            reject(error)
                        })
                    }
                });
                
                let promise = Promise.init(resolvers: { (fulfil, reject) in
                    
                    atLeastXSeconds.always {
                        loadRequest.then(execute: { (value) -> Void in
                            fulfil(value)
                        }).catch(execute: { (error) in
                            reject(error)
                        })
                    }
                })
                promise.always(on: .main) {
                    self.delegate?.relatedLooksManagerReloadSection(self)
                    
                }
                self.relatedLooks = promise
            }else{
                let shopable = self.delegate?.relatedLooksManagerGetShoppable(self)
                Analytics.trackShoppableRelatedLooksNotLoaded(shoppable: shopable)
                let error = NSError.init(domain: "related_looks", code: 1, userInfo: [NSLocalizedDescriptionKey:"no url", "retryable":false])
                self.relatedLooks = Promise.init(error: error)
            }
        }
    }

}


extension RelatedLooksManager {
    
    
    fileprivate func presentReportAlertController(url:String) {
        let alertController = UIAlertController(title: "discover.screenshot.flag.title".localized, message: "discover.screenshot.flag.message".localized, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "discover.screenshot.flag.inappropriate".localized, style: .default, handler: { action in
            self.presentInappropriateAlertController(url:url)
        }))
        alertController.addAction(UIAlertAction(title: "discover.screenshot.flag.copyright".localized, style: .default, handler: { action in
            self.presentCopyrightAlertController(url:url)
        }))
        
        alertController.addAction(UIAlertAction(title: "discover.screenshot.flag.duplicate".localized, style: .default, handler: { action in
            self.presentDuplicateAlertController(url:url)
        }))
        alertController.addAction(UIAlertAction(title: "generic.cancel".localized, style: .cancel, handler: nil))
        self.delegate?.relatedLooksManager(self, present: alertController)
    }
    
    fileprivate func presentInappropriateAlertController(url:String) {
        let alertController = UIAlertController(title: "discover.screenshot.flag.inappropriate.title".localized, message: "discover.screenshot.flag.inappropriate.message".localized, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "generic.ok".localized, style: .cancel, handler: nil))
        self.delegate?.relatedLooksManager(self, present: alertController)
        Analytics.trackScreenshotRelatedLookFlagged(url: url, why: .inappropriate)
    }
    
    fileprivate func presentCopyrightAlertController(url:String) {
        let alertController = UIAlertController(title: "discover.screenshot.flag.copyright.title".localized, message: "discover.screenshot.flag.copyright.message".localized, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "legal.terms_of_service".localized, style: .default, handler: { action in
            self.presentTermsOfServiceViewController()
        }))
        alertController.addAction(UIAlertAction(title: "generic.done".localized, style: .cancel, handler: nil))
        self.delegate?.relatedLooksManager(self, present: alertController)
        
        Analytics.trackScreenshotRelatedLookFlagged(url: url, why: .copyright)
    }
    fileprivate func presentDuplicateAlertController(url:String) {
        let alertController = UIAlertController(title: "discover.screenshot.flag.inappropriate.title".localized, message: "discover.screenshot.flag.inappropriate.message".localized, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "generic.ok".localized, style: .cancel, handler: nil))
        self.delegate?.relatedLooksManager(self, present: alertController)
        
        Analytics.trackScreenshotRelatedLookFlagged(url: url, why: .duplicate)
    }
    
    fileprivate func presentTermsOfServiceViewController() {
        if let viewController = LegalViewControllerFactory.termsOfServiceViewController() {
            self.delegate?.relatedLooksManager(self, present: viewController)
        }
    }
}
