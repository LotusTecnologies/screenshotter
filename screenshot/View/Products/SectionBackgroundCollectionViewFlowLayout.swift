//
//  SectionBackgroundCollectionViewFlowLayout.swift
//  screenshot
//
//  Created by Jonathan Rose on 5/8/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import UIKit

class SectionBackgroundCollectionViewFlowLayout: UICollectionViewFlowLayout {
    static public let ElementKindSectionSectionBackground = "io.craze.screenshot.ElementKindSectionSectionBackground"

    private var decorationItems:[UICollectionViewLayoutAttributes] = []
    
    func loadDecorationItems () {
        decorationItems.removeAll()
        
        
        if let collectionView = self.collectionView {
            
            let lastSection = collectionView.numberOfSections - 1
            if lastSection > 0 {
                for section in 0...lastSection {
                    
                    let lastIndex = collectionView.numberOfItems(inSection: section) - 1
                    if lastIndex < 0 {
                        continue
                    }
                    if let firstItem = self.layoutAttributesForItem(at: IndexPath(row: 0, section: section)), let lastItem = self.layoutAttributesForItem(at: IndexPath(row: lastIndex, section: section)){
                        
                        
                        var sectionInset = self.sectionInset;
                        if let delegate = self.collectionView?.delegate as? UICollectionViewDelegateFlowLayout {
                            sectionInset = (delegate.collectionView?(collectionView, layout: self, insetForSectionAt: section)) ?? self.sectionInset
                        }
                        
                        
                        
                        var frame = firstItem.frame.union(lastItem.frame)
                        frame.origin.x -= sectionInset.left;
                        frame.origin.y -= sectionInset.top;
                        
                        if (self.scrollDirection == .horizontal)
                        {
                            frame.size.width += sectionInset.left + sectionInset.right;
                            frame.size.height = collectionView.frame.size.height;
                        }
                        else
                        {
                            frame.size.width = collectionView.frame.size.width;
                            frame.size.height += sectionInset.top + sectionInset.bottom;
                        }
                        
                        
                        let attributes = UICollectionViewLayoutAttributes.init(forSupplementaryViewOfKind: SectionBackgroundCollectionViewFlowLayout.ElementKindSectionSectionBackground, with: IndexPath.init(row: 0, section: section))
                        attributes.zIndex = -1;
                        attributes.frame = frame;
                        self.decorationItems.append(attributes)
                    }
                }
            }
        }
    }
    override func prepare() {
        super.prepare()
        self.loadDecorationItems()
    }
    override func invalidateLayout() {
        super.invalidateLayout()
        self.loadDecorationItems()
    }
    override func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
        super.invalidateLayout(with: context)
        self.loadDecorationItems()
    }
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return false
    }
    override func layoutAttributesForDecorationView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if elementKind == SectionBackgroundCollectionViewFlowLayout.ElementKindSectionSectionBackground {
            return self.decorationItems[indexPath.section]
        }else{
            return super.layoutAttributesForSupplementaryView(ofKind: elementKind, at: indexPath)
        }
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var attributes = super.layoutAttributesForElements(in: rect)
        for a in self.decorationItems {
            if a.frame.intersects(rect) {
                attributes?.append(a)
            }
        }
        return attributes
    }
}
