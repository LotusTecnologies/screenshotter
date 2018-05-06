//
//  CartTableViewCell.swift
//  screenshot
//
//  Created by Corey Werner on 2/19/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class CartTableViewCell: UITableViewCell, DynamicTypeAccessibilityLayout {
    let productImageView = EmbossedView()
    let titleLabel = UILabel()
    let priceLabel = UILabel()
    let removeButton = BorderButton()
    let quantityStepper = UIStepper()
    fileprivate let errorLabel = UILabel()
    fileprivate var quantityValueLabel: UILabel?
    fileprivate var colorValueLabel: UILabel?
    fileprivate var sizeValueLabel: UILabel?
    
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
        
        let mainView = UIView()
        mainView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(mainView)
        mainView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor).isActive = true
        mainView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        mainView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        let imageViewWidth: CGFloat = 90
        
        productImageView.translatesAutoresizingMaskIntoConstraints = false
        productImageView.contentMode = .scaleAspectFit
        mainView.addSubview(productImageView)
        productImageView.leadingAnchor.constraint(equalTo: mainView.leadingAnchor).isActive = true
        productImageView.bottomAnchor.constraint(lessThanOrEqualTo: mainView.bottomAnchor).isActive = true
        productImageView.widthAnchor.constraint(equalToConstant: imageViewWidth).isActive = true
        productImageView.heightAnchor.constraint(equalTo: productImageView.widthAnchor).isActive = true
        
        fontSizeStandardRangeConstraints += [
            productImageView.topAnchor.constraint(equalTo: mainView.topAnchor)
        ]
        fontSizeAccessibilityRangeConstraints += [
            productImageView.topAnchor.constraint(equalTo: priceLabel.bottomAnchor)
        ]
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = .gray3
        titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 0
        mainView.addSubview(titleLabel)
        titleLabel.setContentHuggingPriority(UILayoutPriority.required, for: .vertical)
        titleLabel.topAnchor.constraint(equalTo: mainView.topAnchor).isActive = true
        
        fontSizeStandardRangeConstraints += [
            titleLabel.leadingAnchor.constraint(equalTo: productImageView.trailingAnchor, constant: .padding)
        ]
        fontSizeAccessibilityRangeConstraints += [
            titleLabel.leadingAnchor.constraint(equalTo: mainView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: mainView.trailingAnchor)
        ]
        
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        priceLabel.textColor = .gray3
        priceLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        priceLabel.minimumScaleFactor = 0.2
        priceLabel.baselineAdjustment = .alignCenters
        priceLabel.adjustsFontSizeToFitWidth = true
        priceLabel.adjustsFontForContentSizeCategory = true
        mainView.addSubview(priceLabel)
        priceLabel.setContentCompressionResistancePriority(UILayoutPriority.required, for: .horizontal)
        
        fontSizeStandardRangeConstraints += [
            priceLabel.topAnchor.constraint(equalTo: mainView.topAnchor),
            priceLabel.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: .padding),
            priceLabel.trailingAnchor.constraint(equalTo: mainView.trailingAnchor)
        ]
        fontSizeAccessibilityRangeConstraints += [
            priceLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),
            priceLabel.leadingAnchor.constraint(equalTo: mainView.leadingAnchor),
            priceLabel.trailingAnchor.constraint(equalTo: productImageView.trailingAnchor)
        ]
        
        let variantDataContainerView = UIView()
        variantDataContainerView.translatesAutoresizingMaskIntoConstraints = false
        mainView.addSubview(variantDataContainerView)
        variantDataContainerView.leadingAnchor.constraint(equalTo: productImageView.trailingAnchor, constant: .padding).isActive = true
        variantDataContainerView.bottomAnchor.constraint(equalTo: mainView.bottomAnchor).isActive = true
        variantDataContainerView.trailingAnchor.constraint(equalTo: mainView.trailingAnchor).isActive = true
        
        fontSizeStandardRangeConstraints += [
            variantDataContainerView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: .padding)
        ]
        fontSizeAccessibilityRangeConstraints += [
            variantDataContainerView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor)
        ]
        
        let variantDataPositionGuide = UIView()
        variantDataPositionGuide.translatesAutoresizingMaskIntoConstraints = false
        variantDataPositionGuide.isHidden = true
        mainView.addSubview(variantDataPositionGuide)
        variantDataPositionGuide.topAnchor.constraint(greaterThanOrEqualTo: variantDataContainerView.topAnchor).isActive = true
        variantDataPositionGuide.leadingAnchor.constraint(equalTo: variantDataContainerView.leadingAnchor).isActive = true
        variantDataPositionGuide.bottomAnchor.constraint(lessThanOrEqualTo: variantDataContainerView.bottomAnchor).isActive = true
        variantDataPositionGuide.trailingAnchor.constraint(equalTo: variantDataContainerView.trailingAnchor).isActive = true
        variantDataPositionGuide.centerYAnchor.constraint(equalTo: variantDataContainerView.centerYAnchor).isActive = true
        
        let variantDataVerticalGuide = UIView()
        variantDataVerticalGuide.translatesAutoresizingMaskIntoConstraints = false
        variantDataVerticalGuide.isHidden = true
        mainView.addSubview(variantDataVerticalGuide)
        variantDataVerticalGuide.widthAnchor.constraint(equalToConstant: .padding).isActive = true
        
        func createTitleLabel() -> UILabel {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.textColor = .gray3
            label.font = UIFont.preferredFont(forTextStyle: .body)
            label.minimumScaleFactor = 0.2
            label.baselineAdjustment = .alignCenters
            label.adjustsFontSizeToFitWidth = true
            label.adjustsFontForContentSizeCategory = true
            variantDataContainerView.addSubview(label)
            label.setContentHuggingPriority(UILayoutPriority.defaultHigh, for: .horizontal)
            label.setContentCompressionResistancePriority(UILayoutPriority.required, for: .horizontal)
            label.widthAnchor.constraint(lessThanOrEqualTo: variantDataPositionGuide.widthAnchor, multiplier: 0.4).isActive = true
            let heightConstraint = label.heightAnchor.constraint(greaterThanOrEqualToConstant: quantityStepper.intrinsicContentSize.height)
            heightConstraint.priority = UILayoutPriority.defaultHigh
            heightConstraint.isActive = true
            return label
        }
        
        func createValueLabel(titleLabel: UILabel) -> UILabel {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.textColor = .gray6
            label.font = UIFont.preferredFont(forTextStyle: .body)
            label.minimumScaleFactor = 0.2
            label.baselineAdjustment = .alignCenters
            label.adjustsFontSizeToFitWidth = true
            label.adjustsFontForContentSizeCategory = true
            variantDataContainerView.addSubview(label)
            label.topAnchor.constraint(equalTo: titleLabel.topAnchor).isActive = true
            label.bottomAnchor.constraint(equalTo: titleLabel.bottomAnchor).isActive = true
            return label
        }
        
        let quantityTitleLabel = createTitleLabel()
        quantityTitleLabel.text = "cart.variant.quantity".localized
        quantityTitleLabel.topAnchor.constraint(equalTo: variantDataPositionGuide.topAnchor).isActive = true
        quantityTitleLabel.leadingAnchor.constraint(equalTo: variantDataPositionGuide.leadingAnchor).isActive = true
        quantityTitleLabel.trailingAnchor.constraint(equalTo: variantDataVerticalGuide.leadingAnchor).isActive = true
        
        let quantityValueLabel = createValueLabel(titleLabel: quantityTitleLabel)
        quantityValueLabel.leadingAnchor.constraint(equalTo: variantDataVerticalGuide.trailingAnchor).isActive = true
        self.quantityValueLabel = quantityValueLabel
        
        quantityStepper.translatesAutoresizingMaskIntoConstraints = false
        quantityStepper.minimumValue = 1
        quantityStepper.maximumValue = Double(Constants.cartItemMaxQuantity)
        quantityStepper.autorepeat = false
        quantityStepper.tintColor = .crazeGreen
        variantDataContainerView.addSubview(quantityStepper)
        quantityStepper.leadingAnchor.constraint(equalTo: quantityValueLabel.trailingAnchor).isActive = true
        quantityStepper.trailingAnchor.constraint(equalTo: variantDataPositionGuide.trailingAnchor).isActive = true
        quantityStepper.centerYAnchor.constraint(equalTo: quantityTitleLabel.centerYAnchor).isActive = true
        
        let colorTitleLabel = createTitleLabel()
        colorTitleLabel.text = "cart.variant.color".localized
        colorTitleLabel.topAnchor.constraint(equalTo: quantityTitleLabel.bottomAnchor).isActive = true
        colorTitleLabel.leadingAnchor.constraint(equalTo: variantDataPositionGuide.leadingAnchor).isActive = true
        colorTitleLabel.trailingAnchor.constraint(equalTo: variantDataVerticalGuide.leadingAnchor).isActive = true
        hideColorLabelConstraint = colorTitleLabel.heightAnchor.constraint(equalToConstant: 0)
        hideColorLabelConstraint?.isActive = true
        
        let colorValueLabel = createValueLabel(titleLabel: colorTitleLabel)
        colorValueLabel.leadingAnchor.constraint(equalTo: variantDataVerticalGuide.trailingAnchor).isActive = true
        colorValueLabel.trailingAnchor.constraint(equalTo: variantDataPositionGuide.trailingAnchor).isActive = true
        self.colorValueLabel = colorValueLabel
        
        let sizeTitleLabel = createTitleLabel()
        sizeTitleLabel.text = "cart.variant.size".localized
        sizeTitleLabel.topAnchor.constraint(equalTo: colorTitleLabel.bottomAnchor).isActive = true
        sizeTitleLabel.leadingAnchor.constraint(equalTo: variantDataPositionGuide.leadingAnchor).isActive = true
        sizeTitleLabel.bottomAnchor.constraint(equalTo: variantDataPositionGuide.bottomAnchor).isActive = true
        sizeTitleLabel.trailingAnchor.constraint(equalTo: variantDataVerticalGuide.leadingAnchor).isActive = true
        hideSizeLabelConstraint = sizeTitleLabel.heightAnchor.constraint(equalToConstant: 0)
        hideSizeLabelConstraint?.isActive = true
        
        let sizeValueLabel = createValueLabel(titleLabel: sizeTitleLabel)
        sizeValueLabel.leadingAnchor.constraint(equalTo: variantDataVerticalGuide.trailingAnchor).isActive = true
        sizeValueLabel.trailingAnchor.constraint(equalTo: variantDataPositionGuide.trailingAnchor).isActive = true
        self.sizeValueLabel = sizeValueLabel
        
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.textAlignment = .center
        errorLabel.textColor = .crazeRed
        errorLabel.numberOfLines = 0
        errorLabel.font = {
            var font = UIFont.preferredFont(forTextStyle: .footnote)
            
            if let descriptor = font.fontDescriptor.withSymbolicTraits(.traitBold) {
                font = UIFont(descriptor: descriptor, size: 0)
            }
            
            return font
        }()
        errorLabel.adjustsFontForContentSizeCategory = true
        mainView.addSubview(errorLabel)
        errorLabel.layoutMarginsGuide.topAnchor.constraint(equalTo: mainView.bottomAnchor).isActive = true
        errorLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        errorLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        let actionView = UIView()
        actionView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(actionView)
        actionView.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: .padding).isActive = true
        actionView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        actionView.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor).isActive = true
        actionView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        removeButton.translatesAutoresizingMaskIntoConstraints = false
        removeButton.setTitle("cart.remove".localized, for: .normal)
        removeButton.setTitleColor(.gray6, for: .normal)
        removeButton.setTitleColor(.crazeRed, for: .selected)
        removeButton.setTitleColor(.crazeRed, for: [.selected, .highlighted])
        actionView.addSubview(removeButton)
        removeButton.topAnchor.constraint(equalTo: actionView.topAnchor).isActive = true
        removeButton.leadingAnchor.constraint(greaterThanOrEqualTo: actionView.leadingAnchor).isActive = true
        removeButton.bottomAnchor.constraint(equalTo: actionView.bottomAnchor).isActive = true
        removeButton.trailingAnchor.constraint(lessThanOrEqualTo: actionView.trailingAnchor).isActive = true
        removeButton.centerXAnchor.constraint(equalTo: actionView.centerXAnchor).isActive = true
        removeButton.widthAnchor.constraint(greaterThanOrEqualTo: actionView.widthAnchor, multiplier: 0.5).isActive = true
        
        adjustDynamicTypeLayout(traitCollection: traitCollection)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        adjustDynamicTypeLayout(traitCollection: traitCollection, previousTraitCollection: previousTraitCollection)
    }
    
    // MARK: Variant Data
    
    private var hideQuantityLabelConstraint: NSLayoutConstraint?
    private var hideColorLabelConstraint: NSLayoutConstraint?
    private var hideSizeLabelConstraint: NSLayoutConstraint?
    
    var quantity: Double = 1.0 {
        didSet {
            quantityStepper.value = quantity
            quantityValueLabel?.text = "\(Int(quantity))"
        }
    }
    
    var color: String? {
        didSet {
            if let color = color, !color.isEmpty {
                colorValueLabel?.text = color
                hideColorLabelConstraint?.isActive = false
            }
            else {
                colorValueLabel?.text = nil
                hideColorLabelConstraint?.isActive = true
            }
        }
    }
    
    var size: String? {
        didSet {
            if let size = size, !size.isEmpty {
                sizeValueLabel?.text = size
                hideSizeLabelConstraint?.isActive = false
            }
            else {
                sizeValueLabel?.text = nil
                hideSizeLabelConstraint?.isActive = true
            }
        }
    }
    
    // MARK: Error
    
    var errorMask: CartItem.ErrorMaskOptions = .none {
        didSet {
            removeButton.isSelected = false
            priceLabel.textColor = .gray3
            quantityStepper.isEnabled = true
            quantityStepper.tintColor = .crazeGreen
            
            var layoutMargins = errorLabel.layoutMargins
            layoutMargins.top = -.padding
            
            if errorMask == .none {
                errorLabel.text = nil
                layoutMargins.top = 0
            }
            else if errorMask.contains(.unavailable) {
                errorLabel.text = "cart.item.error.unavailable".localized
                removeButton.isSelected = true
                quantityStepper.isEnabled = false
                quantityStepper.tintColor = .gray8
            }
            else {
                var texts: [String] = []
                
                if errorMask.contains(.price) {
                    texts.append("cart.item.error.price".localized)
                    priceLabel.textColor = .crazeRed
                }
                if errorMask.contains(.quantity) {
                    texts.append("cart.item.error.quantity".localized)
                    quantityStepper.tintColor = .crazeRed
                }
                
                errorLabel.text = texts.joined(separator: "; ")
            }
            
            errorLabel.layoutMargins = layoutMargins
        }
    }
}
