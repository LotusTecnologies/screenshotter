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
    
    func willSetEmptyView(_ newEmptyView: UIView?, oldEmptyView: UIView?) {
        if newEmptyView == nil, let oldEmptyView = oldEmptyView {
            oldEmptyView.removeFromSuperview()
        }
    }
    
    func didSetEmptyView(_ emptyView: UIView?, scrollView: UIScrollView) {
        if let emptyView = emptyView {
            emptyView.translatesAutoresizingMaskIntoConstraints = false
            emptyView.alpha = isEmptyViewHidden ? 0 : 1
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
        let height = max(0, scrollView.contentSize.height - scrollView.contentInset.top - scrollView.contentInset.bottom)
        
        if height != previousContentHeight {
            if Int(height) == 0 && previousContentHeight > 0 {
                isEmptyViewHidden = false
                scrollView.isScrollEnabled = false
                
                UIView.animate(withDuration: .defaultAnimationDuration, animations: {
                    emptyView?.alpha = 1
                })
            }
            else if height > 0 && Int(previousContentHeight) == 0 {
                isEmptyViewHidden = true
                scrollView.isScrollEnabled = true
                
                UIView.animate(withDuration: .defaultAnimationDuration, animations: {
                    emptyView?.alpha = 0
                })
            }
        }
        
        previousContentHeight = height
    }
    
    func didSetContentInset(scrollView: UIScrollView) {
        syncEmptyViewBottomConstraint(scrollView: scrollView)
    }
}
