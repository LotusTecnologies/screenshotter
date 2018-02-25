//
//  ProductsBarCollectionView.swift
//  screenshot
//
//  Created by Corey Werner on 2/18/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation
import UIKit

class ProductsBarCollectionView: UICollectionView {
    static let cellIdentifier = "productsBarCell"
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        
        register(ProductsBarCollectionViewCell.self, forCellWithReuseIdentifier: ProductsBarCollectionView.cellIdentifier)
        showsHorizontalScrollIndicator = false
        contentInset = UIEdgeInsets(top: 0, left: .padding, bottom: 0, right: .padding)
        scrollsToTop = false
    }
}

class ProductsBarCollectionViewLayout: UICollectionViewFlowLayout {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init() {
        super.init()
        
        scrollDirection = .horizontal
        minimumLineSpacing = .padding
    }
}
