//
//  IntrinsicContentSizePresentationController.swift
//  screenshot
//
//  Created by Corey Werner on 3/11/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class IntrinsicContentSizePresentationController: DimmedPresentationController {
    override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        
        if let presentedView = presentedView {
            presentedView.layer.cornerRadius = .defaultCornerRadius
            presentedView.layer.shadowColor = Shadow.presentation.color.cgColor
            presentedView.layer.shadowOffset = Shadow.presentation.offset
            presentedView.layer.shadowRadius = Shadow.presentation.radius
            presentedView.layer.shadowOpacity = 1
        }
    }
    
    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = containerView, let presentedView = presentedView else {
            return .zero
        }
        
        var intrinsicContentSize = presentedView.intrinsicContentSize
        var rect = containerView.bounds
        
        if intrinsicContentSize.width < 0 || intrinsicContentSize.height < 0 {
            let maxWidth = rect.size.width - (.padding * 2)
            let maxHeight = rect.size.height - (max(.padding, UIApplication.shared.statusBarFrame.height) * 2)
            let width = (intrinsicContentSize.width > 0) ? intrinsicContentSize.width : maxWidth
            
            intrinsicContentSize = presentedView.systemLayoutSizeFitting(CGSize(width: width, height: maxHeight), withHorizontalFittingPriority: UILayoutPriorityRequired, verticalFittingPriority: UILayoutPriorityDefaultLow)
            
            intrinsicContentSize.width = min(maxWidth, intrinsicContentSize.width)
            intrinsicContentSize.height = min(maxHeight, intrinsicContentSize.height)
        }
        
        rect.origin.x = (rect.width / 2) - (intrinsicContentSize.width / 2)
        rect.origin.y = (rect.height / 2) - (intrinsicContentSize.height / 2)
        rect.size = intrinsicContentSize
        return rect
    }
    
    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        
        if let presentedView = presentedView {
            var rect = frameOfPresentedViewInContainerView
            rect.origin = .zero
            
            presentedView.layer.shadowPath = UIBezierPath(roundedRect: rect, cornerRadius: presentedView.layer.cornerRadius).cgPath
        }
    }
}
