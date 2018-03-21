//
//  FavoriteProductsTableViewCell.swift
//  screenshot
//
//  Created by Corey Werner on 3/19/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class FavoriteProductsTableViewCell: UITableViewCell {
    let productImageView = EmbossedView()
    let productControl = UIControl()
    let favoriteControl = FavoriteControl()
    let titleLabel = UILabel()
    let priceLabel = UILabel()
    let merchantLabel = UILabel()
    let priceAlertButton = UIButton()
    let cartButton = BorderButton()
    
    private var fontSizeStandardRangeConstraints: [NSLayoutConstraint] = []
    private var fontSizeAccessibilityRangeConstraints: [NSLayoutConstraint] = []
    
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
        titleLabel.numberOfLines = 0
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
        
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        priceLabel.textColor = .crazeGreen
        priceLabel.font = .screenshopFont(.hindMedium, textStyle: .body)
        priceLabel.adjustsFontForContentSizeCategory = true
        labelsContainerView.addSubview(priceLabel)
        priceLabel.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
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
        productImageView.contentMode = .scaleAspectFill
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
        
        productControl.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(productControl)
        productControl.topAnchor.constraint(equalTo: productImageView.topAnchor).isActive = true
        productControl.leadingAnchor.constraint(equalTo: productImageView.leadingAnchor).isActive = true
        productControl.bottomAnchor.constraint(equalTo: productImageView.bottomAnchor).isActive = true
        productControl.trailingAnchor.constraint(equalTo: productImageView.trailingAnchor).isActive = true
        
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
        merchantLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.layoutMarginsGuide.bottomAnchor).isActive = true
        merchantLabel.trailingAnchor.constraint(equalTo: productImageView.trailingAnchor).isActive = true
        
        let priceAlertImage = UIImage(named: "FavoriteBell")
        let priceAlertTintImage = priceAlertImage?.withRenderingMode(.alwaysTemplate)
        
        priceAlertButton.translatesAutoresizingMaskIntoConstraints = false
        priceAlertButton.setImage(priceAlertImage, for: .normal)
        priceAlertButton.setImage(priceAlertTintImage, for: .selected)
        priceAlertButton.setImage(priceAlertTintImage, for: [.selected, .highlighted])
        priceAlertButton.setTitle("favorites.product.price_alert_off".localized, for: .normal)
        priceAlertButton.setTitle("favorites.product.price_alert_on".localized, for: .selected)
        priceAlertButton.setTitle("favorites.product.price_alert_on".localized, for: [.selected, .highlighted])
        priceAlertButton.setTitleColor(.gray3, for: .normal)
        priceAlertButton.setTitleColor(.crazeRed, for: .selected)
        priceAlertButton.setTitleColor(.crazeRed, for: [.selected, .highlighted])
        priceAlertButton.titleLabel?.font = .screenshopFont(.hindSemibold, size: 12)
        priceAlertButton.tintColor = .crazeRed
        priceAlertButton.contentEdgeInsets = UIEdgeInsets(top: halfPadding, left: 0, bottom: halfPadding, right: 0)
        priceAlertButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
        priceAlertButton.contentHorizontalAlignment = {
            if #available(iOS 11.0, *) {
                return .leading
            }
            else {
                return .left
            }
        }()
        priceAlertButton.addTarget(self, action: #selector(priceAlertAction(_:)), for: .touchUpInside)
        contentView.addSubview(priceAlertButton)
        priceAlertButton.topAnchor.constraint(equalTo: labelsContainerView.bottomAnchor, constant: halfPadding).isActive = true
        priceAlertButton.leadingAnchor.constraint(equalTo: productImageView.layoutMarginsGuide.trailingAnchor).isActive = true
        priceAlertButton.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        cartButton.translatesAutoresizingMaskIntoConstraints = false
        cartButton.setTitle("favorites.product.cart".localized, for: .normal)
        cartButton.setTitleColor(.crazeGreen, for: .normal)
        contentView.addSubview(cartButton)
        cartButton.topAnchor.constraint(equalTo: priceAlertButton.bottomAnchor, constant: halfPadding).isActive = true
        cartButton.leadingAnchor.constraint(equalTo: productImageView.layoutMarginsGuide.trailingAnchor).isActive = true
        cartButton.bottomAnchor.constraint(lessThanOrEqualTo: contentView.layoutMarginsGuide.bottomAnchor).isActive = true
        cartButton.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        NSLayoutConstraint.activate(fontSizeStandardRangeConstraints)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        guard let previousContentSizeCategory = previousTraitCollection?.preferredContentSizeCategory else {
            return
        }
        
        let isAccessibilityCategory = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        
        if previousContentSizeCategory.isAccessibilityCategory != isAccessibilityCategory {
            if isAccessibilityCategory {
                NSLayoutConstraint.deactivate(fontSizeStandardRangeConstraints)
                NSLayoutConstraint.activate(fontSizeAccessibilityRangeConstraints)
            }
            else {
                NSLayoutConstraint.deactivate(fontSizeAccessibilityRangeConstraints)
                NSLayoutConstraint.activate(fontSizeStandardRangeConstraints)
            }
        }
    }
    
    // MARK: Price Alert
    
    @objc fileprivate func priceAlertAction(_ button: UIButton) {
        button.isSelected = !button.isSelected
    }
}
