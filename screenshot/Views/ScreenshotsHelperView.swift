//
//  ScreenshotsHelperView.swift
//  screenshot
//
//  Created by Corey Werner on 9/17/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation

@objc enum ScreenshotsHelperViewType: Int {
    case permission
    case screenshot
}

class ScreenshotsHelperView: HelperView {
    public var type: ScreenshotsHelperViewType = .permission {
        didSet {
            syncType()
        }
    }
    private(set) var button = MainButton()
    private var buttonHeightConstraint: NSLayoutConstraint!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Allow Access", for: .normal)
        controlView.addSubview(button)
        button.topAnchor.constraint(equalTo: controlView.topAnchor).isActive = true
        button.bottomAnchor.constraint(equalTo: controlView.bottomAnchor).isActive = true
        button.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        buttonHeightConstraint = button.heightAnchor.constraint(equalToConstant: 0)
        
        syncType()
    }
    
    private func syncType() {
        if (type == .permission) {
            titleLabel.text = "Shop With CRAZE"
            subtitleLabel.text = "Allow CRAZE to access your screenshots to start shopping!"
            contentImage = UIImage(named: "ScreenshotsNoPermissionGraphic")
            button.isHidden = false
            buttonHeightConstraint.isActive = false
            
        } else if (type == .screenshot) {
            titleLabel.text = "No Screenshots Yet"
            subtitleLabel.text = "Add screenshots you want to shop by pressing the power & home buttons at the same time"
            contentImage = UIImage(named: "ScreenshotsEmptyListGraphic")
            button.isHidden = true
            buttonHeightConstraint.isActive = true
        }
    }
}
