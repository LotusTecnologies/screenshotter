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
    @objc func shoppableSize() -> CGSize {
        
        var size = CGSize.zero
        size.height = self.collectionView.bounds.size.height - self.collectionView.contentInset.top - self.collectionView.contentInset.bottom;
        size.width = size.height * 0.8
        return size
    }
    
    @objc func repositionShoppables(count:Int) {
        
        let shoppablesCount = count
        
        if (shoppablesCount > 0) {
            let  lineSpacing = (self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.minimumLineSpacing ?? 0
            let spacingsWidth:CGFloat = lineSpacing * CGFloat(shoppablesCount - 1)
            let shoppablesWidth:CGFloat = self.shoppableSize().width * CGFloat(shoppablesCount)
            let contentWidth:CGFloat = round(spacingsWidth + shoppablesWidth);
            let width:CGFloat = self.collectionView.bounds.size.width - self.collectionView.contentInset.left - self.collectionView.contentInset.right;
            
            if (width != contentWidth) {
                let maxHorizontalInset:CGFloat = ShoppablesToolbar.preservedCollectionViewContentInset().left
                
                var insets = self.collectionView.contentInset;
                let i = CGFloat.maximum(maxHorizontalInset, floor( (self.collectionView.bounds.size.width - contentWidth) / 2.0) )
                insets.left = i
                insets.right = i
                self.collectionView.contentInset = insets
            }
        }
    }
    
    @objc func selectFirstShoppable() {
        if self.collectionView.numberOfItems(inSection: 0) > 0{
            self.collectionView.selectItem(at: IndexPath.init(item: 0, section: 0), animated: false, scrollPosition: [])
        } else {
            self.needsToSelectFirstShoppable = true
        }
    }
    

    @objc func selectedShoppableIndex() -> Int {
        return self.collectionView.indexPathsForSelectedItems?.first?.item ?? 0
    }
}
