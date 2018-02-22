//
//  EmptyListController.swift
//  screenshot
//
//  Created by Corey Werner on 2/22/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

protocol EmptyListProtocol: NSObjectProtocol {
    var emptyView: UIView? { set get }
}

class EmptyListController: NSObject {
    private var isEmptyViewHidden = false
    
    private func setIsEmptyViewHidden(_ isHidden: Bool, emptyView: UIView?) {
        isEmptyViewHidden = isHidden
        emptyView?.isHidden = isHidden
    }
    
    func willSetEmptyView(_ newEmptyView: UIView?, oldEmptyView: UIView?) {
        if newEmptyView == nil, let oldEmptyView = oldEmptyView {
            oldEmptyView.removeFromSuperview()
        }
    }
    
    func didSetEmptyView(_ emptyView: UIView?, scrollView: UIScrollView) {
        if let emptyView = emptyView {
            emptyView.translatesAutoresizingMaskIntoConstraints = false
            emptyView.isHidden = isEmptyViewHidden
            scrollView.insertSubview(emptyView, at: 0)
            emptyView.topAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.topAnchor).isActive = true
            emptyView.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor).isActive = true
            emptyViewBottomConstraint = emptyView.bottomAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.bottomAnchor)
            emptyViewBottomConstraint?.isActive = true
            emptyView.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor).isActive = true
            
            syncEmptyViewBottomConstraint(scrollView: scrollView)
        }
    }
    
    private var emptyViewBottomConstraint: NSLayoutConstraint?
    
    private func syncEmptyViewBottomConstraint(scrollView: UIScrollView) {
        // This code is only needed for iOS 10
        if #available(iOS 11.0, *) {} else {
            emptyViewBottomConstraint?.constant = -(scrollView.contentInset.top + scrollView.contentInset.bottom)
        }
    }
    
    private var previousContentHeight: CGFloat = 0
    
    func didSetContentSize(scrollView: UIScrollView, emptyView: UIView?) {
        let height = Int(scrollView.contentSize.height)
        let previousHeight = Int(previousContentHeight)
        
        if height != previousHeight {
            if height == 0 && previousHeight > 0 {
                setIsEmptyViewHidden(false, emptyView: emptyView)
            }
            else if height > 0 && previousHeight == 0 {
                setIsEmptyViewHidden(true, emptyView: emptyView)
            }
        }
        
        previousContentHeight = scrollView.contentSize.height
    }
    
    func didSetContentInset(scrollView: UIScrollView) {
        syncEmptyViewBottomConstraint(scrollView: scrollView)
    }
}
