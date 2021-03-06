//
//  FavoriteProductsTableViewCell.swift
//  screenshot
//
//  Created by Corey Werner on 3/19/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import UIKit

class FavoriteProductsTableViewCell: UITableViewCell, DynamicTypeAccessibilityLayout {
    let productImageView = EmbossedView()
    let favoriteControl = FavoriteControl()
    let titleLabel = UILabel()
    let priceLabel = UILabel()

    let merchantLabel = UILabel()
    let shareButton = UIButton()
    let buyButton = BorderButton()
    
    var fontSizeStandardRangeConstraints: [NSLayoutConstraint] = []
    var fontSizeAccessibilityRangeConstraints: [NSLayoutConstraint] = []
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        var layoutMargins = contentView.layoutMargins
        layoutMargins.top = .padding
        layoutMargins.bottom = .padding
        contentView.layoutMargins = layoutMargins
        
        let halfPadding: CGFloat = .padding / 2
        
        let labelsContainerView = UIView()
        labelsContainerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(labelsContainerView)
        labelsContainerView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor).isActive = true
        labelsContainerView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        labelsContainerView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .screenshopFont(.hindLight, textStyle: .body)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: -halfPadding, right: 0)
        labelsContainerView.addSubview(titleLabel)
        titleLabel.topAnchor.constraint(equalTo: labelsContainerView.topAnchor).isActive = true
        
        fontSizeStandardRangeConstraints += [
            titleLabel.bottomAnchor.constraint(equalTo: labelsContainerView.bottomAnchor)
        ]
        fontSizeAccessibilityRangeConstraints += [
            titleLabel.leadingAnchor.constraint(equalTo: labelsContainerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: labelsContainerView.trailingAnchor)
        ]
        
        titleLabel.numberOfLines =  3
        
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        priceLabel.textColor = .crazeGreen
        priceLabel.font = .screenshopFont(.hindMedium, textStyle: .body)
        priceLabel.adjustsFontForContentSizeCategory = true
        labelsContainerView.addSubview(priceLabel)
        priceLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        priceLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        priceLabel.trailingAnchor.constraint(equalTo: labelsContainerView.trailingAnchor).isActive = true
        
        fontSizeStandardRangeConstraints += [
            priceLabel.topAnchor.constraint(equalTo: labelsContainerView.topAnchor),
            priceLabel.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: .padding)
        ]
        fontSizeAccessibilityRangeConstraints += [
            priceLabel.topAnchor.constraint(equalTo: titleLabel.layoutMarginsGuide.bottomAnchor),
            priceLabel.bottomAnchor.constraint(equalTo: labelsContainerView.bottomAnchor)
        ]
        
        productImageView.translatesAutoresizingMaskIntoConstraints = false
        productImageView.contentMode = .scaleAspectFit
        productImageView.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -.padding)
        contentView.addSubview(productImageView)
        productImageView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        productImageView.widthAnchor.constraint(equalToConstant: 120).isActive = true
        productImageView.heightAnchor.constraint(equalTo: productImageView.widthAnchor).isActive = true
        
        fontSizeStandardRangeConstraints += [
            productImageView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            productImageView.trailingAnchor.constraint(equalTo: titleLabel.leadingAnchor, constant: productImageView.layoutMargins.right)
        ]
        fontSizeAccessibilityRangeConstraints += [
            productImageView.topAnchor.constraint(equalTo: titleLabel.layoutMarginsGuide.bottomAnchor)
        ]
        
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
        
        buyButton.translatesAutoresizingMaskIntoConstraints = false
        buyButton.setTitle("product.buy_now".localized, for: .normal)
        buyButton.setTitleColor(.crazeGreen, for: .normal)
        contentView.addSubview(buyButton)
        buyButton.leadingAnchor.constraint(equalTo: productImageView.layoutMarginsGuide.trailingAnchor).isActive = true
        buyButton.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor).isActive = true
        buyButton.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        let shareVerticalGuide = UILayoutGuide()
        contentView.addLayoutGuide(shareVerticalGuide)
        shareVerticalGuide.topAnchor.constraint(equalTo: priceLabel.bottomAnchor).isActive = true
        shareVerticalGuide.bottomAnchor.constraint(equalTo: buyButton.topAnchor).isActive = true
        
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        shareButton.setImage(UIImage(named: "ScreenshotShare"), for: .normal)
        shareButton.contentEdgeInsets = .init(top: 10, left: contentView.layoutMargins.right, bottom: 10, right: contentView.layoutMargins.right)
        contentView.addSubview(shareButton)
        shareButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        shareButton.centerYAnchor.constraint(equalTo: shareVerticalGuide.centerYAnchor).isActive = true
        
        adjustDynamicTypeLayout(traitCollection: traitCollection)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        adjustDynamicTypeLayout(traitCollection: traitCollection, previousTraitCollection: previousTraitCollection)
    }
    
    
   
}
