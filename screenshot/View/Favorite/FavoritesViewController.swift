//
//  FavoritesViewController.swift
//  screenshot
//
//  Created by Corey Werner on 11/29/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation
import CoreData
import UIKit

protocol FavoritesViewControllerDelegate : NSObjectProtocol {
    func favoritesViewController(_ viewController: FavoritesViewController, didSelectItemAt indexPath: IndexPath)
}

class FavoritesViewController : BaseViewController {
    weak var delegate: FavoritesViewControllerDelegate?
    
    fileprivate let coreDataPreparationController = CoreDataPreparationController()
    fileprivate let tableView = UITableView()
    private let helperView = HelperView()
    
    fileprivate var favoriteFrc: FetchedResultsControllerManager<Screenshot>?
    
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
        
        restorationIdentifier = String(describing: type(of: self))
        
        coreDataPreparationController.delegate = self
        
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
        helperView.backgroundColor = view.backgroundColor
        helperView.layoutMargins = UIEdgeInsets(top: .extendedPadding, left: .padding, bottom: .extendedPadding, right: .padding)
        helperView.titleLabel.text = "favorites.empty.title".localized
        helperView.subtitleLabel.text = "favorites.empty.detail".localized
        helperView.contentImage = UIImage(named: "FavoriteEmptyListGraphic")
        view.addSubview(helperView)
        helperView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        helperView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        helperView.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor).isActive = true
        helperView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        coreDataPreparationController.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if screenshotAssetIds.count == 0 {
            syncScreenshotAssetIds()
        }
        
        syncHelperViewVisibility()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Resync since it's possible for a race condition to occur.
        syncHelperViewVisibility()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    deinit {
        coreDataPreparationController.delegate = nil
        tableView.delegate = nil
        tableView.dataSource = nil
    }
    
    // MARK: Screenshot
    
    func screenshot(at indexPath: IndexPath) -> Screenshot? {
        guard let screenshots = favoriteFrc?.fetchedResultsController.fetchedObjects else {
            return nil
        }
        
        return screenshots[indexPath.row]
    }
    
    func screenshot(withAssetId assetId: String) -> Screenshot? {
        return favoriteFrc?.fetchedResultsController.fetchedObjects?.first(where: { screenshot -> Bool in
            return screenshot.assetId == assetId
        })
    }
    
    fileprivate var screenshotAssetIds: [String] = []
    
    fileprivate func syncScreenshotAssetIds() {
        screenshotAssetIds = favoriteFrc?.fetchedResultsController.fetchedObjects?.map { screenshot -> String in
            return screenshot.assetId ?? ""
        } ?? []
    }
    
    // MARK: Products
    
    fileprivate var screenshotsFavorites: [String : ScreenshotFavorites] = [:]

    
    fileprivate func screenshotFavoritesForScreenshot(_ screenshot: Screenshot) -> ScreenshotFavorites {
        let favoritedProducts = screenshot.favoritedProducts
        let products = FavoritesTableViewCell.maxProducts(favoritedProducts)
        let favoritedEachShoppable = (screenshot.shoppablesCount == screenshot.favoritedShoppablesCount)
        
        return ScreenshotFavorites(count: favoritedProducts.count, products: products, favoritedEachShoppable: favoritedEachShoppable)
    }
    
    fileprivate func cachedScreenshotFavoritesForScreenshot(_ screenshot: Screenshot) -> ScreenshotFavorites {
        if let assetId = screenshot.assetId, let screenshotsProduct = screenshotsFavorites[assetId] {
            return screenshotsProduct
            
        } else {
            return screenshotFavoritesForScreenshot(screenshot)
        }
    }
    
    // MARK: Helper View
    
    fileprivate func syncHelperViewVisibility() {
        helperView.isHidden = (tableView.numberOfRows(inSection: 0) > 0)
    }
}

extension FavoritesViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return favoriteFrc?.fetchedResultsController.fetchedObjectsCount ?? 0
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        // Prevent all cells from calculating immediately
        return tableView.rowHeight
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let screenshot = screenshot(at: indexPath) else {
            return UITableViewCell()
        }
        

        let screenshotFavorites = cachedScreenshotFavoritesForScreenshot(screenshot)
        let identifier: String
        
        switch screenshotFavorites.count {
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
            cell.setProducts(screenshotFavorites.products)
            cell.activityBadgeView.badge = screenshotFavorites.favoritedEachShoppable ? .goldHeart : .heart
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .none
            
            if screenshotFavorites.count == 1 {
                cell.textLabel?.text = "favorites.screenshot.title.single".localized(withFormat: screenshotFavorites.count)
                
            } else {
                cell.textLabel?.text = "favorites.screenshot.title.plural".localized(withFormat: screenshotFavorites.count)
            }
        }
        
        return cell
    }
}

extension FavoritesViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.favoritesViewController(self, didSelectItemAt: indexPath)
    }
}

extension FavoritesViewController : CoreDataPreparationControllerDelegate {
    func coreDataPreparationControllerSetup(_ controller: CoreDataPreparationController) {
        favoriteFrc = DataModel.sharedInstance.favoriteFrc(delegate: self)
        tableView.reloadData()

        if DataModel.sharedInstance.isCoreDataStackReady {
            syncHelperViewVisibility()
            syncScreenshotAssetIds()
        }
    }
    
    func coreDataPreparationController(_ controller: CoreDataPreparationController, presentLoader loader: UIView) {
        loader.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loader)
        loader.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        loader.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        loader.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        loader.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    }
    
    func coreDataPreparationController(_ controller: CoreDataPreparationController, dismissLoader loader: UIView) {
        loader.removeFromSuperview()
    }
}

extension FavoritesViewController : FetchedResultsControllerManagerDelegate {
    func managerDidChangeContent(_ controller: NSObject, change: FetchedResultsControllerManagerChange) {
        if self.isViewLoaded {
            for index in change.insertedRows {
                if let screenshot = favoriteFrc?.fetchedResultsController.object(at: index) {
                    if let assetId = screenshot.assetId {
                        screenshotsFavorites[assetId] = screenshotFavoritesForScreenshot(screenshot)
                    }
                }
            }
            for index in change.updatedRows {
                if let screenshot = favoriteFrc?.fetchedResultsController.object(at: index) {
                    if let assetId = screenshot.assetId {
                        screenshotsFavorites[assetId] = screenshotFavoritesForScreenshot(screenshot)
                    }
                }
            }
            change.applyChanges(tableView: tableView)
        }
    }
}

fileprivate struct ScreenshotFavorites {
    var count: Int
    var products: [Product]
    var favoritedEachShoppable: Bool
}
