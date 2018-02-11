//
//  ProductCollectionViewCell+swift.swift
//  screenshot
//
//  Created by Jonathan Rose on 2/11/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation
extension ProductCollectionViewCell {
    @objc func setupProductView(){
        self.productView = {
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
        
    }
    @objc func setupTitleView() {
        self.titleLabel = {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.numberOfLines = ProductCollectionViewCell.titleLabelNumberOfLines()
            label.minimumScaleFactor = 0.7
            label.adjustsFontSizeToFitWidth = true
            label.textAlignment = .center
            label.font = ProductCollectionViewCell.labelFont()
            self.contentView.addSubview(label)
            
            NSLayoutConstraint.init(item: label, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: ProductCollectionViewCell.titleLableHeight()).isActive = true
            
            label.topAnchor.constraint(equalTo: self.productView.bottomAnchor).isActive = true
            label.leadingAnchor.constraint(equalTo: self.productView.leadingAnchor).isActive = true
            label.trailingAnchor.constraint(equalTo: self.productView.trailingAnchor).isActive = true
            
            return label
        }()
    }
    
   
    @objc func setupPriceLabels() {
        let priceContainer:UIView = {
            let view = UIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            self.contentView.addSubview(view)
            
            view.topAnchor.constraint(equalTo: self.titleLabel.bottomAnchor).isActive = true
            view.leadingAnchor.constraint(greaterThanOrEqualTo: self.titleLabel.leadingAnchor).isActive = true
            view.bottomAnchor.constraint(lessThanOrEqualTo: self.contentView.bottomAnchor).isActive = true
            view.trailingAnchor.constraint(lessThanOrEqualTo: self.titleLabel.trailingAnchor).isActive = true
            view.centerXAnchor.constraint(equalTo: self.titleLabel.centerXAnchor).isActive = true
            
            return view;
        }()
        
        
        priceLabel = {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.textAlignment = .center
            label.font = ProductCollectionViewCell.labelFont()
            label.textColor = .gray6
            label.minimumScaleFactor = 0.7
            label.adjustsFontSizeToFitWidth = true
            label.layoutMargins = self.priceLabelLayoutMargins()
            self.contentView.addSubview(label)
            label.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
            
            label.addConstraint( NSLayoutConstraint.init(item: label, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: ProductCollectionViewCell.priceLabelHeight()))
            
            label.topAnchor.constraint(equalTo: priceContainer.topAnchor).isActive = true
            label.leadingAnchor.constraint(equalTo: priceContainer.leadingAnchor).isActive = true
            label.bottomAnchor.constraint(equalTo: priceContainer.bottomAnchor).isActive = true
            
            return label
        }()
        
        originalPriceLabel = {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false;
            label.textAlignment = .center;
            label.font = ProductCollectionViewCell.labelFont()
            label.textColor = .gray7
            label.minimumScaleFactor = 0.7
            label.adjustsFontSizeToFitWidth = true;
            label.isHidden = true;
            self.contentView.addSubview(label)
            
            label.addConstraint( NSLayoutConstraint.init(item: label, attribute: .height, relatedBy: .equal, toItem:nil, attribute: .notAnAttribute, multiplier: 1.0, constant: ProductCollectionViewCell.priceLabelHeight()))
            
            label.topAnchor.constraint(equalTo: priceContainer.topAnchor).isActive = true
            label.leadingAnchor.constraint(equalTo:self.priceLabel.layoutMarginsGuide.trailingAnchor).isActive = true
            label.trailingAnchor.constraint(equalTo: priceContainer.trailingAnchor).isActive = true
            label.bottomAnchor.constraint(equalTo: priceContainer.bottomAnchor).isActive = true
            
            
            self.originalPriceLabelWidthConstraint = label.widthAnchor.constraint(equalToConstant: 0.0)
            
            return label;
        }()
 
    }
    
    @objc func setupFavoriteButton(){
        self.favoriteButton = {
            let button = FavoriteButton.init()
            
            button.translatesAutoresizingMaskIntoConstraints = false;
            button.addTarget(self, action: #selector(favoriteAction), for: .touchUpInside)
            self.contentView.addSubview(button)
            
            button.topAnchor.constraint(equalTo: self.contentView.topAnchor).isActive = true
            button.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor).isActive = true
            
            return button;
        }()
        
    }
    @objc func setupSaleImageView() {
        
        self.saleImageView = {
            let padding:CGFloat = 6.0
            let resizableImageInsets = UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 4.0)
            
            let image = UIImage.init(named: "ProductSaleBanner")?.resizableImage(withCapInsets: resizableImageInsets)
            
            let imageView = UIImageView.init(image: image)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.layoutMargins = UIEdgeInsets.init(top: 0, left: padding, bottom: 0, right: padding + resizableImageInsets.right)
            imageView.isHidden = true;
            self.productView.addSubview(imageView)

            imageView.leadingAnchor.constraint(equalTo:self.productView.leadingAnchor).isActive = true
            imageView.bottomAnchor.constraint(equalTo:self.productView.bottomAnchor, constant:(-1 * Geometry.defaultCornerRadius)).isActive = true
            
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
 
    }
    @objc func favoriteAction() {
        self.delegate.productCollectionViewCellDidTapFavorite(self)
    }
    
}
