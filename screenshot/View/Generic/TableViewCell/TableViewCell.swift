//
//  TableViewCell.swift
//  screenshot
//
//  Created by Corey Werner on 4/24/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class TableViewCell: UITableViewCell {
    private var _next: UIResponder?
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        
    }
    
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
