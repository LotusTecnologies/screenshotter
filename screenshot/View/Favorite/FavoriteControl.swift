//
//  FavoriteControl.swift
//  screenshot
//
//  Created by Corey Werner on 9/4/17.
//  Copyright (c) 2017 crazeapp. All rights reserved.
//

import UIKit
import Lottie
import Appsee

class FavoriteControl: UIControl {
    fileprivate let heartSwitch = LOTAnimatedSwitch(named: "FavoriteHeart")
    fileprivate var heartSwitchWidthConstraint: NSLayoutConstraint!
    fileprivate var animate = false
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addTarget(self, action: #selector(touchUpInsideAction), for: .touchUpInside)
        
        // The heart switch animation needs to be a subview since it's
        // view extends beyond the bounds of the desired tappable rect.
        heartSwitch.translatesAutoresizingMaskIntoConstraints = false
        heartSwitch.isUserInteractionEnabled = false
        addSubview(heartSwitch)
        heartSwitch.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        heartSwitch.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        heartSwitchWidthConstraint = heartSwitch.widthAnchor.constraint(equalToConstant: heartWidth(for: intrinsicContentSize.width))
        heartSwitchWidthConstraint.isActive = true
        heartSwitch.heightAnchor.constraint(equalTo: heartSwitch.widthAnchor).isActive = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        heartSwitchWidthConstraint.constant = heartWidth(for: bounds.size.width)
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 36, height: 36)
    }
    
    fileprivate func heartWidth(for width: CGFloat) -> CGFloat {
        return width * 2.28
    }
    
    override var isSelected: Bool {
        didSet {
            if isSelected != heartSwitch.isOn {
                heartSwitch.setOn(isSelected, animated: animate)
            }
        }
    }
    
    @objc func touchUpInsideAction() {
        animate = true
        isSelected = !isSelected
        animate = false
        
        ActionFeedbackGenerator().actionOccurred(.peek)
        presentPushPermissionsIfNeeded()
    }
}

typealias FavoriteControlPushPermissions = FavoriteControl
extension FavoriteControlPushPermissions {
    private func presentPushPermissionsIfNeeded() {
        if isSelected && !UserDefaults.standard.bool(forKey: UserDefaultsKeys.hasFavorited) {
            UserDefaults.standard.set(true, forKey: UserDefaultsKeys.hasFavorited)
        
            guard !PermissionsManager.shared.hasPermission(for: .push) else {
                return
            }
            
            let alertController = UIAlertController(title: "favorite.price_updates.title".localized, message: "favorite.price_updates.message".localized, preferredStyle: .alert)
            let enableAction = UIAlertAction(title: "generic.enable".localized, style: .default) { action in
                PermissionsManager.shared.requestPermission(for: .push, openSettingsIfNeeded: true)
            }
            alertController.addAction(enableAction)
            alertController.preferredAction = enableAction
            alertController.addAction(UIAlertAction(title: "generic.later".localized, style: .cancel, handler: nil))
            window?.rootViewController?.present(alertController, animated: true)
        }
    }
}
