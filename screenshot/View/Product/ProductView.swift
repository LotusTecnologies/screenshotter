//
//  ProductView.swift
//  screenshot
//
//  Created by Corey Werner on 2/27/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class ProductView: UIScrollView {
    let galleryScrollView = UIScrollView()
    let galleryScrollContentView = UIView()
    let pageControl = UIPageControl()
    
    let titleLabel = UILabel()
    let priceLabel = UILabel()
    let originalPriceLabel = UILabel()
    
    let selectionButton = SegmentedDropDownButton()
    let cartButton = MainButton()
    let buyButton = MainButton()
    let websiteButton = UIButton()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
        layoutMargins = UIEdgeInsets(top: .padding, left: .padding, bottom: .padding, right: .padding)
        keyboardDismissMode = .onDrag
        
        galleryScrollView.translatesAutoresizingMaskIntoConstraints = false
        galleryScrollView.scrollsToTop = false
        galleryScrollView.isPagingEnabled = true
        galleryScrollView.showsHorizontalScrollIndicator = false
        galleryScrollView.bounces = false
        addSubview(galleryScrollView)
        galleryScrollView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        galleryScrollView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        galleryScrollView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        galleryScrollView.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        galleryScrollView.heightAnchor.constraint(equalToConstant: 370).isActive = true
        
        galleryScrollContentView.translatesAutoresizingMaskIntoConstraints = false
        galleryScrollView.addSubview(galleryScrollContentView)
        galleryScrollContentView.topAnchor.constraint(equalTo: galleryScrollView.topAnchor).isActive = true
        galleryScrollContentView.leadingAnchor.constraint(equalTo: galleryScrollView.leadingAnchor).isActive = true
        galleryScrollContentView.bottomAnchor.constraint(equalTo: galleryScrollView.bottomAnchor).isActive = true
        galleryScrollContentView.trailingAnchor.constraint(equalTo: galleryScrollView.trailingAnchor).isActive = true
        galleryScrollContentView.heightAnchor.constraint(equalTo: galleryScrollView.heightAnchor).isActive = true
        
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.hidesForSinglePage = true
        pageControl.pageIndicatorTintColor = UIColor.black.withAlphaComponent(0.5)
        pageControl.currentPageIndicatorTintColor = .crazeGreen
        addSubview(pageControl)
        pageControl.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .padding).isActive = true
        pageControl.bottomAnchor.constraint(equalTo: galleryScrollView.bottomAnchor).isActive = true
        pageControl.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.padding).isActive = true
        pageControl.centerXAnchor.constraint(equalTo: galleryScrollView.centerXAnchor).isActive = true
        
        let labelContainerView = UIView()
        labelContainerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(labelContainerView)
        labelContainerView.topAnchor.constraint(equalTo: galleryScrollView.bottomAnchor, constant: .padding).isActive = true
        labelContainerView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        labelContainerView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        priceLabel.font = UIFont.preferredFont(forTextStyle: .title1)
        priceLabel.textColor = .gray3
        priceLabel.adjustsFontForContentSizeCategory = true
        labelContainerView.addSubview(priceLabel)
        priceLabel.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
        priceLabel.topAnchor.constraint(equalTo: labelContainerView.topAnchor).isActive = true
        priceLabel.trailingAnchor.constraint(equalTo: labelContainerView.trailingAnchor).isActive = true
        
        originalPriceLabel.translatesAutoresizingMaskIntoConstraints = false
        originalPriceLabel.font = UIFont.preferredFont(forTextStyle: .title2)
        originalPriceLabel.textColor = .gray7
        originalPriceLabel.adjustsFontForContentSizeCategory = true
        labelContainerView.addSubview(originalPriceLabel)
        originalPriceLabel.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
        originalPriceLabel.topAnchor.constraint(equalTo: priceLabel.bottomAnchor).isActive = true
        originalPriceLabel.bottomAnchor.constraint(lessThanOrEqualTo: labelContainerView.bottomAnchor).isActive = true
        originalPriceLabel.trailingAnchor.constraint(equalTo: labelContainerView.trailingAnchor).isActive = true
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.preferredFont(forTextStyle: .title2)
        titleLabel.textColor = .gray3
        titleLabel.numberOfLines = 0
        titleLabel.adjustsFontForContentSizeCategory = true
        labelContainerView.addSubview(titleLabel)
        titleLabel.setContentHuggingPriority(UILayoutPriorityDefaultLow, for: .horizontal)
        titleLabel.topAnchor.constraint(equalTo: labelContainerView.topAnchor).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: labelContainerView.leadingAnchor).isActive = true
        titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: labelContainerView.bottomAnchor).isActive = true
        titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: priceLabel.leadingAnchor, constant: -.padding).isActive = true
        titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: originalPriceLabel.leadingAnchor, constant: -.padding).isActive = true
        
        // TODO: how does UI look when all variants are out of stock
        selectionButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(selectionButton)
        selectionButton.topAnchor.constraint(equalTo: labelContainerView.bottomAnchor, constant: .padding).isActive = true
        selectionButton.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        selectionButton.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        selectionButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        cartButton.translatesAutoresizingMaskIntoConstraints = false
        cartButton.backgroundColor = .crazeGreen
        cartButton.setTitle("product.add".localized, for: .normal)
        cartButton.setTitleColor(.white, for: .normal)
        addSubview(cartButton)
        cartButton.topAnchor.constraint(equalTo: selectionButton.bottomAnchor, constant: .padding).isActive = true
        cartButton.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        cartButton.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        buyButton.translatesAutoresizingMaskIntoConstraints = false
        buyButton.backgroundColor = .crazeGreen
        buyButton.setTitle("product.buy".localized, for: .normal)
        buyButton.setTitleColor(.white, for: .normal)
        addSubview(buyButton)
        buyButton.topAnchor.constraint(equalTo: cartButton.bottomAnchor, constant: .padding).isActive = true
        buyButton.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        buyButton.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        websiteButton.translatesAutoresizingMaskIntoConstraints = false
        websiteButton.setTitleColor(.crazeGreen, for: .normal)
        websiteButton.isHidden = true
        addSubview(websiteButton)
        websiteButton.topAnchor.constraint(equalTo: buyButton.bottomAnchor, constant: .padding).isActive = true
        websiteButton.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        websiteButton.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        let contentTextView = UITextView()
        contentTextView.translatesAutoresizingMaskIntoConstraints = false
        contentTextView.backgroundColor = .green
        contentTextView.isScrollEnabled = false
        contentTextView.scrollsToTop = false
        addSubview(contentTextView)
        contentTextView.topAnchor.constraint(equalTo: websiteButton.bottomAnchor, constant: .padding).isActive = true
        contentTextView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        contentTextView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -.padding).isActive = true
        contentTextView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        contentTextView.heightAnchor.constraint(equalToConstant: 500).isActive = true
    }
    
    func setSelection(colorItem: SegmentedDropDownItem, sizeItem: SegmentedDropDownItem?) {
        var items: [SegmentedDropDownItem] = []
        let hasSizeItem = sizeItem != nil
        let widthRatio: CGFloat = hasSizeItem ? 0.4 : 0.8
        
        colorItem.placeholderTitle = "product.color.default".localized
        colorItem.widthRatio = widthRatio
        items.append(colorItem)
        
        if let sizeItem = sizeItem {
            sizeItem.placeholderTitle = "product.size.default".localized
            sizeItem.widthRatio = widthRatio
            items.append(sizeItem)
        }
        
        // TODO: keep this value synced with the CartViewController stepper.maxValue
        let quantityItem = SegmentedDropDownItem(pickerItems: (1...10).map { "\($0)" })
        items.append(quantityItem)
        
        selectionButton.items = items
    }
}
