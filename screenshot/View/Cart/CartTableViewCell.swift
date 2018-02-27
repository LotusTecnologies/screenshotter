//
//  CartTableViewCell.swift
//  screenshot
//
//  Created by Corey Werner on 2/19/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class CartTableViewCell: UITableViewCell {
    let productImageView = UIImageView()
    let titleLabel = UILabel()
    let priceLabel = UILabel()
    let removeButton = UIButton()
    fileprivate let quantityStepper = UIStepper()
    fileprivate var quantityValueLabel: UILabel?
    fileprivate var colorValueLabel: UILabel?
    fileprivate var sizeValueLabel: UILabel?
    
    private var fontSizeStandardRangeConstraints: [NSLayoutConstraint] = []
    private var fontSizeAccessibilityRangeConstraints: [NSLayoutConstraint] = []
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
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
        titleLabel.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
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
        priceLabel.adjustsFontSizeToFitWidth = true
        priceLabel.adjustsFontForContentSizeCategory = true
        mainView.addSubview(priceLabel)
        priceLabel.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
        
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
        variantDataContainerView.isHidden = true
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
        
        let variantDataPositionView = UIView()
        variantDataPositionView.translatesAutoresizingMaskIntoConstraints = false
        variantDataPositionView.isHidden = true
        mainView.addSubview(variantDataPositionView)
        variantDataPositionView.topAnchor.constraint(greaterThanOrEqualTo: variantDataContainerView.topAnchor).isActive = true
        variantDataPositionView.leadingAnchor.constraint(equalTo: variantDataContainerView.leadingAnchor).isActive = true
        variantDataPositionView.bottomAnchor.constraint(lessThanOrEqualTo: variantDataContainerView.bottomAnchor).isActive = true
        variantDataPositionView.trailingAnchor.constraint(equalTo: variantDataContainerView.trailingAnchor).isActive = true
        variantDataPositionView.centerYAnchor.constraint(equalTo: variantDataContainerView.centerYAnchor).isActive = true
        
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
            label.adjustsFontSizeToFitWidth = true
            label.adjustsFontForContentSizeCategory = true
            mainView.addSubview(label)
            label.setContentHuggingPriority(UILayoutPriorityDefaultHigh, for: .horizontal)
            label.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
            label.widthAnchor.constraint(lessThanOrEqualTo: variantDataPositionView.widthAnchor, multiplier: 0.4).isActive = true
            let heightConstraint = label.heightAnchor.constraint(greaterThanOrEqualToConstant: quantityStepper.intrinsicContentSize.height)
            heightConstraint.priority = UILayoutPriorityDefaultHigh
            heightConstraint.isActive = true
            return label
        }
        
        func createValueLabel(titleLabel: UILabel) -> UILabel {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.textColor = .gray6
            label.font = UIFont.preferredFont(forTextStyle: .body)
            label.minimumScaleFactor = 0.2
            label.adjustsFontSizeToFitWidth = true
            label.adjustsFontForContentSizeCategory = true
            mainView.addSubview(label)
            label.topAnchor.constraint(equalTo: titleLabel.topAnchor).isActive = true
            label.bottomAnchor.constraint(equalTo: titleLabel.bottomAnchor).isActive = true
            return label
        }
        
        let quantityTitleLabel = createTitleLabel()
        quantityTitleLabel.text = "Quantity:"
        quantityTitleLabel.topAnchor.constraint(equalTo: variantDataPositionView.topAnchor).isActive = true
        quantityTitleLabel.leadingAnchor.constraint(equalTo: variantDataPositionView.leadingAnchor).isActive = true
        quantityTitleLabel.trailingAnchor.constraint(equalTo: variantDataVerticalGuide.leadingAnchor).isActive = true
        
        let quantityValueLabel = createValueLabel(titleLabel: quantityTitleLabel)
        quantityValueLabel.leadingAnchor.constraint(equalTo: variantDataVerticalGuide.trailingAnchor).isActive = true
        self.quantityValueLabel = quantityValueLabel
        
        quantityStepper.translatesAutoresizingMaskIntoConstraints = false
        quantityStepper.minimumValue = 1
        quantityStepper.tintColor = .crazeGreen
        quantityStepper.addTarget(self, action: #selector(quantityChanged(_:)), for: .valueChanged)
        mainView.addSubview(quantityStepper)
        quantityStepper.leadingAnchor.constraint(equalTo: quantityValueLabel.trailingAnchor).isActive = true
        quantityStepper.trailingAnchor.constraint(equalTo: variantDataPositionView.trailingAnchor).isActive = true
        quantityStepper.centerYAnchor.constraint(equalTo: quantityTitleLabel.centerYAnchor).isActive = true
        
        let colorTitleLabel = createTitleLabel()
        colorTitleLabel.text = "Color:"
        colorTitleLabel.topAnchor.constraint(equalTo: quantityTitleLabel.bottomAnchor).isActive = true
        colorTitleLabel.leadingAnchor.constraint(equalTo: variantDataPositionView.leadingAnchor).isActive = true
        colorTitleLabel.trailingAnchor.constraint(equalTo: variantDataVerticalGuide.leadingAnchor).isActive = true
        hideColorLabelConstraint = colorTitleLabel.heightAnchor.constraint(equalToConstant: 0)
        hideColorLabelConstraint?.isActive = true
        
        let colorValueLabel = createValueLabel(titleLabel: colorTitleLabel)
        colorValueLabel.leadingAnchor.constraint(equalTo: variantDataVerticalGuide.trailingAnchor).isActive = true
        colorValueLabel.trailingAnchor.constraint(equalTo: variantDataPositionView.trailingAnchor).isActive = true
        self.colorValueLabel = colorValueLabel
        
        let sizeTitleLabel = createTitleLabel()
        sizeTitleLabel.text = "Size:"
        sizeTitleLabel.topAnchor.constraint(equalTo: colorTitleLabel.bottomAnchor).isActive = true
        sizeTitleLabel.leadingAnchor.constraint(equalTo: variantDataPositionView.leadingAnchor).isActive = true
        sizeTitleLabel.bottomAnchor.constraint(equalTo: variantDataPositionView.bottomAnchor).isActive = true
        sizeTitleLabel.trailingAnchor.constraint(equalTo: variantDataVerticalGuide.leadingAnchor).isActive = true
        hideSizeLabelConstraint = sizeTitleLabel.heightAnchor.constraint(equalToConstant: 0)
        hideSizeLabelConstraint?.isActive = true
        
        let sizeValueLabel = createValueLabel(titleLabel: sizeTitleLabel)
        sizeValueLabel.leadingAnchor.constraint(equalTo: variantDataVerticalGuide.trailingAnchor).isActive = true
        sizeValueLabel.trailingAnchor.constraint(equalTo: variantDataPositionView.trailingAnchor).isActive = true
        self.sizeValueLabel = sizeValueLabel
        
        let actionView = UIView()
        actionView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(actionView)
        actionView.topAnchor.constraint(equalTo: mainView.bottomAnchor, constant: .padding).isActive = true
        actionView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        actionView.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor).isActive = true
        actionView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        removeButton.translatesAutoresizingMaskIntoConstraints = false
        removeButton.setTitle("Remove", for: .normal)
        removeButton.setTitleColor(.crazeGreen, for: .normal)
        removeButton.layer.borderColor = UIColor.crazeGreen.cgColor
        removeButton.layer.borderWidth = 1
        removeButton.layer.cornerRadius = .defaultCornerRadius
        actionView.addSubview(removeButton)
        removeButton.topAnchor.constraint(equalTo: actionView.topAnchor).isActive = true
        removeButton.leadingAnchor.constraint(equalTo: actionView.leadingAnchor).isActive = true
        removeButton.bottomAnchor.constraint(equalTo: actionView.bottomAnchor).isActive = true
        removeButton.trailingAnchor.constraint(equalTo: actionView.trailingAnchor).isActive = true
        
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
    
    // MARK: Variant Data
    
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
    
    private var hideColorLabelConstraint: NSLayoutConstraint?
    private var hideSizeLabelConstraint: NSLayoutConstraint?
    
    @objc fileprivate func quantityChanged(_ stepper: UIStepper) {
        self.quantityValueLabel?.text = "\(Int(stepper.value))"
    }
}
