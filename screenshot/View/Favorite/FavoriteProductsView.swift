//
//  FavoriteProductsView.swift
//  screenshot
//
//  Created by Corey Werner on 3/20/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import UIKit

class FavoriteProductsView: UIView {
    let tableView = TableView(frame: .zero, style: .grouped)
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorInset = .zero
        addSubview(tableView)
        tableView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    }
}
