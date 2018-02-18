//
//  ProductsBarController.swift
//  screenshot
//
//  Created by Corey Werner on 2/18/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation

class ProductsBarController: NSObject {
    var collectionView: ProductsBarCollectionView? {
        didSet {
            guard let collectionView = collectionView else {
                return
            }
            
            collectionView.dataSource = self
            collectionView.delegate = self
        }
    }
    
    fileprivate let numberOfProducts = 5
    
    var hasProducts: Bool {
        return numberOfProducts >= 4
    }
}

extension ProductsBarController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numberOfProducts
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProductsBarCollectionView.cellIdentifier, for: indexPath)
        
        if let cell = cell as? ProductsBarCollectionViewCell {
            if indexPath.item == 1 {
                cell.isFavorited = true
            }
            if indexPath.item == 2 {
                cell.isSale = true
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
    
}
