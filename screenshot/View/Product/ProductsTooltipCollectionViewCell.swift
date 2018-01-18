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
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundView = UIImageView(image: UIImage(named: "ProductsTooltipConfetti"))
        
        let centerView = UIView()
        centerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(centerView)
        centerView.topAnchor.constraint(lessThanOrEqualTo: contentView.topAnchor, constant: .padding).isActive = true
        centerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: .padding).isActive = true
        centerView.bottomAnchor.constraint(greaterThanOrEqualTo: contentView.bottomAnchor, constant: -.padding).isActive = true
        centerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -.padding).isActive = true
        centerView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        
        let arrowImageView = UIImageView(image: UIImage(named: "ProductsTooltipArrow"))
        arrowImageView.translatesAutoresizingMaskIntoConstraints = false
        arrowImageView.contentMode = .scaleAspectFit
        centerView.addSubview(arrowImageView)
        arrowImageView.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
        arrowImageView.topAnchor.constraint(equalTo: centerView.topAnchor).isActive = true
        arrowImageView.centerXAnchor.constraint(equalTo: centerView.centerXAnchor).isActive = true
        
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.textColor = .gray6
        // TODO: this can supprt dynamic type
        centerView.addSubview(label)
        label.topAnchor.constraint(equalTo: arrowImageView.bottomAnchor, constant: 4).isActive = true
        label.leadingAnchor.constraint(equalTo: centerView.leadingAnchor).isActive = true
        label.bottomAnchor.constraint(equalTo: centerView.bottomAnchor).isActive = true
        label.trailingAnchor.constraint(equalTo: centerView.trailingAnchor).isActive = true
    }
    
    // MARK: Text
    
    var text: String? {
        set {
            label.text = newValue
        }
        get {
            return label.text
        }
    }
}
