//
//  ProductsViewController.swift
//  screenshot
//
//  Created by Jonathan Rose on 2/11/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import PromiseKit
import Hero

enum ProductsSection : Int {
    case product = 0
    case relatedLooks = 1
    case productHeader = -1
    case error = -2
    var section: Int {
        return self.rawValue
    }
}

enum ProductsViewControllerState : Int {
    case loading
    case products
    case retry
    case unknown
}

class ProductsViewController: BaseViewController {
    var productCollectionViewManager = ProductCollectionViewManager()
    var screenshot:Screenshot
    var screenshotController: FetchedResultsControllerManager<Screenshot>?
    fileprivate var productsFRC: FetchedResultsControllerManager<Product>?
    let recoverLostSaleManager = RecoverLostSaleManager()
    var products:[Product] = []
    var relatedLooksManager = RelatedLooksManager()
    
    var noItemsHelperView:HelperView?
    var collectionView:UICollectionView?
    var productsOptions:ProductsOptions = ProductsOptions()
    var scrollRevealController:ScrollRevealController?
    var rateView = ProductsRateView.init(frame: .zero)
    var productsRateNegativeFeedbackSubmitAction:UIAlertAction?
    var productsRateNegativeFeedbackTextField:UITextField?
    var shamrockButton : FloatingActionButton?
    var screenshotLoadingState:ProductsViewControllerState = .unknown {
        didSet {
            Analytics.trackDevLog(file: #file, line: #line, message: "from\(oldValue) to \(screenshotLoadingState)")            
        }
    }
    var productLoadingState:ProductsViewControllerState = .unknown 

    var selectedShoppable:Shoppable?

    func getSelectedShoppable() -> Shoppable? {
        if let s = selectedShoppable {
            return s
        } else if let toolbar = shoppablesToolbar {
            let s = toolbar.selectedShoppable()
            selectedShoppable = s
            return s
        }
        
        return nil
    }
    
    var shareToDiscoverPrompt:UIView?
    
    fileprivate var shoppablesToolbar: ShoppablesToolbar?
    
    var loadingMonitor:AsyncOperationMonitor?
    var productsLoadingMonitor:AsyncOperationMonitor?

    init(screenshot: Screenshot) {
        self.screenshot = screenshot
        super.init(nibName: nil, bundle: nil)
        
        self.loadingMonitor = AsyncOperationMonitor.init(assetId: screenshot.assetId, shoppableId:nil, queues: AssetSyncModel.sharedInstance.queues, delegate: self)

        self.title = "products.title".localized
        self.restorationIdentifier = "ProductsViewController"
        
        self.productsOptions.delegate = self
        recoverLostSaleManager.delegate = self
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "NavigationBarFilter"), style: .plain, target: self, action: #selector(presentOptions))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.relatedLooksManager.delegate = self
        screenshotController = DataModel.sharedInstance.singleScreenshotFrc(delegate: self, screenshot: screenshot)
        
        let shoppablesToolbar: ShoppablesToolbar = {
            let toolbar = ShoppablesToolbar(screenshot: screenshot)
            toolbar.translatesAutoresizingMaskIntoConstraints = false
            toolbar.isHidden = shouldHideToolbar
            toolbar.delegate = self
            toolbar.shoppableToolbarDelegate = self
            view.addSubview(toolbar)
            toolbar.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
            return toolbar
        }()
        self.shoppablesToolbar = shoppablesToolbar
        
        let collectionView:UICollectionView = {
            let minimumSpacing = self.collectionViewMinimumSpacing()
            
            let layout = SectionBackgroundCollectionViewFlowLayout()
            layout.minimumInteritemSpacing = minimumSpacing.x
            layout.minimumLineSpacing = minimumSpacing.y
            
            let collectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: layout)
            collectionView.translatesAutoresizingMaskIntoConstraints = false
            collectionView.delegate = self
            collectionView.dataSource = self
            collectionView.contentInset = UIEdgeInsets(top: self.shoppablesToolbar?.intrinsicContentSize.height ?? 0, left: 0.0, bottom: minimumSpacing.y, right: 0.0)
            collectionView.scrollIndicatorInsets = UIEdgeInsets(top: self.shoppablesToolbar?.intrinsicContentSize.height ?? 0, left: 0.0, bottom: 0.0, right: 0.0)
            collectionView.backgroundColor = self.view.backgroundColor
            // TODO: set the below to interactive and comment the dismissal in -scrollViewWillBeginDragging.
            // Then test why the control view (products options view) jumps before being dragged away.
            collectionView.keyboardDismissMode = .onDrag
            self.productCollectionViewManager.setup(collectionView: collectionView)

            
            self.view.insertSubview(collectionView, at: 0)
            collectionView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
            collectionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
            collectionView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
            collectionView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true

            return collectionView
        }()
        self.collectionView = collectionView
        
        rateView.translatesAutoresizingMaskIntoConstraints = false
        rateView.voteUpButton.addTarget(self, action: #selector(productsRatePositiveAction), for: .touchUpInside)
        rateView.voteDownButton.addTarget(self, action: #selector(productsRateNegativeAction), for: .touchUpInside)
        
        let scrollRevealController = ScrollRevealController(edge: .bottom)
        scrollRevealController.hasBottomBar = !hidesBottomBarWhenPushed
        scrollRevealController.adjustedContentInset = {
            let top = navigationController?.navigationBar.frame.maxY ?? 0
            var bottom = tabBarController?.tabBar.bounds.height ?? 0
            
            if !scrollRevealController.hasBottomBar {
                bottom = 0
            }
            
            return UIEdgeInsets(top: top, left: 0, bottom: bottom, right: 0)
        }()
        scrollRevealController.insertAbove(collectionView)

        scrollRevealController.view.addSubview(rateView)
        self.scrollRevealController = scrollRevealController
        
        rateView.topAnchor.constraint(equalTo:scrollRevealController.view.topAnchor).isActive = true
        rateView.leadingAnchor.constraint(equalTo:scrollRevealController.view.leadingAnchor).isActive = true
        rateView.bottomAnchor.constraint(equalTo:scrollRevealController.view.bottomAnchor).isActive = true
        rateView.trailingAnchor.constraint(equalTo:scrollRevealController.view.trailingAnchor).isActive = true
        
        if !scrollRevealController.hasBottomBar {
            var height = self.rateView.intrinsicContentSize.height
            
            if #available(iOS 11.0, *) {
                height += UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0
            }
            self.rateView.heightAnchor.constraint(equalToConstant: height).isActive = true
        }
        
        if self.screenshotController?.first?.shoppablesCount == -1 {
            self.screenshotLoadingState = .retry
            syncViewsAfterStateChange()
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
        if let collectionView = self.collectionView, let indexPath = collectionView.indexPathForItem(at: point),  let cell = collectionView.cellForItem(at: indexPath){
            
            if let cell = cell as? ProductsCollectionViewCell, let imageView = cell.productImageView {
                CrazeImageZoom.shared.gestureStateChanged(gesture, imageView: imageView)
            }else if let cell = cell as? RelatedLooksCollectionViewCell {
                let imageView = cell.imageView
                CrazeImageZoom.shared.gestureStateChanged(gesture, imageView: imageView)
            }
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.updateLoadingState()
        self.collectionView?.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.shoppablesToolbar?.didViewControllerAppear = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let _ = self.presentedViewController as? ProductsOptionsViewController {
            self.dismissOptions()
        }
        
        hideShareToDiscoverPrompt()
    }
    
    deinit {
        self.shoppablesToolbar?.delegate = nil
        self.shoppablesToolbar?.shoppableToolbarDelegate = nil
    }
}

extension ProductsViewController: UIToolbarDelegate {
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .top
    }
}

private typealias ProductsViewControllerScrollViewDelegate = ProductsViewController
extension ProductsViewControllerScrollViewDelegate: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.dismissOptions()
        self.scrollRevealController?.scrollViewWillBeginDragging(scrollView)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.relatedLooksManager.scrollViewDidScroll(scrollView)
        
        self.scrollRevealController?.scrollViewDidScroll(scrollView)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        self.scrollRevealController?.scrollViewDidEndDragging(scrollView, will: decelerate)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.scrollRevealController?.scrollViewDidEndDecelerating(scrollView)
    }
}

extension ProductsViewController: ShoppablesToolbarDelegate {
    func shoppablesToolbarDidChange(toolbar: ShoppablesToolbar) {
        if self.isViewLoaded  {
            if let selectedShoppable = self.getSelectedShoppable(){
                if let currentShoppable = self.products.first?.shoppable, currentShoppable == selectedShoppable {
                    //already synced
                }else{
                    self.reloadProductsFor(shoppable: selectedShoppable)
                }
                if let p = self.productsLoadingMonitor {
                    p.delegate = nil
                }
                self.productsLoadingMonitor = AsyncOperationMonitor.init(assetId: nil, shoppableId: selectedShoppable.offersURL, queues: AssetSyncModel.sharedInstance.queues, delegate: self)
                self.updateLoadingState()
                
            }else{
                clearProductListAndStateLoading()
            }
        }
    }
    
    func shoppablesToolbarDidChangeSelectedShoppable(toolbar:ShoppablesToolbar, shoppable:Shoppable){
        self.selectedShoppable = shoppable
        if let p = self.productsLoadingMonitor {
            p.delegate = nil
        }
        self.productsLoadingMonitor = AsyncOperationMonitor.init(assetId: nil, shoppableId: shoppable.offersURL, queues: AssetSyncModel.sharedInstance.queues, delegate: self)
        self.reloadProductsFor(shoppable: shoppable)
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
    func sectionIndex(forProductType:ProductsSection) -> Int {
        return forProductType.rawValue
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
        return productSectionType(forSection: section) == .product ? self.products.count : self.relatedLooksManager.numberOfItems()
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let sectionType = productSectionType(forSection: section)

        if sectionType == .relatedLooks {
            if self.relatedLooksManager.numberOfItems() > 0 {
                return CGSize.init(width: collectionView.bounds.size.width, height: 80)
            }
        }
        
        return .zero;
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        var sectionType = productSectionType(forSection: indexPath.section)
        if sectionType == .relatedLooks {
            if self.relatedLooksManager.relatedLooks?.value == nil {
                sectionType = .error
            }
        }
        return self.productCollectionViewManager.collectionView(collectionView, sizeForItemInSectionType: sectionType)
    }
    
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let sectionType = productSectionType(forSection: indexPath.section)
        if kind == UICollectionElementKindSectionHeader {
            
            if sectionType == .relatedLooks {
                return self.productCollectionViewManager.collectionView(collectionView, viewForHeaderWith:  "products.related_looks.headline".localized, hasBackgroundAndLine:true, hasFilterButton:false, indexPath: indexPath)
            }
            
            return self.productCollectionViewManager.collectionView(collectionView, viewForHeaderWith:  "",hasBackgroundAndLine:false, hasFilterButton:false, indexPath: indexPath)
        }else if kind == SectionBackgroundCollectionViewFlowLayout.ElementKindSectionSectionBackground {
            if sectionType == .product {
                return self.productCollectionViewManager.collectionView(collectionView, viewForBackgroundWith: self.view.backgroundColor, indexPath: indexPath)
            }else if sectionType == .relatedLooks{
                if let image = UIImage.init(named: "confetti") {
                    let confettiColor = UIColor.init(patternImage: image )
                    return self.productCollectionViewManager.collectionView(collectionView, viewForBackgroundWith: confettiColor, indexPath: indexPath)
                }
            }
            return self.productCollectionViewManager.collectionView(collectionView, viewForBackgroundWith: .white, indexPath: indexPath)
            
        }
        return UICollectionReusableView()
        
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let sectionType = productSectionType(forSection: indexPath.section)

        if sectionType == .product {
            let product = self.productAtIndex(indexPath.item)
            let cell = self.productCollectionViewManager.collectionView(collectionView, cellForItemAt: indexPath, with: product)
            if let cell = cell as? ProductsCollectionViewCell {
                cell.favoriteControl.addTarget(self, action: #selector(productCollectionViewCellFavoriteAction(_:event:)), for: .touchUpInside)
                cell.actionButton.addTarget(self, action: #selector(productCollectionViewCellBurrowAction(_:event:)), for: .touchUpInside)
                return cell
            }
            return cell
        }else if sectionType == .relatedLooks {
             return self.relatedLooksManager.collectionView(collectionView, cellForItemAt: indexPath)
           
            
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
            return UIEdgeInsets(top: minimumSpacing.y, left: minimumSpacing.x, bottom: 30, right: minimumSpacing.x)
        }else if sectionType == .relatedLooks {
            if self.relatedLooksManager.hasInset() {
                let minimumSpacing:CGPoint = self.collectionViewMinimumSpacing()
                return UIEdgeInsets(top: 0, left: minimumSpacing.x, bottom: 30.0, right: minimumSpacing.x)
            }else{
                return .zero

            }
        }
        
        return .zero
        
    }
   
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let sectionType = productSectionType(forSection: indexPath.section)

        if sectionType == .product {
            let product = self.productAtIndex(indexPath.item)
            product.recordViewedProduct()
            self.recoverLostSaleManager.didClick(on: product)
            LocalNotificationModel.shared.registerCrazeTappedPriceAlert(id: product.id, merchant: product.merchant, lastPrice: product.floatPrice)
            if let productViewController = presentProduct(product, atLocation: .products) {
                productViewController.similarProducts = products
            }
        }
        else if sectionType == .relatedLooks {
            if let url = self.relatedLooksManager.relatedLook(at:indexPath.row) {
                Analytics.trackScreenshotRelatedLookAdd(url: url)
                AssetSyncModel.sharedInstance.addFromRelatedLook(urlString: url, callback: { (screenshot) in
                    Analytics.trackOpenedScreenshot(screenshot: screenshot, source: .relatedLooks)
                    let productsViewController = ProductsViewController.init(screenshot: screenshot)
                    //This is so 'back' doens't say 'shop photo' which looks weird when the tile is shop photo
                    self.navigationItem.backBarButtonItem = UIBarButtonItem.init(title: "", style: .plain, target: nil, action: nil)
                    self.navigationController?.pushViewController(productsViewController, animated: true)
                    
                })
                
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
            let _ = ShoppingCartModel.shared.populateVariants(productOID: product.objectID)
            Analytics.trackProductFavorited(product: product, page: .productList)
            LocalNotificationModel.shared.registerCrazeFavoritedPriceAlert(id: product.id, merchant: product.merchant, lastPrice: product.floatPrice)
        }else{
            Analytics.trackProductUnfavorited(product: product, page: .productList)
            LocalNotificationModel.shared.deregisterCrazeFavoritedPriceAlert(id: product.id, merchant: product.merchant)
        }
    }
    

    @objc func productCollectionViewCellBurrowAction(_ control: UIControl, event: UIEvent) {
        guard let indexPath = collectionView?.indexPath(for: event) else {
            return
        }
        
        let product = self.productAtIndex(indexPath.item)
        product.recordViewedProduct()
        LocalNotificationModel.shared.registerCrazeTappedPriceAlert(id: product.id, merchant: product.merchant, lastPrice: product.floatPrice)

        if let cell = collectionView?.cellForItem(at: indexPath) as? ProductsCollectionViewCell {
            self.productCollectionViewManager.burrow(cell: cell, product: product, fromVC: self)
        }
    }
}

private typealias ProductsViewControllerOptionsView = ProductsViewController
extension ProductsViewControllerOptionsView: ProductsOptionsDelegate {
    @objc func presentOptions() {
        Analytics.trackOpenedFiltersView()
        
        present(self.productsOptions.viewController, animated: true)
    }
    
    func dismissOptions() {
        dismiss(animated: true)
    }
    
    func clearProductListAndStateLoading() {
        self.products = []
        self.relatedLooksManager.relatedLooks = nil
        self.collectionView?.reloadData()
    }
    
    func productsOptionsDidComplete(_ productsOptions: ProductsOptions, withModelChange changed: Bool) {
        self.productsOptions = productsOptions
        if changed, let shoppable = self.getSelectedShoppable(){
            shoppable.set(productsOptions: productsOptions, callback: {
                if let shoppable = self.getSelectedShoppable(){
                    self.reloadProductsFor(shoppable: shoppable)
                }else{
                    self.clearProductListAndStateLoading()
                }
            })
        }else{
            if let shoppable = self.getSelectedShoppable() {
                self.products = self.productCollectionViewManager.productsForShoppable(shoppable, productsOptions: productsOptions)
                self.collectionView?.reloadData()
            }else{
                self.products = []
            }
            self.updateLoadingState()
        }
        self.dismissOptions()
    }
    
    func productsOptionsDidCancel(_ productsOptions: ProductsOptions) {
        dismissOptions()
    }
    
    var shouldHideToolbar: Bool {
        return !self.hasShoppables
    }
}

private typealias ProductsViewControllerShoppables = ProductsViewController
extension ProductsViewControllerShoppables: FetchedResultsControllerManagerDelegate {
    func managerDidChangeContent(_ controller: NSObject, change: FetchedResultsControllerManagerChange) {
        if controller == self.screenshotController {
            self.updateLoadingState()

        }
        else if controller == productsFRC {
            
            if view.window != nil, let collectionView = collectionView {
                if change.updatedRows.count > 0 && change.deletedRows.count == 0 && change.insertedRows.count == 0 {
                    collectionView.indexPathsForVisibleItems.forEach { (indexPath) in
                        let product = self.productAtIndex(indexPath.item)
                        if let cell = collectionView.cellForItem(at: indexPath) as? ProductsCollectionViewCell {
                            self.productCollectionViewManager.setup(cell: cell, with: product)
                        }
                    }
                }else{
                    collectionView.reloadData()
                }
            }
        }
    }
    
    var hasShoppables: Bool {
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
        self.relatedLooksManager.relatedLooks = nil
        self.scrollRevealController?.resetViewOffset()
        self.productLoadingState = .unknown

        self.products = self.productCollectionViewManager.productsForShoppable(shoppable, productsOptions: self.productsOptions)

        
        self.collectionView?.reloadData()
        self.rateView.setRating(UInt(shoppable.getRating()), animated: false)
        
        productsFRC = DataModel.sharedInstance.productFrc(delegate: self, shoppableOID: shoppable.objectID)
        
        if self.collectionView?.numberOfItems(inSection: ProductsSection.product.section) ?? 0 > 0 {
            self.collectionView?.scrollToItem(at: IndexPath(item: 0, section: ProductsSection.product.section), at: .top, animated: false)
        }
        self.updateLoadingState()
        
    }
}

private typealias ProductsViewControllerRatings = ProductsViewController
extension ProductsViewControllerRatings: UITextFieldDelegate {
    
    func presentProductsRateNegativeAlert() {
        let alertController = UIAlertController(title: "negative_feedback.title".localized, message: "negative_feedback.message".localized, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "negative_feedback.options.send".localized, style: .default, handler: { (a) in
            self.presentProductsRateNegativeFeedbackAlert()
        }))
        alertController.addAction(UIAlertAction(title: "generic.cancel".localized, style: .cancel, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    @objc func productsRatePositiveAction() {
        if  let shoppable = self.getSelectedShoppable(){
            shoppable.setRating(positive: true)
            
            if self.screenshot.canSubmitToDiscover {
                let sharePrompt = ShareToDiscoverPrompt.init()
                sharePrompt.translatesAutoresizingMaskIntoConstraints = false
                sharePrompt.alpha = 0
                self.view.addSubview(sharePrompt)
                sharePrompt.addButton.addTarget(self, action: #selector(submitToDiscoverAndPresentThankYouForSharingView(_:)), for: .touchUpInside)
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
        if  let shoppable = self.getSelectedShoppable(){
            shoppable.setRating(positive: false)
            self.presentProductsRateNegativeAlert()
        }
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
                    let shoppable = self.getSelectedShoppable()
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
    
    @objc func submitToDiscoverAndPresentThankYouForSharingView(_ sender:Any) {
        if let button = sender as? UIButton {
            button.isUserInteractionEnabled = false
        }
        self.hideShareToDiscoverPrompt()
        Analytics.trackShareDiscover(screenshot: self.screenshot, page: .productList)

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
    func syncContentInset() {
        guard let collectionView = collectionView, let shoppablesToolbar = self.shoppablesToolbar else {
            return
        }
        
        shoppablesToolbar.layoutIfNeeded()
        
        var scrollInsets = collectionView.scrollIndicatorInsets
        scrollInsets.top = shoppablesToolbar.bounds.size.height
        
        if #available(iOS 11.0, *) {} else {
            scrollInsets.top += self.navigationController?.navigationBar.frame.maxY ?? 0
        }
        
        collectionView.scrollIndicatorInsets = scrollInsets
        
        var insets = collectionView.contentInset
        insets.top = scrollInsets.top
        collectionView.contentInset = insets
    }
    
    func syncViewsAfterStateChange() {
        shoppablesToolbar?.isHidden = shouldHideToolbar
        
        switch (screenshotLoadingState) {
        case .loading, .unknown:
            self.hideNoItemsHelperView()
            self.rateView.isHidden = true
            self.productCollectionViewManager.startAndAddLoader(view: self.view)
            
        case .products:
            syncContentInset()
            self.productCollectionViewManager.stopAndRemoveLoader()
            self.hideNoItemsHelperView()
            self.rateView.isHidden = false
            
            switch self.productLoadingState {
            case .products, .unknown:
                break;
            case .loading:
                self.productCollectionViewManager.startAndAddLoader(view: self.view)
            case .retry:
                self.productCollectionViewManager.stopAndRemoveLoader()
                self.showNoItemsHelperView()
            }
            
        case .retry:
            if #available(iOS 11.0, *) {} else {
                self.automaticallyAdjustsScrollViewInsets = false
            }
            
            self.productCollectionViewManager.stopAndRemoveLoader()
            self.rateView.isHidden = true
            self.hideNoItemsHelperView()
            self.showNoItemsHelperView()
        }
    }
}

private typealias ProductsViewControllerNoItemsHelperView = ProductsViewController
extension ProductsViewControllerNoItemsHelperView{
    
    func showNoItemsHelperView() {
        
        let (helperView, retryButton) = self.productCollectionViewManager.noProductsView()

        self.view.addSubview(helperView)
        self.noItemsHelperView = helperView

        retryButton.addTarget(self, action: #selector(noItemsRetryAction), for: .touchUpInside)

        if let shoppablesToolbar = self.shoppablesToolbar{
            helperView.topAnchor.constraint(equalTo: shoppablesToolbar.bottomAnchor, constant:0).isActive = true
        }else{
            helperView.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor).isActive = true
        }
        helperView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        helperView.bottomAnchor.constraint(equalTo: self.bottomLayoutGuide.topAnchor).isActive = true
        helperView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        
    }
    
    func hideNoItemsHelperView() {
        self.noItemsHelperView?.removeFromSuperview()
        self.noItemsHelperView = nil
    }
    
    @objc func noItemsRetryAction() {
        if self.screenshotLoadingState == .retry {
            AssetSyncModel.sharedInstance.refetchShoppables(screenshot: self.screenshot)
        } else if self.productLoadingState == .retry {
            if let selectedShoppable = self.getSelectedShoppable(), let offersURL = selectedShoppable.offersURL {
                AssetSyncModel.sharedInstance.reExtractProducts(assetId: self.screenshot.assetId, shoppableId: selectedShoppable.objectID, optionsMask: ProductsOptionsMask.global, offersURL: offersURL)
            }
        }
    }
}

extension ProductsViewController : RelatedLooksManagerDelegate {
    func relatedLooksManager(_ relatedLooksManager: RelatedLooksManager, present viewController: UIViewController) {
        self.present(viewController, animated: true, completion: nil)
    }
    
    func relatedLooksManagerGetProducts(_ relatedLooksManager: RelatedLooksManager) -> [Product]? {
        return self.products
    }
        
    func relatedLooksManagerReloadSection(_ relatedLooksManager:RelatedLooksManager){
        let section = self.sectionIndex(forProductType: .relatedLooks)
        self.collectionView?.reloadSections(IndexSet.init(integer: section))

    }
}
extension ProductsViewController : AsyncOperationMonitorDelegate {
    func updateLoadingState(){
        DispatchQueue.mainAsyncIfNeeded {
            var didChange = false
            let isLoading = self.loadingMonitor?.didStart ?? false
            let state:ProductsViewControllerState = {
                if self.hasShoppables {
                    return .products
                }else{
                    if isLoading {
                        return .loading
                    }else{
                        return .retry
                    }
                }
            }()
            if state != self.screenshotLoadingState {
                self.screenshotLoadingState = state
                didChange = true
            }
            
            
            let productState:ProductsViewControllerState = {
                if let monitor = self.productsLoadingMonitor {
                    let isProductLoading = monitor.didStart
                    
                    if self.products.count > 0 {
                        return .products
                    }else{
                        if isProductLoading {
                            return .loading
                        }else{
                            return .retry
                        }
                    }
                }else{
                    return .unknown
                }
            }()
           
            if productState != self.productLoadingState {
                self.productLoadingState = productState
                didChange = true
            }
            
            if didChange {
                self.syncViewsAfterStateChange()
            }
        }
    }
    
    func asyncOperationMonitorDidChange(_ monitor: AsyncOperationMonitor) {
        self.updateLoadingState()
    }

}
extension ProductsViewController: RecoverLostSaleManagerDelegate {
    func recoverLostSaleManager(_ manager:RecoverLostSaleManager, returnedFrom product:Product){
        if let index = self.products.index(of: product) {
            if let cell = self.collectionView?.cellForItem(at: IndexPath.init(row: index, section: 0)) as? ProductsCollectionViewCell, let view = cell.productImageView{
                self.recoverLostSaleManager.presetRecoverAlertViewFor(product: product, in: self, rect: view.bounds.insetBy(dx: 20, dy: 20), view:view)
            }
        }
        
    }
}



