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
    
    private let label = UILabel()
    private var labelTrailingConstraint: NSLayoutConstraint!
    
    var rating: UInt = 0 {
        didSet {
            voteUpButton.isHidden = hasRating
            voteDownButton.isHidden = hasRating
            labelTrailingConstraint.isActive = hasRating
            syncLabel()
            syncBackgroundColor()
        }
    }
    var hasRating: Bool {
        return rating > 0
    }
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupButton(voteDownButton, withImage: UIImage(named: "ProductsRateDown"))
        voteDownButton.topAnchor.constraint(equalTo: mainView.topAnchor).isActive = true
        voteDownButton.bottomAnchor.constraint(equalTo: mainView.bottomAnchor).isActive = true
        voteDownButton.trailingAnchor.constraint(equalTo: mainView.trailingAnchor).isActive = true
        
        setupButton(voteUpButton, withImage: UIImage(named: "ProductsRateUp"))
        voteUpButton.topAnchor.constraint(equalTo: mainView.topAnchor).isActive = true
        voteUpButton.bottomAnchor.constraint(equalTo: mainView.bottomAnchor).isActive = true
        voteUpButton.trailingAnchor.constraint(equalTo: voteDownButton.leadingAnchor).isActive = true
        
        syncLabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 20)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        mainView.addSubview(label)
        label.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, for: .horizontal)
        label.topAnchor.constraint(equalTo: mainView.topAnchor).isActive = true
        label.leadingAnchor.constraint(equalTo: mainView.leadingAnchor, constant: .padding).isActive = true
        label.bottomAnchor.constraint(equalTo: mainView.bottomAnchor).isActive = true
        
        let labelToVoteTrailingConstraint = label.trailingAnchor.constraint(equalTo: voteUpButton.leadingAnchor)
        labelToVoteTrailingConstraint.priority = UILayoutPriorityDefaultHigh
        labelToVoteTrailingConstraint.isActive = true
        
        labelTrailingConstraint = label.trailingAnchor.constraint(equalTo: mainView.trailingAnchor, constant: -.padding)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        voteUpButton.isSelected = false
        voteDownButton.isSelected = false
    }
    
    func syncBackgroundColor() {
        if hasRating {
            mainView.backgroundColor = .crazeGreen
            
        } else {
            mainView.backgroundColor = .white
        }
    }
    
    func syncLabel() {
        if hasRating {
            label.textColor = .white
            label.text = "Thanks for your feedback!"
            label.textAlignment = .center
            
        } else {
            label.textColor = .gray3
            label.text = "Are these results relevant?"
            label.textAlignment = .natural
        }
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
        
        if button == voteUpButton {
            voteDownButton.isSelected = false
            rating = 5
            
        } else {
            voteUpButton.isSelected = false
            rating = 1
        }
    }
}
