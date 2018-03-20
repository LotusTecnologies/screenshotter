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
        tableView.allowsSelection = false
        tableView.register(FavoriteProductsTableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 200
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeUnfavorited()
    }
    
    deinit {
        favoriteProductsView.tableView.dataSource = nil
        favoriteProductsView.tableView.delegate = nil
    }
    
    // MARK: Favorites
    
    fileprivate func removeUnfavorited() {
        guard unfavoriteProducts.count > 0 else {
            return
        }
        
        DataModel.sharedInstance.unfavorite(favoriteArray: unfavoriteProducts)
        unfavoriteProducts.removeAll()
    }
}

extension FavoriteProductsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        if let cell = cell as? FavoriteProductsTableViewCell, let product = products?[indexPath.item] {
            cell.contentView.backgroundColor = .cellBackground
            
            cell.productImageView.setImage(withURLString: product.imageURL)
            cell.titleLabel.text = product.productTitle()
            cell.priceLabel.text = product.price
            cell.merchantLabel.text = product.merchant
//            cell.favoriteControl.isSelected = product.isFavorite
//            cell.favoriteControl.addTarget(self, action: #selector(productCollectionViewCellFavoriteAction(_:event:)), for: .touchUpInside)
        }
        
        return cell
    }
}

extension FavoriteProductsViewController: UITableViewDelegate {
    
}

extension FavoriteProductsViewController : UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let product = products?[indexPath.item] else {
            return
        }
        
        OpenWebPage.presentProduct(product, fromViewController: self)
//        OpenProductPage.present(product: product, fromViewController: self, analyticsKey: .tappedOnProductFavorites, fromPage: "Favorites")
    }
}

//extension FavoriteProductsViewController {
//    func productCollectionViewCellFavoriteAction(_ favoriteControl: FavoriteControl, event: UIEvent) {
//        guard let location = event.allTouches?.first?.location(in: collectionView),
//            let indexPath = collectionView.indexPathForItem(at: location),
//            let product = products?[indexPath.item]
//            else {
//                return
//        }
//
//        let isFavorited = favoriteControl.isSelected
//
//        if isFavorited {
//            if let index = unfavoriteProducts.index(of: product) {
//                unfavoriteProducts.remove(at: index)
//            }
//        }
//        else {
//            unfavoriteProducts.append(product)
//        }
//
//        AnalyticsTrackers.standard.trackFavorited(isFavorited, product: product, onPage: "Favorites")
//    }
//}

