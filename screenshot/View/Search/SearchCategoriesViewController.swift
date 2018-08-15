//
//  SearchCategoriesViewController.swift
//  Screenshop
//
//  Created by Corey Werner on 7/31/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class SearchCategoriesViewController: UIViewController {
    var parentBranch: SearchBranch?
    var branches: [SearchBranch] = [] {
        didSet {
            collectionViewReset()
        }
    }
    var columns = 1
    
    private let searchResultsViewController = SearchResultsViewController()
    private let searchPaginationController = SearchPaginationController()
    private var keywords = ""
    
    private let collectionViewLayout: UICollectionViewFlowLayout
    private let collectionView: UICollectionView
    
    private var currentSearchClass: SearchClass? {
        return (navigationController as? SearchCategoriesNavigationController)?.currentSearchClass
    }
    
    init() {
        collectionViewLayout = UICollectionViewFlowLayout()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        
        super.init(nibName: nil, bundle: nil)
        
        
        searchResultsViewController.delegate = self
        searchPaginationController.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        collectionViewLayout.sectionInset = UIEdgeInsets(top: 0, left: .padding, bottom: .padding, right: .padding)
        
        collectionView.backgroundColor = view.backgroundColor
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(SearchCategoryCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.keyboardDismissMode = .onDrag
        view.addSubview(collectionView)
        collectionView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    }
    
    deinit {
        searchResultsViewController.delegate = nil
        searchPaginationController.delegate = nil
    }
}

extension SearchCategoriesViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return branches.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        
        if let cell = cell as? SearchCategoryCollectionViewCell {
            let branch = branches[indexPath.item]
            
            cell.imageView.sd_setImage(with: URL(string: branch.image ?? ""))
            cell.titleLabel.text = branch.category.title
        }
        
        return cell
    }
    
    private func collectionViewReset() {
        collectionView.resetContentOffset()
        collectionView.reloadData()
    }
}

extension SearchCategoriesViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let branch = branches[indexPath.item]
        
        if let subcategories = branch.subcategories, !subcategories.isEmpty {
            let subcategoriesViewController = SearchCategoriesViewController()
            subcategoriesViewController.branches = subcategories
            subcategoriesViewController.parentBranch = branch
            subcategoriesViewController.title = branch.category.title
            navigationController?.pushViewController(subcategoriesViewController, animated: true)
        }
        else {
            searchAndPushResults(searchBranch: branch)
        }
    }
}

extension SearchCategoriesViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let spacing: CGFloat
        
        if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
            spacing = flowLayout.sectionInset.left
        }
        else {
            spacing = .padding
        }
        
        let size: CGFloat = (view.bounds.size.width - (spacing * CGFloat(columns + 1))) / CGFloat(columns)
        return CGSize(width: size, height: 108)
    }
}

// MARK: - Search

extension SearchCategoriesViewController {
    func searchAndPushResults(searchBranch: SearchBranch) {
        keywords = searchBranch.keyword ?? ""
        
        searchPaginationController.gender = {
            if let currentSearchClass = currentSearchClass {
                switch currentSearchClass {
                case .men:
                    return .male
                case .women:
                    return .female
                }
            }
            return .female
        }()
        searchPaginationController.search(keywords)
        
        searchResultsViewController.title = searchBranch.category.title
        navigationController?.pushViewController(searchResultsViewController, animated: true)
    }
}

// MARK: - Search Results

extension SearchCategoriesViewController: SearchResultsViewControllerDelegate {
    func searchResultsViewControllerRequestNextItems(_ viewController: SearchResultsViewController) {
        searchPaginationController.next()
    }
}

// MARK: - Search Pagination

extension SearchCategoriesViewController: SearchPaginationControllerDelegate {
    func searchPaginationControllerKeywords(_ controller: SearchPaginationController) -> String? {
        return keywords
    }
    
    func searchPaginationController(_ controller: SearchPaginationController, items: [AmazonItem], page: Int) {
        searchResultsViewController.isPaginationEnabled = page < controller.maxPages
        searchResultsViewController.amazonItems = controller.items
    }
}
