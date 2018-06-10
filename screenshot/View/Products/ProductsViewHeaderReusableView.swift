//
//  ProductsViewHeaderReusableView.swift
//  screenshot
//
//  Created by Jonathan Rose on 5/8/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class ProductsViewHeaderReusableView: UICollectionReusableView {
    let label = UILabel.init()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        label.font = .screenshopFont(.hindMedium, textStyle: .headline, staticSize: true)
        label.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(label)
        label.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: .padding).isActive = true
        label.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -.padding).isActive = true
        label.topAnchor.constraint(equalTo: self.topAnchor, constant: .padding).isActive = true
        label.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
