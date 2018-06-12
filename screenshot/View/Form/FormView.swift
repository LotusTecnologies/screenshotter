//
//  FormView.swift
//  screenshot
//
//  Created by Corey Werner on 3/26/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import UIKit

class FormView: UIView {
    let tableView = FormViewTableView(frame: .zero, style: .grouped)
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.keyboardDismissMode = .onDrag
        addSubview(tableView)
        tableView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    }
}

class FormViewTableView: UITableView {
    private var disableContentOffsetAdjustmentTimer: Timer?
    private var contentOffsetCalledCount = 0
    
    deinit {
        disableContentOffsetAdjustmentTimer?.invalidate()
    }
    
    override func beginUpdates() {
        // Prevent unwanted scrolling from picker views opening and closing.
        contentOffsetCalledCount = 0
        var previousContentOffsetCalledCount = 0
        
        disableContentOffsetAdjustmentTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { timer in
            if previousContentOffsetCalledCount == self.contentOffsetCalledCount {
                timer.invalidate()
                self.disableContentOffsetAdjustmentTimer = nil
            }
            
            previousContentOffsetCalledCount = self.contentOffsetCalledCount
        })
        
        super.beginUpdates()
    }
    
    override var contentOffset: CGPoint {
        set {
            contentOffsetCalledCount += 1
            
            if isTracking, let timer = disableContentOffsetAdjustmentTimer {
                timer.invalidate()
                disableContentOffsetAdjustmentTimer = nil
            }
            
            if disableContentOffsetAdjustmentTimer == nil {
                super.contentOffset = newValue
            }
        }
        get {
            return super.contentOffset
        }
    }
}
