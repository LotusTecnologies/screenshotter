//
//  Notification.swift
//  screenshot
//
//  Created by Corey Werner on 10/25/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation

final class NotificationManager: NSObject {
    static let shared = NotificationManager()
    
    fileprivate var window: UIWindow!
    fileprivate var notifications = [NotificationWrapper]()
    
    private override init() {
        super.init()
        
        let windowFrame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 64)
        window = UIWindow(frame: windowFrame)
        window.windowLevel = UIWindowLevelAlert
    }
    
    // MARK: Notification View
    
    private func createNotificationView() -> NotificationView {
        let notificationView = NotificationView()
        notificationView.translatesAutoresizingMaskIntoConstraints = false
        window.addSubview(notificationView)
        notificationView.leadingAnchor.constraint(equalTo: window.leadingAnchor).isActive = true
        notificationView.trailingAnchor.constraint(equalTo: window.trailingAnchor).isActive = true
        notificationView.heightAnchor.constraint(equalTo: window.heightAnchor).isActive = true
        
        let bottomConstraint = notificationView.bottomAnchor.constraint(equalTo: window.topAnchor)
        bottomConstraint.priority = UILayoutPriorityDefaultLow
        bottomConstraint.isActive = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapAction(notificationView:)))
        notificationView.addGestureRecognizer(tapGesture)
        
        // TODO: change to pan gesture
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(swipeAction(notificationView:)))
        swipeGesture.direction = .up
        notificationView.addGestureRecognizer(swipeGesture)
        
        return notificationView
    }
    
    // MARK: Gestures
    
    @objc private func tapAction(notificationView: NotificationView) {
        dismiss()
    }
    
    @objc private func swipeAction(notificationView: NotificationView) {
        dismiss()
    }
    
    // MARK: Present / Dismiss
    
    public func presentScreenshot(completion: (() -> Void)? = nil) {
        let notificationView = createNotificationView()
        notificationView.image = UIImage(named: "TabBarSnapshot")?.withRenderingMode(.alwaysTemplate)
        notificationView.label.text = "Import new screenshot?"
        present(notificationView: notificationView, completion: completion)
    }
    
    public func presentScreenshot(withCount screenshotCount: UInt, completion: (() -> Void)? = nil) {
        if screenshotCount == 1 {
            presentScreenshot()
            
        } else if screenshotCount > 1 {
            let notificationView = createNotificationView()
            notificationView.image = UIImage(named: "TabBarSnapshot")?.withRenderingMode(.alwaysTemplate)
            notificationView.label.text = "You have \(screenshotCount) new screenshots."
            present(notificationView: notificationView, completion: completion)
        }
    }
    
    private func present(notificationView: NotificationView, completion: (() -> Void)? = nil) {
        let constraint = notificationView.topAnchor.constraint(equalTo: window.topAnchor)
        let wrapper = NotificationWrapper(view: notificationView, constraint: constraint, callback: completion)
        notifications.append(wrapper)
        
        window.makeKeyAndVisible()
        window.layoutIfNeeded()
        
        constraint.isActive = true
        
        UIView.animate(withDuration: Constants.defaultAnimationDuration, delay: 0, options: .curveEaseOut, animations: {
            self.window.layoutIfNeeded()
            
        }) { (completed) in
            if self.notifications.count > 1 {
                for i in 0...(self.notifications.count - 2) {
                    self.dismiss(notificationWrapper: self.notifications[i], animated: false)
                }
            }
            
            completion?()
        }
        
        TapticHelper.peek()
    }
    
    public func dismiss() {
        if let notificationWrapper = notifications.last {
            dismiss(notificationWrapper: notificationWrapper, animated: true)
        }
    }
    
    private func dismiss(notificationWrapper: NotificationWrapper, animated: Bool) {
        if let index = notifications.index(of: notificationWrapper) {
            notifications.remove(at: index)
        }
        
        if animated {
            notificationWrapper.constraint.isActive = false
            
            UIView.animate(withDuration: Constants.defaultAnimationDuration, delay: 0, options: .curveEaseIn, animations: {
                self.window.layoutIfNeeded()
                
            }) { (completed) in
                self.hideIfNeeded()
            }
            
        } else {
            notificationWrapper.view.removeFromSuperview()
            hideIfNeeded()
        }
    }
    
    private func hideIfNeeded() {
        if notifications.count == 0 {
            window.isHidden = true
        }
    }
}

private class NotificationView: UIView {
    private var imageView: UIImageView!
    private(set) var label: UILabel!
    private var labelLeadingConstraint: NSLayoutConstraint!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let padding = Geometry.padding()
        
        backgroundColor = .white
        layoutMargins = UIEdgeInsetsMake(padding, padding, padding, padding)
        
        imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = .crazeRed
        imageView.isHidden = true
        addSubview(imageView)
        imageView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
        imageView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor).isActive = true
        imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor).isActive = true
        
        label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = .clear
        label.textAlignment = .center
        label.textColor = .gray3
        addSubview(label)
        label.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
        label.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor).isActive = true
        label.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        labelLeadingConstraint = label.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor)
        labelLeadingConstraint.isActive = true
        
        let labelToImageViewLeadingConstraint = label.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: padding)
        labelToImageViewLeadingConstraint.priority = UILayoutPriorityDefaultHigh
        labelToImageViewLeadingConstraint.isActive = true
        
        let bottomBorder = UIView()
        bottomBorder.translatesAutoresizingMaskIntoConstraints = false
        bottomBorder.backgroundColor = .crazeRed
        addSubview(bottomBorder)
        bottomBorder.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        bottomBorder.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        bottomBorder.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        bottomBorder.heightAnchor.constraint(equalToConstant: Geometry.halfPoint()).isActive = true
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
