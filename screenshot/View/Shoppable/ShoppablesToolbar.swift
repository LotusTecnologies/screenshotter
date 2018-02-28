//
//  ShoppablesToolbar.swift
//  screenshot
//
//  Created by Jonathan Rose on 2/11/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation
import UIKit
import CoreData

protocol ShoppablesToolbarDelegate : UIToolbarDelegate {
    func shoppablesToolbarDidChange(toolbar:ShoppablesToolbar)
    func shoppablesToolbarDidChangeSelectedShoppable(toolbar:ShoppablesToolbar, shoppable:Shoppable)
}

class ShoppablesToolbar : UIToolbar, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, ShoppablesCollectionViewDelegate, FetchedResultsControllerManagerDelegate {
    
    
    weak var shoppableToolbarDelegate:ShoppablesToolbarDelegate?
    var didViewControllerAppear:Bool = false
    var collectionView:ShoppablesCollectionView!
    var screenshotImage:UIImage
    var shoppablesController:FetchedResultsControllerManager<Shoppable>
    
    init(screenshot s:Screenshot) {
        if let data = s.imageData,
            let i = UIImage(data: data as Data) {
            screenshotImage = i
        }else{
            screenshotImage = UIImage()
        }
        
        shoppablesController = DataModel.sharedInstance.shoppableFrc(delegate: nil, screenshot: s)
        super.init(frame: CGRect.zero)
        shoppablesController.delegate = self
        
        self.collectionView = self.createCollectionView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.bringSubview(toFront: self.collectionView)
    }
    
    func repositionShoppables() {
        let shoppablesCount = self.shoppablesController.fetchedObjectsCount
        
        if (shoppablesCount > 0) {
            let  lineSpacing = (self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.minimumLineSpacing ?? 0
            let spacingsWidth:CGFloat = lineSpacing * CGFloat(shoppablesCount - 1)
            let shoppablesWidth:CGFloat = self.shoppableSize().width * CGFloat(shoppablesCount)
            let contentWidth:CGFloat = round(spacingsWidth + shoppablesWidth)
            let width:CGFloat = self.collectionView.bounds.size.width - self.collectionView.contentInset.left - self.collectionView.contentInset.right
            
            if (width != contentWidth) {
                let maxHorizontalInset:CGFloat = ShoppablesToolbar.preservedCollectionViewContentInset().left
                
                var insets = self.collectionView.contentInset
                let i = CGFloat.maximum(maxHorizontalInset, floor( (self.collectionView.bounds.size.width - contentWidth) / 2.0) )
                insets.left = i
                insets.right = i
                self.collectionView.contentInset = insets
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.shoppablesController.fetchedObjectsCount
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return self.shoppableSize()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? ShoppableCollectionViewCell
        cell?.image = self.shoppablesController.object(at: indexPath).cropped(image: screenshotImage, thumbSize: self.shoppableSize())
        return cell ?? UICollectionViewCell.init()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        UserDefaults.standard.set(true, forKey: UserDefaultsKeys.productCompletedTooltip)
        AnalyticsTrackers.standard.track(.tappedOnShoppable)
        
        let shopable = self.shoppablesController.object(at: indexPath)
        self.shoppableToolbarDelegate?.shoppablesToolbarDidChangeSelectedShoppable(toolbar: self, shoppable: shopable)

    }
    
    func createCollectionView() -> ShoppablesCollectionView {
        let p: CGFloat = .padding
        
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = p
        layout.minimumLineSpacing = p
        
        layout.scrollDirection = .horizontal
        let collectionView = ShoppablesCollectionView.init(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self
        collectionView.shoppableDelegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .clear
        collectionView.scrollsToTop = false
        collectionView.contentInset = ShoppablesToolbar.preservedCollectionViewContentInset()
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
        collectionView.performBatchUpdates({
            collectionView.deleteItems(at: change.deletedRows)
            collectionView.deleteSections(change.deletedSections)
            collectionView.insertSections(change.insertedSections)
            collectionView.insertItems(at: change.insertedRows)
        })
        // don't do reload - will lose selection state
        self.shoppableToolbarDelegate?.shoppablesToolbarDidChange(toolbar: self)

    }
    
    func shoppableSize() -> CGSize {
        var size = CGSize.zero
        size.height = self.collectionView.bounds.size.height - self.collectionView.contentInset.top - self.collectionView.contentInset.bottom
        size.width = size.height * 0.8
        return size
    }
    
    func selectFirstShoppable() {
        if self.collectionView.numberOfItems(inSection: 0) > 0{
            self.collectionView.selectItem(at: IndexPath.init(item: 0, section: 0), animated: false, scrollPosition: [])
            if let shoppable = self.selectedShoppable() {
                self.shoppableToolbarDelegate?.shoppablesToolbarDidChangeSelectedShoppable(toolbar: self, shoppable: shoppable)
            }
        }
    }
    
    func selectedShoppable() -> Shoppable? {
        if let index = self.collectionView.indexPathsForSelectedItems?.first?.item {
            return self.shoppablesController.object(at: IndexPath(item: index, section: 0))
        }
        if let firstShoppable = self.shoppablesController.first {
            if self.collectionView.numberOfSections > 0 && self.collectionView.numberOfItems(inSection: 0) > 0 {
                self.collectionView.selectItem(at: IndexPath.init(item: 0, section: 0), animated: false, scrollPosition: [])
                return firstShoppable
            }
        }
        return nil
    }
    
    static func preservedCollectionViewContentInset() -> UIEdgeInsets{
        let p: CGFloat = .padding
        let p2 = p * 0.5
        return UIEdgeInsets.init(top: p2, left: p, bottom: p2, right: p)
    }
}
