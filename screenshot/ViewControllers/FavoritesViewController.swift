//
//  FavoritesViewController.swift
//  screenshot
//
//  Created by Corey Werner on 11/29/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation

class FavoritesViewController : BaseViewController {
    fileprivate let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: UICollectionViewFlowLayout())
    private let helperView = HelperView()
    
    fileprivate let favoriteFrc = DataModel.sharedInstance.favoriteFrc
    fileprivate var unfavoriteProducts: [Product] = []
    
    private var didViewWillAppear = false
    private var needsReloadData = false
    
    override var title: String? {
        set {}
        get {
            return "favorites.title".localized
        }
    }
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground(_:)), name: .UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground(_:)), name: .UIApplicationWillEnterForeground, object: nil)
        
        addNavigationItemLogo()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.minimumInteritemSpacing = .padding
            layout.minimumLineSpacing = .padding
        }
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.contentInset = UIEdgeInsets(top: .padding, left: .padding, bottom: .padding, right: .padding)
        collectionView.backgroundColor = view.backgroundColor
        collectionView.register(ProductCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        view.addSubview(collectionView)
        collectionView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        helperView.translatesAutoresizingMaskIntoConstraints = false
        helperView.layoutMargins = UIEdgeInsets(top: .extendedPadding, left: .padding, bottom: .extendedPadding, right: .padding)
        helperView.titleLabel.text = "favorites.empty.title".localized
        helperView.subtitleLabel.text = "favorites.empty.detail".localized
        helperView.contentImage = UIImage(named: "FavoriteEmptyListGraphic")
        view.addSubview(helperView)
        helperView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        helperView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        helperView.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor).isActive = true
        helperView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if didViewWillAppear || needsReloadData {
            needsReloadData = false
            collectionView.reloadData()
        }
        
        didViewWillAppear = true
        
        syncHelperViewVisibility()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        removeUnfavorited()
    }
    
    @objc private func applicationDidEnterBackground(_ notification: Notification) {
        guard view.window != nil else {
            return
        }
        
        removeUnfavorited()
    }
    
    @objc private func applicationWillEnterForeground(_ notification: Notification) {
        guard view.window != nil else {
            return
        }
        
        if needsReloadData {
            needsReloadData = false
            collectionView.reloadData()
        }
    }
    
    deinit {
        collectionView.delegate = nil
        collectionView.dataSource = nil
        
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Favorites
    
    func removeUnfavorited() {
        guard unfavoriteProducts.count > 0 else {
            return
        }
        
        DataModel.sharedInstance.unfavorite(favoriteArray: unfavoriteProducts)
        unfavoriteProducts.removeAll()
        needsReloadData = true
    }
    
    // MARK: Helper View
    
    func syncHelperViewVisibility() {
        helperView.isHidden = (collectionView.numberOfItems(inSection: 0) > 0)
    }
}

extension FavoritesViewController : UICollectionViewDataSource {
    var numberOfCollectionViewColumns: Int {
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return favoriteFrc.fetchedObjects?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let product = favoriteFrc.object(at: indexPath)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        
        if let cell = cell as? ProductCollectionViewCell {
            cell.delegate = self
            cell.contentView.backgroundColor = collectionView.backgroundColor
            cell.title = product.productDescription
            cell.price = product.price
            cell.imageUrl = product.imageURL
            cell.favoriteButton.isSelected = product.isFavorite
        }
        
        return cell
    }
}

extension FavoritesViewController : UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let topViewController = navigationController?.topViewController,
            !topViewController.isKind(of: WebViewController.self) else
        {
            return
        }
        
        let product = favoriteFrc.object(at: indexPath)
        
        guard let offer = product.offer else {
            return
        }

        let webViewController = WebViewController()
        webViewController.addNavigationItemLogo()
        webViewController.hidesBottomBarWhenPushed = true
        webViewController.url = URL(string: offer)

        navigationController?.pushViewController(webViewController, animated: true)
        
        AnalyticsTrackers.standard.trackTappedOnProduct(product, onPage: "Favorites")
        AnalyticsTrackers.branch.track("Tapped on product")
    }
}

extension FavoritesViewController : UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let columns = CGFloat(numberOfCollectionViewColumns)
        
        var size = CGSize.zero
        size.width = (collectionView.bounds.size.width - ((columns + 1) * .padding)) / columns
        size.height = size.width + ProductCollectionViewCell.labelsHeight()
        return size
    }
}

extension FavoritesViewController : ProductCollectionViewCellDelegate {
    func productCollectionViewCellDidTapFavorite(_ cell: ProductCollectionViewCell!) {
        guard let indexPath = collectionView.indexPath(for: cell) else {
            return
        }
        
        let isFavorited = cell.favoriteButton.isSelected
        let product = favoriteFrc.object(at: indexPath)

        if isFavorited {
            if let index = unfavoriteProducts.index(of: product) {
                unfavoriteProducts.remove(at: index)
            }

        } else {
            unfavoriteProducts.append(product)
        }

        AnalyticsTrackers.standard.trackFavorited(isFavorited, product: product, onPage: "Favorites")
    }
}

