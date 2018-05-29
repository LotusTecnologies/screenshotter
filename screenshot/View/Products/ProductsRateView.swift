//
//  ProductsRateView.swift
//  screenshot
//
//  Created by Corey Werner on 12/12/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation
import UIKit

class ProductsRateView : UIView {
    fileprivate let contentView = UIView()
    let voteUpButton = UIButton()
    let voteDownButton = UIButton()

    fileprivate let label = UILabel()
    fileprivate var labelTrailingConstraint: NSLayoutConstraint!
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        contentView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        contentView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        contentView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        contentView.heightAnchor.constraint(equalToConstant: intrinsicContentSize.height).isActive = true
        
        setupButton(voteDownButton, withImage: UIImage(named: "ProductsRateDown"))
        voteDownButton.tintColor = .crazeRed
        voteDownButton.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        voteDownButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        voteDownButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        
        setupButton(voteUpButton, withImage: UIImage(named: "ProductsRateUp"))
        voteUpButton.tintColor = .crazeGreen
        voteUpButton.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        voteUpButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        voteUpButton.trailingAnchor.constraint(equalTo: voteDownButton.leadingAnchor).isActive = true
        
        syncLabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 20)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        label.baselineAdjustment = .alignCenters
        contentView.addSubview(label)
        label.setContentCompressionResistancePriority(UILayoutPriority.defaultLow, for: .horizontal)
        label.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: .padding).isActive = true
        label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        
        let labelToVoteTrailingConstraint = label.trailingAnchor.constraint(equalTo: voteUpButton.leadingAnchor)
        labelToVoteTrailingConstraint.priority = UILayoutPriority.defaultHigh
        labelToVoteTrailingConstraint.isActive = true
        
        labelTrailingConstraint = label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -.padding)
        
        addSubview(BorderView(edge: .top))

        
        weak var weakSelf = self
        NotificationCenter.default.addObserver(forName: Notification.Name.InAppPurchaseManagerDidUpdate, object: nil, queue: .main) { (notification) in
            DispatchQueue.main.async {
                if let strongWeakSelf = weakSelf {
                    let rating  = strongWeakSelf.rating
                    strongWeakSelf.setRating(rating)
                }
            }
            
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.height = 49 // Same height as tab bar
        return size
    }
    
    // MARK: Content
    
    func syncBackgroundColor() {
        if InAppPurchaseManager.sharedInstance.isInProcessOfBuying() {
            backgroundColor = .crazeGreen
        } else if hasRating {
            if InAppPurchaseManager.sharedInstance.didPurchase(_inAppPurchaseProduct: .personalStylist){
                backgroundColor = .crazeGreen
            }else{
                 backgroundColor = .crazeGreen
            }
        }else{
             backgroundColor = .white
        }
    }
    
    private func syncLabel() {
       if hasRating {
            if InAppPurchaseManager.sharedInstance.didPurchase(_inAppPurchaseProduct: .personalStylist){
                label.textColor = .white
                label.text = "products.rate.talk_to_stylist".localized
                label.textAlignment = .center
                
            }else{
                label.textColor = .white
                label.text = "products.rate.rated".localized
                label.textAlignment = .center
            }
            
        } else {
            label.textColor = .gray3
            label.text = "products.rate.unrated".localized
            label.textAlignment = .natural
        }
    }
    
    private func setupButton(_ button: UIButton, withImage image: UIImage?) {
        let tintImage = image?.withRenderingMode(.alwaysTemplate)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(image, for: .normal)
        button.setImage(tintImage, for: .selected)
        button.setImage(tintImage, for: [.selected, .highlighted])
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: .padding, bottom: 0, right: .padding)
        button.addTarget(self, action: #selector(selectButton(_:)), for: .touchUpInside)
        contentView.addSubview(button)
        button.setContentCompressionResistancePriority(UILayoutPriority.required, for: .horizontal)
    }
    
    @objc private func selectButton(_ button: UIButton) {
        button.isSelected = true
        
        if button == voteUpButton {
            voteDownButton.isSelected = false
            setRating(5, animated: true)
            
        } else {
            voteUpButton.isSelected = false
            setRating(1, animated: true)
        }
    }
    
    // MARK: Rating
    
    private(set) var rating: UInt = 0
    
    var hasRating: Bool {
        return rating > 0
    }
    
    func setRating(_ rating: UInt, animated: Bool = false) {
        self.rating = rating
        if InAppPurchaseManager.sharedInstance.isInProcessOfBuying() {
            voteUpButton.isSelected = false
            voteDownButton.isSelected = false
            voteUpButton.alpha = 0
            voteDownButton.alpha = 0
            labelTrailingConstraint.isActive = true
            syncLabel()
            syncBackgroundColor()
        }else if animated && hasRating {
            let duration: TimeInterval = .defaultAnimationDuration
            
            UIView.animate(withDuration: duration, animations: {
                self.voteUpButton.alpha = 0
                self.voteDownButton.alpha = 0
                self.label.alpha = 0
            }, completion: { finished in
                // Can't use key frames animation since we're setting the labels text
                
                UIView.animate(withDuration: duration, animations: {
                    self.label.alpha = 1
                    self.labelTrailingConstraint.isActive = self.hasRating
                    self.syncLabel()
                    self.syncBackgroundColor()
                    self.layoutIfNeeded()
                })
                
                self.voteUpButton.isSelected = false
                self.voteDownButton.isSelected = false
            })
            
        } else {
            voteUpButton.isSelected = false
            voteDownButton.isSelected = false
            voteUpButton.alpha = self.hasRating ? 0 : 1
            voteDownButton.alpha = self.hasRating ? 0 : 1
            labelTrailingConstraint.isActive = hasRating
            syncLabel()
            syncBackgroundColor()
        }
    }
}
