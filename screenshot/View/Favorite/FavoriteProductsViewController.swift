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
    var  trackingProgressMonitors:[IndexPath:AsyncOperationMonitor] = [:]

    
    
    override var title: String? {
        set {}
        get {
            return "favorites.items.title".localized
        }
    }
    
    // MARK: Views
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        restorationIdentifier = String(describing: type(of: self))
        
        addNavigationItemLogo()
    }
    
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
    
    deinit {
        tableView.dataSource = nil
        tableView.delegate = nil
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
    
    // MARK: Tracking
    
    @objc fileprivate func trackProductAction(_ button: LoadingButton, event: UIEvent) {
        if PermissionsManager.shared.hasPermission(for: .push) {
            guard let indexPath = tableView.indexPath(for: event),
                let product = self.productsFRC?.object(at: indexPath),
                !button.isLoading
                else {
                    return
            }
            
            let hasPriceAlerts =  product.hasPriceAlerts
            if hasPriceAlerts {
                Analytics.trackProductPriceAlertUnsubscribed(product: product)
                product.untrack().catch { (error) in
                    let e = error as NSError
                    Analytics.trackProductPriceAlertUnsubscribedError(product: product, domain: e.domain, code: e.code, localizedDescription: e.localizedDescription)
                }
            }else{
                Analytics.trackProductPriceAlertSubscribed(product: product)
                product.track().catch { (error) in
                    let e = error as NSError
                    Analytics.trackProductPriceAlertSubscribedError(product: product, domain: e.domain, code: e.code, localizedDescription: e.localizedDescription)
                }
            }
        }
        else {
            if PermissionsManager.shared.permissionStatus(for: .push) == .undetermined {
                PermissionsManager.shared.requestPermission(for: .push)
            }
            else {
                if let alertController = PermissionsManager.shared.deniedAlertController(for: .push) {
                    present(alertController, animated: true, completion: nil)
                }
            }
        }
    }
    
    // MARK: Navigation
    
    fileprivate func presentProduct(at indexPath: IndexPath) {
        guard let product = self.productsFRC?.object(at: indexPath) else {
            return
        }
        
        presentProduct(product, atLocation: .favorite)
    }
    
    @objc fileprivate func presentProductAction(_ control: UIControl, event: UIEvent) {
        guard let indexPath = tableView.indexPath(for: event) else {
            return
        }
        
        presentProduct(at: indexPath)
    }
}

extension FavoriteProductsViewController: UITableViewDataSource, AsyncOperationMonitorDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.productsFRC?.fetchedObjectsCount ?? 0
    }
    
    func update(cell:FavoriteProductsTableViewCell, monitor:AsyncOperationMonitor, product:Product){
        cell.priceAlertButton.isLoading = monitor.didStart
        cell.isSelected = product.hasPriceAlerts  // ???: what happens if this is true and the user disables notifications from settings
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let monitor = self.trackingProgressMonitors[indexPath] {
//            monitor.delegate = nil
//            self.trackingProgressMonitors[indexPath] = nil
        }
    }
    
    func asyncOperationMonitorDidChange(_ monitor: AsyncOperationMonitor) {
        self.tableView.indexPathsForVisibleRows?.forEach({ (indexPath) in
            if let monitor = self.trackingProgressMonitors[indexPath], let cell = self.tableView.cellForRow(at: indexPath) as? FavoriteProductsTableViewCell, let product = self.productsFRC?.object(at: indexPath) {
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
            
            if product.isSupportingUSC, let partNumber = product.partNumber, !partNumber.isEmpty {
                cell.priceAlertButton.isHidden = false
                if let oldMonitor = self.trackingProgressMonitors[indexPath] {
                    oldMonitor.delegate = nil
                }
                let monitor = AsyncOperationMonitor.init(tracking: [partNumber], delegate: self)
                self.trackingProgressMonitors[indexPath] = monitor
                self.update(cell: cell, monitor: monitor, product: product)
                
                cell.priceAlertButton.addTarget(self, action: #selector(trackProductAction(_:event:)), for: .touchUpInside)
            } else {
                cell.priceAlertButton.isHidden = true
            }
            
            cell.cartButton.addTarget(self, action: #selector(presentProductAction(_:event:)), for: .touchUpInside)
            cell.isCartButtonHidden = !product.isSupportingUSC
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
