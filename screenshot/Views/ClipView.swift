//
//  ClipView.swift
//  screenshot
//
//  Created by Corey Werner on 11/1/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation

class ClipView: UIView {
    override var frame: CGRect {
        didSet {
            // TODO: call common setup code if we have a frame and clippings
        }
    }
    
    public var clippings: [UIBezierPath]? {
        didSet {
            // TODO: check we have a frame
            guard let clippings = clippings, clippings.count > 0 else {
                layer.mask = nil
                return
            }
            
            //    UIBezierPath *path = [UIBezierPath bezierPathWithRect:self.view.bounds];
            //    UIBezierPath *croppedPath = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:6];
            //    [path appendPath:croppedPath];
            //    [path setUsesEvenOddFillRule:YES];
            //
            //    CAShapeLayer *mask = [CAShapeLayer layer];
            //    mask.path = path.CGPath;
            //    mask.fillRule = kCAFillRuleEvenOdd;
            //    v.layer.mask = mask;
            
            let path = UIBezierPath(rect: bounds)
            path.append(clippings.first!)
            path.usesEvenOddFillRule = true
            
//            clippings.forEach({ clippedPath in
//                path.append(clippedPath)
//            })
            
            let mask = CAShapeLayer()
            mask.path = path.cgPath
            mask.fillRule = kCAFillRuleEvenOdd
            layer.mask = mask
        }
    }
    
    
}
