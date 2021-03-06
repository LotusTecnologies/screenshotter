//
//  ShoppablesToolbar.swift
//  screenshot
//
//  Created by Jonathan Rose on 2/11/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import Foundation
import UIKit
import CoreData

protocol ShoppablesToolbarDelegate : UIToolbarDelegate {
    func shoppablesToolbarDidChange(toolbar:ShoppablesToolbar)
    func shoppablesToolbarDidChangeSelectedShoppable(toolbar:ShoppablesToolbar, shoppable:Shoppable)
}

class ShoppablesToolbar : UIToolbar, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, FetchedResultsControllerManagerDelegate {
    weak var shoppableToolbarDelegate:ShoppablesToolbarDelegate?
    var didViewControllerAppear:Bool = false
    var collectionView:UICollectionView?
    var screenshotImage:UIImage
    var shoppablesController:FetchedResultsControllerManager<Shoppable>
    
    var shoppables:[Shoppable] = []
    var shoppableObjectIdToSelectWhenControllerChanges:NSManagedObjectID?
    
    init(screenshot s:Screenshot) {
        if let data = s.imageData,
            let i = UIImage(data: data as Data) {
            screenshotImage = i
        }else{
            screenshotImage = UIImage()
        }
        
        shoppablesController = DataModel.sharedInstance.shoppableFrc(delegate: nil, screenshot: s)
        shoppables = shoppablesController.fetchedObjects.filter { $0.parentShoppable == nil }
        
        super.init(frame: CGRect.zero)
        shoppablesController.delegate = self
        
        self.collectionView = self.createCollectionView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if let collectionView = self.collectionView {
            // Needed for iOS 10
            self.bringSubview(toFront: collectionView)
        }
    }
    
    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.height = 74
        return size
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.shoppables.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return self.shoppableSize()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        
        let cellCount = CGFloat(collectionView.numberOfItems(inSection: 0))
        let cellWidth = self.shoppableSize().width
        let cellSpacing = (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.minimumLineSpacing ?? 0
        let collectionViewWidth = self.bounds.size.width
        
        let totalCellWidth = cellWidth * cellCount
        let totalSpacingWidth = cellSpacing * (cellCount - 1)
        
        let leftInset = max(0, ((collectionViewWidth - CGFloat(totalCellWidth + totalSpacingWidth)) / 2 ) - collectionView.contentInset.left)
        let rightInset = max(0, ((collectionViewWidth - CGFloat(totalCellWidth + totalSpacingWidth)) / 2 ) - collectionView.contentInset.right)
        
        return UIEdgeInsetsMake(0, leftInset, 0, rightInset)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? ShoppableCollectionViewCell
        let shoppable = shoppables[indexPath.row]
        if let imageUrl = shoppable.imageUrl {
            cell?.imageUrl = imageUrl
        }else {
            cell?.image = shoppable.cropped(image: screenshotImage, thumbSize: self.shoppableSize())
        }
        return cell ?? UICollectionViewCell.init()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let shoppable = shoppables[indexPath.row]
        Analytics.trackTappedOnShoppable(shoppable: shoppable)
        self.shoppableToolbarDelegate?.shoppablesToolbarDidChangeSelectedShoppable(toolbar: self, shoppable: shoppable)

    }
    
    func createCollectionView() -> UICollectionView {
        let p: CGFloat = .padding
        let p2 = p * 0.5

        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = p
        layout.minimumLineSpacing = p
        
        layout.scrollDirection = .horizontal
        let collectionView = UICollectionView.init(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .white
        collectionView.scrollsToTop = false
        collectionView.contentInset = UIEdgeInsets.init(top: p2, left: p, bottom: p2, right: p)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(ShoppableCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        self.addSubview(collectionView)
        collectionView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        collectionView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        return collectionView
    }
    
    func managerDidChangeContent(_ controller: NSObject, change: FetchedResultsControllerManagerChange) {

        var selected:Shoppable? = nil
        if let index = self.collectionView?.indexPathsForSelectedItems?.first?.item {
            selected = shoppables[index]
        }
        shoppables = shoppablesController.fetchedObjects.filter { $0.parentShoppable?.objectID == nil }
        self.collectionView?.reloadData()
        if let selectedObjectId = shoppableObjectIdToSelectWhenControllerChanges, let shoppable = shoppables.first(where: { $0.objectID == selectedObjectId }) {
            self.shoppableObjectIdToSelectWhenControllerChanges = nil
            shoppables = shoppablesController.fetchedObjects.filter { $0.parentShoppable?.objectID == nil }
            self.selectShoppable(shoppable)
            
        }else if let selected = selected, let index = self.shoppables.index(of: selected) {
            self.collectionView?.selectItem(at: IndexPath.init(row: index, section: 0), animated: false, scrollPosition: [])
        }
        
        
        self.shoppableToolbarDelegate?.shoppablesToolbarDidChange(toolbar: self)

    }
    
    func shoppableSize() -> CGSize {
        var size = CGSize.zero
        if let collectionView = self.collectionView {
            size.height = collectionView.bounds.size.height - collectionView.contentInset.top - collectionView.contentInset.bottom
            size.width = size.height * 0.8
        }
        return size
    }
    
    func selectFirstShoppable() {
        if let collectionView = self.collectionView {
            
            if collectionView.numberOfItems(inSection: 0) > 0{
                collectionView.selectItem(at: IndexPath.init(item: 0, section: 0), animated: false, scrollPosition: [])
                if let shoppable = self.selectedShoppable() {
                    self.shoppableToolbarDelegate?.shoppablesToolbarDidChangeSelectedShoppable(toolbar: self, shoppable: shoppable)
                }
            }
        }
    }
    func deselectShoppable() {
        if let collectionView = self.collectionView, let indexPathsForSelectedItems = collectionView.indexPathsForSelectedItems {
            for indexPath in indexPathsForSelectedItems {
                collectionView.deselectItem(at: indexPath, animated: true)
            }
        }
    }
    
    func selectedShoppable() -> Shoppable? {
        if let collectionView = self.collectionView {
            if let index = collectionView.indexPathsForSelectedItems?.first?.item {
                return shoppables[index]
            }
            if let firstShoppable = self.shoppables.first {
                if collectionView.numberOfSections > 0 && collectionView.numberOfItems(inSection: 0) > 0 {
                    collectionView.selectItem(at: IndexPath(item: 0, section: 0), animated: false, scrollPosition: [])
                    return firstShoppable
                }
            }
        }
        return nil
    }
    func selectShoppable(_ s:Shoppable){
        if let collectionView = self.collectionView {
            if let index = shoppables.index(of: s) {
                let isVisible = self.window != nil
                collectionView.selectItem(at: IndexPath(row: index, section: 0), animated: isVisible, scrollPosition: .centeredHorizontally)
                self.shoppableToolbarDelegate?.shoppablesToolbarDidChangeSelectedShoppable(toolbar: self, shoppable: s)
            }else{
                self.shoppableObjectIdToSelectWhenControllerChanges = s.objectID
                print("unable to find shoppable!")
            }
        }
    }
    
    static func preservedCollectionViewContentInset() -> UIEdgeInsets{
        let p: CGFloat = .padding
        let p2 = p * 0.5
        return UIEdgeInsets.init(top: p2, left: p, bottom: p2, right: p)
    }
}
