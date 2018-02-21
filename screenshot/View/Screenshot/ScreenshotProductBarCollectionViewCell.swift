//
//  ScreenshotProductBarCollectionViewCell.swift
//  screenshot
//
//  Created by Corey Werner on 2/18/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation
import UIKit

class ScreenshotProductBarCollectionViewCell: UICollectionViewCell {
    let collectionView = ProductsBarCollectionView(frame: .zero, collectionViewLayout: ProductsBarCollectionViewLayout())
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        layer.shadowColor = Shadow.basic.color.cgColor
        layer.shadowOffset = Shadow.basic.offset
        layer.shadowRadius = Shadow.basic.radius
        layer.shadowOpacity = 1
        layer.shadowPath = UIBezierPath(rect: bounds).cgPath
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .white
        contentView.addSubview(collectionView)
        collectionView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
    }
}
