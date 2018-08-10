//
//  SearchCategoriesNavigationController.swift
//  Screenshop
//
//  Created by Corey Werner on 8/10/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit
import PromiseKit

class SearchCategoriesNavigationController: UINavigationController {
    let searchCategoriesViewController = SearchCategoriesViewController()
    
    private let searchClasses: [SearchClass] = [.women, .men]
    private(set) var currentSearchClass: SearchClass = .women
    
    init() {
        super.init(nibName: nil, bundle: nil)
        
        navigationBar.shadowImage = UIImage()
        
        let genderControl = UISegmentedControl(items: searchClasses.map({ $0.possessiveTitle }))
        genderControl.selectedSegmentIndex = 0
        genderControl.addTarget(self, action: #selector(genderControlDidChange(_:)), for: .valueChanged)
        searchCategoriesViewController.navigationItem.titleView = genderControl
        
        searchCategoriesViewController.columns = 2
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Options
    
    @objc private func genderControlDidChange(_ segmentedControl: UISegmentedControl) {
        currentSearchClass = searchClasses[segmentedControl.selectedSegmentIndex]
        searchCategoriesViewController.branches = currentSearchClass.dataSource
    }
}
