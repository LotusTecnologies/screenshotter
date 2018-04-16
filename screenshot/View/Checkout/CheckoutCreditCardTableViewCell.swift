//
//  CheckoutCreditCardTableViewCell.swift
//  screenshot
//
//  Created by Corey Werner on 4/11/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class CheckoutCreditCardTableViewCell: CardTableViewCell {
    fileprivate let cardNumberLabel = UILabel()
    let nameLabel = UILabel()
    fileprivate let expirationLabel = UILabel()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        cardView.heightAnchor.constraint(greaterThanOrEqualToConstant: 150).isActive = true
        
        cardNumberLabel.translatesAutoresizingMaskIntoConstraints = false
        cardNumberLabel.text = "**** **** **** 9876"
        cardNumberLabel.font = .screenshopFont(.hindLight, size: 22)
        cardNumberLabel.minimumScaleFactor = 0.7
        cardNumberLabel.adjustsFontSizeToFitWidth = true
        cardNumberLabel.textColor = .gray3
        cardNumberLabel.lineBreakMode = .byTruncatingHead
        cardView.addSubview(cardNumberLabel)
        cardNumberLabel.topAnchor.constraint(equalTo: cardView.layoutMarginsGuide.topAnchor).isActive = true
        cardNumberLabel.leadingAnchor.constraint(equalTo: cardView.layoutMarginsGuide.leadingAnchor).isActive = true
        cardNumberLabel.trailingAnchor.constraint(equalTo: editButton.leadingAnchor).isActive = true
        
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.textColor = .gray3
        nameLabel.font = .screenshopFont(.hindLight, size: 16)
        cardView.addSubview(nameLabel)
        nameLabel.topAnchor.constraint(greaterThanOrEqualTo: cardNumberLabel.bottomAnchor, constant: .padding).isActive = true
        nameLabel.leadingAnchor.constraint(equalTo: cardView.layoutMarginsGuide.leadingAnchor).isActive = true
        nameLabel.trailingAnchor.constraint(equalTo: cardView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        expirationLabel.translatesAutoresizingMaskIntoConstraints = false
        expirationLabel.font = .screenshopFont(.hindMedium, size: 14)
        cardView.addSubview(expirationLabel)
        expirationLabel.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        expirationLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor).isActive = true
        expirationLabel.leadingAnchor.constraint(equalTo: cardView.layoutMarginsGuide.leadingAnchor).isActive = true
        expirationLabel.firstBaselineAnchor.constraint(equalTo: cardView.layoutMarginsGuide.bottomAnchor).isActive = true
        expirationLabel.trailingAnchor.constraint(equalTo: cardView.layoutMarginsGuide.trailingAnchor).isActive = true
    }
    
    // MARK: Expiration
    
    var isExpired = false {
        didSet {
            syncExpirationLabel()
        }
    }
    
    private var expirationString = ""
    
    /// month = xx; year = xxxx
    func setExpiration(month: Int, year: Int) {
        expirationString = String(format: "%02d/%d", month, year)
        syncExpirationLabel()
    }
    
    private func syncExpirationLabel() {
        if isExpired {
            expirationLabel.text = "EXPIRED"
            expirationLabel.textColor = .crazeRed
        }
        else {
            expirationLabel.text = "EXPIRES \(expirationString)"
            expirationLabel.textColor = .gray7
        }
    }
}
