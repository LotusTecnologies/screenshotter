//
//  NotificationPromptViewController.swift
//  screenshot
//
//  Created by Corey Werner on 5/14/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class NotificationPromptView: UIView {
    let notificationButton = BorderButton()
    let cancelButton = UIButton()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let backgroundImageView = UIImageView(image: UIImage(named: "BrandGradientBackground"))
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        backgroundImageView.contentMode = .scaleToFill
        addSubview(backgroundImageView)
        backgroundImageView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        backgroundImageView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        backgroundImageView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        backgroundImageView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.font = .screenshopFont(.hindSemibold, textStyle: .title1)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 0
        titleLabel.text = "notification.prompt.title".localized
        addSubview(titleLabel)
        titleLabel.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        let embossedView = EmbossedView()
        embossedView.translatesAutoresizingMaskIntoConstraints = false
        embossedView.imageView.image = UIImage(named: "NotificationProduct")
        embossedView.contentMode = .scaleAspectFit
        addSubview(embossedView)
        embossedView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: .extendedPadding).isActive = true
        embossedView.centerXAnchor.constraint(equalTo: titleLabel.centerXAnchor).isActive = true
        
        let detailLabel = UILabel()
        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        detailLabel.textColor = .white
        detailLabel.textAlignment = .center
        detailLabel.font = .screenshopFont(.hindSemibold, textStyle: .subheadline)
        detailLabel.adjustsFontForContentSizeCategory = true
        detailLabel.numberOfLines = 0
        detailLabel.text = "notification.prompt.detail".localized
        addSubview(detailLabel)
        detailLabel.topAnchor.constraint(equalTo: embossedView.bottomAnchor, constant: .padding).isActive = true
        detailLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        detailLabel.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.setTitle("generic.later".localized, for: .normal)
        addSubview(cancelButton)
        cancelButton.leadingAnchor.constraint(greaterThanOrEqualTo: layoutMarginsGuide.leadingAnchor).isActive = true
        cancelButton.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor).isActive = true
        cancelButton.trailingAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.trailingAnchor).isActive = true
        cancelButton.centerXAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor).isActive = true
        
        notificationButton.translatesAutoresizingMaskIntoConstraints = false
        notificationButton.setTitle("notification.prompt.continue".localized, for: .normal)
        notificationButton.setTitleColor(.white, for: .normal)
        addSubview(notificationButton)
        notificationButton.topAnchor.constraint(greaterThanOrEqualTo: detailLabel.bottomAnchor, constant: .padding).isActive = true
        notificationButton.leadingAnchor.constraint(greaterThanOrEqualTo: layoutMarginsGuide.leadingAnchor).isActive = true
        notificationButton.bottomAnchor.constraint(equalTo: cancelButton.topAnchor, constant: -.padding).isActive = true
        notificationButton.trailingAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.trailingAnchor).isActive = true
        notificationButton.centerXAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor).isActive = true
        notificationButton.widthAnchor.constraint(equalTo: cancelButton.widthAnchor).isActive = true
        
        let confettiImageView = UIImageView(image: UIImage(named: "BrandConfettiLightCenter"))
        confettiImageView.translatesAutoresizingMaskIntoConstraints = false
        confettiImageView.contentMode = .scaleAspectFill
        insertSubview(confettiImageView, aboveSubview: backgroundImageView)
        confettiImageView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        confettiImageView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        confettiImageView.centerYAnchor.constraint(equalTo: embossedView.centerYAnchor).isActive = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let margin = UIDevice.is480h ? .extendedPadding / 2 : .extendedPadding
        layoutMargins = UIEdgeInsets(top: margin, left: margin, bottom: margin, right: margin)
    }
}

class NotificationPromptViewController: UIViewController {
    private var _view: NotificationPromptView {
        return view as! NotificationPromptView
    }
    
    var notificationButton: UIButton {
        return _view.notificationButton
    }
    
    var cancelButton: UIButton {
        return _view.cancelButton
    }
    
    override func loadView() {
        view = NotificationPromptView()
    }
}
