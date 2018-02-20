//
//  ProductsBarController.swift
//  screenshot
//
//  Created by Corey Werner on 2/18/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation
@objc protocol ProductsBarControllerDelegate : NSObjectProtocol {
    func productBarShouldHide(_ controller:ProductsBarController)
    func productBarShouldShow(_ controller:ProductsBarController)
    func productBar(_ controller:ProductsBarController, didTap product:Product)
}
class ProductsBarController: NSObject, FetchedResultsControllerManagerDelegate {
    
    @objc weak var delegate:ProductsBarControllerDelegate?
    var productsFrc: FetchedResultsControllerManager<Product>?
    
    private var isNotHidden:Bool?
    var collectionView: ProductsBarCollectionView? {
        didSet {
            guard let collectionView = collectionView else {
                return
            }
            collectionView.dataSource = self
            collectionView.delegate = self
            collectionView.reloadData()
        }
    }
    
    fileprivate var products:[Product] = []
    
    func setup(){
        self.productsFrc = DataModel.sharedInstance.productBarFrc(delegate: self)
        self.setupProductList()
        self.isNotHidden = self.hasProducts
        if self.hasProducts {
            self.delegate?.productBarShouldShow(self)
        }else{
            self.delegate?.productBarShouldHide(self)
        }
    }
    func setupProductList(){
        if let recentsProducts = self.productsFrc?.fetchedResultsController.fetchedObjects {
            let oneWeekAgo = Date.init(timeIntervalSinceNow: -60*60*24*7)
            self.products = recentsProducts.filter({ (p) -> Bool in
                return p.isFavorite || p.sortDateForProductBar > oneWeekAgo
            }).sorted { $0.sortDateForProductBar > $1.sortDateForProductBar }
            
        }
    }
    
    var hasProducts: Bool {
        return products.count >= 4
    }
    
    func managerDidChangeContent(_ controller: NSObject, change: FetchedResultsControllerManagerChange) {
        setupProductList()
        if self.isNotHidden != self.hasProducts {
            self.isNotHidden = self.hasProducts
            
            if self.hasProducts {
                self.collectionView?.reloadData()
                self.collectionView?.contentOffset = .zero
                self.delegate?.productBarShouldShow(self)
            }else{
                self.delegate?.productBarShouldHide(self)
                self.collectionView?.reloadData()
                self.collectionView?.contentOffset = .zero
            }
        }else{
            //just updates but remain hidden or unhidden
            self.collectionView?.reloadData()
        }

    }
    
}

extension ProductsBarController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.products.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProductsBarCollectionView.cellIdentifier, for: indexPath)
        let product = self.products[indexPath.item]
        
        if let cell = cell as? ProductsBarCollectionViewCell {
            cell.isFavorited = product.isFavorite
            cell.isSale = product.isSale()
            
            if let urlString = product.imageURL, let url = URL.init(string: urlString) {
                cell.imageView.sd_setImage(with: url, placeholderImage: nil, options: [.retryFailed, .highPriority], completed: nil)
            }else{
                cell.imageView.image = nil
            }
            
        }
        
        return cell
    }
}

extension ProductsBarController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let height = collectionView.bounds.height - (.padding * 2)
        return CGSize(width: height * 0.75, height: height)
    }
}

extension ProductsBarController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let product = self.products[indexPath.item]
        self.delegate?.productBar(self, didTap: product)
    }
}
