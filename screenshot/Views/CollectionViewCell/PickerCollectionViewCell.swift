//
//  PickerCollectionViewCell.swift
//  screenshot
//
//  Created by Corey Werner on 9/18/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation

class PickerCollectionViewCell: ImageCollectionViewCell {
    private var checkImageView: UIImageView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        checkImageView = UIImageView.init(image: UIImage.init(named: "PickerCheck"))
        checkImageView.translatesAutoresizingMaskIntoConstraints = false
        checkImageView.contentMode = .scaleAspectFit
        checkImageView.isHidden = true
        contentView.addSubview(checkImageView)
        checkImageView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        checkImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
    }
    
    override var isSelected: Bool {
        didSet {
            checkImageView.isHidden = !isSelected
        }
    }
}
