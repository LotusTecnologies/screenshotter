//
//  ShoppablesContainerView.swift
//  screenshot
//
//  Created by Corey Werner on 6/3/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class ShoppablesContainerView: UIView {
    enum VisibleToolbar: Int {
        case top
        case bottom
        case both
    }
    
    private let containerView = UIView()
    let toolbar: ShoppablesToolbar
    let subToolbar: ShoppablesToolbar
    
    var visibleToolbar: VisibleToolbar = .top {
        didSet {
            let curve: UIViewAnimationOptions
            
            switch visibleToolbar {
            case .top, .bottom:
                heightConstraint?.constant = intrinsicContentSize.height
                curve = .curveEaseIn
            case .both:
                heightConstraint?.constant = intrinsicContentSize.height * 2
                curve = .curveEaseOut
            }
            
            superview?.layoutIfNeeded()
            
            switch visibleToolbar {
            case .top:
                NSLayoutConstraint.deactivate(bottomConstraints)
                NSLayoutConstraint.deactivate(bothConstraints)
                NSLayoutConstraint.activate(topConstraints)
            case .bottom:
                NSLayoutConstraint.deactivate(topConstraints)
                NSLayoutConstraint.deactivate(bothConstraints)
                NSLayoutConstraint.activate(bottomConstraints)
            case .both:
                NSLayoutConstraint.deactivate(topConstraints)
                NSLayoutConstraint.deactivate(bottomConstraints)
                NSLayoutConstraint.activate(bothConstraints)
            }
            
            UIView.animate(withDuration: .defaultAnimationDuration, delay: 0, options: [.beginFromCurrentState, curve], animations: {
                self.layoutIfNeeded()
            })
        }
    }
    
    private var heightConstraint: NSLayoutConstraint?
    private var topConstraints: [NSLayoutConstraint] = []
    private var bottomConstraints: [NSLayoutConstraint] = []
    private var bothConstraints: [NSLayoutConstraint] = []
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(screenshot: Screenshot) {
        toolbar = ShoppablesToolbar(screenshot: screenshot)
        subToolbar = ShoppablesToolbar(screenshot: screenshot)
        super.init(frame: .zero)
        
        let intrinsicHeight = intrinsicContentSize.height
        
        heightConstraint = heightAnchor.constraint(equalToConstant: intrinsicHeight)
        heightConstraint?.isActive = true
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.clipsToBounds = true
        addSubview(containerView)
        containerView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        containerView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        containerView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
        topConstraints += [
            containerView.heightAnchor.constraint(equalToConstant: intrinsicHeight)
        ]
        bottomConstraints += [
            containerView.heightAnchor.constraint(equalToConstant: intrinsicHeight)
        ]
        bothConstraints += [
            containerView.heightAnchor.constraint(equalToConstant: intrinsicHeight * 2)
        ]
        
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.barTintColor = .white
        toolbar.addSubview(BorderView(edge: .bottom))
        containerView.addSubview(toolbar)
        toolbar.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
        toolbar.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true
        
        topConstraints += [
            toolbar.topAnchor.constraint(equalTo: containerView.topAnchor),
            toolbar.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ]
        bottomConstraints += [
            toolbar.bottomAnchor.constraint(equalTo: containerView.topAnchor)
        ]
        bothConstraints += [
            toolbar.topAnchor.constraint(equalTo: containerView.topAnchor),
        ]
        
        subToolbar.translatesAutoresizingMaskIntoConstraints = false
        subToolbar.barTintColor = .white
        subToolbar.addSubview(BorderView(edge: .bottom))
        containerView.insertSubview(subToolbar, belowSubview: toolbar)
        subToolbar.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
        subToolbar.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true
        
        topConstraints += [
            subToolbar.topAnchor.constraint(equalTo: containerView.topAnchor)
        ]
        bottomConstraints += [
            subToolbar.topAnchor.constraint(equalTo: containerView.topAnchor),
            subToolbar.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ]
        bothConstraints += [
            subToolbar.topAnchor.constraint(equalTo: toolbar.bottomAnchor),
            subToolbar.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ]
        
        NSLayoutConstraint.activate(topConstraints)
    }
    
    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.height = toolbar.intrinsicContentSize.height
        return size
    }
}
