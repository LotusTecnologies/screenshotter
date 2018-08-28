//
//  SpinnerCollectionViewCell.swift
//  screenshot
//
//  Created by Jonathan Rose on 5/9/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import UIKit

class SpinnerCollectionViewCell: UICollectionViewCell {
    let spinner = UIActivityIndicatorView.init(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge)
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(spinner)
        spinner.centerXAnchor.constraint(equalTo: self.contentView.centerXAnchor).isActive = true
        spinner.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor).isActive = true
        spinner.startAnimating()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        spinner.startAnimating()
    }
}
