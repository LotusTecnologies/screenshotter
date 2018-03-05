//
//  CartCheckoutView.swift
//  screenshot
//
//  Created by Corey Werner on 3/5/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class CartCheckoutView: UIView {
    let checkoutButton = MainButton()
    fileprivate let priceLabel = UILabel()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        checkoutButton.translatesAutoresizingMaskIntoConstraints = false
        checkoutButton.backgroundColor = .crazeGreen
        checkoutButton.setTitle("Checkout", for: .normal)
        addSubview(checkoutButton)
        checkoutButton.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
        checkoutButton.leadingAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor).isActive = true
        checkoutButton.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor).isActive = true
        checkoutButton.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        priceLabel.backgroundColor = .yellow
        priceLabel.textColor = .gray3
        priceLabel.textAlignment = .center
        priceLabel.minimumScaleFactor = 0.7
        priceLabel.adjustsFontSizeToFitWidth = true
        addSubview(priceLabel)
        priceLabel.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
        priceLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        priceLabel.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor).isActive = true
        priceLabel.trailingAnchor.constraint(equalTo: checkoutButton.leadingAnchor, constant: -.padding).isActive = true
        
        syncPrice()
    }
    
    var price: String? {
        didSet {
            syncPrice()
        }
    }
    
    fileprivate func syncPrice() {
        if let price = price, !price.isEmpty {
            priceLabel.text = "Total: \(price)"
        }
        else {
            priceLabel.text = nil
        }
    }
}
