//
//  FavoriteProductsViewController.swift
//  screenshot
//
//  Created by Corey Werner on 12/27/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import UIKit

class FavoriteProductsViewController : BaseViewController {
    var products: [Product]?
    
    fileprivate var unfavoriteProducts: [Product] = []
    
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
    
    var tableView: UITableView {
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
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeUnfavorited()
    }
    
    deinit {
        tableView.dataSource = nil
        tableView.delegate = nil
    }
    
    // MARK: Favorites
    
    fileprivate func removeUnfavorited() {
        guard unfavoriteProducts.count > 0 else {
            return
        }
        
        DataModel.sharedInstance.unfavorite(favoriteArray: unfavoriteProducts)
        unfavoriteProducts.removeAll()
    }
    
    @objc fileprivate func favoriteProductAction(_ favoriteControl: FavoriteControl, event: UIEvent) {
        guard let indexPath = tableView.indexPath(for: event), let product = products?[indexPath.item] else {
            return
        }
        
        let isFavorited = favoriteControl.isSelected
        
        if isFavorited {
            if let index = unfavoriteProducts.index(of: product) {
                unfavoriteProducts.remove(at: index)
            }
        }
        else {
            unfavoriteProducts.append(product)
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
                let product = products?[indexPath.item],
                !button.isLoading
                else {
                    return
            }
            
            button.isLoading = true
            let hasPriceAlerts =  product.hasPriceAlerts
            if hasPriceAlerts {
                Analytics.trackProductPriceAlertUnsubscribed(product: product)
            }else{
                Analytics.trackProductPriceAlertSubscribed(product: product)
            }
            
            (product.hasPriceAlerts ? product.untrack() : product.track())
                .then { [weak button] isTracking -> Void in
                    button?.isLoading = false
                    button?.isSelected = isTracking
                    
                }.catch { [weak button] error in
                    button?.isLoading = false
                    let e = error as NSError
                    if hasPriceAlerts {
                        Analytics.trackProductPriceAlertUnsubscribedError(product: product, domain: e.domain, code: e.code, localizedDescription: e.localizedDescription)
                    }else{
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
        guard let product = products?[indexPath.item] else {
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

extension FavoriteProductsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        if let cell = cell as? FavoriteProductsTableViewCell, let product = products?[indexPath.item] {
            cell.selectionStyle = .none
            cell.contentView.backgroundColor = .cellBackground
            cell.productImageView.setImage(withURLString: product.imageURL)
            cell.titleLabel.text = product.productTitle()
            cell.priceLabel.text = product.price
            cell.merchantLabel.text = product.merchant
            cell.favoriteControl.isSelected = product.isFavorite
            cell.favoriteControl.addTarget(self, action: #selector(favoriteProductAction(_:event:)), for: .touchUpInside)
            cell.priceAlertButton.isSelected = product.hasPriceAlerts // ???: what happens if this is true and the user disables notifications from settings
            cell.priceAlertButton.addTarget(self, action: #selector(trackProductAction(_:event:)), for: .touchUpInside)
            cell.cartButton.addTarget(self, action: #selector(presentProductAction(_:event:)), for: .touchUpInside)
            cell.isCartButtonHidden = (product.partNumber == nil)
        }
        
        return cell
    }
}

extension FavoriteProductsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        presentProduct(at: indexPath)
    }
}
