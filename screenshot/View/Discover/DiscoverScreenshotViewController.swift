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
            
//            attributes.transform = CGAffineTransform(translationX: rotatedRect.size.width * direction, y: 50).rotated(by: rotationAngle)
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
    
    fileprivate var isAdding = false
    
    fileprivate var count = 10
    
    fileprivate var animator: UIDynamicAnimator?
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
        
        // TODO: add bottom insets for the rotated cell to appear
        
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
        
        
        animator = UIDynamicAnimator(referenceView: collectionView)
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
        
        collectionView.performBatchUpdates({
            self.count -= 1
            collectionView.deleteItems(at: [indexPath])
            
        }, completion: { _ in
            
        })
    }
    
    var behavior: DiscoverScreenshotDynamicBehavior?
    
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
        func updateCell(atIndexPath indexPath: IndexPath, percent: CGFloat? = nil) {
            if let cell = collectionView.cellForItem(at: indexPath) as? DiscoverScreenshotCollectionViewCell,
                let attributes = collectionViewLayout.finalLayoutAttributesForDisappearingItem(at: indexPath)
            {
                let percent = min(1, max(-1, percent ?? (translation.x / 2) / collectionView.center.x))
                let decisionValueThreshold = percent * 3
                
                // Only the first cell should move in the expected direction
                let direction = CGFloat(indexPath.item == 0 ? 0 : 1)
                let itemPercent = abs(direction - abs(percent))
                
//                print("|||2 \(a)")
                if indexPath.item == 0 {
                    cell.decisionValue = decisionValueThreshold
                }
                
                collectionViewLayout.progressFinalAttributes(attributes, cell: cell, percent: itemPercent)
            }
        }
        
        print("|||| state = \(panGesture.state.rawValue)")
        
        switch panGesture.state {
//        case .began:
//            animator?.removeAllBehaviors()
            
        case .changed:
            isAdding = translation.x > 0
            
            collectionView.indexPathsForVisibleItems.forEach { indexPath in
                updateCell(atIndexPath: indexPath)
            }
        
        case .ended:
            // TODO: use panGesture.view not collectionView
            let indexPath = IndexPath(item: 0, section: 0)
            let cell = collectionView.cellForItem(at: indexPath) as! DiscoverScreenshotCollectionViewCell
            let velocity = panGesture.velocity(in: panGesture.view)
            
            
//            let behavior = DiscoverScreenshotDynamicBehavior(item: cell, attachedTo: collectionView)
//            behavior.targetPoint = CGPoint(x: collectionViewLayout.cardFrame.midX, y: collectionViewLayout.cardFrame.midY)
//            behavior.velocity = velocity
//            behavior.action = {
//                let translation = cell.center
//                let collectionViewCenter = CGPoint(x: self.collectionView.contentSize.width / 2, y: self.collectionView.contentSize.height / 2)
//                let percent = 1 - min(1, max(-1, translation.x / collectionViewCenter.x))
//                let decisionValueThreshold = percent * 3
//
//                print("||| \(percent)  \(translation.x)")
//
////                if percent > 1 {
////                    behavior.targetPoint = CGPoint(x: -200, y: collectionViewLayout.cardFrame.midY)
////
////                } else {
//                    cell.decisionValue = percent
//
//                    let attributes = collectionViewLayout.finalLayoutAttributesForDisappearingItem(at: indexPath)!
//                    let t1 = CGAffineTransform.identity
//                    let t2 = attributes.transform
//                    var t3 = cell.transform
//                    t3.a = t1.a + (t2.a - t1.a) * percent
//                    t3.b = t1.b + (t2.b - t1.b) * percent
//                    t3.c = t1.c + (t2.c - t1.c) * percent
//                    t3.d = t1.d + (t2.d - t1.d) * percent
//                    t3.tx = t1.tx + (t2.tx - t1.tx) * percent
//                    t3.ty = t1.ty + (t2.ty - t1.ty) * percent
//                    cell.transform = t3
////                }
//            }
//            self.behavior = behavior
//
//            animator?.addBehavior(behavior)
            
            
            let resistance = CGFloat(0.25)
            let velocityPercent = (velocity.x * resistance) / collectionView.center.x

            let distance = sqrt(abs(translation.x) * abs(velocity.x)) / 2

//            print("||| \(distance)  \(velocityPercent)  \(percent)  \(decisionValueThreshold)")

//            let didSwitchDirections =

//            if abs(decisionValueThreshold) >= 1 {
//
//            } else {
//                if abs(velocityPercent) >= 1 {
//                    // commit direction
//                } else {
//
//                }
//            }


//            if abs(decisionValueThreshold) >= 1 {
//                if decisionValueThreshold > 0 {
//                    translation.x = collectionView.bounds.width
//
//                } else {
//                    translation.x = -collectionView.bounds.width
//                }
//
//            } else {
//                translation.x = 0
//            }


            
            if abs(decisionValueThreshold) >= 1 {
                if decisionValueThreshold > 0 {
                    self.addButtonAction()
                    
                } else {
                    self.passButtonAction()
                }
                
            } else {
                UIView.animate(withDuration: 2.4, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.8, options: [.allowUserInteraction, .beginFromCurrentState], animations: {
                    
                    translation.x = 0
                    updateCell(atIndexPath: indexPath)
                    
                }, completion: nil)
            }
            
            
            
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

class DiscoverScreenshotDynamicBehavior : UIDynamicBehavior {
    let item: UIDynamicItem
    private let attachmentBehavior: UIAttachmentBehavior
    private let itemBehavior: UIDynamicItemBehavior
    private let snapBehavior: UISnapBehavior
    private let gravityBehavior: UIGravityBehavior
    private let radialGravity: UIFieldBehavior
    
    init(item: UIDynamicItem, attachedTo attachedItem: UIDynamicItem) {
        self.item = item
        
        attachmentBehavior = UIAttachmentBehavior(item: item, attachedTo: attachedItem)
        attachmentBehavior.frequency = 10
        attachmentBehavior.damping = 3
        attachmentBehavior.length = 0
        
        itemBehavior = UIDynamicItemBehavior(items: [item])
        itemBehavior.resistance = 30
        itemBehavior.density = 0.5 // 12
        
        snapBehavior = UISnapBehavior(item: item, snapTo: attachedItem.center)
        
        gravityBehavior = UIGravityBehavior(items: [item])
        gravityBehavior.gravityDirection = CGVector(dx: 0, dy: 0)
        gravityBehavior.magnitude = 2
        gravityBehavior.angle = 0
        
        radialGravity = UIFieldBehavior.radialGravityField(position: attachedItem.center)
        radialGravity.region = UIRegion(radius: 200)
//        radialGravity.strength = -1 //repel items
        radialGravity.strength = 1.5 // 3
        radialGravity.falloff = 4.0 // 4
        radialGravity.minimumRadius = 50.0 // 5
        radialGravity.addItem(item)
        
        
        let vortex: UIFieldBehavior = UIFieldBehavior.vortexField() // 6
        vortex.position = attachedItem.center // 7
        vortex.region = UIRegion(radius: 200.0) // 8
        vortex.strength = 0.005 // 9
        vortex.addItem(item) // 14
        
        
        super.init()
        
//        addChildBehavior(attachmentBehavior)
        addChildBehavior(itemBehavior)
//        addChildBehavior(snapBehavior)
//        addChildBehavior(gravityBehavior)
        addChildBehavior(radialGravity)
        addChildBehavior(vortex)
        
    }
    
    var targetPoint: CGPoint {
        set {
            snapBehavior.snapPoint = newValue
//            attachmentBehavior.anchorPoint = newValue
        }
        get {
//            return snapBehavior.snapPoint
            return attachmentBehavior.anchorPoint
        }
    }
    
    var velocity: CGPoint = .zero {
        didSet {
            let currentVelocity = itemBehavior.linearVelocity(for: item)
            let velocityDelta = CGPoint(x: velocity.x - currentVelocity.x, y: velocity.y - currentVelocity.y)
//            itemBehavior.addLinearVelocity(velocityDelta, for: item)
        }
    }
}
