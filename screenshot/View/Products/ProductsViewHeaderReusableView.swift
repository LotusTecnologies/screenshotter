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
    let line = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        label.font = .screenshopFont(.hindMedium, textStyle: .headline, staticSize: true)
        label.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(label)
        label.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: .padding).isActive = true
        label.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -.padding).isActive = true
        label.topAnchor.constraint(equalTo: self.topAnchor, constant: .padding).isActive = true
        label.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        
        line.backgroundColor = UIColor(red:0.85, green:0.88, blue:0.89, alpha:1.0)
        line.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(line)
        line.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        line.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        line.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        line.heightAnchor.constraint(equalToConstant: 2.0).isActive = true
        
        
       
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
