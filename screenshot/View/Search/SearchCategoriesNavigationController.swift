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
        
        navigationBar.backgroundColor = .white
        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.shadowImage = UIImage()
        
        let genderControl = UISegmentedControl(items: searchClasses.map({ $0.possessiveTitle }))
        genderControl.selectedSegmentIndex = 0
        genderControl.addTarget(self, action: #selector(syncBranches(_:)), for: .valueChanged)
        searchCategoriesViewController.navigationItem.titleView = genderControl
        searchCategoriesViewController.columns = 2
        syncBranches(genderControl)
        
        viewControllers = [searchCategoriesViewController]
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Options
    
    @objc private func syncBranches(_ segmentedControl: UISegmentedControl) {
        currentSearchClass = searchClasses[segmentedControl.selectedSegmentIndex]
        
        guard let searchRoot = SearchCategoryModel.shared.root else {
            return
        }
        
        switch currentSearchClass {
        case .men:
            searchCategoriesViewController.branches = searchRoot.men
        case .women:
            searchCategoriesViewController.branches = searchRoot.women
        }
    }
}
