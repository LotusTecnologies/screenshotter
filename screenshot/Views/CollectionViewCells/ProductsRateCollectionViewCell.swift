//
//  ProductsRateCollectionViewCell.swift
//  screenshot
//
//  Created by Corey Werner on 11/22/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation

class ProductsRateCollectionViewCell : ShadowCollectionViewCell {
    let voteUpButton = UIButton()
    let voteDownButton = UIButton()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .gray3
        label.text = "Are these results relevant?"
        label.font = UIFont.systemFont(ofSize: 20)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        mainView.addSubview(label)
        label.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, for: .horizontal)
        label.topAnchor.constraint(equalTo: mainView.topAnchor).isActive = true
        label.leadingAnchor.constraint(equalTo: mainView.leadingAnchor, constant: .padding).isActive = true
        label.bottomAnchor.constraint(equalTo: mainView.bottomAnchor).isActive = true
        
        setupButton(voteUpButton, withImage: UIImage(named: "ProductsRateUp"))
        voteUpButton.topAnchor.constraint(equalTo: mainView.topAnchor).isActive = true
        voteUpButton.leadingAnchor.constraint(equalTo: label.trailingAnchor).isActive = true
        voteUpButton.bottomAnchor.constraint(equalTo: mainView.bottomAnchor).isActive = true
        
        setupButton(voteDownButton, withImage: UIImage(named: "ProductsRateDown"))
        voteDownButton.topAnchor.constraint(equalTo: mainView.topAnchor).isActive = true
        voteDownButton.leadingAnchor.constraint(equalTo: voteUpButton.trailingAnchor).isActive = true
        voteDownButton.bottomAnchor.constraint(equalTo: mainView.bottomAnchor).isActive = true
        voteDownButton.trailingAnchor.constraint(equalTo: mainView.trailingAnchor).isActive = true
    }
    
    func setupButton(_ button: UIButton, withImage image: UIImage?) {
        let tintImage = image?.withRenderingMode(.alwaysTemplate)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(image, for: .normal)
        button.setImage(tintImage, for: .selected)
        button.setImage(tintImage, for: [.selected, .highlighted])
        button.tintColor = .crazeGreen
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: .padding, bottom: 0, right: .padding)
        button.addTarget(self, action: #selector(selectButton(_:)), for: .touchUpInside)
        mainView.addSubview(button)
        button.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
        
    }
    
    func selectButton(_ button: UIButton) {
        button.isSelected = true
        (button == voteUpButton ? voteDownButton : voteUpButton).isSelected = false
    }
}
