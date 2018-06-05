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
class ProductDetailViewController: UIViewController { //}, UICollectionViewDataSource, UICollectionViewDelegate{

    var collectionView:UICollectionView?
    var product:Product?
    var products:[Product] = []

    var productImageView:EmbossedView =  EmbossedView()
    let favoriteControl = FavoriteControl()

    var titleLabel = UILabel()
    var priceLabel = UILabel()
    let buyNowButton = BorderButton()
    let merchantLabel = UILabel()
    let shareButton = UIButton()
    

    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.view.backgroundColor = .white
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
            collectionView.register(ProductsCollectionViewCell.self, forCellWithReuseIdentifier: "cell")

            collectionView.register(RelatedLooksCollectionViewCell.self, forCellWithReuseIdentifier: "relatedLooks")
            collectionView.register(SpinnerCollectionViewCell.self, forCellWithReuseIdentifier: "relatedLooks-spinner")
            collectionView.register(ErrorCollectionViewCell.self, forCellWithReuseIdentifier: "relatedLooks-error")
            collectionView.register(ProductsViewHeaderReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "header")
            collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: SectionBackgroundCollectionViewFlowLayout.ElementKindSectionSectionBackground, withReuseIdentifier: "background")
            
            self.view.insertSubview(collectionView, at: 0)
            collectionView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
            collectionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
            collectionView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
            collectionView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
            
            return collectionView
        }()
        self.collectionView = collectionView
        self.collectionView?.contentInset = UIEdgeInsetsMake(200, 0, 0, 0)
        
        
        let contentView = UIView()
        contentView.backgroundColor = .white
        contentView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(contentView)
        contentView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        contentView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        contentView.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor).isActive = true
        contentView.heightAnchor.constraint(equalToConstant: 200).isActive = true

        let halfPadding: CGFloat = .padding / 2
        
        let labelsContainerView = UIView()
        labelsContainerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(labelsContainerView)
        labelsContainerView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor).isActive = true
        labelsContainerView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        labelsContainerView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.numberOfLines = 2
        titleLabel.font = .screenshopFont(.hindLight, textStyle: .body)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: -halfPadding, right: 0)
        labelsContainerView.addSubview(titleLabel)
        titleLabel.topAnchor.constraint(equalTo: labelsContainerView.topAnchor).isActive = true
        
            titleLabel.bottomAnchor.constraint(equalTo: labelsContainerView.bottomAnchor).isActive = true
        
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        priceLabel.textColor = .crazeGreen
        priceLabel.font = .screenshopFont(.hindMedium, textStyle: .body)
        priceLabel.adjustsFontForContentSizeCategory = true
        labelsContainerView.addSubview(priceLabel)
        priceLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        priceLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        priceLabel.trailingAnchor.constraint(equalTo: labelsContainerView.trailingAnchor).isActive = true
        
            priceLabel.topAnchor.constraint(equalTo: labelsContainerView.topAnchor).isActive = true
            priceLabel.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: .padding).isActive = true
      
        
        productImageView.translatesAutoresizingMaskIntoConstraints = false
        productImageView.contentMode = .scaleAspectFill
        productImageView.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -.padding)
        contentView.addSubview(productImageView)
        productImageView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        productImageView.widthAnchor.constraint(equalToConstant: 120).isActive = true
        productImageView.heightAnchor.constraint(equalTo: productImageView.widthAnchor).isActive = true
        
            productImageView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor).isActive = true
            productImageView.trailingAnchor.constraint(equalTo: titleLabel.leadingAnchor, constant: productImageView.layoutMargins.right).isActive = true
       
        
        favoriteControl.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(favoriteControl)
        favoriteControl.topAnchor.constraint(equalTo: productImageView.topAnchor).isActive = true
        favoriteControl.trailingAnchor.constraint(equalTo: productImageView.trailingAnchor).isActive = true
        
        merchantLabel.translatesAutoresizingMaskIntoConstraints = false
        merchantLabel.font = .screenshopFont(.hindLight, size: 15)
        merchantLabel.adjustsFontSizeToFitWidth = true
        merchantLabel.minimumScaleFactor = 0.7
        merchantLabel.baselineAdjustment = .alignCenters
        merchantLabel.textAlignment = .center
        contentView.addSubview(merchantLabel)
        merchantLabel.topAnchor.constraint(equalTo: productImageView.bottomAnchor, constant: 10).isActive = true
        merchantLabel.leadingAnchor.constraint(equalTo: productImageView.leadingAnchor).isActive = true
        merchantLabel.firstBaselineAnchor.constraint(lessThanOrEqualTo: contentView.layoutMarginsGuide.bottomAnchor).isActive = true
        merchantLabel.trailingAnchor.constraint(equalTo: productImageView.trailingAnchor).isActive = true
        
       
//        shareButton.translatesAutoresizingMaskIntoConstraints = false
//        shareButton.setImage(UIImage(named: "ScreenshotShare"), for: .normal)
//        shareButton.contentEdgeInsets = .init(top: 10, left: contentView.layoutMargins.right, bottom: 10, right: contentView.layoutMargins.right)
//        contentView.addSubview(shareButton)
//        shareButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
//        shareButton.centerYAnchor.constraint(equalTo: priceAlertButton.centerYAnchor).isActive = true
        
        buyNowButton.translatesAutoresizingMaskIntoConstraints = false
        buyNowButton.setTitle("product.buy_now".localized, for: .normal)
        buyNowButton.setTitleColor(.crazeGreen, for: .normal)
        contentView.addSubview(buyNowButton)
        buyNowButton.leadingAnchor.constraint(equalTo: productImageView.layoutMarginsGuide.trailingAnchor).isActive = true
        buyNowButton.bottomAnchor.constraint(lessThanOrEqualTo: contentView.layoutMarginsGuide.bottomAnchor).isActive = true
        buyNowButton.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        buyNowButton.topAnchor.constraint(equalTo: labelsContainerView.bottomAnchor, constant: halfPadding).isActive = true
        
        
        if let product = product {
            productImageView.setImage(withURLString: product.imageURL)
            favoriteControl.isSelected = product.isFavorite
            priceLabel.text = product.price
            merchantLabel.text = product.merchant
            titleLabel.text = product.productTitle()
            
        }
        
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

}


extension ProductDetailViewController : UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    var numberOfCollectionViewProductColumns: Int {
        return 2
    }
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
       
        return self.products.count
            
      
    }
    
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        var size:CGSize = .zero
        let shadowInsets = ScreenshotCollectionViewCell.shadowInsets
        let padding: CGFloat = .padding - shadowInsets.left - shadowInsets.right
        
        let columns = CGFloat(numberOfCollectionViewProductColumns)
        size.width = floor((collectionView.bounds.size.width - (padding * (columns + 1))) / columns)
        size.height = ProductsCollectionViewCell.cellHeight(for: size.width, withBottomLabel: true)
        
        
        return size
    }
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let product = self.products[indexPath.item]
        
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? ProductsCollectionViewCell {
            cell.contentView.backgroundColor = collectionView.backgroundColor
            cell.title = product.calculatedDisplayTitle
            cell.price = product.price
            cell.originalPrice = product.originalPrice
            cell.imageUrl = product.imageURL
            cell.isSale = product.isSale()
            cell.favoriteControl.isSelected = product.isFavorite
            cell.favoriteControl.addTarget(self, action: #selector(productCollectionViewCellFavoriteAction(_:event:)), for: .touchUpInside)
            cell.hasExternalPreview = !product.isSupportingUSC
            cell.actionType = product.hasVariants || product.dateCheckedStock == nil ? .buy : .outStock
            return cell
        }
        
        return UICollectionViewCell()
    }
    
    public func collectionViewMinimumSpacing() -> CGPoint {
        let shadowInsets = ScreenshotCollectionViewCell.shadowInsets
        let p: CGFloat = .padding
        return CGPoint(x: p - shadowInsets.left - shadowInsets.right, y: p - shadowInsets.top - shadowInsets.bottom)
    }
    
    public func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    func productAtIndex(_ index: Int) -> Product {
        return self.products[index]
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
            let minimumSpacing:CGPoint = self.collectionViewMinimumSpacing()
            return UIEdgeInsets(top: minimumSpacing.y, left: minimumSpacing.x, bottom: 30, right: minimumSpacing.x)
       
        
    }
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize.init(width: collectionView.bounds.size.width, height: 80)
        
    }
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {

        if kind == UICollectionElementKindSectionHeader {
            if let cell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "header", for: indexPath) as? ProductsViewHeaderReusableView{
                cell.label.text = "products.related_looks.headline".localized
                return cell
            }
        }
        return UICollectionReusableView()
    }
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
       
        let product = self.productAtIndex(indexPath.item)
            product.recordViewedProduct()
        let uuid = UUID().uuidString
        if let cell = collectionView.cellForItem(at: indexPath) as? ProductsCollectionViewCell{
            cell.productImageView?.hero.id = "\(uuid)-image"
            cell.favoriteControl.hero.id = "\(uuid)-heart"
        }
        
        self.hero.isEnabled = true
        
        let vc = ProductDetailViewController.init()
        vc.product = product
        vc.productImageView.hero.id = "\(uuid)-image"
        vc.favoriteControl.hero.id = "\(uuid)-heart"
        vc.products = self.products
        let _ = vc.view
        if let navigationController = self.navigationController{
            navigationController.hero.isEnabled = true
            navigationController.pushViewController(vc, animated: true)
            navigationController.hero.isEnabled = false
        }
        
        Analytics.trackProductBurrow(product: product, order: nil, sort: nil)
        
    }
    
    @objc func productCollectionViewCellFavoriteAction(_ favoriteControl: FavoriteControl, event: UIEvent) {
        guard let indexPath = collectionView?.indexPath(for: event) else {
            return
        }
        
        let isFavorited = favoriteControl.isSelected
        let product = self.productAtIndex(indexPath.item)
        
        product.setFavorited(toFavorited: isFavorited)
        
        if isFavorited {
            let _ = ShoppingCartModel.shared.populateVariants(productOID: product.objectID)
            Analytics.trackProductFavorited(product: product, page: .productList)
        }else{
            Analytics.trackProductUnfavorited(product: product, page: .productList)
        }
    }
}

