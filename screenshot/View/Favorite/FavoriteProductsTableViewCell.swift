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
    let titleLabel = Label()
    let priceLabel = Label()
    let merchantLabel = Label()
    
    private var fontSizeStandardRangeConstraints: [NSLayoutConstraint] = []
    private var fontSizeAccessibilityRangeConstraints: [NSLayoutConstraint] = []
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        // TODO: move title and price into container view. remove labels guide
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.backgroundColor = .gray8
        titleLabel.numberOfLines = 0
        titleLabel.font = .screenshopFont(.hindLight, textStyle: .body)
        titleLabel.adjustsFontForContentSizeCategory = true
        contentView.addSubview(titleLabel)
        titleLabel.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor).isActive = true
        
        fontSizeAccessibilityRangeConstraints += [
            titleLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor)
        ]
        
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        priceLabel.backgroundColor = .gray8
        priceLabel.font = .screenshopFont(.hindMedium, textStyle: .body)
        priceLabel.adjustsFontForContentSizeCategory = true
        contentView.addSubview(priceLabel)
        priceLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        fontSizeStandardRangeConstraints += [
            priceLabel.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            priceLabel.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: .padding)
        ]
        fontSizeAccessibilityRangeConstraints += [
            priceLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: .padding)
        ]
        
        productImageView.translatesAutoresizingMaskIntoConstraints = false
        productImageView.contentMode = .scaleAspectFill
        productImageView.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -.padding)
        contentView.addSubview(productImageView)
        productImageView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        productImageView.widthAnchor.constraint(equalToConstant: 130).isActive = true
        productImageView.heightAnchor.constraint(equalTo: productImageView.widthAnchor).isActive = true
        
        fontSizeStandardRangeConstraints += [
            productImageView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            productImageView.trailingAnchor.constraint(equalTo: titleLabel.leadingAnchor, constant: productImageView.layoutMargins.right)
        ]
        fontSizeAccessibilityRangeConstraints += [
            productImageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: .padding)
        ]
        
        merchantLabel.translatesAutoresizingMaskIntoConstraints = false
        merchantLabel.font = .screenshopFont(.hindLight, size: 15)
        merchantLabel.adjustsFontSizeToFitWidth = true
        merchantLabel.minimumScaleFactor = 0.7
        merchantLabel.textAlignment = .center
        contentView.addSubview(merchantLabel)
        merchantLabel.topAnchor.constraint(equalTo: productImageView.bottomAnchor, constant: 10).isActive = true
        merchantLabel.leadingAnchor.constraint(equalTo: productImageView.leadingAnchor).isActive = true
        merchantLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.layoutMarginsGuide.bottomAnchor).isActive = true
        merchantLabel.trailingAnchor.constraint(equalTo: productImageView.trailingAnchor).isActive = true
        
        let labelsBottomGuide = UIView()
        labelsBottomGuide.translatesAutoresizingMaskIntoConstraints = false
        labelsBottomGuide.isHidden = true
        contentView.addSubview(labelsBottomGuide)
        labelsBottomGuide.topAnchor.constraint(greaterThanOrEqualTo: titleLabel.bottomAnchor).isActive = true
        labelsBottomGuide.topAnchor.constraint(greaterThanOrEqualTo: priceLabel.bottomAnchor).isActive = true
        labelsBottomGuide.heightAnchor.constraint(equalToConstant: 0).isActive = true
        
        // TODO: use vertical content inset instead of constraint constant
        let priceAlertButton = UIButton()
        priceAlertButton.backgroundColor = .gray8
        priceAlertButton.translatesAutoresizingMaskIntoConstraints = false
        priceAlertButton.setTitle("GET PRICE ALERTS", for: .normal)
        priceAlertButton.setTitle("PRICE ALERTS ON", for: .selected)
        priceAlertButton.setTitleColor(.gray3, for: .normal)
        priceAlertButton.setTitleColor(.crazeRed, for: .selected)
        priceAlertButton.titleLabel?.font = .screenshopFont(.hindSemibold, size: 12)
        priceAlertButton.contentHorizontalAlignment = {
            if #available(iOS 11.0, *) {
                return .leading
            }
            else {
                return .left
            }
        }()
        contentView.addSubview(priceAlertButton)
        priceAlertButton.topAnchor.constraint(equalTo: labelsBottomGuide.bottomAnchor, constant: 0).isActive = true
        priceAlertButton.leadingAnchor.constraint(equalTo: productImageView.layoutMarginsGuide.trailingAnchor).isActive = true
        priceAlertButton.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        let cartButton = MainButton() // TODO: change to BorderButton
        cartButton.translatesAutoresizingMaskIntoConstraints = false
        cartButton.setTitle("Add to Cart", for: .normal)
        cartButton.setTitleColor(.crazeGreen, for: .normal)
        contentView.addSubview(cartButton)
        cartButton.topAnchor.constraint(equalTo: priceAlertButton.bottomAnchor, constant: .padding).isActive = true
        cartButton.leadingAnchor.constraint(equalTo: productImageView.layoutMarginsGuide.trailingAnchor).isActive = true
        cartButton.bottomAnchor.constraint(lessThanOrEqualTo: contentView.layoutMarginsGuide.bottomAnchor).isActive = true
        cartButton.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        NSLayoutConstraint.activate(fontSizeStandardRangeConstraints)
    }
}
