//
//  SearchNavigationController.swift
//  Screenshop
//
//  Created by Corey Werner on 7/30/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class SearchNavigationController: UINavigationController {
    let searchViewController = SearchViewController()
    
    init() {
        super.init(nibName: nil, bundle: nil)
        
        viewControllers = [searchViewController]
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
    }
}
