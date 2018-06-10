//
//  ProductsCollectionViewCell.swift
//  screenshot
//
//  Created by Jonathan Rose on 2/11/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class ProductsCollectionViewCell : UICollectionViewCell {
    enum ActionType: String {
        case none
        case buy
        
        var localized: String? {
            switch self {
            case .none:
                return ""
            case .buy:
                return "product.buy".localized
            }
        }
    }
    
    var title:String? {
        get {
            return self.titleLabel.text
        }
        set(newTitle){
            self.titleLabel.text = newTitle
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
            
            let attributes: [NSAttributedStringKey: Any] = [
                NSAttributedStringKey.foregroundColor: color,
                NSAttributedStringKey.strikethroughStyle: NSUnderlineStyle.styleSingle.rawValue,
                NSAttributedStringKey.strikethroughColor: color
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
            self.priceLabel?.layoutMargins = isSale ? ProductsCollectionViewCell.priceLabelLayoutMargins : .zero
        }
    }
    
    let favoriteControl = FavoriteControl()
    var productView:EmbossedView?
    let actionButton = BorderButton()
    let titleLabel = UILabel()
    var priceLabel:UILabel?
    var originalPriceLabel:UILabel?
    var originalPriceLabelWidthConstraint:NSLayoutConstraint?
    
    fileprivate var saleView: SaleView?
    
    static let labelFont = UIFont.systemFont(ofSize: 17)
    static let labelVerticalPadding:CGFloat = 6.0
    static let titleLabelNumberOfLines:Int = 1
    static let priceLabelLayoutMargins:UIEdgeInsets = UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: -8.0)
    static var titleLabelHeight:CGFloat = {
        return CGFloat(ceil( ProductsCollectionViewCell.labelFont.lineHeight + ProductsCollectionViewCell.labelVerticalPadding) ) * CGFloat(ProductsCollectionViewCell.titleLabelNumberOfLines)
    }()
    static var priceLabelHeight:CGFloat = {
        return ProductsCollectionViewCell.labelFont.lineHeight + ProductsCollectionViewCell.labelVerticalPadding
    }()
    
    static func cellHeight(for cellWidth: CGFloat, withActionButton: Bool = false) -> CGFloat {
        return cellWidth + ProductsCollectionViewCell.titleLabelHeight + ProductsCollectionViewCell.priceLabelHeight + actionButtonHeight(withActionButton)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews(){
        let productView:EmbossedView = {
            let productView = EmbossedView()
            productView.translatesAutoresizingMaskIntoConstraints = false
            productView.placeholderImage = UIImage.init(named:"DefaultProduct")
            productView.contentMode = .scaleAspectFit
            
            self.contentView.addSubview(productView)
            productView.topAnchor.constraint(equalTo: self.contentView.topAnchor).isActive = true
            productView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor).isActive = true
            productView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor).isActive = true
            let heightConstraint = productView.heightAnchor.constraint(equalTo: productView.widthAnchor)
            heightConstraint.priority = .defaultHigh
            heightConstraint.isActive = true
            return productView
        }()
        self.productView = productView
        self.contentView.backgroundColor = .clear
        self.backgroundColor = .clear
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.backgroundColor = .clear
        actionButton.setTitleColor(.crazeGreen, for: .normal)
        contentView.addSubview(actionButton)
        actionButton.topAnchor.constraint(equalTo: productView.bottomAnchor, constant: 8).isActive = true
        actionButton.leadingAnchor.constraint(equalTo: productView.leadingAnchor).isActive = true
        actionButton.trailingAnchor.constraint(equalTo: productView.trailingAnchor).isActive = true
        
        actionButtonHeightConstraint = actionButton.heightAnchor.constraint(equalToConstant: 0)
        actionButtonHeightConstraint?.isActive = true
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.numberOfLines = ProductsCollectionViewCell.titleLabelNumberOfLines
        titleLabel.minimumScaleFactor = 0.7
        titleLabel.baselineAdjustment = .alignCenters
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.textAlignment = .center
        titleLabel.font = ProductsCollectionViewCell.labelFont
        contentView.addSubview(titleLabel)
        titleLabel.topAnchor.constraint(equalTo: actionButton.bottomAnchor, constant: 2).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: productView.leadingAnchor).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: productView.trailingAnchor).isActive = true
        titleLabel.heightAnchor.constraint(equalToConstant: ProductsCollectionViewCell.titleLabelHeight).isActive = true
        
        let priceContainer:UIView = {
            let view = UIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            self.contentView.addSubview(view)
            
            view.topAnchor.constraint(equalTo: titleLabel.bottomAnchor).isActive = true
            view.leadingAnchor.constraint(greaterThanOrEqualTo: productView.leadingAnchor).isActive = true
            view.bottomAnchor.constraint(lessThanOrEqualTo: self.contentView.bottomAnchor).isActive = true
            view.trailingAnchor.constraint(lessThanOrEqualTo: productView.trailingAnchor).isActive = true
            view.centerXAnchor.constraint(equalTo: productView.centerXAnchor).isActive = true
            
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
            label.setContentCompressionResistancePriority(.required, for: .horizontal)
            
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
        
        let saleView: SaleView = {
            let view = SaleView()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.isHidden = true
            productView.addSubview(view)
            view.leadingAnchor.constraint(equalTo: productView.leadingAnchor).isActive = true
            view.bottomAnchor.constraint(equalTo: productView.bottomAnchor, constant: -6).isActive = true
            return view
        }()
        self.saleView = saleView
    }
    
    // MARK: Action Button
    
    var actionType: ActionType = .none {
        didSet {
            actionButtonHeightConstraint?.constant = ProductsCollectionViewCell.actionButtonHeight(hasActionButton)
            actionButton.setTitle(actionType.localized, for: .normal)
        }
    }
    
    var hasActionButton: Bool {
        return actionType != .none
    }
    
    fileprivate var actionButtonHeightConstraint: NSLayoutConstraint?
    
    fileprivate static func actionButtonHeight(_ hasActionButton: Bool) -> CGFloat {
        return hasActionButton ? 40 : 0
    }
    
    // MARK: External Indicator
    
    var productImageView: UIImageView? {
        return self.productView?.imageView
    }
}
