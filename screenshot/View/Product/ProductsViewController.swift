//
//  ProductsViewController.swift
//  screenshot
//
//  Created by Jonathan Rose on 2/11/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation
import FBSDKCoreKit

@objc enum ProductsSection : Int {
    case tooltip = 0
    case product = 1
}

extension ProductsViewController {
    @objc func setupShoppableToolbar() {
        self.shoppablesToolbar = {
            let margin:CGFloat = 8.5 // Anything other then 8 will display horizontal margin
            let shoppableHeight:CGFloat = 60
            
            let toolbar = ShoppablesToolbar.init(frame: CGRect.init(x: 0, y: 0, width: 0, height: margin*2+shoppableHeight))
            toolbar.translatesAutoresizingMaskIntoConstraints = false
            toolbar.delegate = self
            toolbar.shoppableToolbarDelegate = self
            toolbar.barTintColor = .white
            toolbar.isHidden = self.shouldHideToolbar()
            self.view.addSubview(toolbar)
            
            toolbar.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor).isActive = true
            toolbar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
            toolbar.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
            toolbar.heightAnchor.constraint(equalToConstant: toolbar.bounds.size.height).isActive = true
            return toolbar;
        }()
    }
    @objc func setupCollectionView(){
        self.collectionView = {
            let minimumSpacing = self.collectionViewMinimumSpacing()
            
            let layout = UICollectionViewFlowLayout()
            layout.minimumInteritemSpacing = minimumSpacing.x;
            layout.minimumLineSpacing = minimumSpacing.y;
            
            let collectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: layout)

            collectionView.translatesAutoresizingMaskIntoConstraints = false
            collectionView.delegate = self;
            collectionView.dataSource = self;
            collectionView.contentInset = UIEdgeInsets.init(top: self.shoppablesToolbar.bounds.size.height, left: 0.0, bottom: minimumSpacing.y, right: 0.0)
            collectionView.scrollIndicatorInsets = UIEdgeInsets.init(top: self.shoppablesToolbar.bounds.size.height, left: 0.0, bottom: 0.0, right: 0.0)
            
            collectionView.backgroundColor = self.view.backgroundColor;
            // TODO: set the below to interactive and comment the dismissal in -scrollViewWillBeginDragging.
            // Then test why the control view (products options view) jumps before being dragged away.
            collectionView.keyboardDismissMode = .onDrag;
            collectionView.register(ProductsTooltipCollectionViewCell.self, forCellWithReuseIdentifier: "tooltip");
            collectionView.register(ProductCollectionViewCell.self, forCellWithReuseIdentifier: "cell");


            self.view.insertSubview(collectionView, at: 0)
            collectionView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
            collectionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
            collectionView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
            collectionView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
            return collectionView
        }()
    }
}

private typealias ProductsViewControllerCollectionView = ProductsViewController
extension ProductsViewControllerCollectionView : UICollectionViewDelegateFlowLayout, UICollectionViewDataSource{
    func numberOfCollectionViewProductColumns() ->Int {
        return 2
    }
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int{
        if (section == ProductsSection.tooltip.rawValue) {
            let shouldPresentTooldtip = !UserDefaults.standard.bool(forKey: UserDefaultsKeys.productCompletedTooltip)
            let hasProducts = (self.products.count > 0)
            return (shouldPresentTooldtip && hasProducts) ? 1 : 0;
            
        } else if (section == ProductsSection.product.rawValue) {
            return self.products.count;
            
        } else {
            return 0;
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        var size:CGSize = .zero
        let shadowInsets = ScreenshotCollectionViewCell.shadowInsets
        let padding = Geometry.padding - shadowInsets.left - shadowInsets.right;
        
        if (indexPath.section == ProductsSection.tooltip.rawValue) {
            size.width = collectionView.bounds.size.width;
            size.height = ProductsTooltipCollectionViewCell.height(withCellWidth: size.width)
            
        } else if (indexPath.section == ProductsSection.product.rawValue) {
            let columns = CGFloat(self.numberOfCollectionViewProductColumns())
            size.width = floor((collectionView.bounds.size.width - (padding * (columns + 1))) / columns);
            size.height = size.width + ProductCollectionViewCell.labelsHeight
        }
        
        return size;
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if (indexPath.section == ProductsSection.tooltip.rawValue) {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "tooltip", for: indexPath)
            return cell;
        } else if (indexPath.section == ProductsSection.product.rawValue) {
            let product = self.productAtIndex(indexPath.item)
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? ProductCollectionViewCell {
                cell.delegate = self;
                cell.contentView.backgroundColor = collectionView.backgroundColor;
                cell.title = product.displayTitle;
                cell.price = product.price;
                cell.originalPrice = product.originalPrice;
                cell.imageUrl = product.imageURL;
                cell.isSale = product.isSale()
                cell.favoriteButton?.isSelected = product.isFavorite;
                return cell;
            }
            
        }
        return UICollectionViewCell();
        
    }

    
    public func collectionViewMinimumSpacing() -> CGPoint {
        let shadowInsets = ScreenshotCollectionViewCell.shadowInsets
        let p = Geometry.padding
        return CGPoint.init(x: p - shadowInsets.left - shadowInsets.right, y: p - shadowInsets.top - shadowInsets.bottom)
    }
    
    public func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return indexPath.section != ProductsSection.tooltip.rawValue
    }
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        
        if section ==  ProductsSection.product.rawValue {
            let minimumSpacing:CGPoint = self.collectionViewMinimumSpacing()
            
            return UIEdgeInsets.init(top: minimumSpacing.y, left: minimumSpacing.x, bottom: 0.0, right: minimumSpacing.x)
        } else {
            return .zero;
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if (indexPath.section == ProductsSection.product.rawValue) {
            if let _ = self.navigationController?.topViewController as? WebViewController {
                // Somehow the user was able to tap twice
                // do nothing

            }else{
                ProductWebViewController.shared.product = self.productAtIndex(indexPath.item)
                
                if var urlString = ProductWebViewController.shared.product?.offer {
                    if (urlString.hasPrefix("//")) {
                        urlString = "https:".appending(urlString)
                    }
                    if let url = URL.init(string: urlString){
                        ProductWebViewController.shared.rebaseURL(url)
                        self.navigationController?.pushViewController(ProductWebViewController.shared, animated:true)
                    }
                }
            }
            
            let product = self.productAtIndex(indexPath.item)
            AnalyticsTrackers.standard.trackTappedOnProduct(product, onPage: "Products")
            
            
            let email = UserDefaults.standard.string(forKey: UserDefaultsKeys.email)
            
            if (email?.lengthOfBytes(using: .utf8) ?? 0 > 0) {
                let name =  UserDefaults.standard.string(forKey: UserDefaultsKeys.name)
                AnalyticsTrackers.standard.track("Product for email", properties:["screenshot": self.screenshot.uploadedImageURL ?? "",
                                                                                  "merchant": product.merchant ?? "",
                                                                                  "brand": product.brand ?? "",
                                                                                  "title": product.displayTitle ?? "",
                                                                                  "url": product.offer ?? "",
                                                                                  "imageUrl": product.imageURL ?? "",
                                                                                  "price": product.price ?? "",
                                                                                  "email": email ?? "",
                                                                                  "name": name ?? ""])
            }
            AnalyticsTrackers.branch.track("Tapped on product")
            FBSDKAppEvents.logEvent(FBSDKAppEventNameViewedContent, parameters:[FBSDKAppEventParameterNameContentID: product.imageURL ?? ""])
        }
    }
}

private typealias ProductsViewControllerOptionsView = ProductsViewController
extension ProductsViewControllerOptionsView {
    @objc func updateOptionsView() {
        if self.hasShoppables() {
            if (self.navigationItem.titleView == nil) {
                self.navigationItem.titleView = { () -> UIView in
                    let label = UILabel()
                    label.adjustsFontSizeToFitWidth = true
                    label.minimumScaleFactor = 0.7
                    
                    var attributes = UINavigationBar.appearance().titleTextAttributes
                    attributes?[NSForegroundColorAttributeName] = UIColor.crazeGreen

                    let attributedString = NSMutableAttributedString.init(string: "Sort & Filter", attributes: attributes)
                    
                    let offset:CGFloat = 3
                    attributes?[NSBaselineOffsetAttributeName] = offset

                    let arrowString = NSAttributedString.init(string: "⌄", attributes: attributes)
                    attributedString.append(arrowString)
                    
                    
                    label.attributedText = attributedString;
                    label.sizeToFit()
                    
                    var rect = label.frame;
                    rect.origin.y -= offset;
                    label.frame = rect;
                    
                    let container = ProductsViewControllerControl.init(frame:label.bounds)
                    container.addTarget(self, action: #selector(presentOptions(_:)), for: .touchUpInside)
                    container.addSubview(label)
                    return container;
                }()
            }
        }else{
            self.navigationItem.titleView = nil;
        }
    }
    
    @objc func presentOptions(_ control:ProductsViewControllerControl){
        
        if control.isFirstResponder {
            control.resignFirstResponder()
        } else {
            AnalyticsTrackers.standard.track("Opened Filters View", properties:nil)
            let shoppable = self.shoppablesController.shoppable(at: self.shoppablesToolbar.selectedShoppableIndex())
            self.productsOptions.syncOptions(withMask: shoppable.getLast() )
            
            control.customInputView = self.productsOptions.view
            control.becomeFirstResponder()
        }
    }
    @objc func dismissOptions(){
        self.navigationItem.titleView?.endEditing(true)
    }
}

private typealias ProductsViewControllerShoppables = ProductsViewController
extension ProductsViewControllerShoppables {
    @objc func hasShoppables() -> Bool {
        return self.shoppablesController.shoppableCount() > 0
    }
    
    @objc func shoppablesControllerIsEmpty(_ controller:ShoppablesController){
        if (self.noItemsHelperView == nil) {
            self.state = .retry
        }
    }
    
    @objc func shoppablesControllerDidReload(_ controller:ShoppablesController){
        self.reloadProductsForShoppableAtIndex(self.shoppablesToolbar.selectedShoppableIndex());

    }

}
private typealias ProductsViewControllerProducts = ProductsViewController
extension ProductsViewControllerProducts{
    @objc func productAtIndex(_ index:Int) -> Product{
        return self.products[index]
    }
    
    @objc func indexForProduct(_ product:Product )-> Int {
        return self.products.index(of: product) ?? NSNotFound
    }
    
    @objc func reloadProductsForShoppableAtIndex(_ index:Int){
        
        self.products = [];
        self.productsUnfilteredCount = 0;
        
        if self.hasShoppables() {
            self.scrollRevealController.resetViewOffset()
            
            let shoppable = self.shoppablesController.shoppable(at: index)
            
            if (shoppable.productFilterCount == -1) {
                self.state = .retry;
                
            } else {
                self.products = self.productsForShoppable(shoppable)
                
                if (shoppable.productFilterCount == 0 && self.productsUnfilteredCount == 0) {
                    self.state = .loading;
                    
                } else {
                    self.state = (self.products.count == 0) ? .empty : .products;
                }
            }
            
            self.collectionView.reloadData()
            self.rateView.setRating(UInt(shoppable.getRating()), animated: false)
            
            if self.collectionView.numberOfItems(inSection: ProductsSection.tooltip.rawValue) > 0 {
                self.collectionView.scrollToItem(at: IndexPath.init(item: 0, section: ProductsSection.tooltip.rawValue), at: .top, animated: false)
                
            } else if self.collectionView.numberOfItems(inSection: ProductsSection.product.rawValue) > 0 {
                self.collectionView.scrollToItem(at: IndexPath.init(item: 0, section: ProductsSection.product.rawValue), at: .top, animated: false)
            }
            
        } else {
            self.state = .loading;
            self.collectionView.reloadData()
        }
    }
        
    @objc func productsForShoppable(_ shoppable:Shoppable) -> [Product] {
        let descriptors:[NSSortDescriptor] = {
            switch self.productsOptions.sort {
            case .similar :
                return [NSSortDescriptor.init(key: "order", ascending: true)]
            case .priceAsc :
                return [NSSortDescriptor.init(key: "floatPrice", ascending: true)]
            case .priceDes :
                return [NSSortDescriptor.init(key: "floatPrice", ascending: false)]
            case .brands :
                return [NSSortDescriptor.init(key: "displayTitle", ascending: true, selector:#selector(NSString.localizedCaseInsensitiveCompare(_:) ) ), NSSortDescriptor.init(key: "order", ascending: true)]
            }
        }()
        if let mask = shoppable.getLast()?.rawValue , var products:Set = shoppable.products?.filtered(using: NSPredicate.init(format: "(optionsMask & %d) == %d", mask, mask)) as? Set<Product> {
            self.productsUnfilteredCount = UInt(products.count)
            if self.productsOptions.sale == .sale {
                let filtered = (products as NSSet).filtered(using: NSPredicate.init(format: "floatPrice < floatOriginalPrice"))
                products = filtered as! Set<Product>
            }
            return  (((products as NSSet).allObjects as NSArray).sortedArray(using: descriptors) as? [Product]) ?? []
            
        }
        return []

    }
}
private typealias ProductsViewControllerLoader = ProductsViewController

extension ProductsViewControllerLoader {
    @objc func startAndAddLoader(){
        if self.loader == nil {
            self.loader = Loader()
            self.loader.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(self.loader)
            self.loader.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
            self.loader.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        }
        self.loader.startAnimation()
    }
    @objc func stopAndRemoveLoader(){
        if self.loader != nil {
            self.loader.stopAnimation()
            self.loader .removeFromSuperview()
            self.loader = nil
        }
    }

}

private typealias ProductsViewControllerRatings = ProductsViewController
extension ProductsViewControllerRatings {
    @objc func presentProductsRateNegativeAlert() {
        if !InAppPurchaseManager.sharedInstance.didPurchase(_inAppPurchaseProduct: .personalStylist){
            InAppPurchaseManager.sharedInstance .loadProductInfoIfNeeded()
        }
        let alertController = UIAlertController.init(title: "negativeFeedback.title".localized, message: "negativeFeedback.message".localized, preferredStyle: .alert)
        alertController.addAction(UIAlertAction.init(title: "negativeFeedback.options.sendFeedback".localized, style: .default, handler: { (a) in
            self.presentProductsRateNegativeFeedbackAlert()

        }))
        alertController.addAction(UIAlertAction.init(title: "negativeFeedback.options.fashionHelp".localized, style: .default, handler: { (a) in
            if InAppPurchaseManager.sharedInstance.didPurchase(_inAppPurchaseProduct: .personalStylist) {
                self.presentPersonalSylist()
            }else{
                if InAppPurchaseManager.sharedInstance.canPurchase() {
                   let alertController = UIAlertController.init(title: nil, message: "personalSytlistPopup.loading".localized, preferredStyle: .alert)
                    let action = UIAlertAction.init(title: "personalSytlistPopup.option.continue".localized, style: .default, handler: { (action) in
                        if let product = InAppPurchaseManager.sharedInstance.productIfAvailable(product: .personalStylist) {
                            InAppPurchaseManager.sharedInstance.buy(product: product, success: {
                                //don't present anything -  if the user stayed on the same page the bottom bar changed to 'talk to your stylist' otherwise don't do anything
                            }, failure: { (error) in
                                //no reason to present alert - Apple does it for us
                            })
                        }
                    })
                    
                    if let product = InAppPurchaseManager.sharedInstance.productIfAvailable(product: .personalStylist) {
                        action.isEnabled = true;
                        alertController.message = String.init(format: "personalSytlistPopup.canContinue".localized, product.localizedPriceString())
                    }else{
                        action.isEnabled = false;
                        InAppPurchaseManager.sharedInstance.load(product: .personalStylist, success: { (product) in
                            action.isEnabled = true;
                            alertController.message = String.init(format: "personalSytlistPopup.canContinue".localized, product.localizedPriceString())
                        }, failure: { (error) in
                            alertController.message = String.init(format: "personalSytlistPopup.error".localized, error.localizedDescription)
                        })
                        
                    }
                    alertController.addAction(action)
                    alertController.addAction(UIAlertAction.init(title: "generic.cancel".localized, style: .cancel, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                }else{
                    let errorMessage = "personalSytlistPopup.errorCannotPurchaseOnDevice".localized
                    let alertController = UIAlertController.init(title: nil, message: errorMessage, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction.init(title: "generic.ok".localized, style: .cancel, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                    
                }
            }
        }))
        alertController.addAction(UIAlertAction.init(title: "negativeFeedback.options.close".localized, style: .cancel, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    @objc func productsRatePositiveAction(){
        let shoppable = self.shoppablesController.shoppable(at: self.shoppablesToolbar.selectedShoppableIndex())
        shoppable.setRating(positive: true)
    }
    
    @objc func productsRateNegativeAction(){
        let shoppable = self.shoppablesController.shoppable(at: self.shoppablesToolbar.selectedShoppableIndex())
        shoppable.setRating(positive: false)
        self.presentProductsRateNegativeAlert()
    }
    @objc func talkToYourStylistAction(){
        IntercomHelper.sharedInstance.presentMessagingUI()
    }
    
    @objc func presentPersonalSylist() {
        let shortenedUploadedImageURL = self.screenshot.shortenedUploadedImageURL ?? ""
        AnalyticsTrackers.standard.track("Requested Custom Stylist", properties: ["screenshotImageURL" :  shortenedUploadedImageURL])
        let prefiledMessageTemplate = "I need help finding this outfit... %@"
        let prefilledMessage = String.init(format: prefiledMessageTemplate, (self.screenshot.shortenedUploadedImageURL  ?? "null"))
        IntercomHelper.sharedInstance.presentMessageComposer(withInitialMessage: prefilledMessage)
    }
    @objc func presentProductsRateNegativeFeedbackAlert() {
        let alertController = UIAlertController.init(title: "What’s Wrong Here?", message: "What were you expecting to see and what did you see instead?", preferredStyle: .alert)
        alertController.addTextField { (textField) in
            textField.delegate = self;
            textField.autocapitalizationType = .sentences
            textField.enablesReturnKeyAutomatically = true
            textField.tintColor = .crazeGreen
            self.productsRateNegativeFeedbackTextField = textField;
        }
        
        self.productsRateNegativeFeedbackSubmitAction = UIAlertAction.init(title: "Submit", style: .default, handler: { (action) in
            if let trimmedText = self.productsRateNegativeFeedbackTextField.text?.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines) {
            
                if (trimmedText.lengthOfBytes(using: .utf8) > 0) {
                    AnalyticsTrackers.segment.track("Shoppable Feedback Negative", properties:["text": trimmedText])
                }
            }
        })
        
        self.productsRateNegativeFeedbackSubmitAction.isEnabled = false
        alertController.addAction(self.productsRateNegativeFeedbackSubmitAction)

        alertController.preferredAction = self.productsRateNegativeFeedbackSubmitAction;
        alertController.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
//    @objc public func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
//        if let text = textField.text,
//            let textRange = Range(range, in: text) {
//            let updatedText = text.replacingCharacters(in: textRange, with: string)
//            let trimmedText = updatedText.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
//
//            self.productsRateNegativeFeedbackSubmitAction.isEnabled = (trimmedText.lengthOfBytes(using: .utf8) > 0)
//        }
//
//        return true
//    }
}

extension ProductsViewController {
    @objc func syncScreenshotRelatedObjects() {
        if let data = self.screenshot.imageData {
            self.image = UIImage.init(data: data as Data)
        }else{
            self.image = UIImage.init()
        }
        
        self.navigationItem.rightBarButtonItem = {
            let buttonSize:CGFloat = 32
            
            let button = UIButton.init(type: UIButtonType.custom)
            button.frame = CGRect.init(x: 0, y: 0, width: buttonSize, height: buttonSize)
            button.imageView?.contentMode = .scaleAspectFill;
            button.setImage(self.image, for: .normal)
            
            button.addTarget(self, action: #selector(displayScreenshotAction), for: .touchUpInside)
            
            button.layer.borderColor = UIColor.crazeGreen.cgColor
            button.layer.borderWidth = 1
            
            let barButtonItem = UIBarButtonItem.init(customView: button)
            button.widthAnchor.constraint(equalToConstant: button.bounds.size.width).isActive = true
            button.heightAnchor.constraint(equalToConstant: button.bounds.size.height).isActive = true
            
            
            return barButtonItem;
        }()
        
        self.shoppablesToolbar.shoppablesController = self.shoppablesController;
        self.shoppablesToolbar.screenshotImage = self.image;
    }

}

private typealias ProductsViewControllerNoItemsHelperView = ProductsViewController
extension ProductsViewControllerNoItemsHelperView{
    @objc func showNoItemsHelperView() {
        
        let verPadding = Geometry.extendedPadding
        let horPadding = Geometry.padding
        let topOffset:CGFloat = self.shoppablesToolbar.isHidden ? 0.0 : self.shoppablesToolbar.bounds.size.height
        
        let helperView = HelperView.init()
        helperView.translatesAutoresizingMaskIntoConstraints = false
        helperView.layoutMargins = UIEdgeInsets.init(top: verPadding, left: horPadding, bottom: verPadding, right: horPadding)
        helperView.titleLabel.text = "No Items Found"
        helperView.subtitleLabel.text = "No visually similar products were detected"
        helperView.contentImage = UIImage.init(named: "ProductsEmptyListGraphic")
        self.view.addSubview(helperView)
        
        helperView.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor, constant:topOffset).isActive = true
        helperView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        helperView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        helperView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        self.noItemsHelperView = helperView
        if self.state == .retry {
            
            let retryButton = MainButton.init()
            retryButton.translatesAutoresizingMaskIntoConstraints = false
            retryButton.backgroundColor = .crazeGreen
            retryButton.setTitle("Try Again", for: .normal)
            retryButton.addTarget(self, action: #selector(noItemsRetryAction), for: .touchUpInside)
            helperView.controlView.addSubview(retryButton)
            
            retryButton.topAnchor.constraint(equalTo: helperView.controlView.topAnchor).isActive = true
            retryButton.bottomAnchor.constraint(equalTo: helperView.controlView.bottomAnchor).isActive = true
            retryButton.centerXAnchor.constraint(equalTo: helperView.contentView.centerXAnchor).isActive = true
        }
    }
    
    @objc func hideNoItemsHelperView(){
        self.noItemsHelperView?.removeFromSuperview()
        self.noItemsHelperView = nil
    }
    
    @objc func noItemsRetryAction() {
        let alert = UIAlertController.init(title: "Try again as", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction.init(title: "Fashion", style: .default, handler: { (a) in
            self.shoppablesController.refetchShoppablesAsFashion()
            self.state = .loading;

        }))
        alert.addAction(UIAlertAction.init(title: "Furniture", style: .default, handler: { (a) in
                            self.shoppablesController.refetchShoppablesAsFurniture()
            self.state = .loading;

        }))
        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

