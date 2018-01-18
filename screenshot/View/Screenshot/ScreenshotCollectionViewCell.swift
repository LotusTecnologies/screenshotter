//
//  ScreenshotCollectionViewCell.swift
//  screenshot
//
//  Created by Corey Werner on 11/7/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation

@objc protocol ScreenshotCollectionViewCellDelegate: NSObjectProtocol {
    func screenshotCollectionViewCellDidTapShare(_ cell: ScreenshotCollectionViewCell)
    func screenshotCollectionViewCellDidTapDelete(_ cell: ScreenshotCollectionViewCell)
}

class ScreenshotCollectionViewCell: ShadowCollectionViewCell {
    weak var delegate: ScreenshotCollectionViewCellDelegate?
    
    private let imageView = UIImageView()
    private let toolbar = UIToolbar()
    private let badge = UIView()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layoutMargins = .zero
        mainView.addSubview(imageView)
        imageView.layoutMarginsGuide.topAnchor.constraint(equalTo: mainView.topAnchor).isActive = true
        imageView.layoutMarginsGuide.leadingAnchor.constraint(equalTo: mainView.leadingAnchor).isActive = true
        imageView.layoutMarginsGuide.bottomAnchor.constraint(equalTo: mainView.bottomAnchor).isActive = true
        imageView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: mainView.trailingAnchor).isActive = true
        
        let shareButtonItem = UIBarButtonItem(title: "screenshot.option.share".localized, style: .plain, target: self, action: #selector(shareAction))
        let deleteButtonItem = UIBarButtonItem(title: "screenshot.option.delete".localized, style: .plain, target: self, action: #selector(deleteAction))
        let flexilbeItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        // Even though this is set globally, it is possible to hit a race condition
        // where the first cell has the wrong font. This will force the font.
        let toolbarButtonItem = UIBarButtonItem.appearance(whenContainedInInstancesOf: [UIToolbar.self])
        let titleTextAttributesNormal = toolbarButtonItem.titleTextAttributes(for: .normal)
        let titleTextAttributesHighlighted = toolbarButtonItem.titleTextAttributes(for: .highlighted)
        let titleTextAttributesDisabled = toolbarButtonItem.titleTextAttributes(for: .disabled)
        
        shareButtonItem.setTitleTextAttributes(titleTextAttributesNormal, for: .normal)
        shareButtonItem.setTitleTextAttributes(titleTextAttributesHighlighted, for: .highlighted)
        shareButtonItem.setTitleTextAttributes(titleTextAttributesDisabled, for: .disabled)
        
        deleteButtonItem.setTitleTextAttributes(titleTextAttributesNormal, for: .normal)
        deleteButtonItem.setTitleTextAttributes(titleTextAttributesHighlighted, for: .highlighted)
        deleteButtonItem.setTitleTextAttributes(titleTextAttributesDisabled, for: .disabled)
        
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.backgroundColor = UIColor(white: 1, alpha: 0.9)
        toolbar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
        toolbar.tintColor = .gray3
        toolbar.items = [shareButtonItem, flexilbeItem, deleteButtonItem]
        mainView.addSubview(toolbar)
        toolbar.leadingAnchor.constraint(equalTo: mainView.leadingAnchor).isActive = true
        toolbar.bottomAnchor.constraint(equalTo: mainView.bottomAnchor).isActive = true
        toolbar.trailingAnchor.constraint(equalTo: mainView.trailingAnchor).isActive = true
        
        badge.frame = CGRect(x: 0, y: 0, width: 28, height: 28)
        badge.translatesAutoresizingMaskIntoConstraints = false
        badge.backgroundColor = .crazeRed
        badge.isUserInteractionEnabled = false
        badge.isHidden = true
        badge.transform = CGAffineTransform(rotationAngle: .pi / 4)
        badge.layer.shadowPath = UIBezierPath(rect: badge.bounds).cgPath
        badge.layer.shadowColor = UIColor.black.cgColor
        badge.layer.shadowOffset = CGSize(width: 0, height: 1)
        badge.layer.shadowRadius = 2
        badge.layer.shadowOpacity = 0.4
        mainView.addSubview(badge)
        badge.topAnchor.constraint(equalTo: mainView.topAnchor, constant: -badge.bounds.size.height / 2).isActive = true
        badge.trailingAnchor.constraint(equalTo: mainView.trailingAnchor, constant: badge.bounds.size.width / 2).isActive = true
        badge.widthAnchor.constraint(equalToConstant: badge.bounds.size.width).isActive = true
        badge.heightAnchor.constraint(equalToConstant: badge.bounds.size.height).isActive = true
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        isEnabled = true
    }
    
    // MARK: Screenshot
    
    var screenshot: Screenshot? {
        didSet {
            if let screenshot = screenshot, let data = screenshot.imageData as Data? {
                let size = bounds.size
                let rect = screenshot.shoppablesBoundingFrame(in: size)
                
                if rect.isNull {
                    // When there's no shoppables, scale the image by 110%
                    let scaleRatio = CGFloat(0.1)
                    let scaleSize = CGSize(width: size.width * scaleRatio, height: size.height * scaleRatio)
                    
                    imageView.layoutMargins = UIEdgeInsets(top: scaleSize.height, left: scaleSize.width, bottom: scaleSize.height, right: scaleSize.width)
                    
                } else {
                    // Use the shoppables to display the outer bounding rect
                    imageView.layoutMargins = UIEdgeInsets(top: rect.origin.y, left: rect.origin.x, bottom: size.height - rect.maxY, right: size.width - rect.maxX)
                }
                
                imageView.image = UIImage(data: data)
                
            } else {
                imageView.image = nil
            }
        }
    }
    
    // MARK: Enabled
    
    var isEnabled: Bool = true {
        didSet {
            if isEnabled {
                isUserInteractionEnabled = true
                contentView.alpha = 1
                
            } else {
                isUserInteractionEnabled = false
                contentView.alpha = 0.5
            }
        }
    }
    
    // MARK: Badge
    
    var isBadgeEnabled: Bool {
        set {
            badge.isHidden = !newValue
        }
        get {
            return !badge.isHidden
        }
    }
    
    // MARK: Actions
    
    func shareAction() {
        delegate?.screenshotCollectionViewCellDidTapShare(self)
    }
    
    func deleteAction() {
        delegate?.screenshotCollectionViewCellDidTapDelete(self)
    }
}
