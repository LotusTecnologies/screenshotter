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
    
    private let collectionViewLayout: UICollectionViewFlowLayout
    private let collectionView: UICollectionView
    
    private var currentSearchClass: SearchClass? {
        return (navigationController as? SearchCategoriesNavigationController)?.currentSearchClass
    }
    
    init() {
        collectionViewLayout = UICollectionViewFlowLayout()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        
        super.init(nibName: nil, bundle: nil)
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
}

extension SearchCategoriesViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return branches.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        
        if let cell = cell as? SearchCategoryCollectionViewCell {
            let branch = branches[indexPath.item]
            
            let width = Int(round(cell.bounds.width))
            let height = Int(round(cell.bounds.height))
            let url = URL(string: "https://picsum.photos/\(width)/\(height)?image=10\(indexPath.item)")
            cell.imageView.sd_setImage(with: url)
            
            cell.titleLabel.text = branch.category.title
        }
        
        return cell
    }
    
    private func collectionViewReset() {
        collectionView.contentOffset = {
            var contentOffset: CGPoint = .zero
            
            if #available(iOS 11.0, *) {
                contentOffset.y = -collectionView.safeAreaInsets.top
            }
            else {
                contentOffset.y = -collectionView.contentInset.top
            }
            
            return contentOffset
        }()
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
            searchAndPushResults(searchCategory: branch.category)
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
    func searchAndPushResults(searchCategory: SearchCategory) {
        let text = searchQuery(searchCategory)
        let gender: ProductsOptionsGender = {
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
        
        let searchResultsViewController = SearchResultsViewController(style: .plain)
        searchResultsViewController.title = searchCategory.title
        navigationController?.pushViewController(searchResultsViewController, animated: true)
        
        NetworkingPromise.sharedInstance.searchAmazon(keywords: text, options: (.default, gender, .adult))
            .then { [weak searchResultsViewController] amazonItems -> Void in
//                searchResultsViewController?.amazonItems = amazonItems
            }
            .catch { error in
                // TODO:
        }
    }
    
    private func searchQuery(_ searchCategory: SearchCategory) -> String {
        func singular(_ text: String) -> String {
            return text.split(separator: " ").reduce("", { (query, word) -> String in
                var singularWord = word
                let returnedWord: String
                
                if let letter = singularWord.popLast(), letter == "s", singularWord.last != "s" {
                    returnedWord = String(singularWord)
                }
                else {
                    returnedWord = String(word)
                }
                
                return query.isEmpty ? returnedWord : "\(query) \(returnedWord)"
            })
        }
        
        var query = "\(singular(searchCategory.title))"
        
        if let parentSearchCategory = parentBranch?.category {
            if !query.contains(parentSearchCategory.title) {
                query += " \(singular(parentSearchCategory.title))"
            }
        }
        
        return query
    }
}
