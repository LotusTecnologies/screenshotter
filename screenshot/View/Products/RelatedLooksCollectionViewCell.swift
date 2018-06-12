//
//  RelatedLooksCollectionViewCell.swift
//  screenshot
//
//  Created by Jonathan Rose on 5/8/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import UIKit

class RelatedLooksCollectionViewCell: ShadowCollectionViewCell {
    let imageView = UIImageView()
    let flagButton = UIButton()

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        mainView.addSubview(imageView)
        imageView.contentMode = .scaleAspectFill
        imageView.leadingAnchor.constraint(equalTo: mainView.leadingAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: mainView.trailingAnchor).isActive = true
        imageView.topAnchor.constraint(equalTo: mainView.topAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: mainView.bottomAnchor).isActive = true
                
        flagButton.translatesAutoresizingMaskIntoConstraints = false
        flagButton.setImage(UIImage(named: "DiscoverScreenshotFlag"), for: .normal)
        flagButton.contentEdgeInsets = UIEdgeInsets(top: .padding, left: .padding, bottom: .padding, right: .padding)
        mainView.addSubview(flagButton)
        flagButton.bottomAnchor.constraint(equalTo: mainView.bottomAnchor).isActive = true
        flagButton.trailingAnchor.constraint(equalTo: mainView.trailingAnchor).isActive = true
        
        
        
    }
}
