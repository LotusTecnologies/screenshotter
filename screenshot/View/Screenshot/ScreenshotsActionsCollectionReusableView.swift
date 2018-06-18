//
//  ScreenshotsActionsCollectionReusableView.swift
//  screenshot
//
//  Created by Corey Werner on 6/18/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class ScreenshotsActionsCollectionReusableView: UICollectionReusableView {
    // Important for maintaining a smooth transition when hiding the header / footer view
    static let contentHeight: CGFloat = 40
    
    let uploadButton = UIButton()
    let discoverButton = UIButton()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        layoutMargins = .zero
        clipsToBounds = true
        
        let color: UIColor = .crazeGreen
        let highlightedColor = color.darker(by: 12)
        
        uploadButton.translatesAutoresizingMaskIntoConstraints = false
        uploadButton.setTitle("screenshots.actions.upload".localized, for: .normal)
        uploadButton.setTitleColor(color, for: .normal)
        uploadButton.setTitleColor(highlightedColor, for: .highlighted)
        uploadButton.titleLabel?.minimumScaleFactor = 0.7
        uploadButton.titleLabel?.adjustsFontSizeToFitWidth = true
        uploadButton.titleLabel?.baselineAdjustment = .alignCenters
        uploadButton.setImage(UIImage(named: "ScreenshotsActionUpload"), for: .normal)
        uploadButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        uploadButton.isExclusiveTouch = true
        uploadButton.alignImageRight()
        uploadButton.adjustInsetsForImage()
        addSubview(uploadButton)
        uploadButton.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
        uploadButton.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        uploadButton.heightAnchor.constraint(equalToConstant: type(of: self).contentHeight).isActive = true
        uploadButton.trailingAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor).isActive = true
        
        discoverButton.translatesAutoresizingMaskIntoConstraints = false
        discoverButton.setTitle("screenshots.actions.discover".localized, for: .normal)
        discoverButton.setTitleColor(color, for: .normal)
        discoverButton.setTitleColor(highlightedColor, for: .highlighted)
        discoverButton.titleLabel?.minimumScaleFactor = 0.7
        discoverButton.titleLabel?.adjustsFontSizeToFitWidth = true
        discoverButton.titleLabel?.baselineAdjustment = .alignCenters
        discoverButton.setImage(UIImage(named: "ScreenshotsActionPictures"), for: .normal)
        discoverButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        discoverButton.isExclusiveTouch = true
        discoverButton.alignImageRight()
        discoverButton.adjustInsetsForImage()
        addSubview(discoverButton)
        discoverButton.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
        discoverButton.leadingAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor).isActive = true
        discoverButton.heightAnchor.constraint(equalToConstant: type(of: self).contentHeight).isActive = true
        discoverButton.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        let borderView = UIView()
        borderView.translatesAutoresizingMaskIntoConstraints = false
        borderView.backgroundColor = .cellBorder
        borderView.isUserInteractionEnabled = false
        addSubview(borderView)
        borderView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
        borderView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor).isActive = true
        borderView.centerXAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor).isActive = true
        borderView.widthAnchor.constraint(equalToConstant: 1).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
