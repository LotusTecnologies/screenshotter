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
    
    fileprivate var count = 10
    
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
        collectionView.contentInset = UIEdgeInsets(top: .padding, left: .padding, bottom: .padding, right: .padding)
        collectionView.scrollsToTop = false
        collectionView.register(DiscoverScreenshotCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        view.addSubview(collectionView)
        collectionView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: passButton.topAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(collectionViewPanGestureAction(_:)))
        collectionView.addGestureRecognizer(panGesture)
    }
    
    deinit {
        if let layout = collectionView.collectionViewLayout as? DiscoverScreenshotCollectionViewLayout {
            layout.delegate = nil
        }
        
        collectionView.dataSource = nil
        collectionView.delegate = nil
    }
    
    // MARK: Actions
    
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
        
        let indexPath = IndexPath(item: 0, section: 0)
        let cell = collectionView.cellForItem(at: indexPath)
        
        collectionView.performBatchUpdates({
            if let cell = cell as? DiscoverScreenshotCollectionViewCell {
//                cell.decisionValue = 1
                cell.layer.speed = 0.2
            }
            
            self.count -= 1
            collectionView.deleteItems(at: [indexPath])
            
        }, completion: { _ in
            
        })
    }
    
    @objc private func collectionViewPanGestureAction(_ panGesture: UIPanGestureRecognizer) {
        // TODO: use UIDynamicItem to create correct gravity effect. if view goes beyond threshold, update target point
        // only do this if can not get code to work
        
        guard let collectionViewLayout = collectionView.collectionViewLayout as? DiscoverScreenshotCollectionViewLayout else {
            return
        }
        
        var translation = panGesture.translation(in: panGesture.view)
//        let location = panGesture.location(in: panGesture.view)
        
        let percent = min(1, max(-1, (translation.x / 2) / collectionView.center.x))
        let decisionValueThreshold = percent * 3
        
        // TODO: add var which only does the changed if the pan location started on the cell
        
//        var a = 1
//        print("|||1 \(a)")
        func updateCell(atIndexPath indexPath: IndexPath) {
            if let cell = collectionView.cellForItem(at: indexPath) as? DiscoverScreenshotCollectionViewCell,
                let attributes = collectionViewLayout.finalLayoutAttributesForDisappearingItem(at: indexPath)
            {
                let percent = min(1, max(-1, (translation.x / 2) / collectionView.center.x))
                let decisionValueThreshold = percent * 3
                
                // Only the first cell should move in the expected direction
                let direction = CGFloat(indexPath.item == 0 ? 0 : 1)
                let itemPercent = abs(direction - abs(percent))
                
//                print("|||2 \(a)")
                if indexPath.item == 0 {
                    cell.decisionValue = decisionValueThreshold
                }
                
                let t1 = CGAffineTransform.identity
                let t2 = attributes.transform
                
                var t3 = cell.transform
                t3.a = t1.a + (t2.a - t1.a) * itemPercent
                t3.b = t1.b + (t2.b - t1.b) * itemPercent
                t3.c = t1.c + (t2.c - t1.c) * itemPercent
                t3.d = t1.d + (t2.d - t1.d) * itemPercent
                t3.tx = t1.tx + (t2.tx - t1.tx) * itemPercent
                t3.ty = t1.ty + (t2.ty - t1.ty) * itemPercent
                cell.transform = t3
            }
        }
        
        switch panGesture.state {
        case .changed:
            isAdding = translation.x > 0
            
            collectionView.indexPathsForVisibleItems.forEach { indexPath in
                updateCell(atIndexPath: indexPath)
            }
        
        case .ended:
            let indexPath = IndexPath(item: 0, section: 0)
            
            let velocity = panGesture.velocity(in: panGesture.view)
            let resistance = CGFloat(0.25)
            let velocityPercent = (velocity.x * resistance) / collectionView.center.x
            
            let distance = sqrt(abs(translation.x) * abs(velocity.x)) / 2
            
            print("||| \(distance)  \(velocityPercent)  \(percent)  \(decisionValueThreshold)")
            
//            let didSwitchDirections = 
            
            if abs(decisionValueThreshold) >= 1 {
                
            } else {
                if abs(velocityPercent) >= 1 {
                    // commit direction
                } else {
                    
                }
            }
            
            
            if abs(decisionValueThreshold) >= 1 {
                if decisionValueThreshold > 0 {
                    translation.x = collectionView.bounds.width
                    
                } else {
                    translation.x = -collectionView.bounds.width
                }
                
            } else {
                translation.x = 0
            }
            
            
            
            UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.8, options: [], animations: {
                updateCell(atIndexPath: indexPath)
            }, completion: nil)
            
        default:
            print("")
        }
        
    }
    
    // MARK: Animation
    
    
}

extension DiscoverScreenshotViewController : UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        
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
