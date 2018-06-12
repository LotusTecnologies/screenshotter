//
//  EmptyListController.swift
//  screenshot
//
//  Created by Corey Werner on 2/22/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
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
    
    // Note: This doesn't work work table views with a grouped style.
    func didSetContentSize(scrollView: UIScrollView, emptyView: UIView?) {
        let height = max(0, scrollView.contentSize.height - scrollView.contentInset.top - scrollView.contentInset.bottom)
        
        if height != previousContentHeight {
            if Int(height) == 0 && previousContentHeight > 0 {
                isEmptyViewHidden = false
                emptyView?.isHidden = isEmptyViewHidden
                scrollView.isScrollEnabled = isEmptyViewHidden
            }
            else if height > 0 && Int(previousContentHeight) == 0 {
                isEmptyViewHidden = true
                emptyView?.isHidden = isEmptyViewHidden
                scrollView.isScrollEnabled = isEmptyViewHidden
            }
        }
        
        previousContentHeight = height
    }
    
    private var previousHasTableViewRows = false
    
    func didSetContentSize(tableView: UITableView, emptyView: UIView?) {
        let hasTableViewRows = !(tableView.indexPathsForVisibleRows?.isEmpty ?? true)
        
        if hasTableViewRows != previousHasTableViewRows {
            isEmptyViewHidden = hasTableViewRows
            emptyView?.isHidden = isEmptyViewHidden
            tableView.isScrollEnabled = isEmptyViewHidden
        }
        
        previousHasTableViewRows = hasTableViewRows
    }
    
    func didSetContentInset(scrollView: UIScrollView) {
        syncEmptyViewBottomConstraint(scrollView: scrollView)
    }
}
