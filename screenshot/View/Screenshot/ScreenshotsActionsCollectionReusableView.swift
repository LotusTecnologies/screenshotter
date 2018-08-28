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
    
    let uploadButton = BorderButton()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        clipsToBounds = true
        
        uploadButton.translatesAutoresizingMaskIntoConstraints = false
        uploadButton.setTitle("screenshots.actions.upload".localized, for: .normal)
        uploadButton.setTitleColor(.crazeGreen, for: .normal)
        uploadButton.titleLabel?.minimumScaleFactor = 0.7
        uploadButton.titleLabel?.adjustsFontSizeToFitWidth = true
        uploadButton.titleLabel?.baselineAdjustment = .alignCenters
        uploadButton.setImage(UIImage(named: "ScreenshotsActionUpload"), for: .normal)
        uploadButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        uploadButton.isExclusiveTouch = true
        uploadButton.adjustsImageWhenHighlighted = true
        uploadButton.adjustInsetsForImage()
        addSubview(uploadButton)
        uploadButton.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
        uploadButton.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        uploadButton.heightAnchor.constraint(equalToConstant: type(of: self).contentHeight).isActive = true
        uploadButton.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
