//
//  DiscoverScreenshotViewController.swift
//  screenshot
//
//  Created by Corey Werner on 1/7/18.
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
    private var cardFrame: CGRect = .zero
    private var visibleCardAttributes: [UICollectionViewLayoutAttributes] = []
    
    private var deletedItems: [IndexPath] = []
    private var insertedItems: [IndexPath] = []
    
    
    override func prepare() {
        guard let collectionView = collectionView else {
            return
        }
        
        contentRect = UIEdgeInsetsInsetRect(collectionView.bounds, collectionView.contentInset)
        cardFrame = UIEdgeInsetsInsetRect(contentRect, UIEdgeInsetsMake(20, 20, 20, 20)) // TOOD: create card size from ratio and collection view size
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
            
            attributes.transform = CGAffineTransform(translationX: rotatedRect.size.width * direction, y: 50).rotated(by: rotationAngle)
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
}


class DiscoverScreenshotViewController : BaseViewController {
    fileprivate let collectionView = UICollectionView(frame: .zero, collectionViewLayout: DiscoverScreenshotCollectionViewLayout())
    
    fileprivate var isAdding = false
    
    // MARK: Life Cycle
    
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
        
        if let layout = collectionView.collectionViewLayout as? DiscoverScreenshotCollectionViewLayout {
            layout.delegate = self
        }
        
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
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(collectionViewPanGestureAction(_:)))
        collectionView.addGestureRecognizer(panGesture)
    }
    
    deinit {
        collectionView.dataSource = nil
        collectionView.delegate = nil
    }
    
    fileprivate var count = 10
    
    @objc private func passButtonAction() {
        isAdding = false
        
        collectionView.performBatchUpdates({
            self.count -= 1
            collectionView.deleteItems(at: [IndexPath(item: 0, section: 0)])
            
        }, completion: { _ in
            // TODO: disable additional button presses until completed
        })
    }
    
    @objc private func addButtonAction() {
        isAdding = true
        
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

extension DiscoverScreenshotViewController : DiscoverScreenshotCollectionViewLayoutDelegate {
    func discoverScreenshotCollectionViewLayoutIsAdding(_ layout: DiscoverScreenshotCollectionViewLayout) -> Bool {
        return isAdding
    }
}

extension DiscoverScreenshotViewController : UIGestureRecognizerDelegate {
    @objc fileprivate func collectionViewPanGestureAction(_ panGesture: UIPanGestureRecognizer) {
        guard let collectionViewLayout = collectionView.collectionViewLayout as? DiscoverScreenshotCollectionViewLayout else {
            return
        }
        
        let translation = panGesture.translation(in: panGesture.view)
//        let location = panGesture.location(in: panGesture.view)
        
        // TODO: add var which only does the changed if the pan location started on the cell
        
        switch panGesture.state {
        case .changed:
            isAdding = translation.x > 0
            
            collectionView.indexPathsForVisibleItems.forEach { indexPath in
                if let cell = collectionView.cellForItem(at: indexPath),
                    let attributes = collectionViewLayout.finalLayoutAttributesForDisappearingItem(at: indexPath)
                {
                    
                    let minDistanceNeeded = CGFloat(150)
                    
                    // Only the first cell should move in the expected direction
                    let direction = CGFloat(indexPath.item == 0 ? 0 : 1)
                    let percent = abs(direction - min(1, abs(translation.x / 2) / collectionView.center.x))
                    
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
            
        default:
            print("")
        }
        
    }
}
