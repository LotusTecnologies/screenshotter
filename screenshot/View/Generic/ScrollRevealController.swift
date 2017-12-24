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
    
    fileprivate var scrollView: UIScrollView?
    fileprivate let edge: ScrollRevealEdge
    fileprivate var edgeConstraint: NSLayoutConstraint?
    fileprivate var offsetY: CGFloat = 0
    fileprivate var previousOffsetY: CGFloat = 0
    
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
            
            if edge == .top {
                edgeConstraint = view.bottomAnchor.constraint(equalTo: superview.topAnchor, constant: revealedOffset)
                
            } else {
                edgeConstraint = view.topAnchor.constraint(equalTo: superview.bottomAnchor, constant: revealedOffset)
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
        insets.top = (scrollView?.contentInset.top ?? 0) + adjustedContentInset.top
        insets.bottom = (scrollView?.contentInset.bottom ?? 0) + adjustedContentInset.bottom
        return insets
    }
    
    fileprivate var scrollViewExpectedContentOffsetY: CGFloat {
        return (scrollView?.contentOffset.y ?? 0) + scrollViewAdjustedContentInset.top
    }
    
    fileprivate var scrollViewExpectedContentSizeHeight: CGFloat {
        return (scrollView?.contentOffset.y ?? 0) + (scrollView?.bounds.size.height ?? 0) - scrollViewAdjustedContentInset.bottom
    }
    
    fileprivate var revealedOffset: CGFloat {
        if edge == .top {
            return adjustedContentInset.top + view.bounds.size.height
            
        } else {
            return -adjustedContentInset.bottom
        }
    }
    
    fileprivate var concealedOffset: CGFloat {
        if edge == .top {
            return adjustedContentInset.top
            
        } else {
            return -(view.bounds.size.height + adjustedContentInset.bottom)
        }
    }
    
    func resetViewOffset() {
        edgeConstraint?.constant = 0
    }
    
    fileprivate func adjustViewOffset() {
        guard let scrollView = scrollView, let edgeConstraint = edgeConstraint else {
            return
        }
        
        // Dont change the constraint when bouncing
        if scrollViewExpectedContentOffsetY > 0 && scrollViewExpectedContentSizeHeight < scrollView.contentSize.height {
            edgeConstraint.constant = min(revealedOffset, max(concealedOffset, offsetY - scrollView.contentOffset.y))
        }
        
        prepareViewOffset()
        previousOffsetY = scrollView.contentOffset.y
    }
    
    fileprivate func prepareViewOffset() {
        offsetY = (scrollView?.contentOffset.y ?? 0) + (edgeConstraint?.constant ?? 0)
    }
    
    fileprivate func completeViewOffset() {
        let concealed = concealedOffset
        let revealed = revealedOffset
        let offset = edgeConstraint?.constant ?? 0
        
        if offset > concealed && offset < revealed {
            let shouldReveal = revealed - offset < view.bounds.size.height / 2
            
            UIView.animate(withDuration: Constants.defaultAnimationDuration, animations: {
                self.edgeConstraint?.constant = shouldReveal ? revealed : concealed
                self.view.superview?.layoutIfNeeded()
            })
        }
    }
}
