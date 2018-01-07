//
//  DiscoverScreenshotViewController.swift
//  screenshot
//
//  Created by Corey Werner on 1/7/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation


class DiscoverScreenshotCollectionViewLayout : UICollectionViewLayout {
    private var cardCount = 2
    private var contentRect: CGRect = .zero
    private var cardFrame: CGRect = .zero
    private var visibleCardAttributes: [UICollectionViewLayoutAttributes] = []
    
    private var deletedItems: [IndexPath] = []
    private var insertedItems: [IndexPath] = []
    
    
    open override func prepare() {
        guard let collectionView = collectionView else {
            return
        }
        
        contentRect = UIEdgeInsetsInsetRect(collectionView.bounds, collectionView.contentInset)
        cardFrame = UIEdgeInsetsInsetRect(contentRect, UIEdgeInsetsMake(20, 20, 20, 20)) // TOOD: create card size from ratio and collection view size
        visibleCardAttributes = makeVisibleCardAttributes()
        deletedItems = []
        insertedItems = []
    }
    
    open override func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
        deletedItems = updateItems
            .filter { $0.updateAction == .delete }
            .flatMap { $0.indexPathBeforeUpdate }
        insertedItems = updateItems
            .filter { $0.updateAction == .insert }
            .flatMap { $0.indexPathAfterUpdate }
    }
    
    open override var collectionViewContentSize: CGSize {
        return contentRect.size
    }
    
    open override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return visibleCardAttributes
    }
    
    open override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return makeLayoutAttributesForItem(at: indexPath)
    }
    
    open override func initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
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
    
    open override func finalLayoutAttributesForDisappearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attr = makeLayoutAttributesForItem(at: itemIndexPath)
        if deletedItems.contains(itemIndexPath)  {
            attr.zIndex += 1
//            if let callback = delegate?.collectionView(_:deckLayout:willDeleteItem:) {
//                callback(collectionView!, self, attr)
//            } else {
                attr.alpha = 0
//            }
        }
        return attr
    }
    
    open override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
//    private var delegate: DeckCollectionViewLayoutDelegate? {
//        return collectionView?.delegate as? DeckCollectionViewLayoutDelegate
//    }
    
    
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
        attr.transform = CGAffineTransform.identity // ???: needed?
        return attr
    }
}


class DiscoverScreenshotViewController : BaseViewController {
    fileprivate let collectionView = UICollectionView(frame: .zero, collectionViewLayout: DiscoverScreenshotCollectionViewLayout())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let passButton = UIButton()
        passButton.translatesAutoresizingMaskIntoConstraints = false
        passButton.setTitle("Pass", for: .normal)
        passButton.backgroundColor = .red
        passButton.addTarget(self, action: #selector(passButtonAction), for: .touchUpInside)
        view.addSubview(passButton)
        passButton.leadingAnchor.constraint(greaterThanOrEqualTo: view.layoutMarginsGuide.leadingAnchor).isActive = true
        passButton.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor, constant: -.padding).isActive = true
        passButton.trailingAnchor.constraint(equalTo: view.centerXAnchor, constant: -.padding).isActive = true
        
        let addButton = UIButton()
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.setTitle("Add", for: .normal)
        addButton.backgroundColor = .red
        addButton.addTarget(self, action: #selector(addButtonAction), for: .touchUpInside)
        view.addSubview(addButton)
        addButton.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: .padding).isActive = true
        addButton.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor, constant: -.padding).isActive = true
        addButton.trailingAnchor.constraint(lessThanOrEqualTo: view.layoutMarginsGuide.trailingAnchor).isActive = true
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .yellow
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        view.addSubview(collectionView)
        collectionView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: passButton.topAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    }
    
    fileprivate var count = 10
    
    @objc private func passButtonAction() {
        collectionView.performBatchUpdates({
            self.count -= 1
            collectionView.deleteItems(at: [IndexPath(item: 0, section: 0)])
            
        }, completion: { _ in
            
        })
    }
    
    @objc private func addButtonAction() {
        collectionView.performBatchUpdates({
            self.count += 1
            collectionView.insertItems(at: [IndexPath(item: 0, section: 0)])
            
        }, completion: { _ in
            
        })
    }
}

extension DiscoverScreenshotViewController : UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        
        let r = CGFloat(arc4random_uniform(255))
        let g = CGFloat(arc4random_uniform(255))
        let b = CGFloat(arc4random_uniform(255))
        cell.backgroundColor = UIColor(red: r/255, green: g/255, blue: b/255, alpha: 1)
        return cell
    }
}

extension DiscoverScreenshotViewController : UICollectionViewDelegate {
    
}
