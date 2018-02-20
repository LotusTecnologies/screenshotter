//
//  ShoppablesToolbar.swift
//  screenshot
//
//  Created by Jonathan Rose on 2/11/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation


protocol ShoppablesToolbarDelegate : UIToolbarDelegate {
    func shoppablesToolbarDidChange(toolbar:ShoppablesToolbar)
    func shoppablesToolbarDidSelectShoppable(toolbar:ShoppablesToolbar, index:Int)
}

class ShoppablesToolbar : UIToolbar, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, ShoppablesCollectionViewDelegate, FetchedResultsControllerManagerDelegate {
    
    
    
    weak var shoppableToolbarDelegate:ShoppablesToolbarDelegate?
    var didViewControllerAppear:Bool = false
    var needsToSelectFirstShoppable:Bool = false
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
        let shoppablesCount = self.shoppablesController.fetchedResultsController.fetchedObjectsCount
        
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
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.shoppablesController.fetchedResultsController.fetchedObjectsCount
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return self.shoppableSize()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? ShoppableCollectionViewCell
        cell?.image = self.shoppablesController.fetchedResultsController.object(at: indexPath).cropped(image: screenshotImage)
        return cell ?? UICollectionViewCell.init()
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if collectionView.indexPathsForVisibleItems.count == 0 && collectionView.numberOfItems(inSection: 0) > 0 && indexPath.item == 0 {
            if self.needsToSelectFirstShoppable {
                self.needsToSelectFirstShoppable = false
                self.selectFirstShoppable()
                // selectItemAtIndexPath: should auto select the cell however
                // since the cell isnt visible it wont appear selected until
                // the next layout. Force the selected state.
                cell.isSelected = true
            }
            self.shoppableToolbarDelegate?.shoppablesToolbarDidChange(toolbar: self)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.shoppableToolbarDelegate?.shoppablesToolbarDidSelectShoppable(toolbar: self, index: indexPath.item)
    }
    
    func createCollectionView() -> ShoppablesCollectionView {
        let p:CGFloat = Geometry.padding
        let layout = UICollectionViewFlowLayout.init()
        layout.minimumInteritemSpacing = p
        layout.minimumLineSpacing = p
        layout.scrollDirection = .horizontal
        let collectionView = ShoppablesCollectionView.init(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self;
        collectionView.shoppableDelegate = self
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
    }
    
    func managerDidChangeContent(_ controller: NSObject, change: FetchedResultsControllerManagerChange) {
        collectionView.performBatchUpdates({
            collectionView.deleteSections(change.deletedSections)
            collectionView.deleteItems(at: change.deletedRows)
            collectionView.insertSections(change.insertedSections)
            collectionView.insertItems(at: change.insertedRows)
        }) { (completed) in
        }
        // don't do reload - will lose selection state
    }
    
    func shoppableSize() -> CGSize {
        var size = CGSize.zero
        size.height = self.collectionView.bounds.size.height - self.collectionView.contentInset.top - self.collectionView.contentInset.bottom;
        size.width = size.height * 0.8
        return size
    }
    
    func selectFirstShoppable() {
        if self.collectionView.numberOfItems(inSection: 0) > 0{
            self.collectionView.selectItem(at: IndexPath.init(item: 0, section: 0), animated: false, scrollPosition: [])
        } else {
            self.needsToSelectFirstShoppable = true
        }
    }
    
    func selectedShoppableIndex() -> Int {
        return self.collectionView.indexPathsForSelectedItems?.first?.item ?? 0
    }
    
    static func preservedCollectionViewContentInset() -> UIEdgeInsets{
        let p = Geometry.padding
        let p2 = p * 0.5;
        return UIEdgeInsets.init(top: p2, left: p, bottom: p2, right: p)
    }
}
