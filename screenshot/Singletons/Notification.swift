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
    
    var window: UIWindow!
    var notificationViewTopConstraint: NSLayoutConstraint!
    
    private override init() {
        super.init()
        
        let windowFrame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 64)
        window = UIWindow(frame: windowFrame)
        window.windowLevel = UIWindowLevelAlert
        
        let notificationView = NotificationView()
        notificationView.translatesAutoresizingMaskIntoConstraints = false
        window.addSubview(notificationView)
        notificationView.leadingAnchor.constraint(equalTo: window.leadingAnchor).isActive = true
        notificationView.trailingAnchor.constraint(equalTo: window.trailingAnchor).isActive = true
        notificationView.heightAnchor.constraint(equalTo: window.heightAnchor).isActive = true
        
        notificationViewTopConstraint = notificationView.topAnchor.constraint(equalTo: window.topAnchor)
        
        let bottomConstraint = notificationView.bottomAnchor.constraint(equalTo: window.topAnchor)
        bottomConstraint.priority = UILayoutPriorityDefaultLow
        bottomConstraint.isActive = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapAction(notificationView:)))
        notificationView.addGestureRecognizer(tapGesture)
        
        // TODO: change to pan gesture
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(swipeAction(notificationView:)))
        swipeGesture.direction = .up
        notificationView.addGestureRecognizer(swipeGesture)
    }
    
    // MARK: Gestures
    
    @objc private func tapAction(notificationView: NotificationView) {
        dismiss()
    }
    
    @objc private func swipeAction(notificationView: NotificationView) {
        dismiss()
    }
    
    // MARK: Present / Dismiss
    
    public func present() {
        window.makeKeyAndVisible()
        window.layoutIfNeeded()
        
        notificationViewTopConstraint.isActive = true
        
        UIView.animate(withDuration: 2) {
            self.window.layoutIfNeeded()
        }
    }
    
    public func dismiss() {
        notificationViewTopConstraint.isActive = false
        
        UIView.animate(withDuration: 2, animations: {
            self.window.layoutIfNeeded()
            
        }) { (completed) in
            self.window.isHidden = true
        }
    }
}

private enum NotificationViewImageType {
    case none
    case screenshot
}

private class NotificationView: UIView {
    var imageView: UIImageView!
    var label: UILabel!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let padding = Geometry.padding()
        
        backgroundColor = .red
        layoutMargins = UIEdgeInsetsMake(padding, padding, padding, padding)
        
        imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .green
        imageView.isHidden = true
        addSubview(imageView)
        imageView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
        imageView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor).isActive = true
        imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor).isActive = true
        
        label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = .blue
        addSubview(label)
        label.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
        label.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor)
        label.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor).isActive = true
    }
    
    // MARK: Image
    
    var imageType = NotificationViewImageType.none {
        didSet {
            self.imageView.isHidden = imageType == .none
            self.imageView.image = image(for: imageType)
        }
    }
    
    func image(for type: NotificationViewImageType) -> UIImage? {
        var image: UIImage?
        
        switch type {
        case .none:
            break
        case .screenshot:
            image = UIImage(named: "") // TODO:
            break
        }
        
        return image
    }
}
