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
        let padding = CGFloat.padding
        label.font = UIFont.screenshopFont(.hindLight, size: 30)
        label.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(label)
        label.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant:padding).isActive = true
        label.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -padding).isActive = true
        
        let pad1 = UIView()
        pad1.isHidden = true
        pad1.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(pad1)
        let pad2 = UIView()
        pad2.isHidden = true
        pad2.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(pad2)
        
        pad1.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        pad1.bottomAnchor.constraint(equalTo: label.topAnchor).isActive = true
        
        pad2.topAnchor.constraint(equalTo: label.bottomAnchor).isActive = true
        pad2.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        
        pad2.heightAnchor.constraint(equalTo: pad1.heightAnchor).isActive = true

        
        let line = UIView()
        line.backgroundColor = UIColor(red:0.84, green:0.88, blue:0.89, alpha:1.0)
        line.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(line)
        line.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        line.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        line.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        line.heightAnchor.constraint(equalToConstant: 2.0).isActive = true
        
        self.backgroundColor = UIColor(red:0.93, green:0.93, blue:0.93, alpha:1.0)

        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
