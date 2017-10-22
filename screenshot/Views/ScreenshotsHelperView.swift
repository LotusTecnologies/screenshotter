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
    private var imageView: UIImageView!
    private(set) public var button: MainButton!
    
    private var typeConstraints: [ScreenshotsHelperViewType: [NSLayoutConstraint]]!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageView = UIImageView.init()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        contentView.addSubview(imageView)
        imageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        
        button = MainButton.init(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Allow Access", for: .normal)
        contentView.addSubview(button)
        button.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 40).isActive = true
        button.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor).isActive = true
        button.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        
        typeConstraints = [
            .permission: [
                imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Geometry.padding)
            ],
            .screenshot: [
                imageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
            ]
        ]
        
        syncType()
    }
    
    private func syncType() {
        if let permissionConstraints = typeConstraints[.permission], let screenshotConstraints = typeConstraints[.screenshot] {
            if (type == .permission) {
                titleLabel.text = "Shop With CRAZE"
                subtitleLabel.text = "Allow CRAZE to access your screenshots to start shopping!"
                imageView.image = UIImage.init(named: "ScreenshotsNoPermissionGraphic")
                button.isHidden = false
                
                NSLayoutConstraint.deactivate(screenshotConstraints)
                NSLayoutConstraint.activate(permissionConstraints)
                
            } else if (type == .screenshot) {
                titleLabel.text = "No Screenshots Yet"
                subtitleLabel.text = "Add screenshots you want to shop by pressing the power & home buttons at the same time"
                imageView.image = UIImage.init(named: "ScreenshotsEmptyListGraphic")
                button.isHidden = true
                
                NSLayoutConstraint.deactivate(permissionConstraints)
                NSLayoutConstraint.activate(screenshotConstraints)
            }
        }
    }
}
