//
//  FavoriteProductsViewController.swift
//  screenshot
//
//  Created by Corey Werner on 12/27/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation
import UIKit

class FavoriteProductsViewController : BaseViewController {
    fileprivate let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    
    var products: [Product]?
    
    fileprivate var unfavoriteProducts: [Product] = []
    
    override var title: String? {
        set {}
        get {
            return "favorites.items.title".localized
        }
    }
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.minimumInteritemSpacing = .padding
            layout.minimumLineSpacing = .padding
        }
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.contentInset = UIEdgeInsets(top: .padding, left: .padding, bottom: .padding, right: .padding)
        collectionView.backgroundColor = view.backgroundColor
        collectionView.register(ProductCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        view.addSubview(collectionView)
        collectionView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeUnfavorited()
    }
    
    deinit {
        collectionView.delegate = nil
        collectionView.dataSource = nil
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
            cell.favoriteControl.isSelected = product.isFavorite
            cell.favoriteControl.addTarget(self, action: #selector(productCollectionViewCellFavoriteAction(_:event:)), for: .touchUpInside)
        }
        
        return cell
    }
}

extension FavoriteProductsViewController : UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let product = products?[indexPath.item] else {
            return
        }
        self.presentProduct(product, from:"Favorites")
    }
}

extension FavoriteProductsViewController : UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let columns = CGFloat(numberOfCollectionViewColumns)
        
        var size = CGSize.zero
        size.width = (collectionView.bounds.size.width - ((columns + 1) * .padding)) / columns
        size.height = size.width + ProductCollectionViewCell.labelsHeight
        return size
    }
}

typealias FavoriteProductsViewControllerProductCollectionViewCell = FavoriteProductsViewController
extension FavoriteProductsViewControllerProductCollectionViewCell {
    func productCollectionViewCellFavoriteAction(_ favoriteControl: FavoriteControl, event: UIEvent) {
        guard let location = event.allTouches?.first?.location(in: collectionView),
            let indexPath = collectionView.indexPathForItem(at: location),
            let product = products?[indexPath.item]
            else {
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

        AnalyticsTrackers.standard.trackFavorited(isFavorited, product: product, onPage: "Favorites")
    }
}
