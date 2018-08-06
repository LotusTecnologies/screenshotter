//
//  FavoriteProductsViewController.swift
//  screenshot
//
//  Created by Corey Werner on 12/27/17.
//  Copyright (c) 2017 crazeapp. All rights reserved.
//

import UIKit
import CoreData

class FavoriteProductsViewController : BaseViewController {
    enum Section: Int {
        case notification
        case favorite
    }
    
    enum Row: Int {
        case notification
    }
    
    var dataSource: DataSource<Section, Row>?
    var productsFRC:FetchedResultsControllerManager<Product>?
    
    fileprivate var unfavoriteProductsIds: Set<NSManagedObjectID> = []
    private let emptyListView = HelperView()
    var  trackingProgressMonitors:[String:AsyncOperationMonitor] = [:]
    
    override var title: String? {
        set {}
        get {
            return "favorites.title".localized
        }
    }
    
    // MARK: Views
    
    fileprivate var favoriteProductsView: FavoriteProductsView {
        return view as! FavoriteProductsView
    }
    
    var tableView: TableView {
        return favoriteProductsView.tableView
    }
    
    override func loadView() {
        view = FavoriteProductsView()
    }
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        restorationIdentifier = String(describing: type(of: self))
        
        addNavigationItemLogo()
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground(_:)), name: .UIApplicationWillEnterForeground, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = view.backgroundColor
        tableView.register(FavoriteProductsTableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.register(FavoriteNotificationTableViewCell.self, forCellReuseIdentifier: "notification")
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 200
        tableView.layoutMargins = UIEdgeInsets(top: .extendedPadding, left: 0, bottom: .extendedPadding, right: 0) // Needed for emptyListView
        
        emptyListView.titleLabel.text = "favorites.empty.title".localized
        emptyListView.subtitleLabel.text = "favorites.empty.detail".localized
        emptyListView.contentImage = UIImage(named: "FavoriteEmptyListGraphic")
        tableView.emptyView = emptyListView

        
        let pinchZoom = UIPinchGestureRecognizer.init(target: self, action: #selector(pinch(gesture:)))
        self.view.addGestureRecognizer(pinchZoom)
        self.productsFRC = DataModel.sharedInstance.favoritedProductsFrc(delegate: self)
        
        dataSource = DataSource<Section, Row>(data: [
            .notification: [],
            .favorite: []
            ])
        self.tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.syncNotification()
    }
    
    @objc private func applicationWillEnterForeground(_ notification: Notification) {
        if isViewLoaded && view?.window != nil {
            self.syncNotification()
        }
    }
    
    deinit {
        if isViewLoaded {
            tableView.dataSource = nil
            tableView.delegate = nil
        }
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK:
    
    @objc func pinch( gesture:UIPinchGestureRecognizer) {
        if CrazeImageZoom.shared.isHandlingGesture, let imageView = CrazeImageZoom.shared.hostedImageView  {
            CrazeImageZoom.shared.gestureStateChanged(gesture, imageView: imageView)
            return
        }
        let point = gesture.location(in: self.tableView)
        if let indexPath = self.tableView.indexPathForRow(at: point), let cell = self.tableView.cellForRow(at: indexPath) as? FavoriteProductsTableViewCell{
            CrazeImageZoom.shared.gestureStateChanged(gesture, imageView: cell.productImageView.imageView)
        }
    }
    
    public func clearMarkedAsUnfavorite(){
        DataModel.sharedInstance.favorite(toFavorited: false, productOIDs: Array(self.unfavoriteProductsIds))
        
        self.unfavoriteProductsIds.forEach { (objectId) in
            if let product = DataModel.sharedInstance.mainMoc().productWith(objectId: objectId) {
                LocalNotificationModel.shared.deregisterCrazeFavoritedPriceAlert(id: product.id, merchant: product.merchant)
            }
        }
        self.unfavoriteProductsIds.removeAll()
    }
    
    // MARK: Favorites
    
    @objc fileprivate func favoriteProductAction(_ favoriteControl: FavoriteControl, event: UIEvent) {
        guard let indexPath = tableView.indexPath(for: event), let product = self.product(at: indexPath) else {
            return
        }
        
        let isFavorited = favoriteControl.isSelected
        
        if isFavorited {
            self.unfavoriteProductsIds.remove(product.objectID)
            
        }
        else {
            self.unfavoriteProductsIds.insert(product.objectID)
        }
        if isFavorited {
            Analytics.trackProductFavorited(product: product, page: .favorites)
        }else{
            Analytics.trackProductUnfavorited(product: product, page: .favorites)
        }
    }
    
    
    // MARK: Navigation
    
    fileprivate func presentProduct(at indexPath: IndexPath) {
        guard let product = self.product(at: indexPath) else {
            return
        }
        
        presentProduct(product, atLocation: .favorite)
    }
    
    @objc fileprivate func shareProductAction(_ control: UIControl, event: UIEvent) {
        guard let indexPath = tableView.indexPath(for: event), let product = self.product(at: indexPath) else {
            return
        }

        ScreenshotShareManager.share(product: product, in: self)
    }
    
    @objc fileprivate func buyNowProductAction(_ control: UIControl, event: UIEvent) {
        guard let indexPath = tableView.indexPath(for: event), let product = self.product(at: indexPath) else {
            return
        }
       
        presentProduct(product, atLocation: .favorite)
    }
    
    // MARK: Notification
    
    private func syncNotification() {
        let hasFavorite = productsFRC?.fetchedObjectsCount ?? 0 > 0
        let hasPushPermissions = PermissionsManager.shared.hasPermission(for: .push)
        let dismissedNotification = UserDefaults.standard.bool(forKey: UserDefaultsKeys.favoritesDismissedNotification)
        let shouldDisplay = hasFavorite && !hasPushPermissions && !dismissedNotification
        
        let rows: [Row] = shouldDisplay ? [.notification] : []
        dataSource?.updateSection(.notification, rows: rows)
        
        if self.isViewLoaded {
            if self.view.window == nil {
                self.tableView.reloadData()
            }
            else {
                self.tableView.reloadSections(IndexSet(integer: Section.notification.rawValue), with: .none)
            }
        }
    }
    
    @objc private func closeNotificationAction() {
        UserDefaults.standard.set(true, forKey: UserDefaultsKeys.favoritesDismissedNotification)
        self.syncNotification()
    }
    
    @objc private func enableNotificationAction() {
        if PermissionsManager.shared.permissionStatus(for: .push) == .undetermined {
            PermissionsManager.shared.requestPermission(for: .push) { granted in
                self.syncNotification()
            }
        }
        else {
            if let alertController = PermissionsManager.shared.deniedAlertController(for: .push) {
                present(alertController, animated: true)
            }
        }
    }
}


extension FavoriteProductsViewController: UITableViewDataSource {
    func product(at indexPath: IndexPath) -> Product? {
        return self.productsFRC?.object(at: IndexPath(item: indexPath.item, section: 0))
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.dataSource?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let eSection = Section(rawValue: section) else {
            return 0
        }
        
        switch eSection {
        case .notification:
            return self.dataSource?.rows(section)?.count ?? 0
        case .favorite:
            return self.productsFRC?.fetchedObjectsCount ?? 0
        }
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        var visiblePartNumbers:Set<String> = []
        self.tableView.indexPathsForVisibleRows?.forEach({ visibleIndexPath in
            if visibleIndexPath.section == Section.favorite.rawValue,
                let product = product(at: visibleIndexPath),
                let productId = product.partNumber
            {
                visiblePartNumbers.insert(productId)
            }
        })
        let unusedMonitors = self.trackingProgressMonitors.filter {
            return !visiblePartNumbers.contains( $0.key )
        }
        
        unusedMonitors.forEach {
            if let monitor = self.trackingProgressMonitors[$0.key] {
                monitor.delegate = nil
            }
            self.trackingProgressMonitors.removeValue(forKey: $0.key)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = Section(rawValue: indexPath.section) else {
            return UITableViewCell()
        }
        
        switch section {
        case .notification:
            return self.tableView(tableView, notificationCellForRowAt: indexPath)
        case .favorite:
            return self.tableView(tableView, defaultCellForRowAt: indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, defaultCellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        if let cell = cell as? FavoriteProductsTableViewCell, let product = product(at: indexPath) {
            cell.selectionStyle = .none
            cell.contentView.backgroundColor = .cellBackground
            cell.productImageView.setImage(withURLString: product.imageURL)
            cell.titleLabel.text = product.productTitle()?.decodingHTMLEntities()
            cell.priceLabel.text = product.price
            cell.merchantLabel.text = product.merchant?.decodingHTMLEntities()
            cell.favoriteControl.isSelected = !self.unfavoriteProductsIds.contains(product.objectID)
            cell.favoriteControl.addTarget(self, action: #selector(favoriteProductAction(_:event:)), for: .touchUpInside)
            cell.buyButton.addTarget(self, action: #selector(buyNowProductAction(_:event:)), for: .touchUpInside)
            cell.shareButton.addTarget(self, action: #selector(shareProductAction(_:event:)), for: .touchUpInside)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, notificationCellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "notification", for: indexPath)
        
        if let cell = cell as? FavoriteNotificationTableViewCell {
            cell.closeButton.addTarget(self, action: #selector(closeNotificationAction), for: .touchUpInside)
            cell.continueButton.addTarget(self, action: #selector(enableNotificationAction), for: .touchUpInside)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView.init()
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView.init()
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0
    }
}

extension FavoriteProductsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        guard let section = Section(rawValue: indexPath.section) else {
            return false
        }
        
        if section == .notification {
            return false
        }
        return true
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let section = Section(rawValue: indexPath.section) else {
            return
        }
        
        switch section {
        case .notification:
            break
        case .favorite:
            presentProduct(at: indexPath)
        }
    }
}


extension FavoriteProductsViewController: FetchedResultsControllerManagerDelegate {
    func managerDidChangeContent(_ controller: NSObject, change: FetchedResultsControllerManagerChange){
        if self.isViewLoaded {
            change.shiftIndexSections(by: Section.favorite.rawValue)
            change.applyChanges(tableView: tableView)
            self.syncNotification()
        }
    }
}
