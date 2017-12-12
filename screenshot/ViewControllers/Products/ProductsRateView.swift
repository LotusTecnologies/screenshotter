//
//  ProductsRateView.swift
//  screenshot
//
//  Created by Corey Werner on 12/12/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation

class ProductsRateView : UIView {
    fileprivate let contentView = UIView()
    let voteUpButton = UIButton()
    let voteDownButton = UIButton()
    
    fileprivate let label = UILabel()
    fileprivate var labelTrailingConstraint: NSLayoutConstraint!
    
    var rating: UInt = 0 {
        didSet {
            voteUpButton.isSelected = false
            voteUpButton.isHidden = hasRating
            voteDownButton.isSelected = false
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
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = .green
        addSubview(contentView)
        contentView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        contentView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        contentView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        contentView.heightAnchor.constraint(equalToConstant: intrinsicContentSize.height).isActive = true
        
        setupButton(voteDownButton, withImage: UIImage(named: "ProductsRateDown"))
        voteDownButton.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        voteDownButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        voteDownButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        
        setupButton(voteUpButton, withImage: UIImage(named: "ProductsRateUp"))
        voteUpButton.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        voteUpButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        voteUpButton.trailingAnchor.constraint(equalTo: voteDownButton.leadingAnchor).isActive = true
        
        syncLabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 20)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        contentView.addSubview(label)
        label.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, for: .horizontal)
        label.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: .padding).isActive = true
        label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        
        let labelToVoteTrailingConstraint = label.trailingAnchor.constraint(equalTo: voteUpButton.leadingAnchor)
        labelToVoteTrailingConstraint.priority = UILayoutPriorityDefaultHigh
        labelToVoteTrailingConstraint.isActive = true
        
        labelTrailingConstraint = label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -.padding)
        
        let borderView = UIView()
        borderView.translatesAutoresizingMaskIntoConstraints = false
        borderView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        addSubview(borderView)
        borderView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        borderView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        borderView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        borderView.heightAnchor.constraint(equalToConstant: .halfPoint).isActive = true
    }
    
    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.height = 54
        return size
    }
    
    // MARK: Content
    
    func syncBackgroundColor() {
        contentView.backgroundColor = hasRating ? .crazeGreen : .white
    }
    
    private func syncLabel() {
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
    
    private func setupButton(_ button: UIButton, withImage image: UIImage?) {
        let tintImage = image?.withRenderingMode(.alwaysTemplate)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(image, for: .normal)
        button.setImage(tintImage, for: .selected)
        button.setImage(tintImage, for: [.selected, .highlighted])
        button.tintColor = .crazeGreen
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: .padding, bottom: 0, right: .padding)
        button.addTarget(self, action: #selector(selectButton(_:)), for: .touchUpInside)
        contentView.addSubview(button)
        button.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
    }
    
    @objc private func selectButton(_ button: UIButton) {
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
