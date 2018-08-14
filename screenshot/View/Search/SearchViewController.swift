//
//  SearchViewController.swift
//  Screenshop
//
//  Created by Corey Werner on 7/30/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController {
    let searchResultsViewController: SearchResultsViewController
    let searchController: UISearchController
    let categoriesNavigationController = SearchCategoriesNavigationController()
    
    private let searchPaginationController = SearchPaginationController()
    private let productsOptions = ProductsOptions(provider: .amazon)
    private let filterBarButtonItem = UIBarButtonItem(image: UIImage(named: "ProductsFilter"), style: .plain, target: nil, action: nil)
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        searchResultsViewController = SearchResultsViewController()
        searchController = SearchController(searchResultsController: searchResultsViewController)
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        definesPresentationContext = true
        
        searchResultsViewController.delegate = self
        
        productsOptions.delegate = self
        
        searchPaginationController.delegate = self
        syncSearchPagination(productsOptions)
        
        searchController.delegate = self
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = true
        searchController.hidesNavigationBarDuringPresentation = false
        
        searchController.searchBar.placeholder = "search.placeholder".localized
        searchController.searchBar.searchBarStyle = .minimal
        navigationItem.titleView = searchController.searchBar
        
        filterBarButtonItem.target = self
        filterBarButtonItem.action = #selector(presentOptions)
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
    
    deinit {
        searchResultsViewController.delegate = nil
        productsOptions.delegate = nil
        searchPaginationController.delegate = nil
        searchController.delegate = nil
        searchController.searchResultsUpdater = nil
    }
}

extension SearchViewController: SearchResultsViewControllerDelegate {
    func searchResultsViewControllerRequestNextItems(_ viewController: SearchResultsViewController) {
        searchPaginationController.next()
    }
}

extension SearchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text, !text.isEmpty else {
            searchResultsViewController.amazonItems = nil
            navigationItem.rightBarButtonItem = nil
            return
        }
        
        if navigationItem.rightBarButtonItem != filterBarButtonItem {
            navigationItem.setRightBarButton(filterBarButtonItem, animated: true)
        }
        
        searchAmazon(text)
    }
    
    private func searchAmazon(_ keywords: String) {
        guard let lastChar = keywords.last, lastChar != " " else {
            if keywords.trimmingCharacters(in: .whitespaces).isEmpty {
                searchResultsViewController.amazonItems = []
            }
            return
        }
        
        searchResultsViewController.amazonItems = nil
        
        searchPaginationController.search(keywords)
        
//        NetworkingPromise.sharedInstance.searchAmazon(keywords: keywords, options: (productsOptions.sort, productsOptions.gender, productsOptions.size))
//            .then { [weak self] amazonResponse -> Void in
//                if keywords == self?.searchController.searchBar.text {
//                    self?.searchResultsViewController.amazonItems = amazonResponse.items
//                }
//            }
//            .catch { [weak self] error in
//                if keywords == self?.searchController.searchBar.text {
//                    self?.searchResultsViewController.amazonItems = []
//                }
//        }
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

extension SearchViewController: ProductsOptionsDelegate {
    @objc private func presentOptions() {
        Analytics.trackOpenedFiltersView()
        present(productsOptions.viewController, animated: true)
    }
    
    @objc private func dismissOptions() {
        productsOptions.viewController.presentingViewController?.dismiss(animated: true)
    }
    
    func productsOptionsDidComplete(_ productsOptions: ProductsOptions, withModelChange changed: Bool) {
        syncSearchPagination(productsOptions)
        
        if let text = searchController.searchBar.text, !text.isEmpty {
            searchAmazon(text)
        }
        
        dismissOptions()
    }
    
    func productsOptionsDidCancel(_ productsOptions: ProductsOptions) {
        dismissOptions()
    }
}

extension SearchViewController: SearchPaginationControllerDelegate {
    func searchPaginationControllerKeywords(_ controller: SearchPaginationController) -> String? {
        return searchController.searchBar.text
    }
    
    func searchPaginationController(_ controller: SearchPaginationController, items: [AmazonItem], page: Int) {
        searchResultsViewController.amazonItems = items
    }
    
    func searchPaginationControllerFinalPage(_ controller: SearchPaginationController) {
        
    }
    
    private func syncSearchPagination(_ productsOptions: ProductsOptions) {
        searchPaginationController.gender = productsOptions.gender
        searchPaginationController.sort = productsOptions.sort
        searchPaginationController.size = productsOptions.size
    }
}
