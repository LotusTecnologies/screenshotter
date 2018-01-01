//
//  FavoritesTableViewCell.swift
//  screenshot
//
//  Created by Corey Werner on 12/27/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation

class FavoritesTableViewCell : UITableViewCell {
    private let screenshotContainerView = NotifyChangeView()
    fileprivate let screenshotView = EmbossedView()
    private var screenshotImageViewWidthConstraint: NSLayoutConstraint!
    private var screenshotImageViewHeightConstraint: NSLayoutConstraint!
    fileprivate let shoppableContainerView = UIView()
    
    var imageData: NSData? {
        didSet {
            screenshotView.setImage(withNSData: imageData)
            updateScreenshotImageViewSize()
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
        
        screenshotContainerView.translatesAutoresizingMaskIntoConstraints = false
        screenshotContainerView.notifySizeChange = { size in
            self.updateScreenshotImageViewSize()
        }
        contentView.addSubview(screenshotContainerView)
        screenshotContainerView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor).isActive = true
        screenshotContainerView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        screenshotContainerView.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor).isActive = true
        screenshotContainerView.widthAnchor.constraint(equalTo: contentView.layoutMarginsGuide.heightAnchor, multiplier: Screenshot.ratio.width).isActive = true
        
        screenshotView.translatesAutoresizingMaskIntoConstraints = false
        screenshotView.contentMode = .scaleAspectFill
        screenshotContainerView.addSubview(screenshotView)
        screenshotView.topAnchor.constraint(greaterThanOrEqualTo: screenshotContainerView.topAnchor).isActive = true
        screenshotView.leadingAnchor.constraint(greaterThanOrEqualTo: screenshotContainerView.leadingAnchor).isActive = true
        screenshotView.bottomAnchor.constraint(lessThanOrEqualTo: screenshotContainerView.bottomAnchor).isActive = true
        screenshotView.trailingAnchor.constraint(lessThanOrEqualTo: screenshotContainerView.trailingAnchor).isActive = true
        screenshotView.centerXAnchor.constraint(equalTo: screenshotContainerView.centerXAnchor).isActive = true
        screenshotView.centerYAnchor.constraint(equalTo: screenshotContainerView.centerYAnchor).isActive = true
        screenshotImageViewWidthConstraint = screenshotView.widthAnchor.constraint(equalToConstant: 0)
        screenshotImageViewWidthConstraint.isActive = true
        screenshotImageViewHeightConstraint = screenshotView.heightAnchor.constraint(equalToConstant: 0)
        screenshotImageViewHeightConstraint.isActive = true
        
        let centerView = UIView()
        centerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(centerView)
        centerView.topAnchor.constraint(greaterThanOrEqualTo: contentView.layoutMarginsGuide.topAnchor).isActive = true
        centerView.leadingAnchor.constraint(equalTo: screenshotContainerView.trailingAnchor, constant: .padding).isActive = true
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
    
    // MARK: Screenshot
    
    fileprivate func updateScreenshotImageViewSize() {
        if let imageSize = screenshotView.image?.size, !screenshotContainerView.bounds.isEmpty {
            let rect = imageSize.aspectFitRectInSize(screenshotContainerView.bounds.size)
            
            if screenshotImageViewWidthConstraint.constant != rect.size.width {
                screenshotImageViewWidthConstraint.constant = rect.size.width
            }
            if screenshotImageViewHeightConstraint.constant != rect.size.height {
                screenshotImageViewHeightConstraint.constant = rect.size.height
            }
            
        } else {
            screenshotImageViewWidthConstraint.constant = 0
            screenshotImageViewHeightConstraint.constant = 0
        }
    }
    
    // MARK: Products
    
    static let maxProductCount = 3
    
    static func maxProducts(_ products: [Product]) -> [Product] {
        return Array(products.prefix(maxProductCount))
    }
    
    fileprivate var maxProducts: [Product] = []
    
    func setProducts(_ products: [Product]) {
        maxProducts = type(of: self).maxProducts(products)
        
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
            let productView = EmbossedView()
            
            var layoutMargins = productView.layoutMargins
            layoutMargins.left = -.padding / 2 + abs(layoutMargins.left)
            layoutMargins.right = -.padding / 2 + abs(layoutMargins.right)
            productView.layoutMargins = layoutMargins
            
            productView.placeholderImage = UIImage(named: "DefaultProduct")
            productView.setImage(withURLString: product.imageURL)
            productView.translatesAutoresizingMaskIntoConstraints = false
            shoppableContainerView.addSubview(productView)
            productView.layoutMarginsGuide.topAnchor.constraint(equalTo: shoppableContainerView.topAnchor).isActive = true
            productView.layoutMarginsGuide.bottomAnchor.constraint(equalTo: shoppableContainerView.bottomAnchor).isActive = true
            productView.layoutMarginsGuide.widthAnchor.constraint(equalTo: shoppableContainerView.widthAnchor, multiplier: 1 / CGFloat(type(of: self).maxProductCount)).isActive = true
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
            if let productView = shoppableContainerView.subviews[i] as? EmbossedView {
                productView.setImage(withURLString: product.imageURL)
            }
        }
    }
}
