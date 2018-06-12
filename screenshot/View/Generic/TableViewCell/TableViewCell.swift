//
//  TableViewCell.swift
//  screenshot
//
//  Created by Corey Werner on 4/24/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import UIKit

class TableViewCell: UITableViewCell {
    private var _next: UIResponder?
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        if let next = next as? UIView, !next.isKind(of: UITableView.self) {
            var superview = next.superview
            
            while superview != nil {
                if let tableView = superview as? UITableView {
                    _next = tableView
                    break
                }
                else {
                    superview = superview?.superview
                }
            }
        }
    }
    
    override var next: UIResponder? {
        return _next ?? super.next
    }
}
