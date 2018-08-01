//
//  SearchViewController.swift
//  Screenshop
//
//  Created by Corey Werner on 7/30/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController {
    let searchController: UISearchController
    let categoriesNavigationController: UINavigationController
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        categoriesNavigationController = UINavigationController(rootViewController: SearchCategoriesViewController())
        categoriesNavigationController.navigationBar.shadowImage = UIImage()
        
        let tableViewController = UITableViewController(style: .plain)
        
        searchController = SearchController(searchResultsController: tableViewController)
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        definesPresentationContext = true
        
        searchController.delegate = self
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = true
        searchController.hidesNavigationBarDuringPresentation = false
        
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = "search.placeholder".localized
        searchController.searchBar.searchBarStyle = .minimal
        
//        searchController.searchBar.setContentCompressionResistancePriority(.required, for: .horizontal)
        
//        let v = UIView()
//        v.translatesAutoresizingMaskIntoConstraints = false
//        v.backgroundColor = .red
//        v.addSubview(searchController.searchBar)
//        navigationItem.titleView = v
//        v.widthAnchor.constraint(equalToConstant: 300).isActive = true
//        v.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        
        navigationItem.titleView = searchController.searchBar
        
//        searchController.searchBar.translatesAutoresizingMaskIntoConstraints = false
//        searchController.searchBar.topAnchor.constraint(equalTo: v.topAnchor).isActive = true
//        searchController.searchBar.leadingAnchor.constraint(equalTo: v.leadingAnchor).isActive = true
//        searchController.searchBar.bottomAnchor.constraint(equalTo: v.bottomAnchor).isActive = true
//        searchController.searchBar.trailingAnchor.constraint(equalTo: v.trailingAnchor).isActive = true
        
//        searchController.searchBar.widthAnchor.constraint(equalToConstant: 100).isActive = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
//        var frame = searchController.searchBar.frame
//        frame.size.width = 200
//        searchController.searchBar.frame = frame
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addChildViewController(categoriesNavigationController)
        view.addSubview(categoriesNavigationController.view)
        categoriesNavigationController.didMove(toParentViewController: self)
        
        categoriesNavigationController.view.translatesAutoresizingMaskIntoConstraints = false
        categoriesNavigationController.view.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor).isActive = true
        categoriesNavigationController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        categoriesNavigationController.view.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor).isActive = true
        categoriesNavigationController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    }
}

extension SearchViewController: UISearchBarDelegate {
    
}

extension SearchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        
    }
}

extension SearchViewController: UISearchControllerDelegate {
    func presentSearchController() {
        searchController.isActive = true
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak searchController] timer in
            guard let searchController = searchController else {
                timer.invalidate()
                return
            }
            
            if searchController.searchBar.canBecomeFirstResponder {
                searchController.searchBar.becomeFirstResponder()
                timer.invalidate()
            }
        }
    }
}
