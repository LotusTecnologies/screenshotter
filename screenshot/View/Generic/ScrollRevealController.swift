//
//  ScrollRevealController.swift
//  screenshot
//
//  Created by Corey Werner on 12/21/17.
//  Copyright (c) 2017 crazeapp. All rights reserved.
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
    
    // The view will only auto show if it's subview has been
    // added prior to calling insertAbove(_:)
    var isAutoShowingView = false
    
    var isViewHidden = false {
        didSet {
            if view.isHidden != isViewHidden {
                view.isHidden = isViewHidden
                resetViewOffset()
                adjustScrollViewInsets()
            }
        }
    }
    
    fileprivate var scrollView: UIScrollView?
    fileprivate let edge: ScrollRevealEdge
    fileprivate var edgeConstraint: NSLayoutConstraint?
    fileprivate var offsetY: CGFloat = 0
    fileprivate var previousOffsetY: CGFloat = 0
    
    var hasBottomBar = false
    
    convenience init(edge: UInt) {
        self.init(edge: ScrollRevealEdge(rawValue: edge)!)
    }
    
    init(edge: ScrollRevealEdge) {
        self.edge = edge
        super.init()
    }
    
    func insertAbove(_ scrollView: UIScrollView) {
        self.scrollView = scrollView
        
        if let superview = scrollView.superview {
            view.translatesAutoresizingMaskIntoConstraints = false
            superview.insertSubview(view, aboveSubview: scrollView)
            view.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor).isActive = true
            view.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor).isActive = true
            
            // Layout the view to get the height for minOffset
            view.layoutIfNeeded()
            
            let constant = isAutoShowingView ? revealedOffset : concealedOffset
            
            if edge == .top {
                edgeConstraint = view.bottomAnchor.constraint(equalTo: superview.topAnchor, constant: constant)
                
            } else {
                edgeConstraint = view.topAnchor.constraint(equalTo: superview.bottomAnchor, constant: constant)
            }
            
            edgeConstraint?.isActive = true
            
            adjustScrollViewInsets()
        }
    }
}

extension ScrollRevealController {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if self.scrollView == scrollView {
            guard !isViewHidden else {
                return
            }
            
            prepareViewOffset()
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if self.scrollView == scrollView && scrollView.isDragging {
            guard !isViewHidden else {
                return
            }
            
            adjustViewOffset()
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, will decelerate: Bool) {
        if self.scrollView == scrollView && !decelerate {
            guard !isViewHidden else {
                return
            }
            
            completeViewOffset()
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if self.scrollView == scrollView {
            guard !isViewHidden else {
                return
            }
            
            completeViewOffset()
        }
    }
    
    fileprivate var scrollViewAdjustedContentInset: UIEdgeInsets {
        var insets: UIEdgeInsets = .zero
        insets.top = (scrollView?.contentInset.top ?? 0) + adjustedContentInset.top
        insets.bottom = (scrollView?.contentInset.bottom ?? 0) + adjustedContentInset.bottom
        return insets
    }
    
    fileprivate var scrollViewExpectedContentOffsetY: CGFloat {
        let scrollViewContentOffsetY = scrollView?.contentOffset.y ?? 0
        return scrollViewContentOffsetY + scrollViewAdjustedContentInset.top
        
    }
    
    fileprivate var scrollViewExpectedContentSizeHeight: CGFloat {
        let scrollViewContentOffsetY = scrollView?.contentOffset.y ?? 0
        let scrollViewHeight = scrollView?.bounds.size.height ?? 0
        return scrollViewContentOffsetY + scrollViewHeight - scrollViewAdjustedContentInset.bottom
    }
    
    fileprivate var minOffset: CGFloat {
        if edge == .top {
            return view.bounds.size.height + adjustedContentInset.top
            
        } else {
            return -adjustedContentInset.bottom
        }
    }
    
    fileprivate var maxOffset: CGFloat {
        if edge == .top {
            return adjustedContentInset.top
            
        } else {
            return -(view.bounds.size.height + adjustedContentInset.bottom)
        }
    }
    
    fileprivate var concealedOffset: CGFloat {
        if edge == .top {
            return adjustedContentInset.top
            
        } else {
            return -adjustedContentInset.bottom
        }
    }
    
    fileprivate var revealedOffset: CGFloat {
        if edge == .top {
            return view.bounds.size.height + adjustedContentInset.top
            
        } else {
            return -(view.bounds.size.height + adjustedContentInset.bottom)
        }
    }
    
    func resetViewOffset() {
        edgeConstraint?.constant = concealedOffset
    }
    
    fileprivate func adjustViewOffset() {
        guard let scrollView = scrollView, let edgeConstraint = edgeConstraint else {
            return
        }
        
        // Dont change the constraint when bouncing
        let isInContent = scrollViewExpectedContentOffsetY >= 0 && scrollViewExpectedContentSizeHeight <= scrollView.contentSize.height
        
        // Allow changes when tracking beyond the bounds
        let isTrackingBeyondBounds = scrollView.isTracking && abs(edgeConstraint.constant) < abs(revealedOffset)
        
        if isInContent || isTrackingBeyondBounds {
            edgeConstraint.constant = min(minOffset, max(maxOffset, offsetY - scrollView.contentOffset.y))
            adjustScrollViewInsets()
        }
        
        prepareViewOffset()
        previousOffsetY = scrollView.contentOffset.y
    }
    
    fileprivate func prepareViewOffset() {
        offsetY = (scrollView?.contentOffset.y ?? 0) + (edgeConstraint?.constant ?? 0)
    }
    
    fileprivate func completeViewOffset() {
        let max = maxOffset
        let min = minOffset
        let offset = edgeConstraint?.constant ?? 0
        
        if offset > max && offset < min {
            let shouldReveal = min - offset < view.bounds.size.height / 2
            
            UIView.animate(withDuration: .defaultAnimationDuration, animations: {
                self.edgeConstraint?.constant = shouldReveal ? min : max
                self.adjustScrollViewInsets()
                self.view.superview?.layoutIfNeeded()
            })
        }
    }
    
    fileprivate func adjustScrollViewInsets() {
        guard let edgeConstraint = edgeConstraint, let scrollView = scrollView else {
            return
        }
        
        let inset = abs(edgeConstraint.constant - concealedOffset)
        var scrollInset = inset
        
        if #available(iOS 11.0, *), !hasBottomBar {
            let viewHeight = view.bounds.size.height
            
            if viewHeight > 0 {
                let safeAreaBottom = (abs(edgeConstraint.constant) / viewHeight) * scrollView.safeAreaInsets.bottom
                scrollInset = inset - safeAreaBottom
            }
        }
        
        var contentInset = scrollView.contentInset
        var scrollIndicatorInsets = scrollView.scrollIndicatorInsets
        
        if edge == .top {
            contentInset.top = inset
            scrollIndicatorInsets.top = scrollInset
            
        } else {
            contentInset.bottom = inset
            scrollIndicatorInsets.bottom = scrollInset
        }
        
        // Setting the contentInset will call the scrollViewDidScroll delegate.
        // This will create a recursive loop and cause jumping.
        let scrollViewDelegate = scrollView.delegate
        scrollView.delegate = nil
        
        scrollView.contentInset = contentInset
        scrollView.scrollIndicatorInsets = scrollIndicatorInsets
        
        scrollView.delegate = scrollViewDelegate
    }
}
