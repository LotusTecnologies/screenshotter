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
}

extension ProductsBarController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 5
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProductsBarCollectionView.cellIdentifier, for: indexPath)
        
        if let cell = cell as? ProductsBarCollectionViewCell {
            var r: CGFloat {
                return CGFloat(arc4random()) / CGFloat(UInt32.max)
            }
            
            cell.backgroundColor = UIColor(red: r, green: r, blue: r, alpha: 1)
        }
        
        return cell
    }
}

extension ProductsBarController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.height * 0.75, height: collectionView.bounds.height)
    }
}

extension ProductsBarController: UICollectionViewDelegate {
    
}
