//
//  DiscoverScreenshotCollectionViewLayout.swift
//  screenshot
//
//  Created by Corey Werner on 1/14/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation

protocol DiscoverScreenshotCollectionViewLayoutDelegate : NSObjectProtocol {
    func discoverScreenshotCollectionViewLayoutIsAdding(_ layout: DiscoverScreenshotCollectionViewLayout) -> Bool
}

class DiscoverScreenshotCollectionViewLayout : UICollectionViewLayout {
    weak var delegate: DiscoverScreenshotCollectionViewLayoutDelegate?
    
    private var cardCount = 2
    private var contentRect: CGRect = .zero
    private(set) var cardFrame: CGRect = .zero
    private var visibleCardAttributes: [UICollectionViewLayoutAttributes] = []
    
    private var deletedItems: [IndexPath] = []
    private var insertedItems: [IndexPath] = []
    
    
    override func prepare() {
        guard let collectionView = collectionView else {
            return
        }
        
        contentRect = UIEdgeInsetsInsetRect(collectionView.bounds, collectionView.contentInset)
        
        let screenshotSize = CGSize(width: contentRect.size.height * Screenshot.discoverRatio.width, height: contentRect.size.height)
        cardFrame = screenshotSize.aspectFitRectInSize(contentRect.size)
        
        visibleCardAttributes = makeVisibleCardAttributes()
        deletedItems = []
        insertedItems = []
    }
    
    
    override func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
        deletedItems = updateItems.filter({ collectionViewUpdateItem -> Bool in
            return collectionViewUpdateItem.updateAction == .delete
        }).flatMap({ collectionViewUpdateItem -> IndexPath? in
            return collectionViewUpdateItem.indexPathBeforeUpdate
        })
        
        insertedItems = updateItems.filter({ collectionViewUpdateItem -> Bool in
            return collectionViewUpdateItem.updateAction == .insert
        }).flatMap({ collectionViewUpdateItem -> IndexPath? in
            return collectionViewUpdateItem.indexPathAfterUpdate
        })
    }
    
    override var collectionViewContentSize: CGSize {
        return contentRect.size
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return visibleCardAttributes
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return makeLayoutAttributesForItem(at: indexPath)
    }
    
    override func initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attr = makeLayoutAttributesForItem(at: itemIndexPath)
        
        if insertedItems.contains(itemIndexPath) {
            //            if let callback = delegate?.collectionView(_:deckLayout:willInsertItem:) {
            //                callback(collectionView!, self, attr)
            //            } else {
            attr.alpha = 0
            //            }
        }
        
        return attr
    }
    
    override func finalLayoutAttributesForDisappearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes = makeLayoutAttributesForItem(at: itemIndexPath)
        
        if deletedItems.contains(itemIndexPath) || itemIndexPath.item == 0 {
            attributes.zIndex += 1
            
            let isAdded = delegate?.discoverScreenshotCollectionViewLayoutIsAdding(self) ?? false
            let direction: CGFloat = isAdded ? 1 : -1
            let rotationAngle = CGFloat(Double.pi * 0.1) * direction
            let rotatedRect = attributes.frame.applying(CGAffineTransform(rotationAngle: rotationAngle))
            
            // Better to use center then translation on the transform incase
            // future development will incorporate UIDynamics
            attributes.center = CGPoint(x: attributes.frame.midX + (rotatedRect.size.width * direction), y: cardFrame.midY)
            
            attributes.transform = CGAffineTransform(rotationAngle: rotationAngle)
        }
        
        return attributes
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    private func makeVisibleCardAttributes() -> [UICollectionViewLayoutAttributes] {
        var result: [UICollectionViewLayoutAttributes] = []
        
        guard let collectionView = collectionView else {
            return result
        }
        
        for section in 0 ..< collectionView.numberOfSections {
            for item in 0 ..< collectionView.numberOfItems(inSection: section) {
                result.append(makeLayoutAttributesForItem(offset: result.count, at: IndexPath(item: item, section: section)))
                
                if result.count == cardCount {
                    return result
                }
            }
        }
        
        return result
    }
    
    private func makeLayoutAttributesForItem(offset: Int? = nil, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes {
        let attr = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        
        guard let collectionView = collectionView else {
            return attr
        }
        
        let offset = offset ?? (0 ..< indexPath.section).reduce(indexPath.item) { (item, section) in
            return item + collectionView.numberOfItems(inSection: section)
        }
        
        attr.frame = cardFrame
        attr.zIndex = -offset * 2
        
        let scaleRatio = CGFloat(0.9)
        let scale = max(0, 1 - (1 - scaleRatio) * CGFloat(offset))
        attr.transform = CGAffineTransform(scaleX: scale, y: scale)
        
        return attr
    }
    
    func progressFinalAttributes(_ attributes: UICollectionViewLayoutAttributes, cell: DiscoverScreenshotCollectionViewCell, percent: CGFloat) {
        let c1 = CGPoint(x: cardFrame.midX, y: cardFrame.midY)
        let c2 = attributes.center
        var c3 = cell.center
        c3.x = c1.x + (c2.x - c1.x) * percent
        c3.y = c1.y + (c2.y - c1.y) * percent
        cell.center = c3
        
        let t1 = CGAffineTransform.identity
        let t2 = attributes.transform
        var t3 = cell.transform
        t3.a = t1.a + (t2.a - t1.a) * percent
        t3.b = t1.b + (t2.b - t1.b) * percent
        t3.c = t1.c + (t2.c - t1.c) * percent
        t3.d = t1.d + (t2.d - t1.d) * percent
        t3.tx = t1.tx + (t2.tx - t1.tx) * percent
        t3.ty = t1.ty + (t2.ty - t1.ty) * percent
        cell.transform = t3
    }
}
