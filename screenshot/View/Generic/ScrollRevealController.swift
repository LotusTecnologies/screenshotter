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
    var adjustedContentInset: UIEdgeInsets = .zero
    
    fileprivate let scrollView: UIScrollView
    fileprivate let edge: ScrollRevealEdge
    fileprivate var edgeConstraint: NSLayoutConstraint?
    fileprivate var offsetY: CGFloat = 0
    fileprivate var previousOffsetY: CGFloat = 0
    
    convenience init(connectedTo scrollView: UIScrollView, onEdge edge: UInt) {
        self.init(connectedTo: scrollView, onEdge: ScrollRevealEdge(rawValue: edge)!)
    }
    
    init(connectedTo scrollView: UIScrollView, onEdge edge: ScrollRevealEdge) {
        self.scrollView = scrollView
        self.edge = edge
        super.init()
        
        if let superview = scrollView.superview {
            view.translatesAutoresizingMaskIntoConstraints = false
            superview.insertSubview(view, aboveSubview: scrollView)
            view.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor).isActive = true
            view.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor).isActive = true
            
            if edge == .top {
                edgeConstraint = view.bottomAnchor.constraint(equalTo: superview.topAnchor, constant: adjustedContentInset.top)
                
            } else {
                edgeConstraint = view.topAnchor.constraint(equalTo: superview.bottomAnchor, constant: -adjustedContentInset.bottom)
            }
            
            edgeConstraint?.isActive = true
        }
    }
}

extension ScrollRevealController {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if self.scrollView == scrollView {
            prepareViewOffset()
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if self.scrollView == scrollView && scrollView.isDragging {
            adjustViewOffset()
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, will decelerate: Bool) {
        if self.scrollView == scrollView && !decelerate {
            completeViewOffset()
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if self.scrollView == scrollView {
            completeViewOffset()
        }
    }
    
    fileprivate var scrollViewAdjustedContentInset: UIEdgeInsets {
        var insets: UIEdgeInsets = .zero
        insets.top = scrollView.contentInset.top + adjustedContentInset.top
        insets.bottom = scrollView.contentInset.bottom  + adjustedContentInset.bottom
        return insets
    }
    
    fileprivate var scrollViewExpectedContentOffsetY: CGFloat {
        return scrollView.contentOffset.y + scrollViewAdjustedContentInset.top
    }
    
    fileprivate var scrollViewExpectedContentSizeHeight: CGFloat {
        return scrollView.contentOffset.y + scrollView.bounds.size.height - scrollViewAdjustedContentInset.bottom
    }
    
    fileprivate func adjustViewOffset() {
        guard let edgeConstraint = edgeConstraint else {
            return
        }
        
        // Dont change the constraint when bouncing
        if scrollViewExpectedContentOffsetY > 0 && scrollViewExpectedContentSizeHeight < scrollView.contentSize.height {
            let currentOffsetY = offsetY - scrollView.contentOffset.y
            
            if edge == .top {
                edgeConstraint.constant = min(adjustedContentInset.top + view.bounds.size.height, max(adjustedContentInset.top, currentOffsetY))
                
            } else {
                edgeConstraint.constant = min(0, max(-(view.bounds.size.height + adjustedContentInset.bottom), currentOffsetY));
            }
        }
        
        prepareViewOffset()
        previousOffsetY = scrollView.contentOffset.y
    }
    
    fileprivate func prepareViewOffset() {
        offsetY = scrollView.contentOffset.y + (edgeConstraint?.constant ?? 0)
    }
    
    func resetViewOffset() {
        edgeConstraint?.constant = 0
    }
    
    fileprivate func completeViewOffset() {
        let minHeight = -view.bounds.size.height
        let maxHeight = CGFloat(0)
        let offsetY = edgeConstraint?.constant ?? 0
        
        if offsetY > minHeight && offsetY < maxHeight {
            UIView.animate(withDuration: Constants.defaultAnimationDuration, animations: {
                self.edgeConstraint?.constant = offsetY * 2 > minHeight ? maxHeight : minHeight
                self.view.superview?.layoutIfNeeded()
            })
        }
    }
}
