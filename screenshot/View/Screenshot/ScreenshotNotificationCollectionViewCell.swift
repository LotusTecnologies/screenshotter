//
//  ScreenshotNotificationCollectionViewCell.swift
//  screenshot
//
//  Created by Corey Werner on 11/7/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation
import UIKit

enum ScreenshotNotificationCollectionViewCellContentType {
    case labelWithButtons
}

enum ScreenshotNotificationCollectionViewCellContentText {
    case none
    case importSingleScreenshot
    case importMultipleScreenshots
    case importVeryManyScreenshots
}

@objc protocol ScreenshotNotificationCollectionViewCellDelegate: NSObjectProtocol {
    @objc optional func screenshotNotificationCollectionViewCellDidTapReject(_ cell: ScreenshotNotificationCollectionViewCell)
    @objc optional func screenshotNotificationCollectionViewCellDidTapConfirm(_ cell: ScreenshotNotificationCollectionViewCell)
}

class ScreenshotNotificationCollectionViewCell: ShadowCollectionViewCell {
    weak var delegate: ScreenshotNotificationCollectionViewCellDelegate?
    
    private let iconImageView = UIImageView()
    private let tempContentView = UIView()
    private var tempContentViewToIconConstraint: NSLayoutConstraint!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        mainView.layoutMargins = type(of: self).mainViewLayoutMargins
        
        let verPadding = mainView.layoutMargins.top / 2
        
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.isHidden = true
        mainView.addSubview(iconImageView)
        iconImageView.setContentCompressionResistancePriority(UILayoutPriority.required, for: .horizontal)
        iconImageView.topAnchor.constraint(equalTo: mainView.layoutMarginsGuide.topAnchor, constant: -verPadding).isActive = true
        iconImageView.leadingAnchor.constraint(equalTo: mainView.layoutMarginsGuide.leadingAnchor).isActive = true
        iconImageView.bottomAnchor.constraint(equalTo: mainView.layoutMarginsGuide.bottomAnchor, constant: verPadding).isActive = true
        iconImageView.widthAnchor.constraint(equalToConstant: type(of: self).iconWidth).isActive = true
        
        tempContentView.translatesAutoresizingMaskIntoConstraints = false
        mainView.addSubview(tempContentView)
        tempContentView.topAnchor.constraint(equalTo: mainView.layoutMarginsGuide.topAnchor).isActive = true
        tempContentView.bottomAnchor.constraint(equalTo: mainView.layoutMarginsGuide.bottomAnchor).isActive = true
        tempContentView.trailingAnchor.constraint(equalTo: mainView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        let tempContentViewLeadingConstraint = tempContentView.leadingAnchor.constraint(equalTo: mainView.layoutMarginsGuide.leadingAnchor)
        tempContentViewLeadingConstraint.priority = UILayoutPriority.defaultHigh
        tempContentViewLeadingConstraint.isActive = true
        
        tempContentViewToIconConstraint = tempContentView.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: mainView.layoutMargins.left)
    }
    
    fileprivate static let mainViewLayoutMargins = UIEdgeInsets(top: .padding, left: .padding, bottom: .padding, right: .padding)
    
    // MARK: Content Type
    
    func setContentType(_ contentType: ScreenshotNotificationCollectionViewCellContentType) {
        removeContentType()
        
        switch contentType {
        case .labelWithButtons:
            insertContentTypeLabelWithButtons()
            break
        }
    }
    
    private func removeContentType() {
        tempContentView.subviews.forEach { subview in
            subview.removeFromSuperview()
        }
    }
    
    private func insertContentTypeLabelWithButtons() {
        guard let label = tempContentLabel else {
            return
        }
        
        label.translatesAutoresizingMaskIntoConstraints = false
        tempContentView.addSubview(label)
        label.topAnchor.constraint(equalTo: tempContentView.topAnchor).isActive = true
        label.leadingAnchor.constraint(equalTo: tempContentView.leadingAnchor).isActive = true
        label.trailingAnchor.constraint(equalTo: tempContentView.trailingAnchor).isActive = true
        
        let borderView = UIView()
        borderView.translatesAutoresizingMaskIntoConstraints = false
        borderView.backgroundColor = .border
        tempContentView.addSubview(borderView)
        borderView.topAnchor.constraint(equalTo: label.bottomAnchor, constant: type(of: self).mainViewLayoutMargins.top).isActive = true
        borderView.bottomAnchor.constraint(equalTo: tempContentView.bottomAnchor).isActive = true
        borderView.widthAnchor.constraint(equalToConstant: 1).isActive = true
        borderView.centerXAnchor.constraint(equalTo: tempContentView.centerXAnchor).isActive = true
        
        var buttonFont = UIFont.preferredFont(forTextStyle: .body)
        
        if let descriptor = buttonFont.fontDescriptor.withSymbolicTraits(.traitBold) {
            buttonFont = UIFont(descriptor: descriptor, size: 0)
        }
        
        let rejectButton = UIButton()
        rejectButton.translatesAutoresizingMaskIntoConstraints = false
        rejectButton.setTitle("generic.no".localized, for: .normal)
        rejectButton.setTitleColor(.gray3, for: .normal)
        rejectButton.setTitleColor(.gray7, for: .highlighted)
        rejectButton.titleLabel?.font = buttonFont
        rejectButton.titleLabel?.adjustsFontForContentSizeCategory = true
        rejectButton.addTarget(self, action: #selector(rejectButtonAction), for: .touchUpInside)
        tempContentView.addSubview(rejectButton)
        rejectButton.topAnchor.constraint(equalTo: borderView.topAnchor).isActive = true
        rejectButton.leadingAnchor.constraint(equalTo: tempContentView.leadingAnchor).isActive = true
        rejectButton.bottomAnchor.constraint(equalTo: borderView.bottomAnchor).isActive = true
        rejectButton.trailingAnchor.constraint(equalTo: borderView.leadingAnchor).isActive = true
        rejectButton.heightAnchor.constraint(equalToConstant: type(of: self).buttonHeight).isActive = true
        
        let confirmButton = UIButton()
        confirmButton.translatesAutoresizingMaskIntoConstraints = false
        confirmButton.setTitle("generic.yes".localized, for: .normal)
        confirmButton.setTitleColor(.gray3, for: .normal)
        confirmButton.setTitleColor(.gray7, for: .highlighted)
        confirmButton.titleLabel?.font = buttonFont
        rejectButton.titleLabel?.adjustsFontForContentSizeCategory = true
        confirmButton.addTarget(self, action: #selector(confirmButtonAction), for: .touchUpInside)
        tempContentView.addSubview(confirmButton)
        confirmButton.topAnchor.constraint(equalTo: borderView.topAnchor).isActive = true
        confirmButton.leadingAnchor.constraint(equalTo: borderView.trailingAnchor).isActive = true
        confirmButton.bottomAnchor.constraint(equalTo: borderView.bottomAnchor).isActive = true
        confirmButton.trailingAnchor.constraint(equalTo: tempContentView.trailingAnchor).isActive = true
        confirmButton.heightAnchor.constraint(equalToConstant: type(of: self).buttonHeight).isActive = true
    }
    
    fileprivate static let buttonHeight = UIButton().intrinsicContentSize.height
    
    @objc private func rejectButtonAction() {
        delegate?.screenshotNotificationCollectionViewCellDidTapReject?(self)
    }
    
    @objc private func confirmButtonAction() {
        delegate?.screenshotNotificationCollectionViewCellDidTapConfirm?(self)
    }
    
    // MARK: Icon
    
    var iconImage: UIImage? {
        set {
            if let iconImage = newValue {
                iconImageView.isHidden = false
                iconImageView.image = iconImage
                tempContentViewToIconConstraint.isActive = true
                
            } else {
                iconImageView.isHidden = true
                iconImageView.image = nil
                tempContentViewToIconConstraint.isActive = false
            }
        }
        get {
            return iconImageView.image
        }
    }
    
    fileprivate static let iconWidth = CGFloat(30)
    
    // MARK: Label / Text
    
    private var _tempContentLabel: UILabel?
    fileprivate var tempContentLabel: UILabel? {
        set {
            _tempContentLabel = newValue
        }
        get {
            if _tempContentLabel == nil {
                let label = UILabel()
                label.textColor = .gray3
                label.numberOfLines = 0
                label.font = type(of: self).labelFont
                label.adjustsFontForContentSizeCategory = true
                label.textAlignment = .center
                _tempContentLabel = label
            }
            return _tempContentLabel
        }
    }
    
    var contentText = ScreenshotNotificationCollectionViewCellContentText.none {
        didSet {
            tempContentLabel?.text = type(of: self).text(forContentText: contentText)
        }
    }
    
    fileprivate static func text(forContentText contentText: ScreenshotNotificationCollectionViewCellContentText) -> String? {
        let text: String?
        
        switch contentText {
        case .none:
            text = nil
            break
        case .importSingleScreenshot:
            text = "screenshot.import.latest".localized
            break
        case .importMultipleScreenshots:
            text = "screenshot.import.multiple".localized(withFormat: AccumulatorModel.screenshot.newCount)
            break
        case .importVeryManyScreenshots:
            text = "screenshot.import.very_many".localized
            break
        }
        return text
    }
    
    fileprivate static var labelFont: UIFont {
        return UIFont.preferredFont(forTextStyle: .body)
    }
}

// MARK: - Size

extension ScreenshotNotificationCollectionViewCell {
    static func height(withCellWidth width: CGFloat, contentText: ScreenshotNotificationCollectionViewCellContentText, contentType: ScreenshotNotificationCollectionViewCellContentType) -> CGFloat {
        guard width > 0, let string = text(forContentText: contentText) else {
            return CGFloat(0)
        }
        
        let contentWidth = width - shadowInsets.left - mainViewLayoutMargins.left - iconWidth - mainViewLayoutMargins.left - mainViewLayoutMargins.right - shadowInsets.right
        let constraintRect = CGSize(width: contentWidth, height: .greatestFiniteMagnitude)
        
        let boundingBox = string.boundingRect(with: constraintRect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [NSAttributedStringKey.font: labelFont], context: nil)
        
        return shadowInsets.top + mainViewLayoutMargins.top + ceil(boundingBox.height) + mainViewLayoutMargins.top + buttonHeight + mainViewLayoutMargins.bottom + shadowInsets.bottom
    }
}
