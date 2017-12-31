//
//  FavoritesTableViewCell.swift
//  screenshot
//
//  Created by Corey Werner on 12/27/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation

class FavoritesTableViewCell : UITableViewCell {
    fileprivate let screenshotImageView = UIImageView()
    fileprivate let shoppableContainerView = UIView()
    
    var imageData: NSData? {
        didSet {
            if let imageData = imageData as Data? {
                screenshotImageView.image = UIImage(data: imageData)
                
            } else {
                screenshotImageView.image = nil
            }
        }
    }
    
    fileprivate let label = UILabel()
    
    override var textLabel: UILabel? {
        return label
    }
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        // TODO: do math for setting the shadow around the image and not the image view (ie. landscape image)
        screenshotImageView.translatesAutoresizingMaskIntoConstraints = false
        screenshotImageView.contentMode = .scaleAspectFit
        contentView.addSubview(screenshotImageView)
        screenshotImageView.topAnchor.constraint(greaterThanOrEqualTo: contentView.layoutMarginsGuide.topAnchor).isActive = true
        screenshotImageView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        screenshotImageView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.layoutMarginsGuide.bottomAnchor).isActive = true
        screenshotImageView.widthAnchor.constraint(equalTo: contentView.layoutMarginsGuide.heightAnchor, multiplier: Screenshot.ratio.width).isActive = true
        
        let centerView = UIView()
        centerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(centerView)
        centerView.topAnchor.constraint(greaterThanOrEqualTo: contentView.layoutMarginsGuide.topAnchor).isActive = true
        centerView.leadingAnchor.constraint(equalTo: screenshotImageView.trailingAnchor, constant: .padding).isActive = true
        centerView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.layoutMarginsGuide.bottomAnchor).isActive = true
        centerView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        centerView.centerYAnchor.constraint(equalTo: contentView.layoutMarginsGuide.centerYAnchor).isActive = true
        
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .gray3
        label.font = UIFont.preferredFont(forTextStyle: .title3)
        label.adjustsFontForContentSizeCategory = true
        centerView.addSubview(label)
        label.topAnchor.constraint(equalTo: centerView.topAnchor).isActive = true
        label.leadingAnchor.constraint(equalTo: centerView.leadingAnchor).isActive = true
        label.trailingAnchor.constraint(equalTo: centerView.trailingAnchor).isActive = true
        
        shoppableContainerView.translatesAutoresizingMaskIntoConstraints = false
        centerView.addSubview(shoppableContainerView)
        shoppableContainerView.topAnchor.constraint(equalTo: label.bottomAnchor, constant: .padding / 2).isActive = true
        shoppableContainerView.layoutMarginsGuide.leadingAnchor.constraint(equalTo: centerView.leadingAnchor).isActive = true
        shoppableContainerView.bottomAnchor.constraint(equalTo: centerView.bottomAnchor).isActive = true
        shoppableContainerView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: centerView.trailingAnchor).isActive = true
    }
    
    // MARK: Products
    
    fileprivate let maxProductCount = 3
    
    var products: [Product]? {
        didSet {
            if let products = products {
                maxProducts = Array(products.prefix(maxProductCount))
                
            } else {
                maxProducts = []
            }
            
            if maxProducts.count == 0 {
                removeProductViews()
                
            } else {
                if shoppableContainerView.subviews.count != maxProducts.count {
                    removeProductViews()
                    setupProductViews()
                }
                
                updateProductViews()
            }
        }
    }
    
    fileprivate var maxProducts: [Product] = []
    
    private func removeProductViews() {
        shoppableContainerView.subviews.forEach { productView in
            productView.removeFromSuperview()
        }
    }
    
    private func setupProductViews() {
        guard shoppableContainerView.subviews.count == 0, maxProducts.count > 0 else {
            return
        }
        
        maxProducts.enumerated().forEach { (i: Int, product: Product) in
            let productView = ProductView()
            
            var layoutMargins = productView.layoutMargins
            layoutMargins.left = -.padding / 2 + abs(layoutMargins.left)
            layoutMargins.right = -.padding / 2 + abs(layoutMargins.right)
            productView.layoutMargins = layoutMargins
            
            productView.imageURL = product.imageURL
            productView.translatesAutoresizingMaskIntoConstraints = false
            shoppableContainerView.addSubview(productView)
            productView.layoutMarginsGuide.topAnchor.constraint(equalTo: shoppableContainerView.topAnchor).isActive = true
            productView.layoutMarginsGuide.bottomAnchor.constraint(equalTo: shoppableContainerView.bottomAnchor).isActive = true
            productView.layoutMarginsGuide.widthAnchor.constraint(equalTo: shoppableContainerView.widthAnchor, multiplier: 1 / CGFloat(maxProductCount)).isActive = true
            productView.heightAnchor.constraint(equalTo: productView.widthAnchor).isActive = true
            
            if i == 0 {
                productView.layoutMarginsGuide.leadingAnchor.constraint(equalTo: shoppableContainerView.leadingAnchor).isActive = true
                
                var shoppableLayoutMargins = shoppableContainerView.layoutMargins
                shoppableLayoutMargins.left = abs(layoutMargins.left)
                shoppableContainerView.layoutMargins = shoppableLayoutMargins
                
            } else {
                let previousView = shoppableContainerView.subviews[i - 1]
                productView.layoutMarginsGuide.leadingAnchor.constraint(equalTo: previousView.layoutMarginsGuide.trailingAnchor).isActive = true
            }
            
            if i == maxProducts.count - 1 {
                productView.layoutMarginsGuide.trailingAnchor.constraint(lessThanOrEqualTo: shoppableContainerView.trailingAnchor).isActive = true
                
                var shoppableLayoutMargins = shoppableContainerView.layoutMargins
                shoppableLayoutMargins.right = abs(layoutMargins.right)
                shoppableContainerView.layoutMargins = shoppableLayoutMargins
            }
        }
    }
    
    private func updateProductViews() {
        maxProducts.enumerated().forEach { (i: Int, product: Product) in
            if let productView = shoppableContainerView.subviews[i] as? ProductView {
                productView.imageURL = product.imageURL
            }
        }
    }
}
