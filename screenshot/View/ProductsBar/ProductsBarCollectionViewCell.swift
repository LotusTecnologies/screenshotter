//
//  ProductsBarCollectionViewCell.swift
//  screenshot
//
//  Created by Corey Werner on 2/18/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation

class ProductsBarCollectionViewCell: UICollectionViewCell {
    let mainView = UIView()
    let imageView = UIImageView()
    fileprivate let saleView = SaleView()
    fileprivate let buyLabel = UILabel()
    
    fileprivate let borderWidth: CGFloat = 1
    private let checkImageView = UIImageView(image: UIImage(named: "PickerCheckRed"))

    
    var isSale = false {
        didSet {
            saleView.isHidden = !isSale
        }
    }
    
    var isChecked = false{
        didSet {
            checkImageView.alpha = isChecked ? 1.0 : 0.0
            mainView.alpha = isChecked ? 0.5 : 1.0

        }
    }
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        mainView.translatesAutoresizingMaskIntoConstraints = false
        mainView.layer.cornerRadius = .defaultCornerRadius
        mainView.layer.masksToBounds = true
        contentView.addSubview(mainView)
        mainView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        mainView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        mainView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        mainView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        
        buyLabel.translatesAutoresizingMaskIntoConstraints = false
        buyLabel.backgroundColor = .white
        buyLabel.textColor = .crazeGreen
        buyLabel.text = "generic.buy".localized
        buyLabel.textAlignment = .center
        buyLabel.font = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize, weight: UIFontWeightSemibold)
        mainView.addSubview(buyLabel)
        buyLabel.leadingAnchor.constraint(equalTo: mainView.leadingAnchor).isActive = true
        buyLabel.bottomAnchor.constraint(equalTo: mainView.bottomAnchor).isActive = true
        buyLabel.trailingAnchor.constraint(equalTo: mainView.trailingAnchor).isActive = true
        buyLabel.heightAnchor.constraint(equalToConstant: 28).isActive = true
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        mainView.insertSubview(imageView, belowSubview: buyLabel)
        imageView.topAnchor.constraint(equalTo: mainView.topAnchor).isActive = true
        imageView.leadingAnchor.constraint(equalTo: mainView.leadingAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: buyLabel.topAnchor, constant: borderWidth).isActive = true
        imageView.trailingAnchor.constraint(equalTo: mainView.trailingAnchor).isActive = true
        
        saleView.translatesAutoresizingMaskIntoConstraints = false
        saleView.isHidden = true
        mainView.addSubview(saleView)
        saleView.leadingAnchor.constraint(equalTo: mainView.leadingAnchor).isActive = true
        saleView.bottomAnchor.constraint(equalTo: buyLabel.topAnchor, constant: -6).isActive = true
        
        // iOS 10 masking happens in the layoutSubviews
        if #available(iOS 11.0, *) {
            buyLabel.layer.borderColor = UIColor.crazeGreen.cgColor
            buyLabel.layer.borderWidth = borderWidth
            buyLabel.layer.cornerRadius = .defaultCornerRadius
            buyLabel.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]

            imageView.layer.borderColor = UIColor.gray9.cgColor
            imageView.layer.borderWidth = borderWidth
            imageView.layer.cornerRadius = .defaultCornerRadius
            imageView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        }
        
        
        checkImageView.translatesAutoresizingMaskIntoConstraints = false
        checkImageView.alpha = 0
        checkImageView.contentMode = .scaleAspectFit
        contentView.addSubview(checkImageView)
        checkImageView.topAnchor.constraint(equalTo: mainView.topAnchor, constant: 6).isActive = true
        checkImageView.trailingAnchor.constraint(equalTo: mainView.trailingAnchor, constant: -6).isActive = true
        
        
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if #available(iOS 11.0, *) {} else {
            let radii = CGSize(width: .defaultCornerRadius, height: .defaultCornerRadius)
            
            let maskedViews = [
                ProductsBarCollectionViewCellBorder(view: buyLabel, color: .crazeGreen, corners: [.bottomLeft, .bottomRight]),
                ProductsBarCollectionViewCellBorder(view: imageView, color: .gray9, corners: [.topLeft, .topRight])
            ]
            
            maskedViews.forEach { border in
                border.view.layoutIfNeeded()
                
                if let mask = border.view.layer.mask {
                    if mask.frame.equalTo(border.view.frame) {
                        return
                    }
                    else {
                        border.view.layer.sublayers?.forEach { layer in
                            layer.removeFromSuperlayer()
                        }
                    }
                }
                
                let maskPath = UIBezierPath(roundedRect: border.view.bounds, byRoundingCorners: border.corners, cornerRadii: radii).cgPath
                
                let maskLayer = CAShapeLayer()
                maskLayer.frame = border.view.bounds
                maskLayer.path = maskPath
                border.view.layer.mask = maskLayer
                
                let frameLayer = CAShapeLayer()
                frameLayer.path = maskPath
                frameLayer.strokeColor = border.color.cgColor
                frameLayer.lineWidth = borderWidth * 2 // 2x since the clipping cuts half
                frameLayer.fillColor = nil
                border.view.layer.addSublayer(frameLayer)
            }
        }
    }
    
    // MARK: Favorite
    
    var isFavorited = false {
        didSet {
            guard isFavorited || hasHeartView else {
                return
            }
            
            heartView.isHidden = !isFavorited
        }
    }
    
    private var hasHeartView = false
    
    fileprivate lazy var heartView: FavoriteBadgeView = {
        self.hasHeartView = true
        
        let view = FavoriteBadgeView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.tintColor = .crazeRed
        self.mainView.insertSubview(view, aboveSubview: self.imageView)
        view.topAnchor.constraint(equalTo: self.mainView.topAnchor, constant: -4).isActive = true
        view.trailingAnchor.constraint(equalTo: self.mainView.trailingAnchor, constant: 4).isActive = true
        return view
    }()
}

fileprivate struct ProductsBarCollectionViewCellBorder {
    let view: UIView
    let color: UIColor
    let corners: UIRectCorner
}
