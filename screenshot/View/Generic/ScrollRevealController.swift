//
//  ScrollRevealController.swift
//  screenshot
//
//  Created by Corey Werner on 12/21/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation
import UIKit

enum ScrollRevealEdge : UInt {
    case top
    case bottom
}

class ScrollRevealController : NSObject {
    let view = UIView()
    
    fileprivate let scrollView: UIScrollView
    fileprivate let edge: ScrollRevealEdge
    fileprivate var edgeConstraint: NSLayoutConstraint?
    fileprivate var offsetY: CGFloat = 0
    
    convenience init(connectedTo scrollView: UIScrollView, onEdge edge: UInt) {
        self.init(connectedTo: scrollView, onEdge: ScrollRevealEdge(rawValue: edge)!)
    }
    
    init(connectedTo scrollView: UIScrollView, onEdge edge: ScrollRevealEdge) {
        self.scrollView = scrollView
        self.edge = edge
        super.init()
        
        if let superview = scrollView.superview {
            view.translatesAutoresizingMaskIntoConstraints = false
            view.backgroundColor = .red
            superview.insertSubview(view, aboveSubview: scrollView)
            view.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor).isActive = true
            view.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor).isActive = true
            
            if edge == .top {
                // TODO: create extension for this in ios10
//                view.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor).isActive = true
                edgeConstraint = view.topAnchor.constraint(equalTo: scrollView.topAnchor)
                
            } else {
                edgeConstraint = view.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
            }
        }
    }
    
    fileprivate func adjustRateViewOffsetWithScrollView() {
        let expectedContentOffsetY = scrollViewExpectedContentOffsetY
        let expectedContentSizeHeight = scrollViewExpectedContentSizeHeight
        
        // Dont change the constraint when bouncing
        if expectedContentOffsetY > 0 && expectedContentSizeHeight < scrollView.contentSize.height {
//            self.rateViewTopConstraint.constant = MIN(0.f, MAX(-self.rateView.bounds.size.height, self.rateViewOffsetY - scrollView.contentOffset.y));
        }

//        [self resetRateViewOffsetY:scrollView];
//        self.rateViewPreviousOffsetY = scrollView.contentOffset.y;
    }
    
    fileprivate func resetRateViewOffsetY() { // TODO: should be named with set, or rebase, etc
        offsetY = scrollView.contentOffset.y + (edgeConstraint?.constant ?? 0)
    }
    
    fileprivate func repositionView() { // TODO: should be named reset
        edgeConstraint?.constant = 0
    }
    
    
    // MARK: Scroll View
    
    fileprivate var scrollViewAdjustedContentInset: UIEdgeInsets {
        var insets: UIEdgeInsets = .zero
        
        if #available(iOS 11.0, *) {
            insets.top = scrollView.adjustedContentInset.top
            insets.bottom = scrollView.adjustedContentInset.bottom
            
        } else {
            // ???: how to get this value
            let v = CGFloat(0) // CGRectGetMaxY(self.navigationController.navigationBar.frame)
            insets.top = v + scrollView.contentInset.top
            insets.bottom = scrollView.contentInset.bottom
        }
        
        return insets
    }
    
    fileprivate var scrollViewExpectedContentOffsetY: CGFloat {
        return scrollView.contentOffset.y + scrollViewAdjustedContentInset.top
    }
    
    fileprivate var scrollViewExpectedContentSizeHeight: CGFloat {
        return scrollView.contentOffset.y + scrollView.bounds.size.height - scrollViewAdjustedContentInset.bottom
    }
}
