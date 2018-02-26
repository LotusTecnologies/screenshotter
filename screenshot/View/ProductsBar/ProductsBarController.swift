//
//  ProductsBarController.swift
//  screenshot
//
//  Created by Corey Werner on 2/18/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation
import CoreData
import UIKit

@objc protocol ProductsBarControllerDelegate : NSObjectProtocol {
    func productBarCountChanged(_ controller:ProductsBarController)
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
    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(significantTimeChange(_:)), name: Notification.Name.UIApplicationSignificantTimeChange, object: nil)
    }
    
    @objc func significantTimeChange(_ notificaiton:Notification){
        self.setup()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc var toUnfavoriteAndUnViewProductObjectIDs:[NSManagedObjectID] = [] {
        didSet{
            if let collectionView = self.collectionView {
                for indexPath in collectionView.indexPathsForVisibleItems {
                    if let cell = collectionView.cellForItem(at: indexPath) as? ProductsBarCollectionViewCell {
                        if let product =  self.productsFrc?.fetchedResultsController.object(at: indexPath) {
                            cell.isChecked = self.toUnfavoriteAndUnViewProductObjectIDs.contains(product.objectID)
                        }
                    }
                }
            }
        }
    }
    
    func setup(){
        self.productsFrc = DataModel.sharedInstance.productBarFrc(delegate: self)

        self.delegate?.productBarCountChanged(self)
        
        self.collectionView?.reloadData()
    }
    
    var count : Int {
        return self.productsFrc?.fetchedResultsController.fetchedObjectsCount ?? 0
    }
    
    func managerDidChangeContent(_ controller: NSObject, change: FetchedResultsControllerManagerChange) {
        
        if let collectionView = self.collectionView {
            change.applyChanges(collectionView: collectionView)
        }
        self.delegate?.productBarCountChanged(self)

    }
    
}

extension ProductsBarController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.productsFrc?.fetchedResultsController.fetchedObjectsCount ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProductsBarCollectionView.cellIdentifier, for: indexPath)
        
        
        if let cell = cell as? ProductsBarCollectionViewCell {
            if let product =  self.productsFrc?.fetchedResultsController.object(at: indexPath) {
                cell.isFavorited = product.isFavorite
                cell.isSale = product.isSale()
                
                if let urlString = product.imageURL, let url = URL.init(string: urlString) {
                    cell.imageView.sd_setImage(with: url, placeholderImage: nil, options: [.retryFailed, .highPriority], completed: nil)
                }else{
                    cell.imageView.image = nil
                }
                cell.isChecked = self.toUnfavoriteAndUnViewProductObjectIDs.contains(product.objectID)
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
        if let product =  self.productsFrc?.fetchedResultsController.object(at: indexPath) {
            self.delegate?.productBar(self, didTap: product)
        }
    }
}
