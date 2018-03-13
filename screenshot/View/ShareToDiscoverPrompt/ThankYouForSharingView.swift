//
//  ThankYouForSharingView.swift
//  screenshot
//
//  Created by Jonathan Rose on 3/13/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation
import UIKit

protocol ThankYouForSharingViewProtocol {
    func thankYouForSharingViewDidClose(_ view:ThankYouForSharingView)
}
class ThankYouForSharingView : UIView {
    
    var delegate:ThankYouForSharingViewProtocol?
    
    private let title:UILabel
    private let message:UILabel
    private let containerView:UIView

    override init(frame: CGRect) {
        
        containerView = UIView.init()
        title = UILabel.init()
        message = UILabel.init()
        let closeButton = UIButton.init()

        super.init(frame: frame)

        containerView.isUserInteractionEnabled = true
        containerView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(containerView)

        containerView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant:20).isActive = true
        containerView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant:-20).isActive = true
        
        self.topAnchor.constraint(equalTo: containerView.topAnchor, constant:-20).isActive = true
        self.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant:20).isActive = true

        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = .defaultCornerRadius
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowRadius = 3
        containerView.layer.shadowOpacity = 0.5
        containerView.layer.borderColor = UIColor.black.cgColor
        containerView.layer.borderWidth = 1.0
        
        title.text = "share_to_discover.thank_you_popup.title".localized
        title.textAlignment = .center
        title.numberOfLines = 2
        title.font = UIFont.init(name: "Hind", size: 25)
        title.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(title)
        title.topAnchor.constraint(equalTo: containerView.topAnchor, constant:20).isActive = true
        title.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant:20).isActive = true
        title.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant:-20).isActive = true

        
        title.numberOfLines = 2
        message.text = "share_to_discover.thank_you_popup.message".localized
        message.textAlignment = .center
        message.textColor = .crazeGreen
        message.font = UIFont.init(name: "Hind", size: 18)
        message.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(message)
        message.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 20).isActive =  true
        message.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant:20).isActive = true
        message.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant:-20).isActive = true
        
        let image = UIImage.init(named: "ThumbsUpBanner")
        let thumbsUpBanner = UIImageView.init(image: image)
        thumbsUpBanner.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(thumbsUpBanner)
        thumbsUpBanner.topAnchor.constraint(equalTo: message.bottomAnchor, constant: 20).isActive = true
        thumbsUpBanner.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant:20).isActive = true
        thumbsUpBanner.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant:20).isActive = true
        var multipler:CGFloat = 0.1
        if let image = image {
            multipler = (image.size.height / image.size.width)
        }
        
        thumbsUpBanner.heightAnchor.constraint(equalTo: thumbsUpBanner.widthAnchor, multiplier: multipler).isActive = true


        closeButton.setTitle("generic.close".localized, for: .normal)
        closeButton.backgroundColor = .crazeRed
        closeButton.isUserInteractionEnabled = true
        closeButton.showsTouchWhenHighlighted = true
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.layer.cornerRadius = .defaultCornerRadius
        closeButton.addTarget(self, action: #selector(didClose(_:)), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(closeButton)
        closeButton.topAnchor.constraint(equalTo: thumbsUpBanner.bottomAnchor, constant: 20).isActive = true
        closeButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
        closeButton.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.5).isActive = true
        closeButton.heightAnchor.constraint(equalToConstant: 50.0).isActive = true

        containerView.bottomAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 20)

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @IBAction func didClose(_ sender:Any) {
        self.delegate?.thankYouForSharingViewDidClose(self)
    }
    
    override func layoutSubviews() {
        title.preferredMaxLayoutWidth = containerView.bounds.size.width - 40
        message.preferredMaxLayoutWidth = containerView.bounds.size.width - 40
        self.setNeedsUpdateConstraints()
    }
    
    
}
