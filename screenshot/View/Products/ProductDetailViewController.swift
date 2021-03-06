//
//  ProductDetailViewController.swift
//  screenshot
//
//  Created by Jonathan Rose on 6/4/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import UIKit
import SDWebImage
import Hero
class ProductDetailViewController: BaseViewController { 
    var productCollectionViewManager = ProductCollectionViewManager()
    var recoverLostSaleManager = RecoverLostSaleManager()
    var collectionView:UICollectionView?
    var product:Product?
    var products:[Product] = []
    var shoppable:Shoppable?
    var productsOptions:ProductsOptions = ProductsOptions()
    var relatedLooksManager = RelatedLooksManager()
    var noItemsHelperView:HelperView?
    var loaderContainer = UIView()
    var uuid:String?
    var productsLoadingMonitor:AsyncOperationMonitor?
    fileprivate var productsFRC: FetchedResultsControllerManager<Product>?

    var productLoadingState:ProductsViewControllerState = .unknown {
        didSet {
            self.syncViewsAfterStateChange()
        }
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.title = product?.calculatedDisplayTitle
        self.relatedLooksManager.delegate = self
        self.productsOptions.delegate = self
        self.recoverLostSaleManager.delegate = self
        if let shoppable = self.shoppable {
            productsFRC = DataModel.sharedInstance.productFrc(delegate: self, shoppableOID: shoppable.objectID)
            
            updateProductsWithShoppable()
            self.productsLoadingMonitor = AsyncOperationMonitor.init(assetId: nil, shoppableId: shoppable.imageUrl, queues: AssetSyncModel.sharedInstance.queues, delegate: self)
            self.updateLoadingState()
        }
        
        let collectionView:UICollectionView = {
            let minimumSpacing = self.collectionViewMinimumSpacing()
            
            let layout = SectionBackgroundCollectionViewFlowLayout()
            layout.minimumInteritemSpacing = minimumSpacing.x
            layout.minimumLineSpacing = minimumSpacing.y
            let collectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: layout)
            collectionView.translatesAutoresizingMaskIntoConstraints = false
            collectionView.delegate = self
            collectionView.dataSource = self
            collectionView.backgroundColor = self.view.backgroundColor
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
        
        loaderContainer.backgroundColor = .clear
        loaderContainer.isUserInteractionEnabled = false
        loaderContainer.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(loaderContainer)
        loaderContainer.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor, constant:200).isActive = true
        loaderContainer.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        loaderContainer.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        loaderContainer.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        
        
        let pinchZoom = UIPinchGestureRecognizer.init(target: self, action: #selector(pinch(gesture:)))
        self.view.addGestureRecognizer(pinchZoom)

        
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        if let cell = collectionView.cellForItem(at: indexPath){
            if let _ = cell as? RelatedLooksCollectionViewCell {
                let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                
                self.relatedLooksManager.addScreenshotAction(actionSheet, at: indexPath)
                
                if actionSheet.actions.count > 0 {
                    actionSheet.addAction(UIAlertAction(title: "generic.cancel".localized, style: .cancel, handler: nil))
                    self.present(actionSheet, animated: true)
                    return true
                }
            }
        }
        return false
    }
    func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }
    
    func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
        
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
            }else if let cell = cell as? ProductHeaderCollectionViewCell {
                let imageView = cell.productImageView.imageView
                CrazeImageZoom.shared.gestureStateChanged(gesture, imageView: imageView)
            }else if let cell = cell as? RelatedLooksCollectionViewCell {
                let imageView = cell.imageView
                CrazeImageZoom.shared.gestureStateChanged(gesture, imageView: imageView)
            }
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.collectionView?.reloadData()
        if let assetId = self.shoppable?.screenshot?.assetId {
            AssetSyncModel.sharedInstance.moveScreenshotToTopOfQueue(assetId: assetId)
        }
    }
}


extension ProductDetailViewController : UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.relatedLooksManager.scrollViewDidScroll(scrollView)
    }
    var numberOfCollectionViewProductColumns: Int {
        return 2
    }
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 3
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }else if section == 1 {
            return self.products.count
        }else if section == 2{
            return self.relatedLooksManager.numberOfItems()
        }
        return 0
    }
    
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section == 0 {
            return self.productCollectionViewManager.collectionView(collectionView, sizeForItemInSectionType: .productHeader)
        }else if indexPath.section == 1 {
            return self.productCollectionViewManager.collectionView(collectionView, sizeForItemInSectionType: .product)
        }else if indexPath.section == 2 {
            if self.relatedLooksManager.relatedLooks?.value == nil {
                return self.productCollectionViewManager.collectionView(collectionView, sizeForItemInSectionType: .error)
            }else{
                return self.productCollectionViewManager.collectionView(collectionView, sizeForItemInSectionType: .relatedLooks)
            }
        }
        return .zero
        
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            let product = self.product
            let cell = self.productCollectionViewManager.collectionView(collectionView, cellForItemAt: indexPath, withProductHeader: product)
            
            if let cell  = cell as? ProductHeaderCollectionViewCell, let uuid = uuid {
                cell.productImageView.hero.id = "\(uuid)-image"
                cell.favoriteControl.hero.id = "\(uuid)-heart"
                cell.buyNowButton.hero.id = "\(uuid)-button"
                
                cell.favoriteControl.addTarget(self, action: #selector(productCollectionViewCellFavoriteAction(_:event:)), for: .touchUpInside)
                cell.buyNowButton.addTarget(self, action: #selector(productCollectionViewCellBuyNowAction(_:event:)), for: .touchUpInside)
                cell.productControl.addTarget(self, action: #selector(productCollectionViewCellBuyNowAction(_:event:)), for: .touchUpInside)
            }
            
            return cell
        }
        else if indexPath.section == 1{
            let product = self.products[indexPath.row]
            let cell = self.productCollectionViewManager.collectionView(collectionView, cellForItemAt: indexPath, with: product)
            
            if let cell = cell as? ProductsCollectionViewCell {
                cell.favoriteControl.addTarget(self, action: #selector(productCollectionViewCellFavoriteAction(_:event:)), for: .touchUpInside)
                cell.actionButton.addTarget(self, action: #selector(productCollectionViewCellBurrowAction(_:event:)), for: .touchUpInside)
            }
            return cell
        }else {
            return self.relatedLooksManager.collectionView(collectionView, cellForItemAt: indexPath)
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        if indexPath.section == 0 {
            return false
        }
        return true
    }
    public func collectionViewMinimumSpacing() -> CGPoint {
        let shadowInsets = ScreenshotCollectionViewCell.shadowInsets
        let p: CGFloat = .padding
        return CGPoint(x: p - shadowInsets.left - shadowInsets.right, y: p - shadowInsets.top - shadowInsets.bottom)
    }
    func productAtIndex(_ index: Int) -> Product {
        return self.products[index]
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if section == 0 {
            return .zero
        }else if section == 1{
            let minimumSpacing:CGPoint = self.collectionViewMinimumSpacing()
            return UIEdgeInsets(top: minimumSpacing.y, left: minimumSpacing.x, bottom: minimumSpacing.y, right: minimumSpacing.x)
        }else if section == 2{
            if self.relatedLooksManager.hasInset() {
                let minimumSpacing:CGPoint = self.collectionViewMinimumSpacing()
                return UIEdgeInsets(top: minimumSpacing.y, left: minimumSpacing.x, bottom: minimumSpacing.y, right: minimumSpacing.x)
            }
        }
        return .zero
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == 1{
            return CGSize.init(width: collectionView.bounds.size.width, height: 50)
        }else if section == 2 {
            if  self.relatedLooksManager.hasRelatedLooksSection() {
                return CGSize.init(width: collectionView.bounds.size.width, height: 50)
            }
        }
        return .zero
    }
    
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {

        if kind == UICollectionElementKindSectionHeader {
            if indexPath.section == 1 && self.productLoadingState != .retry {
                let view = self.productCollectionViewManager.collectionView(collectionView, viewForHeaderWith: "products.details.similar".localized, hasBackgroundAndLine:false, hasFilterButton:(self.productLoadingState == .products), indexPath: indexPath)
                if let view = view as? ProductsViewHeaderReusableView {
                    view.filterButton.addTarget(self, action: #selector(presentOptions), for: .touchUpInside)
                }
                return view
            }else if indexPath.section == 2 && self.relatedLooksManager.hasRelatedLooksSection() {
                let view = self.productCollectionViewManager.collectionView(collectionView, viewForHeaderWith: "products.related_looks.headline".localized, hasBackgroundAndLine:true, hasFilterButton:false, indexPath: indexPath)
                return view
            }
            
            return self.productCollectionViewManager.collectionView(collectionView, viewForHeaderWith: "",hasBackgroundAndLine:false, hasFilterButton:false, indexPath: indexPath)
        }
        else if kind == SectionBackgroundCollectionViewFlowLayout.ElementKindSectionSectionBackground {
            if indexPath.section == 1 {
                return self.productCollectionViewManager.collectionView(collectionView, viewForBackgroundWith: .background, indexPath: indexPath)
            }else if indexPath.section == 2 {
                if let image = UIImage.init(named: "confetti") {
                    let confettiColor = UIColor.init(patternImage: image )
                    return self.productCollectionViewManager.collectionView(collectionView, viewForBackgroundWith: confettiColor, indexPath: indexPath)
                }
            }
            return self.productCollectionViewManager.collectionView(collectionView, viewForBackgroundWith: .white, indexPath: indexPath)
        }
        return UICollectionReusableView()
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 1{
            let product = self.productAtIndex(indexPath.item)
            product.recordViewedProduct()
            self.recoverLostSaleManager.didClick(on: product)
            LocalNotificationModel.shared.registerCrazeTappedPriceAlert(id: product.id, merchant: product.merchant, lastPrice: product.floatPrice)
            presentProduct(product, atLocation: .burrowList) 
        }else if indexPath.section == 2 {
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
        if let product = indexPath.section == 0 ? self.product : self.productAtIndex(indexPath.item) {
            
            product.setFavorited(toFavorited: isFavorited)
            if isFavorited {
                Analytics.trackProductFavorited(product: product, page: .productList)
                LocalNotificationModel.shared.registerCrazeFavoritedPriceAlert(id: product.id, merchant: product.merchant, lastPrice: product.floatPrice)
            }else{
                Analytics.trackProductUnfavorited(product: product, page: .productList)
                LocalNotificationModel.shared.deregisterCrazeFavoritedPriceAlert(id: product.id, merchant: product.merchant)
            }
        }
    }
    
    @objc func productCollectionViewCellBurrowAction(_ control: UIControl, event: UIEvent) {
        guard let indexPath = collectionView?.indexPath(for: event) else {
            return
        }
        
        if  indexPath.section == 1 {
            let product = self.productAtIndex(indexPath.item)
            if let collectionView = self.collectionView,  let cell = collectionView.cellForItem(at: indexPath) as? ProductsCollectionViewCell {
                self.productCollectionViewManager.burrow(cell: cell, product: product, fromVC: self)
            }
        }
        
        
    }
    
    @objc func productCollectionViewCellBuyNowAction(_ control: UIControl, event: UIEvent) {
        guard !self.recoverLostSaleManager.isPresented, let indexPath = collectionView?.indexPath(for: event) else {
            return
        }

        if  indexPath.section == 0, let product = self.product {
            self.recoverLostSaleManager.didClick(on: product)
            presentProduct(product, atLocation: .burrownMain) 
        }
    }
    
}

extension ProductDetailViewController: ProductsOptionsDelegate {
    @objc private func presentOptions() {
        Analytics.trackOpenedFiltersView()
        
        present(self.productsOptions.viewController, animated: true)
    }
    
    @objc private func dismissOptions() {
        productsOptions.viewController.presentingViewController?.dismiss(animated: true)
    }
    
    func productsOptionsDidComplete(_ productsOptions: ProductsOptions, withModelChange changed: Bool) {
        self.productsOptions = productsOptions
        updateProductsWithShoppable()
        self.dismissOptions()
    }
    
    func productsOptionsDidCancel(_ productsOptions: ProductsOptions) {
        dismissOptions()
    }
}

extension ProductDetailViewController : AsyncOperationMonitorDelegate, FetchedResultsControllerManagerDelegate {
    func syncViewsAfterStateChange() {
        self.collectionView?.reloadData()
        
        switch (self.productLoadingState) {
        case .loading, .unknown:
            self.hideNoItemsHelperView()
            
            self.productCollectionViewManager.startAndAddLoader(view: self.loaderContainer)
            self.collectionView?.visibleSupplementaryViews(ofKind: UICollectionElementKindSectionHeader).forEach({ (view) in
                if let view = view as? ProductsViewHeaderReusableView {
                    view.filterButton.isHidden = true
                }
            })
        case .products:
            self.productCollectionViewManager.stopAndRemoveLoader()
            self.hideNoItemsHelperView()
            self.collectionView?.visibleSupplementaryViews(ofKind: UICollectionElementKindSectionHeader).forEach({ (view) in
                if let view = view as? ProductsViewHeaderReusableView {
                    view.filterButton.isHidden = true
                }
            })
        case .retry:
            self.productCollectionViewManager.stopAndRemoveLoader()
            self.hideNoItemsHelperView()
            self.showNoItemsHelperView()
            self.collectionView?.visibleSupplementaryViews(ofKind: UICollectionElementKindSectionHeader).forEach({ (view) in
                if let view = view as? ProductsViewHeaderReusableView {
                    view.filterButton.isHidden = true
                }
            })
        }
    }
    
    func showNoItemsHelperView() {
        
        let (helperView, retryButton) = self.productCollectionViewManager.noProductsView()
        
        self.view.addSubview(helperView)
        self.noItemsHelperView = helperView
        
        retryButton.addTarget(self, action: #selector(noItemsRetryAction), for: .touchUpInside)
        
        helperView.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor, constant: productCollectionViewManager.productHeaderHeight).isActive = true
        helperView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        helperView.bottomAnchor.constraint(equalTo: self.bottomLayoutGuide.topAnchor).isActive = true
        helperView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        
    }
    
    func hideNoItemsHelperView() {
        self.noItemsHelperView?.removeFromSuperview()
        self.noItemsHelperView = nil
    }
    
    @objc func noItemsRetryAction() {
        if let shoppable = self.shoppable {
            let _ = AssetSyncModel.sharedInstance.reloadSubShoppable(shoppable: shoppable)
        }
    }
    
    func updateLoadingState(){
        DispatchQueue.main.async {
           
            let isProductLoading = self.productsLoadingMonitor?.didStart ?? false
            let productState:ProductsViewControllerState = {
                if self.products.count > 0 {
                    return .products
                }else{
                    if isProductLoading {
                        return .loading
                    }else{
                        return .retry
                    }
                }
            }()
            if productState != self.productLoadingState {
                self.productLoadingState = productState
            }
        }
    }
    
    func asyncOperationMonitorDidChange(_ monitor: AsyncOperationMonitor) {
        self.updateLoadingState()
    }
    func managerDidChangeContent(_ controller: NSObject, change: FetchedResultsControllerManagerChange) {
        if self.products.count == 0 {
            updateProductsWithShoppable()
        }else if view.window != nil, let collectionView = collectionView {
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
    func updateProductsWithShoppable(){
        if let shoppable = self.shoppable{
            self.products = self.productCollectionViewManager.productsForShoppable(shoppable, productsOptions: self.productsOptions).filter{ !$0.isSimmilar( self.product) }
        }else{
            self.products = []
        }
        self.collectionView?.reloadData()
        self.updateLoadingState()
        
    }
}
extension ProductDetailViewController: RelatedLooksManagerDelegate {
    func relatedLooksManager(_ relatedLooksManager: RelatedLooksManager, present viewController: UIViewController) {
        self.present(viewController, animated: true, completion: nil)
    }
    
    func relatedLooksManagerGetShoppable(_ relatedLooksManager: RelatedLooksManager) -> Shoppable? {
        return self.products.first?.shoppable
    }
    
    func relatedLooksManagerReloadSection(_ relatedLooksManager:RelatedLooksManager){
        let section = 2
        self.collectionView?.reloadSections(IndexSet.init(integer: section))
        
    }
    
    
}

extension ProductDetailViewController: RecoverLostSaleManagerDelegate {
    func recoverLostSaleManager(_ manager: RecoverLostSaleManager, returnedFrom product: Product, timeSinceLeftApp: Int) {
        if product == self.product {
            if let cell = self.collectionView?.cellForItem(at: IndexPath.init(row: 0, section: 0)) as? ProductHeaderCollectionViewCell {
                let view = cell.productImageView
                self.recoverLostSaleManager.presetRecoverAlertViewFor(product: product, in: self, rect: view.bounds, view:view, timeSinceLeftApp:timeSinceLeftApp)
            }
        }else {
            if let index = self.products.index(of: product) {
                if let cell = self.collectionView?.cellForItem(at: IndexPath.init(row: index, section: 1)) as? ProductsCollectionViewCell, let view = cell.productImageView{
                    self.recoverLostSaleManager.presetRecoverAlertViewFor(product: product, in: self, rect: view.bounds, view:view, timeSinceLeftApp:timeSinceLeftApp)
                }
            }
        }
        
        
    }
    
}
