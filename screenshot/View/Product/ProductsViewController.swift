//
//  ProductsViewController.swift
//  screenshot
//
//  Created by Jonathan Rose on 2/11/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation

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
    @objc func setupRatingView(){
//        self.rateView = {
//            let view = ProductsRateView.init()
//            view.translatesAutoresizingMaskIntoConstraints = false
//            view.voteUpButton.add
//            [view.voteUpButton addTarget:self action:@selector(productsRatePositiveAction) forControlEvents:UIControlEventTouchUpInside];
//            [view.voteDownButton addTarget:self action:@selector(productsRateNegativeAction) forControlEvents:UIControlEventTouchUpInside];
//            [view.talkToYourStylistButton addTarget:self action:@selector(talkToYourStylistAction) forControlEvents:UIControlEventTouchUpInside];
//            
//            return view;
//        }()
    }
}
private typealias ProductsViewControllerProducts = ProductsViewController
extension ProductsViewControllerProducts{
    @objc func productsForShoppable(shoppable:Shoppable) -> [Product] {
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
            return []
        }()
        if let mask = shoppable.getLast()?.rawValue , var products:Set = shoppable.products?.filtered(using: NSPredicate.init(format: "(optionsMask & %d) == %d", mask, mask)) as? Set<Product> {
            self.productsUnfilteredCount = UInt(products.count)
            if self.productsOptions.sale == .sale {
                products = products.filter({ (p) -> Bool in  return p.floatPrice < p.floatOriginalPrice})
            }
            return  (((products as NSSet).allObjects as NSArray).sortedArray(using: descriptors) as? [Product]) ?? []
            
        }
        return []

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
                                self.presentPersonalSylist()
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
