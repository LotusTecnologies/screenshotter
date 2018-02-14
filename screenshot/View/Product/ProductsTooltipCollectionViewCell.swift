//
//  ProductsTooltipCollectionViewCell.swift
//  screenshot
//
//  Created by Corey Werner on 1/18/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation

class ProductsTooltipCollectionViewCell : UICollectionViewCell {
    fileprivate let label = UILabel()
    static fileprivate let contentInset = UIEdgeInsets(top: .padding, left: .padding, bottom: .padding, right: .padding)
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let backgroundImageView = UIImageView(image: UIImage(named: "ProductsTooltipConfetti"))
        backgroundImageView.contentMode = .top
        backgroundView = backgroundImageView
        
        let contentInset = type(of: self).contentInset
        
        let centerView = UIView()
        centerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(centerView)
        centerView.topAnchor.constraint(lessThanOrEqualTo: contentView.topAnchor, constant: contentInset.top).isActive = true
        centerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: contentInset.left).isActive = true
        centerView.bottomAnchor.constraint(greaterThanOrEqualTo: contentView.bottomAnchor, constant: -contentInset.bottom).isActive = true
        centerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -contentInset.right).isActive = true
        centerView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        
        let arrowImageView = UIImageView(image: type(of: self).arrowImage)
        arrowImageView.translatesAutoresizingMaskIntoConstraints = false
        arrowImageView.contentMode = .scaleAspectFit
        centerView.addSubview(arrowImageView)
        arrowImageView.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
        arrowImageView.topAnchor.constraint(equalTo: centerView.topAnchor).isActive = true
        arrowImageView.centerXAnchor.constraint(equalTo: centerView.centerXAnchor).isActive = true
        
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.textColor = .gray6
        label.text = type(of: self).text
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        centerView.addSubview(label)
        label.topAnchor.constraint(equalTo: arrowImageView.bottomAnchor, constant: type(of: self).imageToLabelPadding).isActive = true
        label.leadingAnchor.constraint(equalTo: centerView.leadingAnchor).isActive = true
        label.bottomAnchor.constraint(equalTo: centerView.bottomAnchor).isActive = true
        label.trailingAnchor.constraint(equalTo: centerView.trailingAnchor).isActive = true
    }
    
    // MARK: Label / Text / Image
    
    static fileprivate let text = "products.tooltip.title".localized
    
    fileprivate static var labelFont: UIFont {
        return UIFont.preferredFont(forTextStyle: .body)
    }
    
    static fileprivate let arrowImage = UIImage(named: "ProductsTooltipArrow")
    
    static fileprivate let imageToLabelPadding: CGFloat = 4
}

// MARK: - Size

extension ProductsTooltipCollectionViewCell {
    static func height(withCellWidth width: CGFloat) -> CGFloat {
        guard width > 0 else {
            return CGFloat(0)
        }
        
        let contentWidth = width - contentInset.left - contentInset.right
        let constraintRect = CGSize(width: contentWidth, height: .greatestFiniteMagnitude)
        
        let boundingBox = text.boundingRect(with: constraintRect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [NSFontAttributeName: labelFont], context: nil)
        let arrowImageHeight = (arrowImage?.size.height ?? 0)
        return contentInset.top + arrowImageHeight + imageToLabelPadding + ceil(boundingBox.height) + contentInset.bottom
    }
}
