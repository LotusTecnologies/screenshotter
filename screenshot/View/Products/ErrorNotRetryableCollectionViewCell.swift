//
//  ErrorNotRetryableCollectionViewCell.swift
//  screenshot
//
//  Created by Jonathan Rose on 5/9/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class ErrorNotRetryableCollectionViewCell: UICollectionViewCell {
    let label = UILabel.init()

    override init(frame: CGRect) {
        super.init(frame: frame)
        let padding = CGFloat.padding
        label.font = UIFont.systemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .gray4
        self.addSubview(label)
        label.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant:padding*2).isActive = true
        label.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -padding*2).isActive = true
        
        label.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        
        
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
