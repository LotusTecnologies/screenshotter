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
    fileprivate var screenshotsProducts: [[Product]] = []
    fileprivate var reloadProductsSet: Set<Int> = Set()
    
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
        
        DataModel.sharedInstance.favoriteFrcDelegate = self
        
        addNavigationItemLogo()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = view.backgroundColor
        tableView.register(FavoritesTableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.rowHeight = 150
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
        
        if (reloadProductsSet.count > 0) {
            // TODO:
            reloadProductsSet.removeAll()
        }
        
        syncHelperViewVisibility()
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
    
    // MARK: Helper View
    
    fileprivate func syncHelperViewVisibility() {
        helperView.isHidden = (tableView.numberOfRows(inSection: 0) > 0)
    }
}

extension FavoritesViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return favoriteFrc.fetchedObjects?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? FavoritesTableViewCell,
            let screenshot = screenshot(at: indexPath) else {
            return UITableViewCell()
        }
        
//        screenshot.favoritedProducts
        
        cell.imageData = screenshot.imageData
        cell.backgroundColor = view.backgroundColor
        cell.accessoryType = .disclosureIndicator
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
        tableView.reloadData()
        
        reloadProductsSet.insert(indexPath.row)
    }
    
    func frc(_ frc: NSFetchedResultsController<NSFetchRequestResult>, oneMovedTo indexPath: IndexPath) {
        tableView.reloadData()
    }
    
    func frc(_ frc: NSFetchedResultsController<NSFetchRequestResult>, oneDeletedAt indexPath: IndexPath) {
        tableView.reloadData()
        
        reloadProductsSet.remove(indexPath.row)
    }
    
    func frc(_ frc: NSFetchedResultsController<NSFetchRequestResult>, oneUpdatedAt indexPath: IndexPath) {
        tableView.reloadData()
    }
    
    func frcReloadData(_ frc: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.reloadData()
    }
}
