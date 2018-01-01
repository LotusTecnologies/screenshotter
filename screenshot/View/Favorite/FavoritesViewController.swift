//
//  FavoritesViewController.swift
//  screenshot
//
//  Created by Corey Werner on 11/29/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation
import CoreData

protocol FavoritesViewControllerDelegate : NSObjectProtocol {
    func favoritesViewController(_ viewController: FavoritesViewController, didSelectItemAt indexPath: IndexPath)
}

class FavoritesViewController : BaseViewController {
    weak var delegate: FavoritesViewControllerDelegate?
    
    fileprivate let tableView = UITableView()
    private let helperView = HelperView()
    
    fileprivate let favoriteFrc = DataModel.sharedInstance.favoriteFrc
    
    override var title: String? {
        set {}
        get {
            return "favorites.title".localized
        }
    }
    
    // MARK: Life Cycle
    
    private var isViewWillAppear = false
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        DataModel.sharedInstance.favoriteFrcDelegate = self
        
        addNavigationItemLogo()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = view.backgroundColor
        tableView.register(FavoritesTableViewCell.self, forCellReuseIdentifier: "cell1")
        tableView.register(FavoritesTableViewCell.self, forCellReuseIdentifier: "cell2")
        tableView.register(FavoritesTableViewCell.self, forCellReuseIdentifier: "cell3")
        tableView.rowHeight = 170
        tableView.tableFooterView = UIView() // Remove empty cells
        tableView.separatorInset = .zero
        view.addSubview(tableView)
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
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
        isViewWillAppear = true
        
        if screenshotAssetIds.count == 0 {
            syncScreenshotAssetIds()
        }
        
        updateScreenshotsProductsIfNeeded()
        syncHelperViewVisibility()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        isViewWillAppear = false
    }
    
    deinit {
        tableView.delegate = nil
        tableView.dataSource = nil
        
        DataModel.sharedInstance.favoriteFrcDelegate = nil
    }
    
    // MARK: Screenshot
    
    func screenshot(at indexPath: IndexPath) -> Screenshot? {
        guard let screenshots = favoriteFrc.fetchedObjects else {
            return nil
        }
        
        return screenshots[indexPath.row]
    }
    
    func screenshot(withAssetId assetId: String) -> Screenshot? {
        return favoriteFrc.fetchedObjects?.first(where: { screenshot -> Bool in
            return screenshot.assetId == assetId
        })
    }
    
    fileprivate var screenshotAssetIds: [String] = []
    
    fileprivate func syncScreenshotAssetIds() {
        screenshotAssetIds = favoriteFrc.fetchedObjects?.map { screenshot -> String in
            return screenshot.assetId ?? ""
        } ?? []
    }
    
    // MARK: Products
    
    fileprivate var screenshotsProducts: [String : [Product]] = [:]
    fileprivate var reloadProductsSet: Set<String> = Set()
    fileprivate var removeProductsSet: Set<String> = Set()
    
    fileprivate func updateReloadProductsSet(at indexPath: IndexPath) {
        guard let assetId = screenshot(at: indexPath)?.assetId else {
            return
        }
        
        reloadProductsSet.insert(assetId)
        
        updateScreenshotsProductsIfNeeded()
        
        if tableView.numberOfRows(inSection: 0) > 0 && indexPath.row == 0 {
            tableView.scrollToRow(at: indexPath, at: .top, animated: false)
        }
    }
    
    fileprivate func updateRemoveProductsSet(at indexPath: IndexPath) {
        removeProductsSet.insert(screenshotAssetIds[indexPath.row])
        
        updateScreenshotsProductsIfNeeded()
    }
    
    fileprivate func insertUniqueScreenshotProducts(withScreenshot screenshot: Screenshot) {
        if let assetId = screenshot.assetId, screenshotsProducts[assetId] == nil {
            screenshotsProducts[assetId] = screenshot.favoritedProducts
        }
    }
    
    fileprivate func updateScreenshotsProducts(withAssetIds assetIds: [String]) {
        assetIds.forEach { assetId in
            if screenshotsProducts[assetId] != nil, let screenshot = self.screenshot(withAssetId: assetId) {
                screenshotsProducts[assetId] = screenshot.favoritedProducts
            }
        }
    }
    
    fileprivate func removeScreenshotsProducts(withAssetIds assetIds: [String]) {
        assetIds.forEach { assetId in
            screenshotsProducts.removeValue(forKey: assetId)
        }
    }
    
    fileprivate func removeAllScreenshotsProducts() {
        screenshotsProducts.removeAll()
    }
    
    fileprivate func updateScreenshotsProductsIfNeeded() {
        guard isViewWillAppear else {
            return
        }
        
        var didChangeData = false
        
        if reloadProductsSet.count > 0 {
            updateScreenshotsProducts(withAssetIds: Array(reloadProductsSet))
            reloadProductsSet.removeAll()
            didChangeData = true
        }
        
        if removeProductsSet.count > 0 {
            removeScreenshotsProducts(withAssetIds: Array(removeProductsSet))
            removeProductsSet.removeAll()
            didChangeData = true
        }
        
        if didChangeData {
            tableView.reloadData()
            syncHelperViewVisibility()
        }
    }
    
    func products(for screenshot: Screenshot) -> [Product] {
        if let assetId = screenshot.assetId {
            return screenshotsProducts[assetId] ?? []
            
        } else {
            return screenshot.favoritedProducts
        }
    }
    
    // MARK: Helper View
    
    fileprivate func syncHelperViewVisibility() {
        helperView.isHidden = (tableView.numberOfRows(inSection: 0) > 0)
    }
}

extension FavoritesViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return favoriteFrc.fetchedObjects?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        // Prevent all cells from calculating immediately
        return tableView.rowHeight
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let screenshot = screenshot(at: indexPath) else {
            return UITableViewCell()
        }
        
        insertUniqueScreenshotProducts(withScreenshot: screenshot)
        let products = self.products(for: screenshot)
        let identifier: String
        
        switch products.count {
        case 1:
            identifier = "cell1"
        case 2:
            identifier = "cell2"
        default:
            identifier = "cell3"
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        
        if let cell = cell as? FavoritesTableViewCell {
            cell.backgroundColor = view.backgroundColor
            cell.imageData = screenshot.imageData
            cell.textLabel?.text = "\(products.count) Favorited Items" // TODO: localize
            cell.products = products
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .none
        }
        
        return cell
    }
}

extension FavoritesViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.favoritesViewController(self, didSelectItemAt: indexPath)
    }
}

extension FavoritesViewController : FrcDelegateProtocol {
    func frc(_ frc: NSFetchedResultsController<NSFetchRequestResult>, oneAddedAt indexPath: IndexPath) {
        syncScreenshotAssetIds()
        updateReloadProductsSet(at: indexPath)
    }
    
    func frc(_ frc: NSFetchedResultsController<NSFetchRequestResult>, oneDeletedAt indexPath: IndexPath) {
        updateRemoveProductsSet(at: indexPath)
        syncScreenshotAssetIds()
    }
    
    func frc(_ frc: NSFetchedResultsController<NSFetchRequestResult>, oneUpdatedAt indexPath: IndexPath) {
        updateReloadProductsSet(at: indexPath)
    }
    
    func frc(_ frc: NSFetchedResultsController<NSFetchRequestResult>, oneMovedTo indexPath: IndexPath) {
        updateReloadProductsSet(at: indexPath)
    }
    
    func frcReloadData(_ frc: NSFetchedResultsController<NSFetchRequestResult>) {
        removeAllScreenshotsProducts()
        syncScreenshotAssetIds()
    }
}
