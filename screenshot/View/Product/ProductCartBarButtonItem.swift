//
//  ProductCartBarButtonItem.swift
//  screenshot
//
//  Created by Corey Werner on 2/28/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class ProductCartBarButtonItem: UIBarButtonItem {
    fileprivate let countLabel = Label()
    private var timer: Timer?
    
    convenience init(target: Any?, action: Selector?) {
        let image = UIImage(named: "ProductCart")?.withRenderingMode(.alwaysTemplate)
        
        self.init(image: image, style: .plain, target: target, action: action)
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            if let view = self?.targetView {
                timer.invalidate()
                self?.view = view
            }
        }
    }
    
    fileprivate var view: UIView? {
        didSet {
            guard let view = view else {
                return
            }
            
            countLabel.delegate = self
            countLabel.translatesAutoresizingMaskIntoConstraints = false
            countLabel.textColor = .crazeRed
            countLabel.textAlignment = .right
            countLabel.font = .systemFont(ofSize: 12)
            view.addSubview(countLabel)
            countLabel.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            countLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            countLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        }
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
    
    // MARK: Count
    
    var count: UInt = 0 {
        didSet {
            syncCount()
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
        guard let tintView = tintView else {
            return
        }
        
        if count > 0 {
            tintView.tintColor = .crazeRed
        }
        else {
            tintView.tintColor = UINavigationBar.appearance().tintColor
        }
    }
}

fileprivate protocol ProductCartBarButtonItemLabelDelegate: NSObjectProtocol {
    func labelLayoutSubviews()
}

extension ProductCartBarButtonItem: ProductCartBarButtonItemLabelDelegate {
    fileprivate class Label: UILabel {
        weak var delegate: ProductCartBarButtonItemLabelDelegate?
        
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
