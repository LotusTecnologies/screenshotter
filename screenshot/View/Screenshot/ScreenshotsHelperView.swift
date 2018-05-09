//
//  ScreenshotsHelperView.swift
//  screenshot
//
//  Created by Corey Werner on 9/17/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import UIKit

enum ScreenshotsHelperViewType: Int {
    case permission
    case screenshot
}

class ScreenshotsHelperView: HelperView {
    let permissionButton = MainButton()
    let uploadButton = MainButton()
    let discoverButton = MainButton()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        permissionButton.translatesAutoresizingMaskIntoConstraints = false
        permissionButton.setTitle("screenshot.permission.photo.allow".localized, for: .normal)
        
        uploadButton.translatesAutoresizingMaskIntoConstraints = false
        uploadButton.backgroundColor = .crazeGreen
        uploadButton.setTitle("screenshot.empty.upload".localized, for: .normal)
        
        discoverButton.translatesAutoresizingMaskIntoConstraints = false
        discoverButton.backgroundColor = .crazeGreen
        discoverButton.setTitle("screenshot.empty.discover".localized, for: .normal)
        
        syncType()
    }
    
    var type: ScreenshotsHelperViewType = .permission {
        didSet {
            syncType()
        }
    }
    
    fileprivate func syncType() {
        switch type {
        case .permission:
            titleLabel.text = "screenshot.permission.photo.title".localized
            subtitleLabel.text = "screenshot.permission.photo.detail".localized
            contentImage = UIImage(named: "ScreenshotsNoPermissionGraphic")
            removeScreenshotContent()
            insertPermissionControl()
            
        case .screenshot:
            titleLabel.text = "screenshot.empty.title".localized
            subtitleLabel.text = "screenshot.empty.detail".localized
            contentImage = nil
            removePermissionControl()
            insertScreenshotContent()
        }
    }
    
    private func insertPermissionControl() {
        guard permissionButton.superview == nil else {
            return
        }
        
        controlView.addSubview(permissionButton)
        permissionButton.topAnchor.constraint(equalTo: controlView.topAnchor).isActive = true
        permissionButton.bottomAnchor.constraint(equalTo: controlView.bottomAnchor).isActive = true
        permissionButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
    }
    
    private func removePermissionControl() {
        permissionButton.removeFromSuperview()
    }
    
    private func insertScreenshotContent() {
        guard uploadButton.superview == nil else {
            return
        }
        
        contentView.addSubview(uploadButton)
        uploadButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: .extendedPadding).isActive = true
        uploadButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        
        contentView.addSubview(discoverButton)
        discoverButton.topAnchor.constraint(equalTo: uploadButton.bottomAnchor, constant: .extendedPadding).isActive = true
        discoverButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        discoverButton.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor).isActive = true
        discoverButton.widthAnchor.constraint(equalTo: uploadButton.widthAnchor).isActive = true
    }
    
    private func removeScreenshotContent() {
        uploadButton.removeFromSuperview()
        discoverButton.removeFromSuperview()
    }
}
