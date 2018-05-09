//
//  DiscoverScreenshotCollectionViewCell.swift
//  screenshot
//
//  Created by Corey Werner on 1/9/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation
import UIKit

class DiscoverScreenshotCollectionViewCell : ShadowCollectionViewCell {
    let imageView = UIImageView()
    let flagButton = UIButton()
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.image = UIImage(named: "TutorialScreenshot") // TODO: change with real screenshot image
        mainView.addSubview(imageView)
        imageView.topAnchor.constraint(equalTo: mainView.topAnchor).isActive = true
        imageView.leadingAnchor.constraint(equalTo: mainView.leadingAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: mainView.bottomAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: mainView.trailingAnchor).isActive = true
        
        flagButton.translatesAutoresizingMaskIntoConstraints = false
        flagButton.setImage(UIImage(named: "DiscoverScreenshotFlag"), for: .normal)
        flagButton.contentEdgeInsets = UIEdgeInsets(top: .padding, left: .padding, bottom: .padding, right: .padding)
        mainView.addSubview(flagButton)
        flagButton.bottomAnchor.constraint(equalTo: mainView.bottomAnchor).isActive = true
        flagButton.trailingAnchor.constraint(equalTo: mainView.trailingAnchor).isActive = true
        
        decisionView.translatesAutoresizingMaskIntoConstraints = false
        decisionView.alpha = 0
        decisionView.isUserInteractionEnabled = false
        mainView.addSubview(decisionView)
        decisionView.topAnchor.constraint(equalTo: mainView.topAnchor).isActive = true
        decisionView.leadingAnchor.constraint(equalTo: mainView.leadingAnchor).isActive = true
        decisionView.bottomAnchor.constraint(equalTo: mainView.bottomAnchor).isActive = true
        decisionView.trailingAnchor.constraint(equalTo: mainView.trailingAnchor).isActive = true
        
        decisionImageView.translatesAutoresizingMaskIntoConstraints = false
        decisionImageView.contentMode = .scaleAspectFit
        decisionImageView.image = UIImage(named: "DiscoverScreenshotX")
        decisionImageView.highlightedImage = UIImage(named: "DiscoverScreenshotCheck")
        decisionView.addSubview(decisionImageView)
        decisionImageView.centerXAnchor.constraint(equalTo: decisionView.centerXAnchor).isActive = true
        NSLayoutConstraint(item: decisionImageView, attribute: .centerY, relatedBy: .equal, toItem: decisionView, attribute: .centerY, multiplier: 1.5, constant: 0).isActive = true
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        decisionValue = 0
    }
    
    // MARK: Decision
    
    fileprivate let decisionView = UIView()
    fileprivate let decisionImageView = UIImageView()
    
    /// 1 = add, 0 = hide, -1 = remove
    var decisionValue: CGFloat = 0 {
        didSet {
            let value = min(1, max(-1, decisionValue))
            
            decisionView.alpha = abs(value)
            
            if value > 0 {
                decisionView.backgroundColor = UIColor.crazeGreen.withAlphaComponent(0.75)
                decisionImageView.isHighlighted = true
                
            } else if value < 0 {
                decisionView.backgroundColor = UIColor.black.withAlphaComponent(0.75)
                decisionImageView.isHighlighted = false
            }
        }
    }
    
    // MARK: Image
    
    var image: UIImage? {
        set {
            imageView.image = newValue
        }
        get {
            return imageView.image
        }
    }
}
