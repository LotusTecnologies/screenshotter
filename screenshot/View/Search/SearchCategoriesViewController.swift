//
//  SearchCategoriesViewController.swift
//  Screenshop
//
//  Created by Corey Werner on 7/31/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class SearchCategoriesViewController: UIViewController {
    private let collectionViewLayout: UICollectionViewFlowLayout
    private let collectionView: UICollectionView
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        collectionViewLayout = UICollectionViewFlowLayout()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        let genderControl = UISegmentedControl(items: searchClasses.map({ $0.possessiveTitle }))
        genderControl.selectedSegmentIndex = 0
        genderControl.addTarget(self, action: #selector(genderControlDidChange(_:)), for: .valueChanged)
        navigationItem.titleView = genderControl
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        let columns: CGFloat = 2
        let spacing: CGFloat = .padding
        let size: CGFloat = (view.bounds.size.width - (spacing * (columns + 1))) / columns
        collectionViewLayout.itemSize = CGSize(width: size, height: 108)
        collectionViewLayout.sectionInset = UIEdgeInsets(top: 0, left: spacing, bottom: spacing, right: spacing)
        
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
    
    // MARK: Search Class
    
    private let searchClasses: [SearchClass] = [.women, .men]
    private var currentSearchClass: SearchClass = .women
    
    @objc private func genderControlDidChange(_ segmentedControl: UISegmentedControl) {
        currentSearchClass = searchClasses[segmentedControl.selectedSegmentIndex]
        
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

extension SearchCategoriesViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return currentSearchClass.dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        
        if let cell = cell as? SearchCategoryCollectionViewCell,
            let searchCategory = currentSearchClass.dataSource.section(indexPath.item)
        {
            let width = Int(round(cell.bounds.width))
            let height = Int(round(cell.bounds.height))
            let genderInt = currentSearchClass.intValue + 1
            let url = URL(string: "https://picsum.photos/\(width)/\(height)?image=\(genderInt)0\(indexPath.item)")
            cell.imageView.sd_setImage(with: url)
            
            cell.titleLabel.text = searchCategory.rawValue
        }
        
        return cell
    }
}

extension SearchCategoriesViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let searchCategory = currentSearchClass.dataSource.section(indexPath.item),
            let searchSubcategories = currentSearchClass.dataSource.rows(indexPath.item)
            else {
                return
        }
        
        if searchSubcategories.isEmpty {
            // TODO:
        }
        else {
            let subcategoriesViewController = SearchSubcategoriesViewController(searchCategories: searchSubcategories)
            subcategoriesViewController.title = searchCategory.rawValue
            navigationController?.pushViewController(subcategoriesViewController, animated: true)
        }
    }
}
