//
//  CheckoutCreditCardTableViewCell.swift
//  screenshot
//
//  Created by Corey Werner on 4/11/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class CheckoutCreditCardTableViewCell: CardTableViewCell {
    let cardNumberLabel = UILabel()
    let nameLabel = UILabel()
    fileprivate let expirationLabel = UILabel()
    fileprivate let brandImageView = UIImageView()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        cardView.heightAnchor.constraint(greaterThanOrEqualToConstant: 150).isActive = true
        
        cardNumberLabel.translatesAutoresizingMaskIntoConstraints = false
        cardNumberLabel.font = .screenshopFont(.hindLight, size: 22)
        cardNumberLabel.minimumScaleFactor = 0.7
        cardNumberLabel.adjustsFontSizeToFitWidth = true
        cardNumberLabel.textColor = .gray3
        cardNumberLabel.lineBreakMode = .byTruncatingHead
        cardView.addSubview(cardNumberLabel)
        cardNumberLabel.topAnchor.constraint(equalTo: cardView.layoutMarginsGuide.topAnchor).isActive = true
        cardNumberLabel.leadingAnchor.constraint(equalTo: cardView.layoutMarginsGuide.leadingAnchor).isActive = true
        cardNumberLabel.trailingAnchor.constraint(equalTo: editButton.leadingAnchor).isActive = true
        
        brandImageView.translatesAutoresizingMaskIntoConstraints = false
        brandImageView.contentMode = .scaleAspectFit
        brandImageView.setContentHuggingPriority(.required, for: .horizontal)
        brandImageView.setContentHuggingPriority(.required, for: .vertical)
        brandImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        brandImageView.setContentCompressionResistancePriority(.required, for: .vertical)
        cardView.addSubview(brandImageView)
        brandImageView.bottomAnchor.constraint(lessThanOrEqualTo: cardView.layoutMarginsGuide.bottomAnchor).isActive = true
        brandImageView.trailingAnchor.constraint(equalTo: cardView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.textColor = .gray3
        nameLabel.font = .screenshopFont(.hindLight, size: 16)
        cardView.addSubview(nameLabel)
        nameLabel.topAnchor.constraint(greaterThanOrEqualTo: cardNumberLabel.bottomAnchor, constant: .padding).isActive = true
        nameLabel.leadingAnchor.constraint(equalTo: cardView.layoutMarginsGuide.leadingAnchor).isActive = true
        nameLabel.trailingAnchor.constraint(equalTo: brandImageView.leadingAnchor, constant: -.padding).isActive = true
        
        let brandImageViewTopConstraint = brandImageView.topAnchor.constraint(equalTo: nameLabel.topAnchor)
        brandImageViewTopConstraint.priority = .defaultHigh
        brandImageViewTopConstraint.isActive = true
        
        expirationLabel.translatesAutoresizingMaskIntoConstraints = false
        expirationLabel.font = .screenshopFont(.hindMedium, size: 14)
        cardView.addSubview(expirationLabel)
        expirationLabel.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        expirationLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor).isActive = true
        expirationLabel.leadingAnchor.constraint(equalTo: cardView.layoutMarginsGuide.leadingAnchor).isActive = true
        expirationLabel.firstBaselineAnchor.constraint(equalTo: cardView.layoutMarginsGuide.bottomAnchor).isActive = true
        expirationLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor).isActive = true
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
    
    // MARK: Brand
    
    func setBrandImage(_ brand: CreditCardBrand) {
        switch brand {
        case .Amex:
            brandImageView.image = UIImage(named: "CheckoutCardAmex")
        case .DinersClub:
            brandImageView.image = UIImage(named: "CheckoutCardDiners")
        case .Discover:
            brandImageView.image = UIImage(named: "CheckoutCardDiscover")
        case .JCB:
            brandImageView.image = UIImage(named: "CheckoutCardJCB")
        case .Mastercard:
            brandImageView.image = UIImage(named: "CheckoutCardMastercard")
        case .Visa:
            brandImageView.image = UIImage(named: "CheckoutCardVisa")
        }
    }
}
