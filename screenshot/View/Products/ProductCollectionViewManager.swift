//
//  ProductCollectionViewManager.swift
//  screenshot
//
//  Created by Jonathan Rose on 6/7/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation
import PromiseKit

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
            size.height = ProductsCollectionViewCell.cellHeight(for: size.width, withBottomLabel: true)
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
            cell.hasExternalPreview = !product.isSupportingUSC
            cell.actionType = product.hasVariants || product.dateCheckedStock == nil ? .buy : .outStock
        }
        return cell
       
    }
    
    
}
