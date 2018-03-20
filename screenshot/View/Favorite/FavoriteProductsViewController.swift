//
//  FavoriteProductsViewController.swift
//  screenshot
//
//  Created by Corey Werner on 12/27/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import UIKit

class FavoriteProductsView: UIView {
    let tableView = UITableView(frame: .zero, style: .grouped)
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tableView)
        tableView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    }
}

class FavoriteProductsViewController : BaseViewController {
    fileprivate var favoriteProductsView: FavoriteProductsView {
        return view as! FavoriteProductsView
    }
    
    var products: [Product]?
    
    fileprivate var unfavoriteProducts: [Product] = []
    
    override var title: String? {
        set {}
        get {
            return "favorites.items.title".localized
        }
    }
    
    // MARK: Life Cycle
    
    override func loadView() {
        view = FavoriteProductsView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        favoriteProductsView.tableView.dataSource = self
        favoriteProductsView.tableView.delegate = self
        favoriteProductsView.tableView.backgroundColor = view.backgroundColor
        favoriteProductsView.tableView.allowsSelection = false
        favoriteProductsView.tableView.register(FavoriteProductsTableViewCell.self, forCellReuseIdentifier: "cell")
        favoriteProductsView.tableView.rowHeight = UITableViewAutomaticDimension
        favoriteProductsView.tableView.estimatedRowHeight = 200
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
            cell.contentView.backgroundColor = .background // TODO: change to cell background
            
            cell.productImageView.setImage(withURLString: product.imageURL)
            cell.titleLabel.text = product.productDescription // TODO: use product.productTitle()
            cell.priceLabel.text = product.price
            cell.merchantLabel.text = product.merchant
        }
        
        return cell
    }
}

extension FavoriteProductsViewController: UITableViewDelegate {
    
}

extension FavoriteProductsViewController : UICollectionViewDataSource {
    var numberOfCollectionViewColumns: Int {
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return products?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        
        if let cell = cell as? ProductCollectionViewCell, let product = products?[indexPath.item] {
            cell.contentView.backgroundColor = collectionView.backgroundColor
            cell.title = product.productDescription
            cell.price = product.price
            cell.imageUrl = product.imageURL
            cell.favoriteButton?.isSelected = product.isFavorite
        }
        
        return cell
    }
}

extension FavoriteProductsViewController : UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let product = products?[indexPath.item] else {
            return
        }
        OpenProductPage.present(product: product, fromViewController: self, analyticsKey: .tappedOnProductFavorites, fromPage: "Favorites")
    }
}

//extension FavoriteProductsViewController : ProductCollectionViewCellDelegate {
//    func productCollectionViewCellDidTapFavorite(cell: ProductCollectionViewCell) {
//        guard let indexPath = collectionView.indexPath(for: cell), let product = products?[indexPath.item] else {
//            return
//        }
//
//        let isFavorited = cell.favoriteButton?.isSelected ?? false
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

