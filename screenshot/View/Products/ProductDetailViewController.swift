//
//  ProductDetailViewController.swift
//  screenshot
//
//  Created by Jonathan Rose on 6/4/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit
import SDWebImage
import Hero
class ProductDetailViewController: BaseViewController { 
    var productCollectionViewManager = ProductCollectionViewManager()

    var collectionView:UICollectionView?
    var product:Product?
    var products:[Product] = []
    var uuid:String?

    var headerCell:ProductHeaderCollectionViewCell? {
        if self.collectionView?.numberOfSections ?? 0 > 0 && self.collectionView?.numberOfItems(inSection: 0) ?? 0 > 0 {
            return self.collectionView?.cellForItem(at: IndexPath.init(row: 0, section: 0)) as? ProductHeaderCollectionViewCell
        }
        return nil
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.title = product?.calculatedDisplayTitle
        let collectionView:UICollectionView = {
            let minimumSpacing = self.collectionViewMinimumSpacing()
            
            let layout = SectionBackgroundCollectionViewFlowLayout()
            layout.minimumInteritemSpacing = minimumSpacing.x
            layout.minimumLineSpacing = minimumSpacing.y
            let collectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: layout)
            collectionView.translatesAutoresizingMaskIntoConstraints = false
            collectionView.delegate = self
            collectionView.dataSource = self
            collectionView.backgroundColor = self.view.backgroundColor
            // TODO: set the below to interactive and comment the dismissal in -scrollViewWillBeginDragging.
            // Then test why the control view (products options view) jumps before being dragged away.
            collectionView.keyboardDismissMode = .onDrag
            self.productCollectionViewManager.setup(collectionView: collectionView)
            
            self.view.insertSubview(collectionView, at: 0)
            collectionView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
            collectionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
            collectionView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
            collectionView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
            
            return collectionView
        }()
        self.collectionView = collectionView
        
        
        
        
        
    }

}


extension ProductDetailViewController : UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    var numberOfCollectionViewProductColumns: Int {
        return 2
    }
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        return self.products.count
            }
    
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section == 0{
            return self.productCollectionViewManager.collectionView(collectionView, sizeForItemInSectionType: .productHeader)
        }
            return self.productCollectionViewManager.collectionView(collectionView, sizeForItemInSectionType: .product)
        
    }
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0{
            let product = self.product
            let cell = self.productCollectionViewManager.collectionView(collectionView, cellForItemAt: indexPath, withProductHeader: product)
            if let cell  = cell as? ProductHeaderCollectionViewCell, let uuid = uuid {
                cell.productImageView.hero.id = "\(uuid)-image"
                cell.favoriteControl.hero.id = "\(uuid)-heart"
                cell.favoriteControl.addTarget(self, action: #selector(productCollectionViewCellFavoriteAction(_:event:)), for: .touchUpInside)
                cell.buyNowButton.addTarget(self, action: #selector(productCollectionViewCellBuyAction(_:event:)), for: .touchUpInside)
            }
          

            return cell

        }
        let product = self.products[indexPath.row]
        let cell = self.productCollectionViewManager.collectionView(collectionView, cellForItemAt: indexPath, with: product)
        if let cell = cell as? ProductsCollectionViewCell {
            cell.favoriteControl.addTarget(self, action: #selector(productCollectionViewCellFavoriteAction(_:event:)), for: .touchUpInside)
            cell.actionButton.addTarget(self, action: #selector(productCollectionViewCellBuyAction(_:event:)), for: .touchUpInside)
        }
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        if indexPath.section == 0 {
            return false
        }
        return true
    }
    public func collectionViewMinimumSpacing() -> CGPoint {
        let shadowInsets = ScreenshotCollectionViewCell.shadowInsets
        let p: CGFloat = .padding
        return CGPoint(x: p - shadowInsets.left - shadowInsets.right, y: p - shadowInsets.top - shadowInsets.bottom)
    }
    func productAtIndex(_ index: Int) -> Product {
        return self.products[index]
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if section == 0 {
            return .zero
        }
        
        let minimumSpacing:CGPoint = self.collectionViewMinimumSpacing()
        return UIEdgeInsets(top: minimumSpacing.y, left: minimumSpacing.x, bottom: 30, right: minimumSpacing.x)
    }
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == 1{
            return CGSize.init(width: collectionView.bounds.size.width, height: 80)
        }
        return .zero
        
    }
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {

        if kind == UICollectionElementKindSectionHeader {
            if indexPath.section == 1 {
                let view = self.productCollectionViewManager.collectionView(collectionView, viewForHeaderWith: "Similar Items".localized, indexPath: indexPath)
                view.backgroundColor = self.view.backgroundColor
                return view
            }
            return self.productCollectionViewManager.collectionView(collectionView, viewForHeaderWith: "".localized, indexPath: indexPath)
        }else if kind == SectionBackgroundCollectionViewFlowLayout.ElementKindSectionSectionBackground {
            if indexPath.section == 1 {
                return self.productCollectionViewManager.collectionView(collectionView, viewForBackgroundWith: .background, indexPath: indexPath)
            }
            return self.productCollectionViewManager.collectionView(collectionView, viewForBackgroundWith: .white, indexPath: indexPath)
        }
        return UICollectionReusableView()
    }
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 1{
            let product = self.productAtIndex(indexPath.item)
            if let cell = collectionView.cellForItem(at: indexPath) as? ProductsCollectionViewCell{
                self.productCollectionViewManager.burrow(cell: cell, product: product, fromVC: self)
            }
        }
    }

    @objc func productCollectionViewCellFavoriteAction(_ favoriteControl: FavoriteControl, event: UIEvent) {
        guard let indexPath = collectionView?.indexPath(for: event) else {
            return
        }
        
        let isFavorited = favoriteControl.isSelected
        if let product = indexPath.section == 0 ? self.product : self.productAtIndex(indexPath.item) {
            
            product.setFavorited(toFavorited: isFavorited)
            if isFavorited {
                let _ = ShoppingCartModel.shared.populateVariants(productOID: product.objectID)
                Analytics.trackProductFavorited(product: product, page: .productList)
            }else{
                Analytics.trackProductUnfavorited(product: product, page: .productList)
            }
        }
    }
    
    @objc func productCollectionViewCellBuyAction(_ control: UIControl, event: UIEvent) {
        guard let indexPath = collectionView?.indexPath(for: event) else {
            return
        }
        
        if let product = indexPath.section == 0 ? self.product : self.productAtIndex(indexPath.item) {
            product.recordViewedProduct()
            
            if let productViewController = presentProduct(product, atLocation: .products) {
                productViewController.similarProducts = products
            }
        }
    }
    
}

