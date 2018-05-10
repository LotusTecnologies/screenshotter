//
//  ErrorRetryableCollectionViewCell.swift
//  screenshot
//
//  Created by Jonathan Rose on 5/9/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class ErrorCollectionViewCell: UICollectionViewCell {
    
    let label = UILabel.init()
    let button = MainButton()
    override init(frame: CGRect) {
        super.init(frame: frame)
        let padding = CGFloat.padding
        label.font = UIFont.systemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .gray4
        self.contentView.addSubview(label)
        label.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant:padding).isActive = true
        label.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -padding).isActive = true
        
        label.topAnchor.constraint(equalTo: self.contentView.topAnchor).isActive = true
        

        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .crazeGreen
        button.setTitle("generic.retry".localized, for: .normal)
        self.contentView.addSubview(button)
        button.centerXAnchor.constraint(equalTo: self.contentView.centerXAnchor).isActive = true
        button.topAnchor.constraint(equalTo: label.bottomAnchor, constant: .padding).isActive = true

        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
