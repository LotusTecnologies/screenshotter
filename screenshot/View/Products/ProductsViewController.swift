//
//  ProductsViewController.swift
//  screenshot
//
//  Created by Jonathan Rose on 2/11/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation
import UIKit
import CoreData

enum ProductsSection : Int {
    case product = 0
    
    var section: Int {
        return self.rawValue
    }
}

enum ProductsViewControllerState : Int {
    case loading
    case products
    case retry
    case empty
}

class ProductsViewController: BaseViewController, ProductsOptionsDelegate, UIToolbarDelegate, ShoppablesToolbarDelegate {
    var screenshot:Screenshot
    var screenshotController: FetchedResultsControllerManager<Screenshot>?
    fileprivate var productsFRC: FetchedResultsControllerManager<Product>?
    
    var products:[Product] = []
    
    var loader:Loader?
    var noItemsHelperView:HelperView?
    var collectionView:UICollectionView?
    var shoppablesToolbar:ShoppablesToolbar?
    var productsOptions:ProductsOptions = ProductsOptions()
    var scrollRevealController:ScrollRevealController?
    var rateView:ProductsRateView!
    var productsRateNegativeFeedbackSubmitAction:UIAlertAction?
    var productsRateNegativeFeedbackTextField:UITextField?
    var shamrockButton : FloatingActionButton?
    var productsUnfilteredCount:Int = 0
    var state:ProductsViewControllerState = .loading {
        didSet {
            self.syncViewsAfterStateChange()
        }
    }
    var shareToDiscoverPrompt:UIView?
    fileprivate let filterView = CustomInputtableView()
    
    init(screenshot: Screenshot) {
        self.screenshot = screenshot
    
        super.init(nibName: nil, bundle: nil)
        
        self.title = "products.title".localized
        self.restorationIdentifier = "ProductsViewController"
        
        self.productsOptions.delegate = self
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "NavigationBarFilter"), style: .plain, target: self, action: #selector(presentOptions))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        screenshotController = DataModel.sharedInstance.singleScreenshotFrc(delegate: self, screenshot: screenshot)
        
        let toolbar:ShoppablesToolbar = {
            let margin:CGFloat = 8.5 // Anything other then 8 will display horizontal margin
            let shoppableHeight:CGFloat = 60
            
            let toolbar = ShoppablesToolbar.init(screenshot: self.screenshot)
            toolbar.frame = CGRect(x: 0, y: 0, width: 0, height: margin*2+shoppableHeight)
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
            return toolbar
        }()
        
        self.shoppablesToolbar = toolbar
        
        let collectionView:UICollectionView = {
            let minimumSpacing = self.collectionViewMinimumSpacing()
            
            let layout = UICollectionViewFlowLayout()
            layout.minimumInteritemSpacing = minimumSpacing.x
            layout.minimumLineSpacing = minimumSpacing.y
            
            let collectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: layout)
            
            collectionView.translatesAutoresizingMaskIntoConstraints = false
            collectionView.delegate = self
            collectionView.dataSource = self
            collectionView.contentInset = UIEdgeInsets(top: self.shoppablesToolbar?.bounds.size.height ?? 0, left: 0.0, bottom: minimumSpacing.y, right: 0.0)
            collectionView.scrollIndicatorInsets = UIEdgeInsets(top: self.shoppablesToolbar?.bounds.size.height ?? 0, left: 0.0, bottom: 0.0, right: 0.0)
            
            collectionView.backgroundColor = self.view.backgroundColor
            // TODO: set the below to interactive and comment the dismissal in -scrollViewWillBeginDragging.
            // Then test why the control view (products options view) jumps before being dragged away.
            collectionView.keyboardDismissMode = .onDrag
            collectionView.register(ProductsCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
            
            
            self.view.insertSubview(collectionView, at: 0)
            collectionView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
            collectionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
            collectionView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
            collectionView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true

            return collectionView
        }()
        self.collectionView = collectionView
        
        let rateView:ProductsRateView = {
            let view = ProductsRateView.init(frame: .zero)
            view.translatesAutoresizingMaskIntoConstraints = false
            view.voteUpButton.addTarget(self, action: #selector(productsRatePositiveAction), for: .touchUpInside)
            view.voteDownButton.addTarget(self, action: #selector(productsRateNegativeAction), for: .touchUpInside)
            view.talkToYourStylistButton.addTarget(self, action: #selector(talkToYourStylistAction), for: .touchUpInside)
            return view
        }()
        self.rateView = rateView
        
        let scrollRevealController = ScrollRevealController(edge: .bottom)
        scrollRevealController.adjustedContentInset = UIEdgeInsets(top: self.navigationController?.navigationBar.frame.maxY ?? 0, left: 0, bottom: 0, right: 0)
        scrollRevealController.insertAbove(collectionView)

        scrollRevealController.view.addSubview(rateView)
        self.scrollRevealController = scrollRevealController
        
        rateView.topAnchor.constraint(equalTo:scrollRevealController.view.topAnchor).isActive = true
        rateView.leadingAnchor.constraint(equalTo:scrollRevealController.view.leadingAnchor).isActive = true
        rateView.bottomAnchor.constraint(equalTo:scrollRevealController.view.bottomAnchor).isActive = true
        rateView.trailingAnchor.constraint(equalTo:scrollRevealController.view.trailingAnchor).isActive = true
        
        view.addSubview(filterView)
        
        var height = self.rateView.intrinsicContentSize.height

        if #available(iOS 11.0, *) {
            height += UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0
        }
        self.rateView.heightAnchor.constraint(equalToConstant: height).isActive = true
        
        if self.screenshotController?.first?.shoppablesCount == -1 {
            self.state = .retry
            Analytics.trackScreenshotOpenedWithoutShoppables(screenshot: screenshot)
        }
        else {
            self.shoppablesToolbar?.selectFirstShoppable()
        }
        
        let pinchZoom = UIPinchGestureRecognizer.init(target: self, action: #selector(pinch(gesture:)))
        self.view.addGestureRecognizer(pinchZoom)

    }
    
    @objc func pinch( gesture:UIPinchGestureRecognizer) {
        if CrazeImageZoom.shared.isHandlingGesture, let imageView = CrazeImageZoom.shared.hostedImageView  {
            CrazeImageZoom.shared.gestureStateChanged(gesture, imageView: imageView)
            return
        }
        let point = gesture.location(in: self.collectionView)
        if let collectionView = self.collectionView, let indexPath = collectionView.indexPathForItem(at: point), let cell = collectionView.cellForItem(at: indexPath) as? ProductsCollectionViewCell, let imageView = cell.productImageView {
            CrazeImageZoom.shared.gestureStateChanged(gesture, imageView: imageView)
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !self.hasShoppables() && self.noItemsHelperView == nil {
            self.state = .loading
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.shoppablesToolbar?.didViewControllerAppear = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.dismissOptions()
        hideShareToDiscoverPrompt()
    }
    
    deinit {
        self.shoppablesToolbar?.delegate = nil
        self.shoppablesToolbar?.shoppableToolbarDelegate = nil
    }
}

private typealias ProductsViewControllerScrollViewDelegate = ProductsViewController
extension ProductsViewControllerScrollViewDelegate: UIScrollViewDelegate {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.dismissOptions()
        self.scrollRevealController?.scrollViewWillBeginDragging(scrollView)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.scrollRevealController?.scrollViewDidScroll(scrollView)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        self.scrollRevealController?.scrollViewDidEndDragging(scrollView, will: decelerate)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.scrollRevealController?.scrollViewDidEndDecelerating(scrollView)
    }
}

extension ProductsViewController {
    func clearProductListAndStateLoading(){
        self.products = []
        self.productsUnfilteredCount = 0
        self.state = .loading
        self.collectionView?.reloadData()
    }
    func productsOptionsDidComplete(_ productsOptions: ProductsOptions, withChange changed: Bool) {
        
        if changed {
            if  let shoppable = self.shoppablesToolbar?.selectedShoppable(){
                shoppable.set(productsOptions: productsOptions, callback:  {
                    if  let shoppable = self.shoppablesToolbar?.selectedShoppable(){
                        self.reloadProductsFor(shoppable: shoppable)
                    }else{
                        self.clearProductListAndStateLoading()
                    }
                })
            }
        }
        self.dismissOptions()
    }
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
    
    func shoppablesToolbarDidChange(toolbar: ShoppablesToolbar) {
        if self.isViewLoaded  {
            if  let selectedShoppable = self.shoppablesToolbar?.selectedShoppable(){
                if let currentShoppable = self.products.first?.shoppable, currentShoppable == selectedShoppable {
                    //already synced
                }else{
                    self.reloadProductsFor(shoppable: selectedShoppable)
                }
            }else{
                clearProductListAndStateLoading()
            }
        }
    }
    
    func shoppablesToolbarDidChangeSelectedShoppable(toolbar:ShoppablesToolbar, shoppable:Shoppable){
        self.reloadProductsFor(shoppable: shoppable)
    }
    
    func shouldHideToolbar()->Bool{
        return !self.hasShoppables()
    }
    
}

private typealias ProductsViewControllerCollectionView = ProductsViewController
extension ProductsViewControllerCollectionView : UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    var numberOfCollectionViewProductColumns: Int {
        return 2
    }
    
    func productSectionType(forSection:Int) -> ProductsSection {
        return ProductsSection(rawValue: forSection) ?? .product
    }
    
    func collectionViewToShoppablesFrcIndexPath(_ index:Int) ->IndexPath {
        return IndexPath(item: index, section: 0)
    }
    
    func shoppablesFrcToCollectionViewIndexPath(_ index:Int) -> IndexPath {
        return IndexPath(item: index, section: ProductsSection.product.section)
    }
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionType = productSectionType(forSection: section)
        if sectionType == .product {
            return self.products.count
            
        } else {
            return 0
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        var size:CGSize = .zero
        let shadowInsets = ScreenshotCollectionViewCell.shadowInsets
        let padding: CGFloat = .padding - shadowInsets.left - shadowInsets.right
        let sectionType = productSectionType(forSection: indexPath.section)

        if sectionType == .product {
            let columns = CGFloat(numberOfCollectionViewProductColumns)
            size.width = floor((collectionView.bounds.size.width - (padding * (columns + 1))) / columns)
            size.height = ProductsCollectionViewCell.cellHeight(for: size.width, withBottomLabel: true)
        }
        
        return size
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let sectionType = productSectionType(forSection: indexPath.section)

        if sectionType == .product {
            let product = self.productAtIndex(indexPath.item)
            
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? ProductsCollectionViewCell {
                cell.contentView.backgroundColor = collectionView.backgroundColor
                cell.title = product.calculatedDisplayTitle
                cell.price = product.price
                cell.originalPrice = product.originalPrice
                cell.imageUrl = product.imageURL
                cell.isSale = product.isSale()
                cell.favoriteControl.isSelected = product.isFavorite
                cell.favoriteControl.addTarget(self, action: #selector(productCollectionViewCellFavoriteAction(_:event:)), for: .touchUpInside)
                cell.hasBuyLabel = true
                cell.hasExternalPreview = (product.partNumber == nil)
                return cell
            }
        }
        
        return UICollectionViewCell()
    }
    
    public func collectionViewMinimumSpacing() -> CGPoint {
        let shadowInsets = ScreenshotCollectionViewCell.shadowInsets
        let p: CGFloat = .padding
        return CGPoint(x: p - shadowInsets.left - shadowInsets.right, y: p - shadowInsets.top - shadowInsets.bottom)
    }
    
    public func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let sectionType = productSectionType(forSection: section)

        if sectionType == .product {
            let minimumSpacing:CGPoint = self.collectionViewMinimumSpacing()
            return UIEdgeInsets(top: minimumSpacing.y, left: minimumSpacing.x, bottom: 0.0, right: minimumSpacing.x)
        } else {
            return .zero
        }
    }
   
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let sectionType = productSectionType(forSection: indexPath.section)

        if sectionType == .product {
            let product = self.productAtIndex(indexPath.item)
            product.recordViewedProduct()
            
            if let productViewController = presentProduct(product, atLocation: .products) {
                productViewController.similarProducts = products
            }
        }
    }
    
    @objc func productCollectionViewCellFavoriteAction(_ favoriteControl: FavoriteControl, event: UIEvent) {
        guard let indexPath = collectionView?.indexPath(for: event) else {
            return
        }
        
        let isFavorited = favoriteControl.isSelected
        let product = self.productAtIndex(indexPath.item)
        
        product.setFavorited(toFavorited: isFavorited)
        if isFavorited {
            Analytics.trackProductFavorited(product: product, page: .productList)
        }else{
            Analytics.trackProductUnfavorited(product: product, page: .productList)
        }
    }
}

private typealias ProductsViewControllerOptionsView = ProductsViewController
extension ProductsViewControllerOptionsView {
    @objc func presentOptions() {
        if filterView.isFirstResponder {
            filterView.resignFirstResponder()
        }
        else {
            Analytics.trackOpenedFiltersView()
            
            if let shoppable = self.shoppablesToolbar?.selectedShoppable() {
                self.productsOptions.syncOptions(withMask: shoppable.getLast())
            }
            filterView.customInputView = self.productsOptions.view
            filterView.becomeFirstResponder()
        }
    }
    
    func dismissOptions() {
        filterView.endEditing(true)
    }
}

private typealias ProductsViewControllerShoppables = ProductsViewController
extension ProductsViewControllerShoppables: FetchedResultsControllerManagerDelegate {
    func managerDidChangeContent(_ controller: NSObject, change: FetchedResultsControllerManagerChange) {
        if controller == self.screenshotController {
            if let screenShot = self.screenshotController?.first {
                if screenShot.shoppablesCount == 0 {
                    
                }else if screenShot.shoppablesCount == -1 {
                    if self.noItemsHelperView == nil {
                        self.state = .retry
                    }
                }
            }
        }
        else if controller == productsFRC {
            if view.window == nil, let collectionView = collectionView {
                collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
            }
        }
    }
    
    func hasShoppables() -> Bool {
        return (self.shoppablesToolbar?.shoppablesController.fetchedObjectsCount ?? 0 ) > 0
    }
}

private typealias ProductsViewControllerProducts = ProductsViewController
extension ProductsViewControllerProducts{
    func productAtIndex(_ index: Int) -> Product {
        return self.products[index]
    }
    
    func indexForProduct(_ product: Product) -> Int? {
        return self.products.index(of: product)
    }
    
    func reloadProductsFor(shoppable:Shoppable) {
        self.products = []
        self.productsUnfilteredCount = 0
        self.scrollRevealController?.resetViewOffset()
        
        if shoppable.productFilterCount == -1 {
            self.state = .retry
        } else {
            self.products = self.productsForShoppable(shoppable)
            
            if shoppable.productFilterCount == 0 && self.productsUnfilteredCount == 0 {
                self.state = .loading
            } else {
                self.state = (self.products.count == 0) ? .empty : .products
            }
        }
        
        self.collectionView?.reloadData()
        self.rateView.setRating(UInt(shoppable.getRating()), animated: false)
        
        productsFRC = DataModel.sharedInstance.productFrc(delegate: self, shoppableOID: shoppable.objectID)
        
        if self.collectionView?.numberOfItems(inSection: ProductsSection.product.section) ?? 0 > 0 {
            self.collectionView?.scrollToItem(at: IndexPath(item: 0, section: ProductsSection.product.section), at: .top, animated: false)
        }
    }
    
    func productsForShoppable(_ shoppable:Shoppable) -> [Product] {
        if let mask = shoppable.getLast()?.rawValue,
          var products = shoppable.products?.filtered(using: NSPredicate(format: "(optionsMask & %d) == %d", mask, mask)) as? Set<Product> {
            self.productsUnfilteredCount = products.count
            if self.productsOptions.sale == .sale {
                products = products.filter { $0.floatPrice < $0.floatOriginalPrice }
            }
            let productArray: [Product]
            switch self.productsOptions.sort {
            case .similar :
                productArray = products.sorted { $0.order < $1.order }
            case .priceAsc :
                productArray = products.sorted { $0.floatPrice < $1.floatPrice }
            case .priceDes :
                productArray = products.sorted(by: { $0.floatPrice > $1.floatPrice })
            case .brands :
                productArray = products.sorted { (a, b) -> Bool in
                    if let aDisplayTitle = a.calculatedDisplayTitle?.lowercased(),
                      let bDisplayTitle = b.calculatedDisplayTitle?.lowercased(),
                      aDisplayTitle != bDisplayTitle {
                        return aDisplayTitle < bDisplayTitle
                    } else if a.calculatedDisplayTitle == nil && b.calculatedDisplayTitle != nil {
                        return false // Empty brands at end
                    } else if a.calculatedDisplayTitle != nil && b.calculatedDisplayTitle == nil {
                        return true // Empty brands at end
                    }
                    return a.order < b.order // Secondary sort
                }
            }
            return productArray
        }
        
        return []
    }
}

private typealias ProductsViewControllerLoader = ProductsViewController
extension ProductsViewControllerLoader {
    
    func startAndAddLoader() {
        let loader = self.loader ?? ( {
            let loader = Loader()
            loader.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(loader)
            loader.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
            loader.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
            
            
            return loader
        }())
        self.loader = loader
        loader.startAnimation()
    }
    
    func stopAndRemoveLoader() {
        if let loader = self.loader {
            loader.stopAnimation()
            loader.removeFromSuperview()
            self.loader = nil
        }
    }
    
}

private typealias ProductsViewControllerRatings = ProductsViewController
extension ProductsViewControllerRatings: UITextFieldDelegate {
    
    func presentProductsRateNegativeAlert() {
        if !InAppPurchaseManager.sharedInstance.didPurchase(_inAppPurchaseProduct: .personalStylist) {
            InAppPurchaseManager.sharedInstance .loadProductInfoIfNeeded()
        }
        let alertController = UIAlertController(title: "negative_feedback.title".localized, message: "negative_feedback.message".localized, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "negative_feedback.options.send".localized, style: .default, handler: { (a) in
            self.presentProductsRateNegativeFeedbackAlert()
        }))
        alertController.addAction(UIAlertAction(title: "negative_feedback.options.help".localized, style: .default, handler: { (a) in
            if InAppPurchaseManager.sharedInstance.didPurchase(_inAppPurchaseProduct: .personalStylist) {
                self.presentPersonalStylist()
            } else {
                if InAppPurchaseManager.sharedInstance.canPurchase() {
                    let alertController = UIAlertController(title: nil, message: "personal_stylist.loading".localized, preferredStyle: .alert)
                    let action = UIAlertAction(title: "generic.continue".localized, style: .default, handler: { (action) in
                        if let product = InAppPurchaseManager.sharedInstance.productIfAvailable(product: .personalStylist) {
                            InAppPurchaseManager.sharedInstance.buy(product: product, success: {
                                //don't present anything -  if the user stayed on the same page the bottom bar changed to 'talk to your stylist' otherwise don't do anything
                            }, failure: { (error) in
                                //no reason to present alert - Apple does it for us
                            })
                        }
                    })
                    
                    if let product = InAppPurchaseManager.sharedInstance.productIfAvailable(product: .personalStylist) {
                        action.isEnabled = true
                        alertController.message = String(format: "personal_stylist.unlock".localized, product.localizedPriceString())
                    } else {
                        action.isEnabled = false
                        InAppPurchaseManager.sharedInstance.load(product: .personalStylist, success: { (product) in
                            action.isEnabled = true
                            alertController.message = String(format: "personal_stylist.unlock".localized, product.localizedPriceString())
                        }, failure: { (error) in
                            alertController.message = String(format: "personal_stylist.error".localized, error.localizedDescription)
                        })
                        
                    }
                    alertController.addAction(action)
                    alertController.addAction(UIAlertAction(title: "generic.cancel".localized, style: .cancel, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                }else{
                    let errorMessage = "personal_stylist.error.invalid_device".localized
                    let alertController = UIAlertController(title: nil, message: errorMessage, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "generic.ok".localized, style: .cancel, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                    
                }
            }
        }))
        alertController.addAction(UIAlertAction(title: "generic.cancel".localized, style: .cancel, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    @objc func productsRatePositiveAction() {
        if  let shoppable = self.shoppablesToolbar?.selectedShoppable(){
            shoppable.setRating(positive: true)
            
            if self.screenshot.canSubmitToDiscover {
                let sharePrompt = ShareToDiscoverPrompt.init()
                sharePrompt.translatesAutoresizingMaskIntoConstraints = false
                sharePrompt.alpha = 0
                self.view.addSubview(sharePrompt)
                sharePrompt.addButton.addTarget(self, action: #selector(submitToDiscoverAndPresentThankYouForSharingView), for: .touchUpInside)
                sharePrompt.closeButton.addTarget(self, action: #selector(hideShareToDiscoverPrompt), for: .touchUpInside)
                sharePrompt.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
                sharePrompt.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier:0.9).isActive = true
                sharePrompt.bottomAnchor.constraint(equalTo: self.rateView.topAnchor, constant: 0).isActive = true
                self.shareToDiscoverPrompt = sharePrompt
                
                UIView.animate(withDuration: .defaultAnimationDuration, animations: {
                    sharePrompt.alpha = 1
                    self.shamrockButton?.alpha = 0
                })
            }
        }
    }
    
    @objc func productsRateNegativeAction() {
        if  let shoppable = self.shoppablesToolbar?.selectedShoppable(){
            shoppable.setRating(positive: false)
            self.presentProductsRateNegativeAlert()
        }
    }
    
    @objc func talkToYourStylistAction() {
        IntercomHelper.sharedInstance.presentMessagingUI()
    }
    
    func presentPersonalStylist() {
        let shoppable = self.shoppablesToolbar?.selectedShoppable()
        Analytics.trackRequestedCustomStylist(shoppable: shoppable)
        let prefiledMessageTemplate = "products.rate.negative.help_finding_outfit".localized
        let prefilledMessage = String(format: prefiledMessageTemplate, (self.screenshot.shortenedUploadedImageURL ?? "null"))
        IntercomHelper.sharedInstance.presentMessageComposer(withInitialMessage: prefilledMessage)
    }
    
    func presentProductsRateNegativeFeedbackAlert() {
        let alertController = UIAlertController(title: "products.rate.negative.popup.title".localized, message: "products.rate.negative.popup.message".localized, preferredStyle: .alert)
        alertController.addTextField { (textField) in
            textField.delegate = self
            textField.autocapitalizationType = .sentences
            textField.enablesReturnKeyAutomatically = true
            textField.tintColor = .crazeGreen
            self.productsRateNegativeFeedbackTextField = textField
        }
        
        let productsRateNegativeFeedbackSubmitAction = UIAlertAction(title: "generic.submit".localized, style: .default, handler: { (action) in
            if let trimmedText = self.productsRateNegativeFeedbackTextField?.text?.trimmingCharacters(in: .whitespacesAndNewlines) {
                
                if trimmedText.lengthOfBytes(using: .utf8) > 0 {
                    let shoppable = self.shoppablesToolbar?.selectedShoppable()
                    Analytics.trackShoppableFeedbackNegative(shoppable:shoppable , text: trimmedText)
                }
            }
        })
        
        productsRateNegativeFeedbackSubmitAction.isEnabled = false
        alertController.addAction(productsRateNegativeFeedbackSubmitAction)
        self.productsRateNegativeFeedbackSubmitAction = productsRateNegativeFeedbackSubmitAction
        alertController.preferredAction = self.productsRateNegativeFeedbackSubmitAction
        alertController.addAction(UIAlertAction(title: "generic.cancel".localized, style: .cancel, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        var isEnabled = false
        if let text = textField.text,
            let textRange = Range(range, in: text) {
            let updatedText = text.replacingCharacters(in: textRange, with: string)
            let trimmedText = updatedText.trimmingCharacters(in: .whitespaces)
            
            if trimmedText.lengthOfBytes(using:.utf8) > 0 {
                isEnabled = true
            }
        }
        
        self.productsRateNegativeFeedbackSubmitAction?.isEnabled = isEnabled
        
        return true
    }
}

typealias ProductsViewControllerShareToDiscoverPrompt = ProductsViewController
extension ProductsViewControllerShareToDiscoverPrompt {
    @objc func hideShareToDiscoverPrompt (){
        UIView.animate(withDuration: .defaultAnimationDuration, animations: {
            self.shareToDiscoverPrompt?.alpha = 0
            self.shamrockButton?.alpha = 1
        }) { completed in
            self.shareToDiscoverPrompt?.removeFromSuperview()
            self.shareToDiscoverPrompt = nil
        }
    }
    
    @objc func submitToDiscoverAndPresentThankYouForSharingView() {
        self.hideShareToDiscoverPrompt()
        
        self.screenshot.submitToDiscover()
        
        let thankYou = ThankYouForSharingViewController()
        thankYou.closeButton.addTarget(self, action: #selector(thankYouForSharingViewDidClose(_:)), for: .touchUpInside)
        self.present(thankYou, animated: true, completion: nil)
    }
    
    @objc func thankYouForSharingViewDidClose(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension ProductsViewController {
    func syncViewsAfterStateChange() {
        self.shoppablesToolbar?.isHidden = self.shouldHideToolbar()
        
        switch (state) {
        case .loading:
            self.hideNoItemsHelperView()
            self.rateView.isHidden = true
            self.startAndAddLoader()
            
        case .products:
            if #available(iOS 11.0, *) {} else {
                if !self.automaticallyAdjustsScrollViewInsets {
                    // Setting back to YES doesn't update. Need to manually adjust.
                    if let collectionView = collectionView, let shoppablesToolbar = self.shoppablesToolbar {
                        var scrollInsets = collectionView.scrollIndicatorInsets
                        scrollInsets.top = shoppablesToolbar.bounds.size.height + (self.navigationController?.navigationBar.frame.maxY ?? 0)
                        collectionView.scrollIndicatorInsets = scrollInsets
                        
                        var insets = collectionView.contentInset
                        insets.top = scrollInsets.top
                        collectionView.contentInset = insets
                    }
                }
            }
            
            self.stopAndRemoveLoader()
            self.hideNoItemsHelperView()
            self.rateView.isHidden = false
            
        case .retry, .empty:
            if #available(iOS 11.0, *) {} else {
                self.automaticallyAdjustsScrollViewInsets = false
            }
            
            self.stopAndRemoveLoader()
            self.rateView.isHidden = true
            self.hideNoItemsHelperView()
            self.showNoItemsHelperView()
        }
    }
}

private typealias ProductsViewControllerNoItemsHelperView = ProductsViewController
extension ProductsViewControllerNoItemsHelperView{
    
    func showNoItemsHelperView() {
        let verPadding: CGFloat = .extendedPadding
        let horPadding: CGFloat = .padding
        var topOffset: CGFloat = 0
        
        if let shoppablesToolbar = self.shoppablesToolbar, !shoppablesToolbar.isHidden {
            topOffset = shoppablesToolbar.bounds.size.height
        }
        
        let helperView = HelperView()
        helperView.translatesAutoresizingMaskIntoConstraints = false
        helperView.layoutMargins = UIEdgeInsets(top: verPadding, left: horPadding, bottom: verPadding, right: horPadding)
        helperView.titleLabel.text = "products.helper.title".localized
        helperView.subtitleLabel.text = "products.helper.message".localized
        helperView.contentImage = UIImage(named: "ProductsEmptyListGraphic")
        self.view.addSubview(helperView)
        
        helperView.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor, constant:topOffset).isActive = true
        helperView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        helperView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        helperView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        self.noItemsHelperView = helperView
        
        if self.state == .retry {
            let retryButton = MainButton()
            retryButton.translatesAutoresizingMaskIntoConstraints = false
            retryButton.backgroundColor = .crazeGreen
            retryButton.setTitle("products.helper.retry".localized, for: .normal)
            retryButton.addTarget(self, action: #selector(noItemsRetryAction), for: .touchUpInside)
            helperView.controlView.addSubview(retryButton)
            retryButton.topAnchor.constraint(equalTo: helperView.controlView.topAnchor).isActive = true
            retryButton.leadingAnchor.constraint(greaterThanOrEqualTo: helperView.controlView.layoutMarginsGuide.leadingAnchor).isActive = true
            retryButton.bottomAnchor.constraint(equalTo: helperView.controlView.bottomAnchor).isActive = true
            retryButton.trailingAnchor.constraint(greaterThanOrEqualTo: helperView.controlView.layoutMarginsGuide.trailingAnchor).isActive = true
            retryButton.centerXAnchor.constraint(equalTo: helperView.contentView.centerXAnchor).isActive = true
        }
    }
    
    func hideNoItemsHelperView() {
        self.noItemsHelperView?.removeFromSuperview()
        self.noItemsHelperView = nil
    }
    
    @objc func noItemsRetryAction() {
        let alert = UIAlertController(title: "products.helper.retry.title".localized, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "products.helper.retry.fashion".localized, style: .default, handler: { (a) in
            AssetSyncModel.sharedInstance.refetchShoppables(screenshot: self.screenshot, classificationString: "h")
            self.state = .loading
        }))
        alert.addAction(UIAlertAction(title: "products.helper.retry.furniture".localized, style: .default, handler: { (a) in
            AssetSyncModel.sharedInstance.refetchShoppables(screenshot: self.screenshot, classificationString: "f")
            self.state = .loading
        }))
        alert.addAction(UIAlertAction(title: "generic.cancel".localized, style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
