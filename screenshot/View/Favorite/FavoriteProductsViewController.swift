//
//  FavoriteProductsViewController.swift
//  screenshot
//
//  Created by Corey Werner on 12/27/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import UIKit
import CoreData

class FavoriteProductsViewController : BaseViewController {
    var productsFRC:FetchedResultsControllerManager<Product>?
    
    fileprivate var unfavoriteProductsIds: Set<NSManagedObjectID> = []
    private let emptyListView = HelperView()
    var  trackingProgressMonitors:[String:AsyncOperationMonitor] = [:]
    
    override var title: String? {
        set {}
        get {
            return "favorites.items.title".localized
        }
    }
    
    // MARK: Views
    
    fileprivate var favoriteProductsView: FavoriteProductsView {
        return view as! FavoriteProductsView
    }
    
    var tableView: TableView {
        return favoriteProductsView.tableView
    }
    
    override func loadView() {
        view = FavoriteProductsView()
    }
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        restorationIdentifier = String(describing: type(of: self))
        
        addNavigationItemLogo()
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTableView), name: .isUSCUpdated, object: nil)

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = view.backgroundColor
        tableView.register(FavoriteProductsTableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 200
        tableView.layoutMargins = UIEdgeInsets(top: .extendedPadding, left: 0, bottom: .extendedPadding, right: 0) // Needed for emptyListView
        
        emptyListView.titleLabel.text = "favorites.empty.title".localized
        emptyListView.subtitleLabel.text = "favorites.empty.detail".localized
        emptyListView.contentImage = UIImage(named: "FavoriteEmptyListGraphic")
        tableView.emptyView = emptyListView

        
        let pinchZoom = UIPinchGestureRecognizer.init(target: self, action: #selector(pinch(gesture:)))
        self.view.addGestureRecognizer(pinchZoom)
        self.productsFRC = DataModel.sharedInstance.favoritedProductsFrc(delegate: self)
        self.tableView.reloadData()
    }
    
    deinit {
        tableView.dataSource = nil
        tableView.delegate = nil
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK:
    
    @objc func pinch( gesture:UIPinchGestureRecognizer) {
        if CrazeImageZoom.shared.isHandlingGesture, let imageView = CrazeImageZoom.shared.hostedImageView  {
            CrazeImageZoom.shared.gestureStateChanged(gesture, imageView: imageView)
            return
        }
        let point = gesture.location(in: self.tableView)
        if let indexPath = self.tableView.indexPathForRow(at: point), let cell = self.tableView.cellForRow(at: indexPath) as? FavoriteProductsTableViewCell{
            CrazeImageZoom.shared.gestureStateChanged(gesture, imageView: cell.productImageView.imageView)
        }
    }
    
    public func clearMarkedAsUnfavorite(){
        DataModel.sharedInstance.unfavorite(favoriteArray: Array(self.unfavoriteProductsIds))
        self.unfavoriteProductsIds.removeAll()
    }
    
    // MARK: Favorites
    
    @objc fileprivate func favoriteProductAction(_ favoriteControl: FavoriteControl, event: UIEvent) {
        guard let indexPath = tableView.indexPath(for: event),let product = self.productsFRC?.object(at: indexPath) else {
            return
        }
        
        let isFavorited = favoriteControl.isSelected
        
        if isFavorited {
            self.unfavoriteProductsIds.remove(product.objectID)
            
        }
        else {
            self.unfavoriteProductsIds.insert(product.objectID)
        }
        if isFavorited {
            Analytics.trackProductFavorited(product: product, page: .favorites)
        }else{
            Analytics.trackProductUnfavorited(product: product, page: .favorites)
        }
    }
    
    // MARK: Price Alerts
    
    private let priceAlertController = ProductPriceAlertController()
    
    @objc fileprivate func trackProductAction(_ button: LoadingButton, event: UIEvent) {
        guard let indexPath = tableView.indexPath(for: event),
            let product = self.productsFRC?.object(at: indexPath)
            else {
                return
        }
        
        if let deniedAlertController = priceAlertController.priceAlertAction(button, on: product) {
            present(deniedAlertController, animated: true, completion: nil)
        }
    }
    
    // MARK: Navigation
    
    fileprivate func presentProduct(at indexPath: IndexPath) {
        guard let product = self.productsFRC?.object(at: indexPath) else {
            return
        }
        
        presentProduct(product, atLocation: .favorite)
    }
    
    @objc fileprivate func shareProductAction(_ control: UIControl, event: UIEvent) {
        guard let indexPath = tableView.indexPath(for: event), let product = self.productsFRC?.object(at: indexPath) else {
            return
        }

        ScreenshotShareManager.share(product: product, in: self)
    }
    
    @objc fileprivate func addToCartOrBuyNowProductAction(_ control: UIControl, event: UIEvent) {
        guard let indexPath = tableView.indexPath(for: event) else {
            return
        }
        guard let product = self.productsFRC?.object(at: indexPath) else {
            return
        }
        if let _ = product.partNumber {
            if product.hasVariants {
                let productVariantsSelectorViewController = ProductVariantsSelectorViewController.init(product: product)
                productVariantsSelectorViewController.delegate = self
                productVariantsSelectorViewController.titleLabel.text = "favorites.product.cart".localized
                productVariantsSelectorViewController.continueButton.setTitle("favorites.product.cart".localized, for: .normal)

                self.present(productVariantsSelectorViewController, animated: true, completion: nil)
                
            }else{
                //out of stock shouldn't happen
               
             
            }
        }else{
            //This will open in browser since there is no part Number
            presentProduct(product, atLocation: .favorite)
        }
        
        
    }
}

extension FavoriteProductsViewController: ProductVariantsSelectorViewControllerDelegate {
    func productVariantsSelectorViewControllerDidPressCancel(_ productVariantsSelectorViewController: ProductVariantsSelectorViewController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func productVariantsSelectorViewControllerDidPressContinue(_ productVariantsSelectorViewController: ProductVariantsSelectorViewController) {
        
        if let variant = productVariantsSelectorViewController.selectedVariant {
            variant.product?.setFavorited(toFavorited: false)
            ShoppingCartModel.shared.update(variant: variant, quantity: Int16(productVariantsSelectorViewController.selectedQuantity))
            if let tabBarController = self.tabBarController as? MainTabBarController {
                tabBarController.cartTabPulseAnimation()
            }
            self.dismiss(animated: true) {
                self.presentNextStep()
            }
            
        }else{
            self.dismiss(animated: true, completion: nil)
            //error?
        }
    }
    
    fileprivate func presentNextStep() {
        let nextStepViewController = ProductNextStepViewController()
        nextStepViewController.continueButton.addTarget(self, action: #selector(nextStepContinueAction), for: .touchUpInside)
        nextStepViewController.cancelButton.addTarget(self, action: #selector(nextStepCancelAction), for: .touchUpInside)
        present(nextStepViewController, animated: true, completion: nil)
    }
    
    @objc fileprivate func nextStepContinueAction() {
        if presentedViewController != nil {
            dismiss(animated: true, completion: nil)
        }
        if let tabBarController = self.tabBarController as? MainTabBarController {
            tabBarController.goToCart()
        }
        
    }
    
    @objc fileprivate func nextStepCancelAction() {
        dismiss(animated: true, completion: nil)
    }
}


extension FavoriteProductsViewController: UITableViewDataSource, AsyncOperationMonitorDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.productsFRC?.fetchedObjectsCount ?? 0
    }
    
    func update(cell:FavoriteProductsTableViewCell, monitor:AsyncOperationMonitor, product:Product){
        cell.priceAlertButton.isLoading = monitor.didStart
        cell.priceAlertButton.isSelected = product.hasPriceAlerts  // ???: what happens if this is true and the user disables notifications from settings
        if product.hasVariants {
            cell.priceAlertButton.setTitle("favorites.product.price_alert_off".localized, for: .normal)
        }else{
            cell.priceAlertButton.setTitle("product.price_alert_on".localized, for: .normal)
        }
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        var visiblePartNumbers:Set<String> = []
        self.tableView.indexPathsForVisibleRows?.forEach({ (indexPath) in
            if  let product = self.productsFRC?.object(at: indexPath), let productId = product.partNumber {
                visiblePartNumbers.insert(productId)
            }
        })
        let unusedMonitors = self.trackingProgressMonitors.filter {
            return !visiblePartNumbers.contains( $0.key )
        }
        
        unusedMonitors.forEach {
            if let monitor = self.trackingProgressMonitors[$0.key] {
                monitor.delegate = nil
            }
            self.trackingProgressMonitors.removeValue(forKey: $0.key) }
    }
    
    func asyncOperationMonitorDidChange(_ monitor: AsyncOperationMonitor) {
        self.tableView.indexPathsForVisibleRows?.forEach({ (indexPath) in
            if  let cell = self.tableView.cellForRow(at: indexPath) as? FavoriteProductsTableViewCell, let product = self.productsFRC?.object(at: indexPath), let productId = product.partNumber, let monitor = self.trackingProgressMonitors[productId] {
                self.update(cell: cell, monitor: monitor, product: product)
            }else{
                print("error updating from monitor Change")
            }
        })
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        if let cell = cell as? FavoriteProductsTableViewCell, let product = self.productsFRC?.object(at: indexPath) {
            cell.selectionStyle = .none
            cell.contentView.backgroundColor = .cellBackground
            cell.productImageView.setImage(withURLString: product.imageURL)
            cell.titleLabel.text = product.productTitle()
            cell.priceLabel.text = product.price
            cell.merchantLabel.text = product.merchant
            cell.favoriteControl.isSelected = !self.unfavoriteProductsIds.contains(product.objectID)
            cell.favoriteControl.addTarget(self, action: #selector(favoriteProductAction(_:event:)), for: .touchUpInside)
                        
            
            if UIApplication.isUSC {
                if let partNumber = product.partNumber, !partNumber.isEmpty {
                    if product.hasVariants {
                        cell.cartButton.setTitle("favorites.product.cart".localized, for: .normal)
                        cell.isCartButtonHidden = false
                        cell.isOutOfStockLabelHidden = true
                        cell.isShareButtonHidden = (product.offer == nil)
                    }else{
                        cell.isOutOfStockLabelHidden = false
                        cell.isCartButtonHidden = true
                        cell.isShareButtonHidden = true
                    }
                    
                    cell.isPriceAlertButtonHidden = false
                    
                    if let oldMonitor = self.trackingProgressMonitors[partNumber] {
                        self.update(cell: cell, monitor: oldMonitor, product: product)
                    }else{
                        let monitor = AsyncOperationMonitor.init(tracking: [partNumber], delegate: self)
                        self.trackingProgressMonitors[partNumber] = monitor
                        self.update(cell: cell, monitor: monitor, product: product)
                    }
                    
                }else{
                    cell.isOutOfStockLabelHidden = true
                    cell.isPriceAlertButtonHidden = true
                    cell.isShareButtonHidden = true
                    cell.isCartButtonHidden = false
                    cell.cartButton.setTitle("product.buy_now".localized, for: .normal)
                }
            }else{
                cell.isOutOfStockLabelHidden = true
                cell.isPriceAlertButtonHidden = true
                cell.isCartButtonHidden = false
                cell.isShareButtonHidden = true
                cell.cartButton.setTitle("product.buy_now".localized, for: .normal)
            }
            
            cell.priceAlertButton.addTarget(self, action: #selector(trackProductAction(_:event:)), for: .touchUpInside)
            cell.cartButton.addTarget(self, action: #selector(addToCartOrBuyNowProductAction(_:event:)), for: .touchUpInside)
            cell.shareButton.addTarget(self, action: #selector(shareProductAction(_:event:)), for: .touchUpInside)

        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView.init()
    }
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView.init()
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0
    }
    @objc func reloadTableView(){
        if self.isViewLoaded {
            self.tableView.reloadData()
        }
    }
}

extension FavoriteProductsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        presentProduct(at: indexPath)
    }
}

extension FavoriteProductsViewController: FetchedResultsControllerManagerDelegate {
    func managerDidChangeContent(_ controller: NSObject, change: FetchedResultsControllerManagerChange){
        if self.isViewLoaded {
            change.applyChanges(tableView: tableView)
        }
    }

}
