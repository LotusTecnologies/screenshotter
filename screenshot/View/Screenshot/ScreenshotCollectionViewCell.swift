//
//  ScreenshotCollectionViewCell.swift
//  screenshot
//
//  Created by Corey Werner on 11/7/17.
//  Copyright (c) 2017 crazeapp. All rights reserved.
//

import Foundation
import UIKit

enum ScreenshotCollectionViewCellSelectedState {
    case none
    case checked
    case disabled
}

protocol ScreenshotCollectionViewCellDelegate: NSObjectProtocol {
    func screenshotCollectionViewCellDidTapShare(_ cell: ScreenshotCollectionViewCell)
}

class ScreenshotCollectionViewCell: ShadowCollectionViewCell {
    weak var delegate: ScreenshotCollectionViewCellDelegate?
    
    let imageView = UIImageView()
    fileprivate let shopLabel = UILabel()
    private let badge = UIView()
    private let checkImageView = UIImageView(image: UIImage(named: "PickerCheckRed"))
    private var shamrockView:UIView?
    private var likesCountView:UIView?
    fileprivate let shareButton = UIButton()
    
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
        
        shopLabel.translatesAutoresizingMaskIntoConstraints = false
        shopLabel.text = "screenshot.shop".localized
        shopLabel.textAlignment = .center
        shopLabel.backgroundColor = .white
        shopLabel.font = .screenshopFont(.hindSemibold, size: 16)
        shopLabel.textColor = .gray5
        mainView.addSubview(shopLabel)
        shopLabel.leadingAnchor.constraint(equalTo: mainView.leadingAnchor).isActive = true
        shopLabel.bottomAnchor.constraint(equalTo: mainView.bottomAnchor).isActive = true
        shopLabel.trailingAnchor.constraint(equalTo: mainView.trailingAnchor).isActive = true
        shopLabel.heightAnchor.constraint(equalToConstant: 38).isActive = true
        
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
        
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        shareButton.setImage(UIImage(named: "ScreenshotShare"), for: .normal)
        shareButton.addTarget(self, action: #selector(shareAction), for: .touchUpInside)
        mainView.addSubview(shareButton)
        shareButton.topAnchor.constraint(equalTo: mainView.layoutMarginsGuide.topAnchor).isActive = true
        shareButton.trailingAnchor.constraint(equalTo: mainView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        checkImageView.translatesAutoresizingMaskIntoConstraints = false
        checkImageView.alpha = 0
        checkImageView.contentMode = .scaleAspectFit
        mainView.addSubview(checkImageView)
        checkImageView.topAnchor.constraint(equalTo: mainView.topAnchor, constant: 6).isActive = true
        checkImageView.trailingAnchor.constraint(equalTo: mainView.trailingAnchor, constant: -6).isActive = true
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        isEditing = false
        isBadgeEnabled = false
        selectedState = .none
        isShamrock = false
        likes = nil
    }
    
    // MARK: Screenshot
    
    var screenshot: Screenshot? {
        didSet {
            // If the screenshot object does not have imageData but does have a URL, go fetch async then callback
            if let screenshot = screenshot, screenshot.imageData == nil, let i = screenshot.uploadedImageURL {
                DispatchQueue.global().async {
                    if let url = URL(string: i) {
                        if let data = try? Data(contentsOf: url) {
                            screenshot.imageData = data
                        }
                    }
                    DispatchQueue.main.async {
                        self.setScreenshot(screenshot: screenshot)
                    }
                }
            } else {
                setScreenshot(screenshot: screenshot)
            }
        }
    }
    
    func setScreenshot(screenshot: Screenshot?) {
        //Since this can be called asynchonously (if image needs to be downloaded - lines 110-119) and the screenshot associated with the cell may have changed by the time we make the callback, we need to check that the screenshot we fetched for is still valid (i.e. the screenshot variable associated with the view cell equals the one passed into the callback)
        if self.screenshot?.screenshotId != screenshot?.screenshotId {
            return
        }
        
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
            Analytics.trackDevLog(file: NSString(string: #file).lastPathComponent, line: #line, message: "blank screenshot")
        }
    }
    
    // MARK: States
    
    private func createShamrockViewIfNeeded() {
        if self.shamrockView == nil {
            let shamrackImageView = UIImageView.init(image: UIImage(named: "ShamrockBadge"))
            shamrackImageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.addSubview(shamrackImageView)
            shamrackImageView.topAnchor.constraint(equalTo: mainView.topAnchor).isActive = true
            shamrackImageView.leadingAnchor.constraint(equalTo: mainView.leadingAnchor).isActive = true
            shamrackImageView.widthAnchor.constraint(equalToConstant: 58).isActive = true
            shamrackImageView.heightAnchor.constraint(equalToConstant: 60).isActive = true
            
            self.shamrockView = shamrackImageView
        }
    }
    
    private func createLikeCountViewIfNeeded() {
        if self.likesCountView == nil {
            let view = UIView.init()
            view.backgroundColor = .white
            view.layer.cornerRadius = 15
            view.layer.borderColor = UIColor.gray6.cgColor
            view.layer.borderWidth = .halfPoint
            view.translatesAutoresizingMaskIntoConstraints = false
            self.mainView.addSubview(view)
            view.topAnchor.constraint(equalTo: mainView.topAnchor, constant:8).isActive = true
            view.leadingAnchor.constraint(equalTo: mainView.leadingAnchor, constant:10).isActive = true
            view.heightAnchor.constraint(equalToConstant: 32).isActive = true
            
            let imageView = UIImageView.init(image: UIImage.init(named: "likeButtonSmallGreen"))
            imageView.contentMode = .scaleAspectFit
            imageView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(imageView)
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant:10).isActive = true
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
            imageView.widthAnchor.constraint(equalToConstant: 20.0).isActive = true
            imageView.heightAnchor.constraint(equalToConstant: 18).isActive = true
            
            let label = UILabel.init()
            label.textColor = .crazeGreen
            label.tag = 100
            label.textAlignment = .center
            label.text = ""
            label.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(label)
            label.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant:5).isActive = true
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant:-10).isActive = true
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
            
            self.likesCountView = view
        }
    }
    
    var selectedState: ScreenshotCollectionViewCellSelectedState = .none {
        didSet {
            syncSelectedState()
        }
    }
    
    fileprivate func resetSelectedState() {
        imageView.alpha = 1
        badge.alpha = 1
        shopLabel.alpha = isEditing ? 0 : 1
        likesCountView?.alpha = isEditing ? 0 : 1
        shareButton.alpha = isEditing ? 0 : 1
        checkImageView.alpha = 0
        isUserInteractionEnabled = true
    }
    
    fileprivate func syncSelectedState() {
        guard isSelected else {
            return
        }
        
        let alpha: CGFloat = isEditing ? 0 : 0.5
        
        switch selectedState {
        case .none:
            resetSelectedState()
            
        case .checked:
            imageView.alpha = 0.5
            badge.alpha = 0.5
            shopLabel.alpha = alpha
            likesCountView?.alpha = alpha
            shareButton.alpha = alpha
            checkImageView.alpha = 1
            isUserInteractionEnabled = true
            
        case .disabled:
            imageView.alpha = 0.5
            badge.alpha = 0.5
            shopLabel.alpha = alpha
            likesCountView?.alpha = alpha
            shareButton.alpha = alpha
            checkImageView.alpha = 0
            isUserInteractionEnabled = false
        }
    }
    
    var isShamrock:Bool = false {
        didSet {
            if isShamrock {
                createShamrockViewIfNeeded()
            }
            self.shamrockView?.isHidden = !isShamrock
        }
    }
    override var isSelected: Bool {
        didSet {
            isSelected ? syncSelectedState() : resetSelectedState()
        }
    }
    
    var isEditing = false {
        didSet {
            shopLabel.alpha = isEditing ? 0 : 1
            likesCountView?.alpha = isEditing ? 0 : 1
            shareButton.alpha = isEditing ? 0 : 1
        }
    }
    
    var likes : Int?  = nil {
        didSet{
            if let likesCount = likes, likesCount > 0 {
                self.createLikeCountViewIfNeeded()
                self.likesCountView?.isHidden = false
                if let label = self.likesCountView?.viewWithTag(100) as? UILabel{
                    label.text = String(likesCount)
                }
                
            }else{
                self.likesCountView?.isHidden = true
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
    
    @objc func shareAction() {
        delegate?.screenshotCollectionViewCellDidTapShare(self)
    }
}
