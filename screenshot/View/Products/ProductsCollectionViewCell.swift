//
//  ProductsCollectionViewCell.swift
//  screenshot
//
//  Created by Jonathan Rose on 2/11/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class ProductsCollectionViewCell : UICollectionViewCell {
    var title:String? {
        get {
            return self.titleLabel?.text
        }
        set(newTitle){
            self.titleLabel?.text = newTitle
        }
    }
    var price:String? {
        get {
            return self.priceLabel?.text
        }
        set(newPrice){
            self.priceLabel?.text = newPrice
        }
    }
    var originalPrice:String? {
        get{
            return self.originalPriceLabel?.text
        }
        set(newOriginalPrice){
            guard let newString = newOriginalPrice, !newString.isEmpty else {
                self.originalPriceLabel?.attributedText = nil
                return
            }
            
            let color: UIColor = .gray6
            
            let attributes: [String: Any] = [
                NSForegroundColorAttributeName: color,
                NSStrikethroughStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue,
                NSStrikethroughColorAttributeName: color
            ]
            
            self.originalPriceLabel?.attributedText = NSAttributedString.init(string: newString, attributes: attributes)
        }
    }
    var imageUrl:String? {
        didSet {
            self.productView?.setImage(withURLString: imageUrl)
            
        }
    }
    var isSale:Bool = false {
        didSet {
            self.saleView?.isHidden = !isSale
            self.originalPriceLabel?.isHidden = !isSale
            self.originalPriceLabelWidthConstraint?.isActive = !isSale
            self.priceLabel?.layoutMargins = isSale ?  ProductsCollectionViewCell.priceLabelLayoutMargins : .zero
        }
    }
    
    let favoriteControl = FavoriteControl()
    var productView:EmbossedView?
    var titleLabel:UILabel?
    var priceLabel:UILabel?
    var originalPriceLabel:UILabel?
    var originalPriceLabelWidthConstraint:NSLayoutConstraint?
    fileprivate var saleView: SaleView?
    
    static let labelFont = UIFont.systemFont(ofSize: 17)
    static let labelVerticalPadding:CGFloat = 6.0
    static let titleLabelNumberOfLines:Int = 1
    static let priceLabelLayoutMargins:UIEdgeInsets = UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: -8.0)
    static var titleLableHeight:CGFloat = {
        return CGFloat(ceil( ProductsCollectionViewCell.labelFont.lineHeight + ProductsCollectionViewCell.labelVerticalPadding) ) * CGFloat(ProductsCollectionViewCell.titleLabelNumberOfLines)
    }()
    static var priceLabelHeight:CGFloat = {
        return ProductsCollectionViewCell.labelFont.lineHeight + ProductsCollectionViewCell.labelVerticalPadding
    }()
    
    static func cellHeight(for cellWidth: CGFloat, withBottomLabel: Bool = false) -> CGFloat {
        return cellWidth + ProductsCollectionViewCell.titleLableHeight + ProductsCollectionViewCell.priceLabelHeight + buyLabelHeight(withBottomLabel)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupViews()
    }
    
    func setupViews(){
        let productView:EmbossedView = {
            let productView = EmbossedView()
            
            productView.translatesAutoresizingMaskIntoConstraints = false
            productView.placeholderImage = UIImage.init(named:"DefaultProduct")
            
            self.contentView.addSubview(productView)
            productView.topAnchor.constraint(equalTo: self.contentView.topAnchor).isActive = true
            productView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor).isActive = true
            productView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor).isActive = true
            return productView
        }()
        self.productView = productView
        
        let titleLabel: UILabel = {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.numberOfLines = ProductsCollectionViewCell.titleLabelNumberOfLines
            label.minimumScaleFactor = 0.7
            label.baselineAdjustment = .alignCenters
            label.adjustsFontSizeToFitWidth = true
            label.textAlignment = .center
            label.font = ProductsCollectionViewCell.labelFont
            self.contentView.addSubview(label)
            
            NSLayoutConstraint.init(item: label, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: ProductsCollectionViewCell.titleLableHeight).isActive = true
            
            label.topAnchor.constraint(equalTo: productView.bottomAnchor).isActive = true
            label.leadingAnchor.constraint(equalTo: productView.leadingAnchor).isActive = true
            label.trailingAnchor.constraint(equalTo: productView.trailingAnchor).isActive = true
            
            return label
        }()
        self.titleLabel = titleLabel
        
        let priceContainer:UIView = {
            let view = UIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            self.contentView.addSubview(view)
            
            view.topAnchor.constraint(equalTo: titleLabel.bottomAnchor).isActive = true
            view.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.leadingAnchor).isActive = true
            view.bottomAnchor.constraint(lessThanOrEqualTo: self.contentView.bottomAnchor).isActive = true
            view.trailingAnchor.constraint(lessThanOrEqualTo: titleLabel.trailingAnchor).isActive = true
            view.centerXAnchor.constraint(equalTo: titleLabel.centerXAnchor).isActive = true
            
            return view
        }()
        
        let priceLabel:UILabel = {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.textAlignment = .center
            label.font = ProductsCollectionViewCell.labelFont
            label.textColor = .gray6
            label.minimumScaleFactor = 0.7
            label.baselineAdjustment = .alignCenters
            label.adjustsFontSizeToFitWidth = true
            label.layoutMargins = ProductsCollectionViewCell.priceLabelLayoutMargins
            self.contentView.addSubview(label)
            label.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
            
            label.addConstraint( NSLayoutConstraint.init(item: label, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: ProductsCollectionViewCell.priceLabelHeight))
            
            label.topAnchor.constraint(equalTo: priceContainer.topAnchor).isActive = true
            label.leadingAnchor.constraint(equalTo: priceContainer.leadingAnchor).isActive = true
            label.bottomAnchor.constraint(lessThanOrEqualTo: priceContainer.bottomAnchor).isActive = true
            
            return label
        }()
        self.priceLabel = priceLabel
        
        let originalPriceLabel:UILabel = {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.textAlignment = .center
            label.font = ProductsCollectionViewCell.labelFont
            label.textColor = .gray7
            label.minimumScaleFactor = 0.7
            label.baselineAdjustment = .alignCenters
            label.adjustsFontSizeToFitWidth = true
            label.isHidden = true
            self.contentView.addSubview(label)
            
            label.addConstraint( NSLayoutConstraint.init(item: label, attribute: .height, relatedBy: .equal, toItem:nil, attribute: .notAnAttribute, multiplier: 1.0, constant: ProductsCollectionViewCell.priceLabelHeight))
            
            label.topAnchor.constraint(equalTo: priceContainer.topAnchor).isActive = true
            label.leadingAnchor.constraint(equalTo:priceLabel.layoutMarginsGuide.trailingAnchor).isActive = true
            label.trailingAnchor.constraint(equalTo: priceContainer.trailingAnchor).isActive = true
            label.bottomAnchor.constraint(lessThanOrEqualTo: priceContainer.bottomAnchor).isActive = true
            
            
            self.originalPriceLabelWidthConstraint = label.widthAnchor.constraint(equalToConstant: 0.0)
            
            return label
        }()
        self.originalPriceLabel = originalPriceLabel
        
        favoriteControl.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(favoriteControl)
        favoriteControl.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        favoriteControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        
        let buyLabel: UILabel = {
            let label = UILabel()
            productView.contentView.addSubview(label)
            
            label.translatesAutoresizingMaskIntoConstraints = false
            label.leadingAnchor.constraint(equalTo: productView.leadingAnchor).isActive = true
            label.trailingAnchor.constraint(equalTo: productView.trailingAnchor).isActive = true
            label.bottomAnchor.constraint(equalTo: productView.bottomAnchor).isActive = true
            
            let constant = ProductsCollectionViewCell.buyLabelHeight(hasBuyLabel)
            buyLabelHeightConstraint = label.heightAnchor.constraint(equalToConstant: constant)
            buyLabelHeightConstraint?.isActive = true
            
            label.backgroundColor = .white
            label.text = "generic.buy".localized
            label.textColor = .crazeGreen
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: UIFont.buttonFontSize, weight: UIFontWeightMedium)
            return label
        }()
        
        let saleView: SaleView = {
            let view = SaleView()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.isHidden = true
            productView.addSubview(view)
            view.leadingAnchor.constraint(equalTo: productView.leadingAnchor).isActive = true
            view.bottomAnchor.constraint(equalTo: buyLabel.topAnchor, constant: -6).isActive = true
            return view
        }()
        self.saleView = saleView
    }
    
    // MARK: Buy Label
    
    fileprivate static func buyLabelHeight(_ hasBuyLabel: Bool) -> CGFloat {
        return hasBuyLabel ? 40 : 0
    }
    
    fileprivate var buyLabelHeightConstraint: NSLayoutConstraint?
    
    var hasBuyLabel: Bool = false {
        didSet {
            buyLabelHeightConstraint?.constant = ProductsCollectionViewCell.buyLabelHeight(hasBuyLabel)
        }
    }
}
