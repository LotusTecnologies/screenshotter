//
//  NotifyChangeView.swift
//  screenshot
//
//  Created by Corey Werner on 11/30/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation

class NotifyChangeView : UIView {
    private var previousSize = CGSize()
    private var previousSubviewCount = Int()
    
    var notifySizeChange: ((CGSize)->())?
    var notifySubviewChange: ((Int)->())?
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        previousSize = frame.size
    }
    
    override func didAddSubview(_ subview: UIView) {
        super.didAddSubview(subview)
        
        subviewChanged()
    }
    
    override func willRemoveSubview(_ subview: UIView) {
        super.willRemoveSubview(subview)
        
        subviewChanged()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let notifySizeChange = notifySizeChange, !previousSize.equalTo(bounds.size) {
            previousSize = bounds.size
            notifySizeChange(bounds.size)
        }
    }
    
    // MARK: Setters
    
    override var frame: CGRect {
        didSet {
            previousSize = frame.size
        }
    }
    
    override var bounds: CGRect {
        didSet {
            previousSize = bounds.size
        }
    }
    
    // MARK:
    
    private func subviewChanged() {
        if let notifySubviewChange = notifySubviewChange, previousSubviewCount != subviews.count {
            previousSubviewCount = subviews.count
            notifySubviewChange(subviews.count)
        }
    }
}
