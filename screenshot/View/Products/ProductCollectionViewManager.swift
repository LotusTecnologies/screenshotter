//
//  ProductCollectionViewManager.swift
//  screenshot
//
//  Created by Jonathan Rose on 6/7/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import Foundation
import PromiseKit
import Hero

class ProductCollectionViewManager {
    var loader:Loader?
    
    public func setup(collectionView:UICollectionView){
        collectionView.register(ProductsCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.register(RelatedLooksCollectionViewCell.self, forCellWithReuseIdentifier: "relatedLooks")
        collectionView.register(SpinnerCollectionViewCell.self, forCellWithReuseIdentifier: "relatedLooks-spinner")
        collectionView.register(ErrorCollectionViewCell.self, forCellWithReuseIdentifier: "relatedLooks-error")
        collectionView.register(ProductsViewHeaderReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "header")
        collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: SectionBackgroundCollectionViewFlowLayout.ElementKindSectionSectionBackground, withReuseIdentifier: "background")
        
        collectionView.register(ProductHeaderCollectionViewCell.self, forCellWithReuseIdentifier: "productHeader")

        
    }
    
    let productHeaderHeight: CGFloat = 176
    
    public func collectionView(_ collectionView: UICollectionView, sizeForItemInSectionType sectionType: ProductsSection) -> CGSize {
        
        var size:CGSize = .zero
        let shadowInsets = ScreenshotCollectionViewCell.shadowInsets
        let padding: CGFloat = .padding - shadowInsets.left - shadowInsets.right
        if sectionType == .productHeader{
            size.width = collectionView.bounds.size.width
            size.height = productHeaderHeight
        }else if sectionType == .product {
            let columns = CGFloat(2)
            size.width = floor((collectionView.bounds.size.width - (padding * (columns + 1))) / columns)
            size.height = ProductsCollectionViewCell.cellHeight(for: size.width, withActionButton: true)
        }else if sectionType == .relatedLooks {
            let columns:CGFloat = 2
            size.width = floor((collectionView.bounds.size.width - (padding * (columns + 1))) / columns)
            size.height = size.width * CGFloat(Double.goldenRatio)
        }else if sectionType == .error {
            size.width = collectionView.bounds.size.width
            size.height = 200
            
        }
        
        return size
    }
    public func collectionView(_ collectionView: UICollectionView, viewForHeaderWith text:String, hasBackgroundAndLine:Bool, hasFilterButton:Bool, indexPath: IndexPath) -> UICollectionReusableView {
        if let cell = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "header", for: indexPath) as? ProductsViewHeaderReusableView{
            cell.label.text = text
            cell.line.isHidden = !hasBackgroundAndLine
            cell.filterButton.isHidden = !hasFilterButton
            if hasBackgroundAndLine, let image = UIImage.init(named: "confetti") {
                cell.backgroundColor = UIColor.init(patternImage: image )
            }else {
                cell.backgroundColor = .clear
            }
            return cell
        }
        return UICollectionReusableView()
    }
    public func collectionView(_ collectionView: UICollectionView, viewForBackgroundWith color:UIColor?, indexPath: IndexPath) -> UICollectionReusableView {
        let cell = collectionView.dequeueReusableSupplementaryView(ofKind: SectionBackgroundCollectionViewFlowLayout.ElementKindSectionSectionBackground, withReuseIdentifier: "background", for: indexPath)
        cell.backgroundColor = color ?? .clear
        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath, withProductHeader:Product?) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "productHeader", for: indexPath)
        if let cell = cell  as? ProductHeaderCollectionViewCell, let product = withProductHeader{
            cell.productImageView.setImage(withURLString: product.imageURL)
            cell.favoriteControl.isSelected = product.isFavorite
            cell.priceLabel.text = product.price
            cell.merchantLabel.text = product.merchant
            cell.titleLabel.text = product.productTitle()
        }
        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath, with product:Product) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        if let cell = cell  as? ProductsCollectionViewCell{
            cell.contentView.backgroundColor = collectionView.backgroundColor
            self.setup(cell: cell, with: product)
        }
        return cell
    }
    public func setup(cell:ProductsCollectionViewCell, with product:Product) {
        
        cell.title = product.calculatedDisplayTitle
        cell.price = product.price
        cell.originalPrice = product.originalPrice
        cell.imageUrl = product.imageURL
        cell.isSale = product.isSale()
        cell.favoriteControl.isSelected = product.isFavorite
        cell.actionType = .buy
    }
    
    
    public func burrow(cell:ProductsCollectionViewCell, product: Product, fromVC: UIViewController) {
        AssetSyncModel.sharedInstance.addSubShoppable(fromProduct: product).then { shoppable -> Void in
            let uuid = UUID().uuidString
            
            cell.productView?.hero.id = "\(uuid)-image"
            cell.favoriteControl.hero.id = "\(uuid)-heart"
            
            fromVC.hero.isEnabled = true
            
            let vc = ProductDetailViewController.init()
            vc.product = product
            vc.shoppable = shoppable
            vc.uuid = uuid
            let _ = vc.view
            
            fromVC.navigationController?.hero.isEnabled = true
            fromVC.navigationController?.pushViewController(vc, animated: true)
            fromVC.navigationController?.hero.isEnabled = false
            
            Analytics.trackProductBurrow(product: product, order: nil, sort: nil)
        }

      
    }
    
    public func noProductsView() -> (HelperView, MainButton) {
        let verPadding: CGFloat = .extendedPadding
        let horPadding: CGFloat = .padding

       let helperView = HelperView()
        helperView.translatesAutoresizingMaskIntoConstraints = false
        helperView.layoutMargins = UIEdgeInsets(top: verPadding, left: horPadding, bottom: verPadding, right: horPadding)
        helperView.titleLabel.text = "products.helper.title".localized
        helperView.subtitleLabel.text = "products.helper.message".localized
        helperView.contentImage = UIImage(named: "ProductsEmptyListGraphic")
        
        let retryButton = MainButton()
        retryButton.translatesAutoresizingMaskIntoConstraints = false
        retryButton.backgroundColor = .crazeGreen
        retryButton.setTitle("products.helper.retry".localized, for: .normal)
        helperView.controlView.addSubview(retryButton)
        retryButton.topAnchor.constraint(equalTo: helperView.controlView.topAnchor).isActive = true
        retryButton.leadingAnchor.constraint(greaterThanOrEqualTo: helperView.controlView.layoutMarginsGuide.leadingAnchor).isActive = true
        retryButton.bottomAnchor.constraint(equalTo: helperView.controlView.bottomAnchor).isActive = true
        retryButton.trailingAnchor.constraint(greaterThanOrEqualTo: helperView.controlView.layoutMarginsGuide.trailingAnchor).isActive = true
        retryButton.centerXAnchor.constraint(equalTo: helperView.contentView.centerXAnchor).isActive = true
        return (helperView, retryButton)
    }
    
    func productsForShoppable(_ shoppable:Shoppable, productsOptions:ProductsOptions) -> [Product] {
        
        func stockOrder(a: Product, b: Product) -> Bool? {
            if a.hasVariants && !b.hasVariants {
                return true
            } else if !a.hasVariants && b.hasVariants {
                return false
            } else {
                return nil
            }
        }
        func titleOrder(a: Product, b: Product) -> Bool? {
            if let aDisplayTitle = a.calculatedDisplayTitle?.lowercased(),
                let bDisplayTitle = b.calculatedDisplayTitle?.lowercased(),
                aDisplayTitle != bDisplayTitle {
                return aDisplayTitle < bDisplayTitle
            } else if a.calculatedDisplayTitle == nil && b.calculatedDisplayTitle != nil {
                return false // Empty brands at end
            } else if a.calculatedDisplayTitle != nil && b.calculatedDisplayTitle == nil {
                return true // Empty brands at end
            } else {
                return nil
            }
        }

        if let mask = shoppable.getLast()?.rawValue,
          var products = shoppable.products?.filtered(using: NSPredicate(format: "(optionsMask & %d) == %d", mask, mask)) as? Set<Product> {
            if productsOptions.sale == .sale {
                products = products.filter { $0.floatPrice < $0.floatOriginalPrice }
            }
            let productArray: [Product]
            switch productsOptions.sort {
            case .similar :
                productArray = products.sorted { stockOrder(a: $0, b: $1) ?? ($0.order < $1.order) }
            case .priceAsc :
                productArray = products.sorted { stockOrder(a: $0, b: $1) ?? ($0.floatPrice < $1.floatPrice) }
            case .priceDes :
                productArray = products.sorted { stockOrder(a: $0, b: $1) ?? ($0.floatPrice > $1.floatPrice) }
            case .brands :
                productArray = products.sorted { stockOrder(a: $0, b: $1) ?? titleOrder(a: $0, b: $1) ?? ($0.order < $1.order) }
            }
            return productArray
        }
        
        return []
    }
    
    func startAndAddLoader(view:UIView) {
        let loader = self.loader ?? ( {
            let loader = Loader()
            loader.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(loader)
            loader.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
            loader.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
            
            
            return loader
            }())
        self.loader = loader
        loader.startAnimation()
    }
    
    func stopAndRemoveLoader() {
        if let loader = self.loader {
            loader.stopAnimation()
            loader.removeFromSuperview()
            self.loader = nil
        }
    }
}

