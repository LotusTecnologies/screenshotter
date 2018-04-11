//
//  CheckoutOrderView.swift
//  screenshot
//
//  Created by Corey Werner on 4/10/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class CheckoutOrderView: UIScrollView, DynamicTypeAccessibilityLayout {
    let orderLabel = UILabel()
    let shippingControl: UIControl = Control()
    let nameLabel = UILabel()
    let addressLabel = UILabel()
    let paymentControl: UIControl = Control()
    let cardLabel = UILabel()
    let itemsPriceLabel = UILabel()
    let shippingPriceLabel = UILabel()
    let beforeTaxPriceLabel = UILabel()
    let estimateTaxLabel = UILabel()
    let totalPriceLabel = UILabel()
    let itemsLabel = UILabel()
    let tableView: UITableView = AutoresizingTableView()
    let orderButton = MainButton()
    let cancelButton = BorderButton()
    let legalTextView = UITextView()
    
    var fontSizeStandardRangeConstraints: [NSLayoutConstraint] = []
    var fontSizeAccessibilityRangeConstraints: [NSLayoutConstraint] = []
    
    // MARK: View
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // TODO: test with ios10
        layoutMargins = UIEdgeInsets(top: .padding, left: .padding, bottom: .padding, right: .padding)
        
        let bottomImageView = UIImageView(image: UIImage(named: "CheckoutOrderConfetti"))
        bottomImageView.translatesAutoresizingMaskIntoConstraints = false
        bottomImageView.contentMode = .scaleAspectFill
        addSubview(bottomImageView)
        bottomImageView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        bottomImageView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        bottomImageView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
        orderLabel.translatesAutoresizingMaskIntoConstraints = false
        orderLabel.text = "Order Summary"
        orderLabel.textColor = .gray3
        orderLabel.font = .screenshopFont(.hindLight, textStyle: .title2)
        orderLabel.adjustsFontForContentSizeCategory = true
        orderLabel.minimumScaleFactor = 0.7
        orderLabel.adjustsFontSizeToFitWidth = true
        addSubview(orderLabel)
        orderLabel.topAnchor.constraint(equalTo: topAnchor, constant: layoutMargins.top).isActive = true
        orderLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        orderLabel.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        let summaryView = UIView()
        summaryView.translatesAutoresizingMaskIntoConstraints = false
        summaryView.backgroundColor = .white
        summaryView.layoutMargins = UIEdgeInsetsMake(.padding, .padding, .padding, .padding)
        summaryView.layer.borderColor = UIColor.cellBorder.cgColor
        summaryView.layer.borderWidth = 1
        summaryView.layer.cornerRadius = .defaultCornerRadius
        summaryView.layer.masksToBounds = true
        addSubview(summaryView)
        summaryView.topAnchor.constraint(equalTo: orderLabel.bottomAnchor, constant: .padding / 2).isActive = true
        summaryView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        summaryView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        func setLabeledControl(_ control: UIControl) -> UILabel {
            control.translatesAutoresizingMaskIntoConstraints = false
            summaryView.addSubview(control)
            control.leadingAnchor.constraint(equalTo: summaryView.leadingAnchor).isActive = true
            control.trailingAnchor.constraint(equalTo: summaryView.trailingAnchor).isActive = true
            
            let borderView = BorderView(edge: .bottom)
            borderView.backgroundColor = .cellBorder
            control.addSubview(borderView)
            
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.font = .screenshopFont(.hindSemibold, textStyle: .body)
            label.adjustsFontForContentSizeCategory = true
            label.minimumScaleFactor = 0.7
            label.adjustsFontSizeToFitWidth = true
            label.textColor = .gray3
            control.addSubview(label)
            label.topAnchor.constraint(equalTo: control.topAnchor, constant: summaryView.layoutMargins.top).isActive = true
            label.leadingAnchor.constraint(equalTo: summaryView.layoutMarginsGuide.leadingAnchor).isActive = true
            label.trailingAnchor.constraint(equalTo: control.layoutMarginsGuide.trailingAnchor).isActive = true
            return label
        }
        
        let shippingLabel = setLabeledControl(shippingControl)
        shippingLabel.text = "Shipping to:"
        shippingControl.topAnchor.constraint(equalTo: summaryView.topAnchor).isActive = true
        
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.textColor = .gray3
        nameLabel.font = .screenshopFont(.hindLight, textStyle: .callout)
        nameLabel.adjustsFontForContentSizeCategory = true
        nameLabel.baselineAdjustment = .alignCenters
        shippingControl.addSubview(nameLabel)
        nameLabel.topAnchor.constraint(equalTo: shippingLabel.bottomAnchor).isActive = true
        nameLabel.leadingAnchor.constraint(equalTo: summaryView.layoutMarginsGuide.leadingAnchor).isActive = true
        nameLabel.trailingAnchor.constraint(equalTo: shippingControl.layoutMarginsGuide.trailingAnchor).isActive = true
        
        addressLabel.translatesAutoresizingMaskIntoConstraints = false
        addressLabel.textColor = .gray3
        addressLabel.font = .screenshopFont(.hindLight, textStyle: .callout)
        addressLabel.adjustsFontForContentSizeCategory = true
        addressLabel.baselineAdjustment = .alignCenters
        addressLabel.numberOfLines = 0
        shippingControl.addSubview(addressLabel)
        addressLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor).isActive = true
        addressLabel.leadingAnchor.constraint(equalTo: summaryView.layoutMarginsGuide.leadingAnchor).isActive = true
        addressLabel.bottomAnchor.constraint(equalTo: shippingControl.bottomAnchor, constant: -summaryView.layoutMargins.bottom).isActive = true
        addressLabel.trailingAnchor.constraint(equalTo: shippingControl.layoutMarginsGuide.trailingAnchor).isActive = true
        
        let paymentLabel = setLabeledControl(paymentControl)
        paymentLabel.text = "Payment Method:"
        paymentControl.topAnchor.constraint(equalTo: shippingControl.bottomAnchor).isActive = true
        
        cardLabel.translatesAutoresizingMaskIntoConstraints = false
        cardLabel.textColor = .gray3
        cardLabel.font = .screenshopFont(.hindLight, textStyle: .callout)
        cardLabel.adjustsFontForContentSizeCategory = true
        cardLabel.baselineAdjustment = .alignCenters
        cardLabel.lineBreakMode = .byTruncatingMiddle // Card type and number should always be shown
        paymentControl.addSubview(cardLabel)
        cardLabel.topAnchor.constraint(equalTo: paymentLabel.bottomAnchor).isActive = true
        cardLabel.leadingAnchor.constraint(equalTo: summaryView.layoutMarginsGuide.leadingAnchor).isActive = true
        cardLabel.bottomAnchor.constraint(equalTo: paymentControl.bottomAnchor, constant: -summaryView.layoutMargins.bottom).isActive = true
        cardLabel.trailingAnchor.constraint(equalTo: paymentControl.layoutMarginsGuide.trailingAnchor).isActive = true
        
        func createSummaryKeyLabel() -> UILabel {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.textColor = .gray3
            label.font = .screenshopFont(.hindLight, textStyle: .callout)
            label.adjustsFontForContentSizeCategory = true
            label.minimumScaleFactor = 0.7
            label.adjustsFontSizeToFitWidth = true
            label.baselineAdjustment = .alignCenters
            summaryView.addSubview(label)
            label.leadingAnchor.constraint(equalTo: summaryView.layoutMarginsGuide.leadingAnchor).isActive = true
            
            fontSizeAccessibilityRangeConstraints += [
                label.trailingAnchor.constraint(lessThanOrEqualTo: summaryView.layoutMarginsGuide.trailingAnchor)
            ]
            
            return label
        }
        
        func setSummaryValueLabel(_ label: UILabel, with keyLabel: UILabel) {
            label.translatesAutoresizingMaskIntoConstraints = false
            label.textColor = .gray3
            label.font = .screenshopFont(.hindLight, textStyle: .callout)
            label.adjustsFontForContentSizeCategory = true
            label.baselineAdjustment = .alignCenters
            summaryView.addSubview(label)
            
            fontSizeStandardRangeConstraints += [
                label.topAnchor.constraint(equalTo: keyLabel.topAnchor),
                label.leadingAnchor.constraint(greaterThanOrEqualTo: keyLabel.trailingAnchor, constant: .padding),
                label.trailingAnchor.constraint(equalTo: summaryView.layoutMarginsGuide.trailingAnchor)
            ]
            fontSizeAccessibilityRangeConstraints += [
                label.topAnchor.constraint(equalTo: keyLabel.bottomAnchor),
                label.leadingAnchor.constraint(equalTo: keyLabel.leadingAnchor),
                label.trailingAnchor.constraint(lessThanOrEqualTo: summaryView.layoutMarginsGuide.trailingAnchor)
            ]
        }
        
        let itemsKeyLabel = createSummaryKeyLabel()
        itemsKeyLabel.text = "Items:"
        itemsKeyLabel.topAnchor.constraint(equalTo: paymentControl.bottomAnchor, constant: summaryView.layoutMargins.top).isActive = true
        
        setSummaryValueLabel(itemsPriceLabel, with: itemsKeyLabel)
        
        let shippingKeyLabel = createSummaryKeyLabel()
        shippingKeyLabel.text = "Shipping & handling:"
        shippingKeyLabel.topAnchor.constraint(equalTo: itemsPriceLabel.bottomAnchor).isActive = true
        
        setSummaryValueLabel(shippingPriceLabel, with: shippingKeyLabel)
        
        let beforeTaxKeyLabel = createSummaryKeyLabel()
        beforeTaxKeyLabel.text = "Total before tax:"
        beforeTaxKeyLabel.topAnchor.constraint(equalTo: shippingPriceLabel.bottomAnchor).isActive = true
        
        setSummaryValueLabel(beforeTaxPriceLabel, with: beforeTaxKeyLabel)
        
        let estimateTaxKeyLabel = createSummaryKeyLabel()
        estimateTaxKeyLabel.text = "Estimated tax to be collected:"
        estimateTaxKeyLabel.topAnchor.constraint(equalTo: beforeTaxPriceLabel.bottomAnchor).isActive = true
        
        setSummaryValueLabel(estimateTaxLabel, with: estimateTaxKeyLabel)
        
        let totalKeyLabel = createSummaryKeyLabel()
        totalKeyLabel.font = .screenshopFont(.hindSemibold, textStyle: .body)
        totalKeyLabel.text = "Order Total:"
        totalKeyLabel.topAnchor.constraint(equalTo: estimateTaxLabel.bottomAnchor, constant: .padding).isActive = true
        
        setSummaryValueLabel(totalPriceLabel, with: totalKeyLabel)
        totalPriceLabel.font = .screenshopFont(.hindSemibold, textStyle: .body)
        totalPriceLabel.textColor = .crazeRed
        totalPriceLabel.bottomAnchor.constraint(equalTo: summaryView.layoutMarginsGuide.bottomAnchor).isActive = true
        
        itemsLabel.translatesAutoresizingMaskIntoConstraints = false
        itemsLabel.text = "Items"
        itemsLabel.textColor = .gray3
        itemsLabel.font = .screenshopFont(.hindLight, textStyle: .title2)
        itemsLabel.adjustsFontForContentSizeCategory = true
        itemsLabel.minimumScaleFactor = 0.7
        itemsLabel.adjustsFontSizeToFitWidth = true
        addSubview(itemsLabel)
        itemsLabel.topAnchor.constraint(equalTo: summaryView.bottomAnchor, constant: .padding).isActive = true
        itemsLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        itemsLabel.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.scrollsToTop = false
        tableView.isScrollEnabled = false
        tableView.separatorInset = .zero
        tableView.separatorColor = .cellBorder
        tableView.allowsSelection = false
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 120
        tableView.layer.borderColor = UIColor.cellBorder.cgColor
        tableView.layer.borderWidth = 1
        tableView.layer.cornerRadius = .defaultCornerRadius
        tableView.layer.masksToBounds = true
        addSubview(tableView)
        tableView.topAnchor.constraint(equalTo: itemsLabel.bottomAnchor, constant: .padding / 2).isActive = true
        tableView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        let orderButtonHeightGuide = UIView()
        orderButtonHeightGuide.translatesAutoresizingMaskIntoConstraints = false
        orderButtonHeightGuide.isHidden = true
        addSubview(orderButtonHeightGuide)
        orderButtonHeightGuide.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: .padding).isActive = true
        
        orderButton.translatesAutoresizingMaskIntoConstraints = false
        orderButton.backgroundColor = .crazeGreen
        orderButton.setTitle("Place Your Order", for: .normal)
        addSubview(orderButton)
        orderButton.leadingAnchor.constraint(greaterThanOrEqualTo: layoutMarginsGuide.leadingAnchor).isActive = true
        orderButton.bottomAnchor.constraint(lessThanOrEqualTo: orderButtonHeightGuide.bottomAnchor).isActive = true
        orderButton.bottomAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.bottomAnchor).isActive = true
        orderButton.trailingAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.trailingAnchor).isActive = true
        orderButton.centerXAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor).isActive = true
        
        orderButtonHeightGuide.heightAnchor.constraint(equalTo: orderButton.heightAnchor).isActive = true
        
        let dividerView = UIView()
        dividerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dividerView)
        dividerView.topAnchor.constraint(equalTo: orderButtonHeightGuide.bottomAnchor, constant: .padding).isActive = true
        dividerView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        dividerView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        let dividerLabel = UILabel()
        dividerLabel.translatesAutoresizingMaskIntoConstraints = false
        dividerLabel.text = "or"
        dividerLabel.textColor = .gray3
        dividerLabel.font = .screenshopFont(.hindMedium, size: 16)
        dividerLabel.textAlignment = .center
        dividerView.addSubview(dividerLabel)
        dividerLabel.topAnchor.constraint(equalTo: dividerView.topAnchor).isActive = true
        dividerLabel.bottomAnchor.constraint(equalTo: dividerView.bottomAnchor).isActive = true
        dividerLabel.centerXAnchor.constraint(equalTo: dividerView.centerXAnchor).isActive = true
        
        func createDividerFragment() -> UIView {
            let dividerFragment = UIView()
            dividerFragment.translatesAutoresizingMaskIntoConstraints = false
            dividerFragment.backgroundColor = .cellBorder
            dividerView.addSubview(dividerFragment)
            dividerFragment.centerYAnchor.constraint(equalTo: dividerView.centerYAnchor).isActive = true
            dividerFragment.heightAnchor.constraint(equalToConstant: 1).isActive = true
            return dividerFragment
        }
        
        let leftDividerFragment = createDividerFragment()
        leftDividerFragment.leadingAnchor.constraint(equalTo: dividerView.leadingAnchor).isActive = true
        leftDividerFragment.trailingAnchor.constraint(equalTo: dividerLabel.leadingAnchor, constant: -.padding).isActive = true
        
        let rightDividerFragment = createDividerFragment()
        rightDividerFragment.leadingAnchor.constraint(equalTo: dividerLabel.trailingAnchor, constant: .padding).isActive = true
        rightDividerFragment.trailingAnchor.constraint(equalTo: dividerView.trailingAnchor).isActive = true
        
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.setTitle("Cancel and Continue Shopping", for: .normal)
        cancelButton.setTitleColor(.crazeGreen, for: .normal)
        addSubview(cancelButton)
        cancelButton.topAnchor.constraint(equalTo: dividerView.bottomAnchor, constant: .padding).isActive = true
        cancelButton.leadingAnchor.constraint(greaterThanOrEqualTo: layoutMarginsGuide.leadingAnchor).isActive = true
        cancelButton.trailingAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.trailingAnchor).isActive = true
        cancelButton.centerXAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor).isActive = true
        cancelButton.widthAnchor.constraint(equalTo: orderButton.widthAnchor).isActive = true
        
        legalTextView.translatesAutoresizingMaskIntoConstraints = false
        legalTextView.scrollsToTop = false
        legalTextView.isScrollEnabled = false
        legalTextView.backgroundColor = .clear
        legalTextView.textColor = .gray3
        legalTextView.font = .screenshopFont(.hindLight, textStyle: .footnote)
        legalTextView.adjustsFontForContentSizeCategory = true
        legalTextView.text = """
        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam quis risus eget urna mollis ornare vel eu leo. Vestibulum id ligula porta felis euismod semper. Etiam porta sem malesuada magna mollis euismod. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam id dolor id nibh ultricies vehicula ut id elit. Morbi leo risus, porta ac consectetur ac, vestibulum at eros.
        
        Aenean eu leo quam. Pellentesque ornare sem lacinia quam venenatis vestibulum. Vivamus sagittis lacus vel augue laoreet rutrum faucibus dolor auctor.
        """
        addSubview(legalTextView)
        legalTextView.topAnchor.constraint(equalTo: cancelButton.bottomAnchor, constant: .padding).isActive = true
        legalTextView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        legalTextView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -layoutMargins.bottom).isActive = true
        legalTextView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        adjustDynamicTypeLayout(traitCollection: traitCollection, previousTraitCollection: previousTraitCollection)
    }
}

fileprivate extension CheckoutOrderView {
    class Control: UIControl {
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            let image = UIImage(named: "CheckoutOrderChevron")
            let imagePadding: CGFloat = .padding
            
            layoutMargins = UIEdgeInsetsMake(0, 0, 0, (image?.size.width ?? 0) + (imagePadding * 2))
            
            let chevronImageView = UIImageView(image: image)
            chevronImageView.translatesAutoresizingMaskIntoConstraints = false
            chevronImageView.contentMode = .scaleAspectFit
            addSubview(chevronImageView)
            chevronImageView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor).isActive = true
            chevronImageView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor).isActive = true
            chevronImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -imagePadding).isActive = true
            chevronImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        }
        
        override var isHighlighted: Bool {
            didSet {
                backgroundColor = isHighlighted ? .gray9 : nil
            }
        }
    }
}
