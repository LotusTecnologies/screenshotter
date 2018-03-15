//
//  ProductsCollectionView.swift
//  screenshot
//
//  Created by Corey Werner on 3/15/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class ProductsCollectionView: UICollectionView {
    static let cellSize: CGSize = {
        let width: CGFloat = 144
        let height = ProductsCollectionViewCell.cellHeight(for: width)
        return CGSize(width: width, height: height)
    }()
    
    var products: [Product]?
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    convenience init() {
        let layout = UICollectionViewFlowLayout()
        
        self.init(frame: .zero, collectionViewLayout: layout)
        
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = minimumSpacing.x
        layout.minimumLineSpacing = minimumSpacing.y
        layout.itemSize = ProductsCollectionView.cellSize
    }
    
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        super.dataSource = self
        
        contentInset = UIEdgeInsets(top: .padding, left: .padding, bottom: .padding, right: .padding)
        register(ProductsCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
    }
    
    // MARK: Layout
    
    var minimumSpacing: CGPoint = {
        let shadowInsets = ScreenshotCollectionViewCell.shadowInsets
        let x = .padding - shadowInsets.left - shadowInsets.right
        let y = .padding - shadowInsets.top - shadowInsets.bottom
        return CGPoint(x: x, y: y)
    }()
    
    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        
        if numberOfItems(inSection: 0) > 0 {
            size.height = ProductsCollectionView.cellSize.height + contentInset.top + contentInset.bottom
        }
        
        return size
    }
    
    // MARK: Favorite
    
    @objc fileprivate func favoriteAction(_ favoriteControl: FavoriteControl, event: UIEvent) {
        guard let location = event.allTouches?.first?.location(in: self),
            let indexPath = indexPathForItem(at: location)
            else {
                return
        }
        
        // TODO: Analytics
    }
}

extension ProductsCollectionView: UICollectionViewDataSource {
    override var dataSource: UICollectionViewDataSource? {
        set {}
        get {
            return self
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return products?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        
        if let cell = cell as? ProductsCollectionViewCell, let product = products?[indexPath.item] {
            cell.contentView.backgroundColor = collectionView.backgroundColor
            cell.title = product.displayTitle
            cell.price = product.price
            cell.originalPrice = product.originalPrice
            cell.imageUrl = product.imageURL
            cell.isSale = product.isSale()
            cell.favoriteControl.isSelected = product.isFavorite
            cell.favoriteControl.addTarget(self, action: #selector(favoriteAction), for: .touchUpInside)
        }
        
        return cell
    }
}
