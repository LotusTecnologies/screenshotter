//
//  AutoresizingTableView.swift
//  screenshot
//
//  Created by Corey Werner on 4/9/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class AutoresizingTableView: UITableView {
    override var contentSize: CGSize {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    
    override var intrinsicContentSize: CGSize {
        layoutSubviews()
        return CGSize(width: UIViewNoIntrinsicMetric, height: contentSize.height)
    }
}
