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
        label.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(label)
        label.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant:padding).isActive = true
        label.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -padding).isActive = true
        
        label.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        label.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        let line = UIView()
        line.backgroundColor = UIColor(red:0.85, green:0.88, blue:0.89, alpha:1.0)
        line.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(line)
        line.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        line.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        line.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        line.heightAnchor.constraint(equalToConstant: 2.0).isActive = true
        
        
        if let image = UIImage.init(named: "confetti") {
            self.backgroundColor = UIColor.init(patternImage: image )
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
