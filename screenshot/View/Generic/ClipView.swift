//
//  ClipView.swift
//  screenshot
//
//  Created by Corey Werner on 11/1/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation
import UIKit

class ClipView: UIView {
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor(white: 0, alpha: 0.55)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateMask()
    }
    
    override var frame: CGRect {
        didSet {
            updateMask()
        }
    }
    
    // MARK: Mask
    
    public var clippings: [UIBezierPath]? {
        didSet {
            updateMask()
        }
    }
    
    private func updateMask() {
        guard let clippings = clippings, clippings.count > 0, !bounds.size.equalTo(.zero) else {
            layer.mask = nil
            return
        }
        
        let path = UIBezierPath(rect: bounds)
        path.usesEvenOddFillRule = true
        
        clippings.forEach({ clippedPath in
            path.append(clippedPath)
        })
        
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        mask.fillRule = kCAFillRuleEvenOdd
        layer.mask = mask
    }
    
    // MARK: User Interaction
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        var isInside = super.point(inside: point, with: event)
        
        if let clippings = clippings {
            for (_, clippedPath) in clippings.enumerated() {
                if clippedPath.bounds.contains(point) {
                    isInside = false
                    break
                }
            }
        }
        
        return isInside
    }
}
