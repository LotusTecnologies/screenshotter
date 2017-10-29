//
//  Notification.swift
//  screenshot
//
//  Created by Corey Werner on 10/25/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation

private enum NotificationAnimation {
    case none
    case slide
    case fade
}

final class NotificationManager: NSObject {
    static let shared = NotificationManager()
    
    fileprivate var window: UIWindow!
    fileprivate var notifications = [NotificationWrapper]()
    
    private override init() {
        super.init()
        
        let padding = CGFloat(8)
        
        let windowFrame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 0)
        window = UIWindow(frame: windowFrame)
        window.layoutMargins = UIEdgeInsetsMake(padding, padding, padding, padding)
        window.windowLevel = UIWindowLevelAlert
    }
    
    // MARK: Notification View
    
    private func createNotificationView() -> NotificationView {
        let notificationView = NotificationView()
        notificationView.translatesAutoresizingMaskIntoConstraints = false
        window.addSubview(notificationView)
        notificationView.leadingAnchor.constraint(equalTo: window.layoutMarginsGuide.leadingAnchor).isActive = true
        notificationView.trailingAnchor.constraint(equalTo: window.layoutMarginsGuide.trailingAnchor).isActive = true
        notificationView.heightAnchor.constraint(greaterThanOrEqualToConstant: 64).isActive = true
        
        let bottomConstraint = notificationView.bottomAnchor.constraint(equalTo: window.topAnchor)
        bottomConstraint.priority = UILayoutPriorityDefaultLow
        bottomConstraint.isActive = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapAction(tapGesture:)))
        notificationView.addGestureRecognizer(tapGesture)
        
        // TODO: change to pan gesture
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(swipeAction(swipeGesture:)))
        swipeGesture.direction = .up
        notificationView.addGestureRecognizer(swipeGesture)
        
        return notificationView
    }
    
    // MARK: Gestures
    
    @objc private func tapAction(tapGesture: UITapGestureRecognizer) {
        if let notificationView = tapGesture.view,
            let index = notifications.index(where: { $0.view == notificationView }) {
            notifications[index].callback?()
        }
        
        dismiss()
    }
    
    @objc private func swipeAction(swipeGesture: UISwipeGestureRecognizer) {
        dismiss()
    }
    
    // MARK: Present / Dismiss
    
    public func presentScreenshot(withUserTapped userTapped: (() -> Void)? = nil) {
        let notificationView = createNotificationView()
        notificationView.image = UIImage(named: "TabBarSnapshot")?.withRenderingMode(.alwaysTemplate)
        notificationView.label.text = "Import new screenshot?"
        present(notificationView: notificationView, userTapped: userTapped)
    }
    
    public func presentScreenshot(withCount screenshotCount: UInt, userTapped: (() -> Void)? = nil) {
        if screenshotCount == 1 {
            presentScreenshot()
            
        } else if screenshotCount > 1 {
            let notificationView = createNotificationView()
            notificationView.image = UIImage(named: "TabBarSnapshot")?.withRenderingMode(.alwaysTemplate)
            notificationView.label.text = "You have \(screenshotCount) new screenshots."
            present(notificationView: notificationView, userTapped: userTapped)
        }
    }
    
    private func present(notificationView: NotificationView, userTapped: (() -> Void)? = nil) {
        let constraint = notificationView.topAnchor.constraint(equalTo: window.layoutMarginsGuide.topAnchor)
        let wrapper = NotificationWrapper(view: notificationView, constraint: constraint, callback: userTapped)
        notifications.append(wrapper)
        
        window.makeKeyAndVisible()
        window.layoutIfNeeded()
        
        var windowFrame = window.frame
        windowFrame.size.height = notificationView.frame.size.height + window.layoutMargins.top + window.layoutMargins.bottom
        window.frame = windowFrame
        
        notificationView.applyShadow()
        
        constraint.isActive = true
        
        UIView.animate(withDuration: Constants.defaultAnimationDuration, delay: 0, options: .curveEaseOut, animations: {
            self.window.layoutIfNeeded()
            
        }) { (completed) in
            if self.notifications.count > 1 {
                for i in 0...(self.notifications.count - 2) {
                    self.dismiss(notificationWrapper: self.notifications[i], animation: .fade)
                }
            }
        }
        
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] timer in
            if wrapper.view.superview != nil {
                self?.dismiss(notificationWrapper: wrapper, animation: .slide)
            }
        }
        
        TapticHelper.peek()
    }
    
    public func dismiss() {
        if let notificationWrapper = notifications.last {
            dismiss(notificationWrapper: notificationWrapper, animation: .slide)
        }
    }
    
    private func dismiss(notificationWrapper: NotificationWrapper, animation: NotificationAnimation) {
        if let index = notifications.index(of: notificationWrapper) {
            notifications.remove(at: index)
        }
        
        switch animation {
        case .slide:
            notificationWrapper.constraint.isActive = false
            
            UIView.animate(withDuration: Constants.defaultAnimationDuration, delay: 0, options: .curveEaseIn, animations: {
                self.window.layoutIfNeeded()
                
            }) { (completed) in
                self.hideWindowAndNotificationIfPossible(notificationWrapper.view)
            }
            break
            
        case .fade:
            UIView.animate(withDuration: Constants.defaultAnimationDuration, delay: 0, options: .curveEaseIn, animations: {
                notificationWrapper.view.alpha = 0
                
            }) { (completed) in
                self.hideWindowAndNotificationIfPossible(notificationWrapper.view)
            }
            break
            
        case .none:
            hideWindowAndNotificationIfPossible(notificationWrapper.view)
            break
        }
    }
    
    private func hideWindowAndNotificationIfPossible(_ notificationView: NotificationView) {
        notificationView.removeFromSuperview()
        
        if notifications.count == 0 {
            window.isHidden = true
        }
    }
}

private class NotificationView: UIView {
    private let cornerRadius = CGFloat(5)
    
    private var imageView: UIImageView!
    private(set) var label: UILabel!
    private var labelLeadingConstraint: NSLayoutConstraint!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let padding = Geometry.padding
        
        let backgroundView = UIView()
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.backgroundColor = .white
        backgroundView.layer.cornerRadius = cornerRadius
        backgroundView.layer.masksToBounds = true
        addSubview(backgroundView)
        backgroundView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
        imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .crazeRed
        imageView.isHidden = true
        addSubview(imageView)
        imageView.topAnchor.constraint(equalTo: topAnchor, constant: padding).isActive = true
        imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding).isActive = true
        imageView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -padding).isActive = true
        imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor).isActive = true
        
        label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = .clear
        label.textAlignment = .center
        label.textColor = .gray3
        label.numberOfLines = 0
        addSubview(label)
        label.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        label.topAnchor.constraint(equalTo: topAnchor, constant: padding).isActive = true
        label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding).isActive = true
        label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding).isActive = true
        
        labelLeadingConstraint = label.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor)
        labelLeadingConstraint.isActive = true
        
        let labelToImageViewLeadingConstraint = label.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: padding)
        labelToImageViewLeadingConstraint.priority = UILayoutPriorityDefaultHigh
        labelToImageViewLeadingConstraint.isActive = true
    }
    
    // MARK: Image
    
    var image: UIImage? {
        set {
            self.imageView.image = newValue
            self.imageView.isHidden = image == nil
            self.labelLeadingConstraint.isActive = self.imageView.isHidden
        }
        get {
            return self.imageView.image
        }
    }
    
    // MARK: Shadow
    
    func applyShadow() {
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).cgPath
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
        layer.shadowOpacity = 0.5
    }
}

private class NotificationWrapper: NSObject {
    var view: NotificationView
    var constraint: NSLayoutConstraint
    var callback: (() -> Void)?
    
    init(view: NotificationView, constraint: NSLayoutConstraint, callback: (() -> Void)?) {
        self.view = view
        self.constraint = constraint
        self.callback = callback
        super.init()
    }
}
