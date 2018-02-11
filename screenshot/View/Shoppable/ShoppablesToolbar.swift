//
//  ShoppablesToolbar.swift
//  screenshot
//
//  Created by Jonathan Rose on 2/11/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation
extension ShoppablesToolbar {
    @objc func setupViews() {
        self.collectionView = {
            let p:CGFloat = Geometry.padding
            let layout = UICollectionViewFlowLayout.init()
            layout.minimumInteritemSpacing = p
            layout.minimumLineSpacing = p
            layout.scrollDirection = .horizontal
            let collectionView = ShoppablesCollectionView.init(frame: CGRect.zero, collectionViewLayout: layout)
            collectionView.translatesAutoresizingMaskIntoConstraints = false
            collectionView.delegate = self;
            collectionView.dataSource = self;
            collectionView.backgroundColor = .clear
            collectionView.scrollsToTop = false;
            collectionView.contentInset = ShoppablesToolbar.preservedCollectionViewContentInset()
            collectionView.showsHorizontalScrollIndicator = false;
            collectionView.register(ShoppableCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
            self.addSubview(collectionView)
            collectionView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
            collectionView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
            collectionView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
            collectionView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
            
            return collectionView
        }()
    
    }
}
