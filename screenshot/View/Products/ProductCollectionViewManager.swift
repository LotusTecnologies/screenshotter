//
//  ProductCollectionViewManager.swift
//  screenshot
//
//  Created by Jonathan Rose on 6/7/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation
import PromiseKit
import Hero
protocol ProductCollectionViewManagerDelegate : class {
    var rootProduct:Product? { get }
    var products:[Product] { get }
    var loadingState:ProductsViewControllerState { get }
    var relatedLooks:Promise<[String]>? { get }
    func hasRelatedLooksSection() -> Bool
    var collectionView:UICollectionView? {get}

}

class ProductCollectionViewManager {
    
    
    weak var delegate:ProductCollectionViewManagerDelegate?
    
    
    
    public func setup(collectionView:UICollectionView){
        collectionView.register(ProductsCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.register(RelatedLooksCollectionViewCell.self, forCellWithReuseIdentifier: "relatedLooks")
        collectionView.register(SpinnerCollectionViewCell.self, forCellWithReuseIdentifier: "relatedLooks-spinner")
        collectionView.register(ErrorCollectionViewCell.self, forCellWithReuseIdentifier: "relatedLooks-error")
        collectionView.register(ProductsViewHeaderReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "header")
        collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: SectionBackgroundCollectionViewFlowLayout.ElementKindSectionSectionBackground, withReuseIdentifier: "background")
        
        collectionView.register(ProductHeaderCollectionViewCell.self, forCellWithReuseIdentifier: "productHeader")

        
    }
    
    
    public func collectionView(_ collectionView: UICollectionView, sizeForItemInSectionType sectionType: ProductsSection) -> CGSize {
        
        var size:CGSize = .zero
        let shadowInsets = ScreenshotCollectionViewCell.shadowInsets
        let padding: CGFloat = .padding - shadowInsets.left - shadowInsets.right
        if sectionType == .productHeader{
            size.width = collectionView.bounds.size.width
            size.height = 200
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
    public func collectionView(_ collectionView: UICollectionView, viewForHeaderWith text:String, indexPath: IndexPath) -> UICollectionReusableView {
        if let cell = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "header", for: indexPath) as? ProductsViewHeaderReusableView{
                cell.label.text = text
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
            cell.title = product.calculatedDisplayTitle
            cell.price = product.price
            cell.originalPrice = product.originalPrice
            cell.imageUrl = product.imageURL
            cell.isSale = product.isSale()
            cell.favoriteControl.isSelected = product.isFavorite
            cell.actionType = .buy
        }
        return cell
       
    }
    
    
    public func burrow(cell:ProductsCollectionViewCell, product: Product, fromVC: UIViewController) {

        let uuid = UUID().uuidString
        cell.productImageView?.hero.id = "\(uuid)-image"
        cell.favoriteControl.hero.id = "\(uuid)-heart"

        
        fromVC.hero.isEnabled = true
        
        let vc = ProductDetailViewController.init()
        vc.product = product
        vc.uuid = uuid
        vc.products = product.shoppable?.products?.allObjects as? [Product] ?? []
        let _ = vc.view
        
        fromVC.navigationController?.hero.isEnabled = true
        fromVC.navigationController?.pushViewController(vc, animated: true)
        fromVC.navigationController?.hero.isEnabled = false
        
        Analytics.trackProductBurrow(product: product, order: nil, sort: nil)
    }
}
