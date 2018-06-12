//
//  ProductHeaderCollectionViewCell.swift
//  screenshot
//
//  Created by Jonathan Rose on 6/7/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import UIKit

class ProductHeaderCollectionViewCell: UICollectionViewCell {
    
    let productImageView = EmbossedView()
    let favoriteControl = FavoriteControl()
    
    let titleLabel = UILabel()
    let priceLabel = UILabel()
    let buyNowButton = BorderButton()
    let merchantLabel = UILabel()
    let shareButton = UIButton()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews(){
        let shadowInsets = ScreenshotCollectionViewCell.shadowInsets
        let horPadding: CGFloat = .padding - shadowInsets.left - shadowInsets.right
        
        contentView.backgroundColor = .white
        contentView.layoutMargins = UIEdgeInsets(top: .padding, left: horPadding, bottom: .padding, right: horPadding)
        
        let halfPadding: CGFloat = .padding / 2
        
        let labelsContainerView = UIView()
        labelsContainerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(labelsContainerView)
        labelsContainerView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor).isActive = true
        labelsContainerView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        labelsContainerView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.numberOfLines = 3
        titleLabel.font = .screenshopFont(.hindLight, textStyle: .body, staticSize: true)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: -halfPadding, right: 0)
        labelsContainerView.addSubview(titleLabel)
        titleLabel.topAnchor.constraint(equalTo: labelsContainerView.topAnchor).isActive = true
        
        titleLabel.bottomAnchor.constraint(equalTo: labelsContainerView.bottomAnchor).isActive = true
        
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        priceLabel.textColor = .crazeGreen
        priceLabel.font = .screenshopFont(.hindMedium, textStyle: .body, staticSize: true)
        priceLabel.adjustsFontForContentSizeCategory = true
        labelsContainerView.addSubview(priceLabel)
        priceLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        priceLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        priceLabel.trailingAnchor.constraint(equalTo: labelsContainerView.trailingAnchor).isActive = true
        
        priceLabel.topAnchor.constraint(equalTo: labelsContainerView.topAnchor).isActive = true
        priceLabel.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: .padding).isActive = true
        
        
        productImageView.translatesAutoresizingMaskIntoConstraints = false
        productImageView.contentMode = .scaleAspectFit
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
        
        buyNowButton.translatesAutoresizingMaskIntoConstraints = false
        buyNowButton.setTitle("product.buy_now".localized, for: .normal)
        buyNowButton.setTitleColor(.crazeGreen, for: .normal)
        contentView.addSubview(buyNowButton)
        buyNowButton.leadingAnchor.constraint(equalTo: productImageView.layoutMarginsGuide.trailingAnchor).isActive = true
        buyNowButton.bottomAnchor.constraint(lessThanOrEqualTo: contentView.layoutMarginsGuide.bottomAnchor).isActive = true
        buyNowButton.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        buyNowButton.topAnchor.constraint(equalTo: labelsContainerView.bottomAnchor, constant: halfPadding).isActive = true
        
        contentView.addSubview(BorderView(edge: .bottom))
    }
}
