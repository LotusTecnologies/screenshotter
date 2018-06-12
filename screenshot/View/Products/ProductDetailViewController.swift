//
//  ProductDetailViewController.swift
//  screenshot
//
//  Created by Jonathan Rose on 6/4/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit
import SDWebImage
import Hero
class ProductDetailViewController: BaseViewController { 
    var productCollectionViewManager = ProductCollectionViewManager()

    var collectionView:UICollectionView?
    var product:Product?
    var products:[Product] = []
    var shoppable:Shoppable?
    var productsOptions:ProductsOptions = ProductsOptions()
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
    var headerCell:ProductHeaderCollectionViewCell? {
        if self.collectionView?.numberOfSections ?? 0 > 0 && self.collectionView?.numberOfItems(inSection: 0) ?? 0 > 0 {
            return self.collectionView?.cellForItem(at: IndexPath.init(row: 0, section: 0)) as? ProductHeaderCollectionViewCell
        }
        return nil
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.title = product?.calculatedDisplayTitle
        
        self.productsOptions.delegate = self
        
        if let shoppable = self.shoppable {
            productsFRC = DataModel.sharedInstance.productFrc(delegate: self, shoppableOID: shoppable.objectID)
            
            self.products = self.productCollectionViewManager.productsForShoppable(shoppable, productsOptions: self.productsOptions).filter{ $0.price != self.product?.price || $0.merchant != self.product?.merchant || $0.productTitle() != self.product?.productTitle() || $0.imageURL != self.product?.imageURL }
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
            }
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.collectionView?.reloadData()
    }
}


extension ProductDetailViewController : UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    var numberOfCollectionViewProductColumns: Int {
        return 2
    }
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        return self.products.count
    }
    
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section == 0{
            return self.productCollectionViewManager.collectionView(collectionView, sizeForItemInSectionType: .productHeader)
        }
            return self.productCollectionViewManager.collectionView(collectionView, sizeForItemInSectionType: .product)
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
                cell.buyNowButton.addTarget(self, action: #selector(productCollectionViewCellBuyAction(_:event:)), for: .touchUpInside)
            }
            
            return cell
        }
        else {
            let product = self.products[indexPath.row]
            let cell = self.productCollectionViewManager.collectionView(collectionView, cellForItemAt: indexPath, with: product)
            
            if let cell = cell as? ProductsCollectionViewCell {
                cell.favoriteControl.addTarget(self, action: #selector(productCollectionViewCellFavoriteAction(_:event:)), for: .touchUpInside)
                cell.actionButton.addTarget(self, action: #selector(productCollectionViewCellBuyAction(_:event:)), for: .touchUpInside)
            }
            return cell
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
        }
        
        let minimumSpacing:CGPoint = self.collectionViewMinimumSpacing()
        return UIEdgeInsets(top: minimumSpacing.y, left: minimumSpacing.x, bottom: minimumSpacing.y, right: minimumSpacing.x)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == 1{
            return CGSize.init(width: collectionView.bounds.size.width, height: 50)
        }
        return .zero
    }
    
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {

        if kind == UICollectionElementKindSectionHeader {
            if indexPath.section == 1 && self.productLoadingState != .retry {
                let view = self.productCollectionViewManager.collectionView(collectionView, viewForHeaderWith: "products.details.similar".localized, indexPath: indexPath)
                view.backgroundColor = self.view.backgroundColor
                
                if let view = view as? ProductsViewHeaderReusableView {
                    view.filterButton.addTarget(self, action: #selector(presentOptions), for: .touchUpInside)
                }
                
                return view
            }
            return self.productCollectionViewManager.collectionView(collectionView, viewForHeaderWith: "", indexPath: indexPath)
        }
        else if kind == SectionBackgroundCollectionViewFlowLayout.ElementKindSectionSectionBackground {
            if indexPath.section == 1 {
                return self.productCollectionViewManager.collectionView(collectionView, viewForBackgroundWith: .background, indexPath: indexPath)
            }
            return self.productCollectionViewManager.collectionView(collectionView, viewForBackgroundWith: .white, indexPath: indexPath)
        }
        return UICollectionReusableView()
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 1{
            let product = self.productAtIndex(indexPath.item)
            if let cell = collectionView.cellForItem(at: indexPath) as? ProductsCollectionViewCell{
                self.productCollectionViewManager.burrow(cell: cell, product: product, fromVC: self)
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
                let _ = ShoppingCartModel.shared.populateVariants(productOID: product.objectID)
                Analytics.trackProductFavorited(product: product, page: .productList)
            }else{
                Analytics.trackProductUnfavorited(product: product, page: .productList)
            }
        }
    }
    
    @objc func productCollectionViewCellBuyAction(_ control: UIControl, event: UIEvent) {
        guard let indexPath = collectionView?.indexPath(for: event) else {
            return
        }
        
        if let product = indexPath.section == 0 ? self.product : self.productAtIndex(indexPath.item) {
            product.recordViewedProduct()
            
            if let productViewController = presentProduct(product, atLocation: .products) {
                productViewController.similarProducts = products
            }
        }
    }
    
}

extension ProductDetailViewController: ProductsOptionsDelegate {
    @objc private func presentOptions() {
        Analytics.trackOpenedFiltersView()
        
        if let shoppable = self.shoppable {
            self.productsOptions.syncOptions(withMask: shoppable.getLast())
        }
        
        present(self.productsOptions.viewController, animated: true)
    }
    
    @objc private func dismissOptions() {
        dismiss(animated: true)
    }
    
    func productsOptionsDidComplete(_ productsOptions: ProductsOptions, withChange changed: Bool) {
        if changed, let shoppable = self.shoppable {
            // TODO:
            shoppable.set(productsOptions: productsOptions, callback: {
                if let shoppable = self.shoppable {
//                    self.reloadProductsFor(shoppable: shoppable)
                }
                else {
//                    self.clearProductListAndStateLoading()
                }
            })
        }
        
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
        case .products:
            self.productCollectionViewManager.stopAndRemoveLoader()
            self.hideNoItemsHelperView()
        case .retry:
            self.productCollectionViewManager.stopAndRemoveLoader()
            self.hideNoItemsHelperView()
            self.showNoItemsHelperView()
        }
    }
    
    func showNoItemsHelperView() {
        
        let (helperView, retryButton) = self.productCollectionViewManager.noProductsView()
        
        self.view.addSubview(helperView)
        self.noItemsHelperView = helperView
        
        retryButton.addTarget(self, action: #selector(noItemsRetryAction), for: .touchUpInside)
        
        helperView.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor, constant: productCollectionViewManager.productHeaderHeight).isActive = true
        helperView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        helperView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
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
        if let shoppable = self.shoppable, self.products.count == 0 {
            self.products = self.productCollectionViewManager.productsForShoppable(shoppable, productsOptions: self.productsOptions)
            self.updateLoadingState()
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
}
