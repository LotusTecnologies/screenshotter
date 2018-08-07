//
//  SearchSubcategoriesViewController.swift
//  Screenshop
//
//  Created by Corey Werner on 7/31/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class SearchSubcategoriesViewController: UIViewController {
    let searchCategories: [SearchCategory]
    private let collectionViewLayout: UICollectionViewFlowLayout
    private let collectionView: UICollectionView
    
    init(searchCategories: [SearchCategory]) {
        self.searchCategories = searchCategories
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
        
        let columns: CGFloat = 1
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
}

extension SearchSubcategoriesViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return searchCategories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        
        if let cell = cell as? SearchCategoryCollectionViewCell {
            let width = Int(round(cell.bounds.width))
            let height = Int(round(cell.bounds.height))
            let url = URL(string: "https://picsum.photos/\(width)/\(height)?image=20\(indexPath.item)")
            cell.imageView.sd_setImage(with: url)
            
            cell.titleLabel.text = searchCategories[indexPath.item].rawValue
        }
        
        return cell
    }
}

extension SearchSubcategoriesViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
}
