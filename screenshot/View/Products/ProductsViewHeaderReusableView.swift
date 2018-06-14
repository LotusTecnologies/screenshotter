//
//  ProductsViewHeaderReusableView.swift
//  screenshot
//
//  Created by Jonathan Rose on 5/8/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import UIKit

class ProductsViewHeaderReusableView: UICollectionReusableView {
    let label = UILabel.init()
    let filterButton = UIButton()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        layoutMargins = UIEdgeInsets(top: .padding, left: .padding, bottom: 0, right: .padding)
        
        label.font = .screenshopFont(.hindMedium, textStyle: .headline, staticSize: true)
        label.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(label)
        label.leadingAnchor.constraint(equalTo: self.layoutMarginsGuide.leadingAnchor).isActive = true
        label.topAnchor.constraint(equalTo: self.layoutMarginsGuide.topAnchor).isActive = true
        label.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        
        self.filterButton.translatesAutoresizingMaskIntoConstraints = false
        self.filterButton.setImage(UIImage(named: "ProductsFilter"), for: .normal)
        self.filterButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: layoutMargins.right, bottom: 0, right: layoutMargins.right)
        self.addSubview(filterButton)
        self.filterButton.setContentHuggingPriority(.required, for: .horizontal)
        self.filterButton.topAnchor.constraint(equalTo: self.layoutMarginsGuide.topAnchor).isActive = true
        self.filterButton.leadingAnchor.constraint(equalTo: self.label.trailingAnchor).isActive = true
        self.filterButton.bottomAnchor.constraint(equalTo: self.layoutMarginsGuide.bottomAnchor).isActive = true
        self.filterButton.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
