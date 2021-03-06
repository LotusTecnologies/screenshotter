//
//  BorderView.swift
//  screenshot
//
//  Created by Corey Werner on 3/5/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import UIKit

class BorderView: UIView {
    let edge: UIRectEdge
    
    required init?(coder aDecoder: NSCoder) {
        self.edge = .top
        super.init(coder: aDecoder)
    }
    
    init(edge: UIRectEdge, height: CGFloat = .halfPoint) {
        self.edge = edge
        super.init(frame: .zero)
        
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .border
        setContentHuggingPriority(UILayoutPriority.required, for: .vertical)
        setContentHuggingPriority(UILayoutPriority.required, for: .horizontal)
        setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        setContentCompressionResistancePriority(UILayoutPriority.required, for: .horizontal)
        
        switch edge {
        case .top, .bottom:
            heightAnchor.constraint(equalToConstant: height).isActive = true
        case .left, .right:
            widthAnchor.constraint(equalToConstant: height).isActive = true
        default:
            break
        }
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        guard let superview = superview else {
            return
        }
        
        switch edge {
        case .top:
            topAnchor.constraint(equalTo: superview.topAnchor).isActive = true
            leadingAnchor.constraint(equalTo: superview.leadingAnchor).isActive = true
            trailingAnchor.constraint(equalTo: superview.trailingAnchor).isActive = true
            
        case .left:
            topAnchor.constraint(equalTo: superview.topAnchor).isActive = true
            leadingAnchor.constraint(equalTo: superview.leadingAnchor).isActive = true
            bottomAnchor.constraint(equalTo: superview.bottomAnchor).isActive = true
            
        case .bottom:
            leadingAnchor.constraint(equalTo: superview.leadingAnchor).isActive = true
            bottomAnchor.constraint(equalTo: superview.bottomAnchor).isActive = true
            trailingAnchor.constraint(equalTo: superview.trailingAnchor).isActive = true
            
        case .right:
            topAnchor.constraint(equalTo: superview.topAnchor).isActive = true
            bottomAnchor.constraint(equalTo: superview.bottomAnchor).isActive = true
            trailingAnchor.constraint(equalTo: superview.trailingAnchor).isActive = true
            
        default:
            break
        }
    }
}
