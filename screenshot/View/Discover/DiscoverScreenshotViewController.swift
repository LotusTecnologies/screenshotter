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


class DiscoverScreenshotViewController : BaseViewController {
    fileprivate let collectionView = UICollectionView(frame: .zero, collectionViewLayout: DiscoverScreenshotCollectionViewLayout())
    fileprivate let passButton = UIButton()
    fileprivate let addButton = UIButton()
    
    fileprivate var isAdding = false
    
    fileprivate var count = 10
    fileprivate let topIndexPath = IndexPath(item: 0, section: 0)
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        addNavigationItemLogo()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let layout = collectionView.collectionViewLayout as? DiscoverScreenshotCollectionViewLayout {
            layout.delegate = self
        }
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = view.backgroundColor
        collectionView.contentInset = UIEdgeInsets(top: .padding, left: .padding, bottom: .padding, right: .padding)
        collectionView.scrollsToTop = false
        collectionView.register(DiscoverScreenshotCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        view.addSubview(collectionView)
        collectionView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(collectionViewPanGestureAction(_:)))
        collectionView.addGestureRecognizer(panGesture)
        
        let image = UIImage(named: "DiscoverScreenshotArrow")
        let arrowPadding: CGFloat = 18
        
        passButton.translatesAutoresizingMaskIntoConstraints = false
        passButton.setTitle("discover.screenshot.pass".localized, for: .normal)
        passButton.setTitleColor(.gray3, for: .normal)
        passButton.setImage(image, for: .normal)
        passButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -arrowPadding, bottom: 0, right: arrowPadding)
        passButton.contentEdgeInsets = UIEdgeInsets(top: .padding, left: arrowPadding, bottom: .padding, right: .padding)
        passButton.addTarget(self, action: #selector(passButtonAction), for: .touchUpInside)
        passButton.adjustsImageWhenDisabled = false
        view.addSubview(passButton)
        passButton.topAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: -.padding).isActive = true
        passButton.leadingAnchor.constraint(greaterThanOrEqualTo: view.layoutMarginsGuide.leadingAnchor).isActive = true
        passButton.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor).isActive = true
        passButton.trailingAnchor.constraint(equalTo: view.centerXAnchor, constant: -.padding).isActive = true
        
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.setTitle("discover.screenshot.add".localized, for: .normal)
        addButton.setTitleColor(.gray3, for: .normal)
        addButton.setImage(image, for: .normal)
        addButton.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        addButton.titleLabel?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        addButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -arrowPadding, bottom: 0, right: arrowPadding)
        addButton.contentEdgeInsets = UIEdgeInsets(top: .padding, left: arrowPadding, bottom: .padding, right: .padding)
        addButton.addTarget(self, action: #selector(addButtonAction), for: .touchUpInside)
        addButton.adjustsImageWhenDisabled = false
        view.addSubview(addButton)
        addButton.topAnchor.constraint(equalTo: passButton.topAnchor).isActive = true
        addButton.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: .padding).isActive = true
        addButton.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor).isActive = true
        addButton.trailingAnchor.constraint(lessThanOrEqualTo: view.layoutMarginsGuide.trailingAnchor).isActive = true
    }
    
    deinit {
        if let layout = collectionView.collectionViewLayout as? DiscoverScreenshotCollectionViewLayout {
            layout.delegate = nil
        }
        
        collectionView.dataSource = nil
        collectionView.delegate = nil
    }
    
    // MARK: Actions
    
    private func decisionAction(isAdded: Bool) {
        guard collectionView.numberOfItems(inSection: 0) > 0 else {
            return
        }
        
        passButton.isEnabled = false
        addButton.isEnabled = false
        
        isAdding = isAdded
        
        if let cell = collectionView.cellForItem(at: topIndexPath) as? DiscoverScreenshotCollectionViewCell {
            UIView.animate(withDuration: 0.2) {
                cell.decisionValue = isAdded ? 1 : -1
            }
        }
        
        collectionView.performBatchUpdates({
            self.count -= 1
            collectionView.deleteItems(at: [topIndexPath])
            
        }) { completed in
            self.passButton.isEnabled = true
            self.addButton.isEnabled = true
        }
    }
    
    @objc private func passButtonAction() {
        decisionAction(isAdded: false)
    }
    
    @objc private func addButtonAction() {
        decisionAction(isAdded: true)
    }
    
    private var canPanScreenshot = false
    
    private func decisionValueThreshold(_ percent: CGFloat) -> CGFloat {
        return percent * 3
    }
    
    @objc private func collectionViewPanGestureAction(_ panGesture: UIPanGestureRecognizer) {
        var translation = panGesture.translation(in: panGesture.view)
        var percent: CGFloat {
            return min(1, max(-1, (translation.x / 2) / collectionView.center.x))
        }
        
        switch panGesture.state {
        case .began:
            canPanScreenshot = false
            
        case .changed:
            let location = panGesture.location(in: panGesture.view)
            let indexPathAtLocation = collectionView.indexPathForItem(at: location)
            
            if !canPanScreenshot && indexPathAtLocation != nil {
                canPanScreenshot = true
                panGesture.setTranslation(.zero, in: panGesture.view)
                translation = panGesture.translation(in: panGesture.view)
            }
            
            isAdding = translation.x > 0
            
            if canPanScreenshot {
                collectionView.indexPathsForVisibleItems.forEach { indexPath in
                    updateCell(atIndexPath: indexPath, percent: percent)
                }
            }
            
        case .ended, .cancelled:
            let decisionValueThreshold = self.decisionValueThreshold(percent)
            
            UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.8, options: [.allowUserInteraction, .beginFromCurrentState], animations: {
                if abs(decisionValueThreshold) >= 1 {
                    decisionValueThreshold > 0 ? self.addButtonAction() : self.passButtonAction()
                    
                } else {
                    self.updateCell(atIndexPath: self.topIndexPath, percent: 0)
                }
            })
            
        default:
            break
        }
    }
    
    private func updateCell(atIndexPath indexPath: IndexPath, percent: CGFloat) {
        guard let collectionViewLayout = collectionView.collectionViewLayout as? DiscoverScreenshotCollectionViewLayout else {
            return
        }
        
        if let cell = collectionView.cellForItem(at: indexPath) as? DiscoverScreenshotCollectionViewCell,
            let attributes = collectionViewLayout.finalLayoutAttributesForDisappearingItem(at: indexPath)
        {
            let percent = min(1, max(-1, percent))
            
            // Only the first cell should move in the expected direction
            let direction = CGFloat(indexPath.item == 0 ? 0 : 1)
            let itemPercent = abs(direction - abs(percent))
            
            if indexPath.item == 0 {
                cell.decisionValue = decisionValueThreshold(percent)
            }
            
            collectionViewLayout.progressFinalAttributes(attributes, cell: cell, percent: itemPercent)
        }
    }
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
