//
//  BadgeBarButtonItem.swift
//  screenshot
//
//  Created by Corey Werner on 6/21/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class BadgeBarButtonItem: UIBarButtonItem {
    enum BadgeStyle {
        case `default`
        case tint
    }
    
    var badgeStyle: BadgeStyle = .default
    
    fileprivate let countContainer = UIView()
    fileprivate let countLabel = Label()
    private var timer: Timer?
    
    override init() {
        super.init()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            if let view = self?.targetView {
                timer.invalidate()
                self?.view = view
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(UIView.tintColor) {
            if let oldColor = change?[.oldKey] as? UIColor, let newColor = change?[.newKey] as? UIColor {
                if oldColor != newColor {
                    syncImageTintColor()
                }
            }
        }
        else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    deinit {
        timer?.invalidate()
        
        if #available(iOS 11.0, *) {} else {
            tintView?.removeObserver(self, forKeyPath: #keyPath(UIView.tintColor))
        }
    }
    
    // MARK: Label
    
    fileprivate var view: UIView? {
        didSet {
            guard let view = view else {
                return
            }
            
            countContainer.translatesAutoresizingMaskIntoConstraints = false
            countContainer.clipsToBounds = true
            countContainer.isUserInteractionEnabled = false
            view.addSubview(countContainer)
            countContainer.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            countContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
            countContainer.widthAnchor.constraint(greaterThanOrEqualTo: countContainer.heightAnchor).isActive = true
            
            countLabel.delegate = self
            countLabel.translatesAutoresizingMaskIntoConstraints = false
            countLabel.font = .systemFont(ofSize: 12)
            countContainer.addSubview(countLabel)
            countLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
            countLabel.topAnchor.constraint(equalTo: countContainer.layoutMarginsGuide.topAnchor).isActive = true
            countLabel.leadingAnchor.constraint(equalTo: countContainer.layoutMarginsGuide.leadingAnchor).isActive = true
            countLabel.bottomAnchor.constraint(equalTo: countContainer.layoutMarginsGuide.bottomAnchor).isActive = true
            countLabel.trailingAnchor.constraint(equalTo: countContainer.layoutMarginsGuide.trailingAnchor).isActive = true
            
            syncLabelVisibility()
            syncLabelStyle()
        }
    }
    
    fileprivate func syncLabelStyle() {
        if badgeStyle == .default {
            countContainer.layoutIfNeeded()
            countContainer.layoutMargins = UIEdgeInsets(top: 3, left: 5, bottom: 3, right: 5)
            countContainer.backgroundColor = .crazeRed
            countContainer.layer.borderColor = UIColor.white.cgColor
            countContainer.layer.borderWidth = 2
            countContainer.layer.cornerRadius = countContainer.bounds.height * 0.5
            
            countLabel.textColor = .white
            countLabel.textAlignment = .center
        }
        else {
            countContainer.layoutMargins = .zero
            countContainer.backgroundColor = nil
            countContainer.layer.borderColor = nil
            countContainer.layer.borderWidth = 0
            countContainer.layer.cornerRadius = 0
            
            countLabel.textColor = tintColor
            countLabel.textAlignment = .right
        }
    }
    
    fileprivate func syncLabelVisibility() {
        countContainer.isHidden = countLabel.text == nil
    }
    
    // MARK: Count
    
    var count: UInt = 0 {
        didSet {
            syncCount()
            syncLabelStyle()
            syncImageTintColor()
        }
    }
    
    fileprivate func syncCount() {
        switch count {
        case 1 ... 99:
            countLabel.text = "\(count)"
            
        case _ where count > 99:
            countLabel.text = "99+"
            
        default:
            countLabel.text = nil
        }
        
        syncLabelVisibility()
    }
    
    // MARK: Tint View
    
    fileprivate var tintView: UIView?
    
    fileprivate func findTintView() {
        guard tintView == nil, let view = view else {
            return
        }
        
        tintView = view.subviews.first { subview -> Bool in
            return subview != countLabel
        }
        
        // iOS 10 resets the tintColor
        if #available(iOS 11.0, *) {} else {
            tintView?.addObserver(self, forKeyPath: #keyPath(UIView.tintColor), options: [.old, .new], context: nil)
        }
    }
    
    fileprivate func syncImageTintColor() {
        guard let tintView = tintView, badgeStyle == .tint else {
            return
        }
        
        if count > 0 {
            tintView.tintColor = tintColor
        }
        else {
            tintView.tintColor = UINavigationBar.appearance().tintColor
        }
    }
}

fileprivate protocol BadgeBarButtonItemLabelDelegate: NSObjectProtocol {
    func labelLayoutSubviews()
}

extension BadgeBarButtonItem: BadgeBarButtonItemLabelDelegate {
    fileprivate class Label: UILabel {
        weak var delegate: BadgeBarButtonItemLabelDelegate?
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            delegate?.labelLayoutSubviews()
        }
    }
    
    fileprivate func labelLayoutSubviews() {
        findTintView()
        syncImageTintColor()
    }
}
