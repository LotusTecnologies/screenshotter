//
//  ProductCollectionViewCell+swift.swift
//  screenshot
//
//  Created by Jonathan Rose on 2/11/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation

@objc protocol ProductCollectionViewCellDelegate : NSObjectProtocol {
    func productCollectionViewCellDidTapFavorite(cell:ProductCollectionViewCell)
}
class ProductCollectionViewCell : UICollectionViewCell {
    
    weak var delegate:ProductCollectionViewCellDelegate?
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
            if let newString = newOriginalPrice, newString.lengthOfBytes(using: .utf8) > 0 {
                let attributes: [String: Any] = [
                    NSForegroundColorAttributeName : UIColor.gray6,
                    NSStrikethroughStyleAttributeName : NSUnderlineStyle.styleSingle.rawValue,
                    NSStrikethroughColorAttributeName:UIColor.gray6
                ]
                self.originalPriceLabel?.attributedText = NSAttributedString.init(string: newString, attributes: attributes)
                
            }else{
                self.originalPriceLabel?.attributedText = nil;
                
            }
        }
    }
    var imageUrl:String? {
        didSet {
            self.productView?.setImage(withURLString: imageUrl)
            
        }
    }
    var isSale:Bool = false {
        didSet {
            self.saleImageView?.isHidden = !isSale;
            self.originalPriceLabel?.isHidden = !isSale;
            self.originalPriceLabelWidthConstraint?.isActive = !isSale;
            self.priceLabel?.layoutMargins = isSale ?  ProductCollectionViewCell.priceLabelLayoutMargins : .zero;
        }
    }
    var favoriteButton:FavoriteButton?
    
    var productView:EmbossedView?
    var titleLabel:UILabel?
    var priceLabel:UILabel?
    var originalPriceLabel:UILabel?
    var originalPriceLabelWidthConstraint:NSLayoutConstraint?
    var saleImageView:UIImageView?
    
    static let labelFont = UIFont.systemFont(ofSize: 17)
    static let labelVerticalPadding:CGFloat = 6.0
    static let titleLabelNumberOfLines:Int = 1
    static let priceLabelLayoutMargins:UIEdgeInsets = UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: -8.0)
    static var titleLableHeight:CGFloat = {
        return CGFloat(ceil( ProductCollectionViewCell.labelFont.lineHeight + ProductCollectionViewCell.labelVerticalPadding) ) * CGFloat(ProductCollectionViewCell.titleLabelNumberOfLines)
    }()
    static var priceLabelHeight:CGFloat = {
        return ProductCollectionViewCell.labelFont.lineHeight + ProductCollectionViewCell.labelVerticalPadding
    }()
    static var labelsHeight = {
        return ProductCollectionViewCell.titleLableHeight + ProductCollectionViewCell.priceLabelHeight
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupViews()
    }
    
    func setupViews(){
        let productView:EmbossedView =  {
            let pathRect = CGRect.init(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.width)
            
            let productView = EmbossedView()
            
            productView.translatesAutoresizingMaskIntoConstraints = false;
            productView.placeholderImage = UIImage.init(named:"DefaultProduct");
            
            productView.layer.shadowPath = UIBezierPath.init(roundedRect: _Shadow.pathRect(pathRect), cornerRadius: Geometry.defaultCornerRadius).cgPath
            self.contentView.addSubview(productView)
            productView.topAnchor.constraint(equalTo: self.contentView.topAnchor).isActive = true
            productView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor).isActive = true
            productView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor).isActive = true
            productView.heightAnchor.constraint(equalTo: productView.widthAnchor).isActive = true
            return productView
        }()
        
        self.productView = productView
        
        let titleLabel: UILabel = {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.numberOfLines = ProductCollectionViewCell.titleLabelNumberOfLines
            label.minimumScaleFactor = 0.7
            label.adjustsFontSizeToFitWidth = true
            label.textAlignment = .center
            label.font = ProductCollectionViewCell.labelFont
            self.contentView.addSubview(label)
            
            NSLayoutConstraint.init(item: label, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: ProductCollectionViewCell.titleLableHeight).isActive = true
            
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
            
            return view;
        }()
        
        
        let priceLabel:UILabel = {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.textAlignment = .center
            label.font = ProductCollectionViewCell.labelFont
            label.textColor = .gray6
            label.minimumScaleFactor = 0.7
            label.adjustsFontSizeToFitWidth = true
            label.layoutMargins = ProductCollectionViewCell.priceLabelLayoutMargins
            self.contentView.addSubview(label)
            label.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
            
            label.addConstraint( NSLayoutConstraint.init(item: label, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: ProductCollectionViewCell.priceLabelHeight))
            
            label.topAnchor.constraint(equalTo: priceContainer.topAnchor).isActive = true
            label.leadingAnchor.constraint(equalTo: priceContainer.leadingAnchor).isActive = true
            label.bottomAnchor.constraint(lessThanOrEqualTo: priceContainer.bottomAnchor).isActive = true
            
            return label
        }()
        
        self.priceLabel = priceLabel
        let originalPriceLabel:UILabel = {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false;
            label.textAlignment = .center;
            label.font = ProductCollectionViewCell.labelFont
            label.textColor = .gray7
            label.minimumScaleFactor = 0.7
            label.adjustsFontSizeToFitWidth = true;
            label.isHidden = true;
            self.contentView.addSubview(label)
            
            label.addConstraint( NSLayoutConstraint.init(item: label, attribute: .height, relatedBy: .equal, toItem:nil, attribute: .notAnAttribute, multiplier: 1.0, constant: ProductCollectionViewCell.priceLabelHeight))
            
            label.topAnchor.constraint(equalTo: priceContainer.topAnchor).isActive = true
            label.leadingAnchor.constraint(equalTo:priceLabel.layoutMarginsGuide.trailingAnchor).isActive = true
            label.trailingAnchor.constraint(equalTo: priceContainer.trailingAnchor).isActive = true
            label.bottomAnchor.constraint(lessThanOrEqualTo: priceContainer.bottomAnchor).isActive = true
            
            
            self.originalPriceLabelWidthConstraint = label.widthAnchor.constraint(equalToConstant: 0.0)
            
            return label;
        }()
        self.originalPriceLabel = originalPriceLabel;
        let favoriteButton : FavoriteButton = {
            let button = FavoriteButton.init()
            
            button.translatesAutoresizingMaskIntoConstraints = false;
            button.addTarget(self, action: #selector(favoriteAction), for: .touchUpInside)
            self.contentView.addSubview(button)
            
            button.topAnchor.constraint(equalTo: self.contentView.topAnchor).isActive = true
            button.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor).isActive = true
            
            return button;
        }()
        self.favoriteButton = favoriteButton
        
        let saleImageView:UIImageView = {
            let padding:CGFloat = 6.0
            let resizableImageInsets = UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 4.0)
            
            let image = UIImage.init(named: "ProductSaleBanner")?.resizableImage(withCapInsets: resizableImageInsets)
            
            let imageView = UIImageView.init(image: image)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.layoutMargins = UIEdgeInsets.init(top: 0, left: padding, bottom: 0, right: padding + resizableImageInsets.right)
            imageView.isHidden = true;
            self.productView?.addSubview(imageView)
            
            imageView.leadingAnchor.constraint(equalTo:productView.leadingAnchor).isActive = true
            imageView.bottomAnchor.constraint(equalTo:productView.bottomAnchor, constant:(-1 * Geometry.defaultCornerRadius)).isActive = true
            
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false;
            label.textColor = .white
            label.font = UIFont.boldSystemFont(ofSize: 10.0)
            label.textAlignment = .center;
            label.text = "SALE";
            imageView.addSubview(label)
            label.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
            
            label.topAnchor.constraint(equalTo:imageView.topAnchor).isActive = true
            label.leadingAnchor.constraint(equalTo:imageView.layoutMarginsGuide.leadingAnchor).isActive = true
            label.bottomAnchor.constraint(equalTo:imageView.bottomAnchor).isActive = true
            label.trailingAnchor.constraint(equalTo:imageView.layoutMarginsGuide.trailingAnchor).isActive = true
            
            return imageView;
        }()
        self.saleImageView = saleImageView
        
    }
    @objc func favoriteAction() {
        self.delegate?.productCollectionViewCellDidTapFavorite(cell: self)
    }
    
}
