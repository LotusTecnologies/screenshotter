//
//  ScreenshotsViewController.swift
//  screenshot
//
//  Created by Jonathan Rose on 2/18/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation
import CoreData
import SafariServices
import FBSDKCoreKit
@objc enum ScreenshotsSection : Int {
    case product
    case notification
    case image
}

//Setup view
extension ScreenshotsViewController {
    @objc func setupViews() {
        let collectionView: UICollectionView = {
            let minimumSpacing = self.collectionViewInteritemOffset()
            
            let layout = UICollectionViewFlowLayout()
            layout.minimumInteritemSpacing = minimumSpacing.x
            layout.minimumLineSpacing = minimumSpacing.y
            
            let collectionView = UICollectionView.init(frame: self.view.bounds, collectionViewLayout: layout)
            collectionView.translatesAutoresizingMaskIntoConstraints = false
            collectionView.delegate = self
            collectionView.dataSource = self
            collectionView.contentInset = UIEdgeInsets.init(top: 0, left: 0, bottom: minimumSpacing.y, right: 0)
            collectionView.backgroundColor = self.view.backgroundColor;
            collectionView.alwaysBounceVertical = true
            collectionView.isScrollEnabled = false
            collectionView.allowsMultipleSelection = true
            
            collectionView.register(ScreenshotProductBarCollectionViewCell.self, forCellWithReuseIdentifier: "product")
            collectionView.register(ScreenshotNotificationCollectionViewCell.self, forCellWithReuseIdentifier: "notification")
            collectionView.register(ScreenshotCollectionViewCell.self, forCellWithReuseIdentifier: "cell")

            self.view.addSubview(collectionView)
            collectionView.topAnchor.constraint( equalTo: self.view.topAnchor).isActive = true
            collectionView.bottomAnchor.constraint( equalTo: self.view.bottomAnchor).isActive = true
            collectionView.leftAnchor.constraint( equalTo: self.view.leftAnchor).isActive = true
            collectionView.trailingAnchor.constraint( equalTo: self.view.trailingAnchor).isActive = true

            return collectionView;
        }()
        self.collectionView = collectionView
        
        let refreshControl:UIRefreshControl = {
            let refreshControl = UIRefreshControl()
            refreshControl.tintColor = .crazeRed
            refreshControl.addTarget(self, action: #selector(refreshControlAction(_:)), for:.valueChanged)

            collectionView.addSubview(refreshControl)
            
            // Recenter view
            var rect = refreshControl.subviews[0].frame;
            rect.origin.x = -collectionView.contentInset.left / 2.0
            refreshControl.subviews[0].frame = rect
            return refreshControl;
        }()
        self.refreshControl = refreshControl
        
        let helperView:ScreenshotsHelperView = {
            let verPadding = Geometry.extendedPadding
            let horPadding = Geometry.padding
            
            let helperView = ScreenshotsHelperView()
            helperView.translatesAutoresizingMaskIntoConstraints = false
            helperView.layoutMargins = UIEdgeInsets.init(top: verPadding, left: horPadding, bottom: verPadding, right: horPadding)
            refreshControl.addTarget(self, action: #selector(helperViewAllowAccessAction), for:.touchUpInside)
            self.view.addSubview(helperView)
            helperView.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor).isActive = true
            helperView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
            helperView.bottomAnchor.constraint(equalTo: self.bottomLayoutGuide.topAnchor).isActive = true
            helperView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true

            return helperView;
        }()
        self.helperView = helperView
        
    }
    @objc func refreshControlAction(_ refreshControl:UIRefreshControl){
        
        if (refreshControl.isRefreshing) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                refreshControl.endRefreshing()
            }
        }
    }
    
    @objc func helperViewAllowAccessAction() {
        PermissionsManager.shared.requestPermission(for: .photo, openSettingsIfNeeded: true) { (granted) in
            self.syncHelperViewVisibility()
        }
    }

}

extension ScreenshotsViewController : FetchedResultsControllerManagerbgate {
    func managerDidChangeContent(_ controller: NSObject, change: FetchedResultsControllerManagerChange) {
        change.shiftIndexSections(by: 2)
        change.applyChanges(collectionView: self.collectionView)
        self.syncHelperViewVisibility()

    }
    
    @objc func setupFetchedResultsController(){
        self.screenshotFrcManager = DataModel.sharedInstance.screenshotFrc(delegate: self)
        
    }
    @objc func screenshotFrc() -> NSFetchedResultsController<Screenshot>? {
        return (self.screenshotFrcManager as? FetchedResultsControllerManager<Screenshot>)?.fetchedResultsController
        
    }
}

extension ScreenshotsViewController : ProductsBarControllerDelegate {
    func productBarShouldHide(_ controller: ProductsBarController) {
        if self.collectionView.numberOfItems(inSection: ScreenshotsSection.product.rawValue) == 1{
            self.collectionView.deleteItems(at: [IndexPath.init(row: 0, section: ScreenshotsSection.product.rawValue)])
        }
    }
    
    func productBarShouldShow(_ controller: ProductsBarController) {
        if self.collectionView.numberOfItems(inSection: ScreenshotsSection.product.rawValue) == 0{
            self.collectionView.insertItems(at: [IndexPath.init(row: 0, section: ScreenshotsSection.product.rawValue)])
        }
    }
    
    func productBar(_ controller: ProductsBarController, didTap product: Product) {
        if !self.isEditing {
            OpenProductPage.present(product: product, fromViewController: self, analyticsKey: "ProductBar")
        }else{
            if self.toUnfavoriteAndUnViewProductObjectIDs.contains(product.objectID){
                self.toUnfavoriteAndUnViewProductObjectIDs.remove(product.objectID)
            }else{
                self.toUnfavoriteAndUnViewProductObjectIDs.add(product.objectID)
            }
            if let a = self.toUnfavoriteAndUnViewProductObjectIDs as? [NSManagedObjectID] {
                controller.toUnfavoriteAndUnViewProductObjectIDs = a
            }
            self.updateDeleteButtonCount()
        }
    }
}

//Helper view
extension ScreenshotsViewController {
    @objc func insertScreenshotHelperView() {
        
        let hasPresented = UserDefaults.standard.bool(forKey: UserDefaultsKeys.onboardingPresentedScreenshotHelper)
        if !hasPresented && self.collectionView.numberOfItems(inSection: ScreenshotsSection.image.rawValue) == 1{
            UserDefaults.standard.set(true, forKey: UserDefaultsKeys.onboardingPresentedScreenshotHelper)
            if let layout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                let backgroundView = UIView()
                
                self.collectionView.backgroundView = backgroundView;
                
                let contentView = UIView()
                contentView.translatesAutoresizingMaskIntoConstraints = false
                backgroundView.addSubview(contentView)
                
                contentView.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor, constant:layout.minimumLineSpacing).isActive = true
                contentView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant:-layout.minimumInteritemSpacing).isActive = true
                contentView.widthAnchor.constraint(equalTo: backgroundView.widthAnchor,multiplier:0.5, constant:-layout.minimumInteritemSpacing * 1.5).isActive = true
                contentView.heightAnchor.constraint(equalTo: backgroundView.widthAnchor,multiplier:Screenshot.ratio.height, constant:0).isActive = true
                
                
                let titleLabel = UILabel()
                titleLabel.translatesAutoresizingMaskIntoConstraints = false
                titleLabel.text = "screenshots.helperView.title".localized
                titleLabel.font = UIFont.systemFont(ofSize: 22, weight: UIFontWeightSemibold)
                titleLabel.numberOfLines = 0
                contentView.addSubview(titleLabel)
                titleLabel.topAnchor.constraint(equalTo:contentView.topAnchor).isActive = true
                titleLabel.leadingAnchor.constraint(equalTo:contentView.leadingAnchor).isActive = true
                titleLabel.trailingAnchor.constraint(equalTo:contentView.trailingAnchor).isActive = true
                
                
                let descriptionLabel = UILabel()
                descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
                descriptionLabel.text = "screenshots.helperView.byline".localized
                descriptionLabel.font = UIFont.systemFont(ofSize: 22, weight: UIFontWeightLight)
                
                descriptionLabel.numberOfLines = 0
                contentView.addSubview(descriptionLabel)
                descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: Geometry.padding).isActive = true
                descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
                descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
                
                
                let imageView = UIImageView.init(image: UIImage.init(named: "TutorialReadyArrow"))
                imageView.translatesAutoresizingMaskIntoConstraints = false
                imageView.contentMode = .scaleAspectFit
                contentView.addSubview(imageView)
                imageView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor).isActive = true
                imageView.leadingAnchor.constraint(equalTo: descriptionLabel.leadingAnchor).isActive = true
                imageView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor).isActive = true
                imageView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor).isActive = true
            }
        }
    }
    
    @objc func removeScreenshotHelperView(){
        if self.collectionView.backgroundView != nil {
           self.collectionView.backgroundView?.removeFromSuperview()
            self.collectionView.backgroundView = nil
        }
    }
}


//Edit actions
extension ScreenshotsViewController {
    @objc func editButtonAction() {
        
        let isEditing = !self.isEditing
        
        if !isEditing {
            // Needs to be before setEditing
            self.deselectDeletedScreenshots()
        }
        self.setEditing(isEditing, animated: true)
        
    }
    @objc open override func setEditing(_ editing: Bool, animated: Bool) {
        
        super.setEditing(editing, animated: animated)
        
        if (self.tabBarController != nil && editing) {
            var bottom:CGFloat = 0.0
            
            if #available(iOS 11.0, *) {
                if let safeAreaInsetsBottom = UIApplication.shared.keyWindow?.safeAreaInsets.bottom {
                    bottom = safeAreaInsetsBottom / 2.0
                }
            }
            if self.deleteButton == nil {
                 let deleteButton = ScreenshotsDeleteButton.init()
                deleteButton.autoresizingMask = [.flexibleWidth,.flexibleHeight]
                deleteButton.translatesAutoresizingMaskIntoConstraints = true
                deleteButton.addTarget(self, action: #selector(deleteButtonAction), for: .touchUpInside)
                self.deleteButton = deleteButton
            }
            
            self.deleteButton.alpha = 0
            self.deleteButton.contentEdgeInsets = UIEdgeInsets.init(top: 0, left: 0, bottom: bottom, right: 0)
            
            self.deleteButton.frame = self.tabBarController!.tabBar.bounds;
            self.tabBarController?.tabBar.addSubview(self.deleteButton)
            
        }
        let removeDeleteButton = {
            if (self.tabBarController != nil && !editing) {
                self.deleteButton.removeFromSuperview()
                self.updateDeleteButtonCount()
            }
        }
        
        let cellEditing = {
            for index in self.collectionView.indexPathsForVisibleItems {
                if let cell = self.collectionView.cellForItem(at: index) as? ScreenshotCollectionViewCell {
                    cell.isEditing = editing;
                    self.syncScreenshotCollectionViewCellSelectedState(cell)

                }
            }
            
            
            if (self.hasNewScreenshot) {
                self.collectionView.reloadSections(IndexSet.init(integer: ScreenshotsSection.notification.rawValue))
            }
            
            self.deleteButton.alpha = editing ? 1.0: 0.0
        }
        
        if (animated) {
            UIView.animate(withDuration: Constants.defaultAnimationDuration, animations: {
                
                cellEditing();
                ///     putting `removeDeleteButton` here instead of in the completion
                //      prevents animation on the button fading away,
                //      but ALSO fixes a bug where if you take edit cancel
                //      edit cancel very fast you can get into a state
                //      where there no delete button in edit mode
                removeDeleteButton();
            })
        }
        else {
            cellEditing();
            removeDeleteButton();
        }
        
        self.navigationItem.rightBarButtonItem?.isEnabled = !editing;
        
        if (editing) {
            self.editButtonItem.title = "generic.cancel".localized
            
            self.deleteScreenshotObjectIDs = []
            self.toUnfavoriteAndUnViewProductObjectIDs = []
        }else {
            self.productsBarController.toUnfavoriteAndUnViewProductObjectIDs = []
        }
    }
    
    @objc func deselectDeletedScreenshots() {
        
        // Deselect all cells
        self.collectionView.selectItem(at: nil, animated: true, scrollPosition: [])
        
        
        self.deleteScreenshotObjectIDs = []
        self.toUnfavoriteAndUnViewProductObjectIDs = []
        self.productsBarController.toUnfavoriteAndUnViewProductObjectIDs = self.toUnfavoriteAndUnViewProductObjectIDs as! [NSManagedObjectID];
    }
    
    @objc func updateDeleteButtonCount () {

        self.deleteButton.deleteCount = self.toUnfavoriteAndUnViewProductObjectIDs.count + self.deleteScreenshotObjectIDs.count;
    }
    
    @objc func deleteButtonAction(){
        self.setEditing(false, animated: true)
        self.editButtonItem.isEnabled = true
        if (self.deleteScreenshotObjectIDs.count + self.toUnfavoriteAndUnViewProductObjectIDs.count > 0) {
            DataModel.sharedInstance.hide(screenshotOIDArray: self.deleteScreenshotObjectIDs as! [NSManagedObjectID])
            DataModel.sharedInstance.unfavoriteAndUnview(productObjectIDs: self.toUnfavoriteAndUnViewProductObjectIDs as! [NSManagedObjectID])
            
        }
    }
}

//Screenshot cell
extension ScreenshotsViewController : ScreenshotCollectionViewCellDelegate{
    func screenshotCollectionViewCellDidTapShare(_ cell: ScreenshotCollectionViewCell) {
        if let indexPath = self.collectionView.indexPath(for: cell),  let screenshot = self.screenshot(at: indexPath.item) {
            let introductoryText = "screenshots.share.introductoryText".localized
            
            if screenshot.shoppablesCount <= 0 {
                //TODO: fix this when there is a better indciator of failure to load
                let alertController = UIAlertController.init(title: "screenshots.share.error.title".localized, message: "screenshots.share.error.message".localized, preferredStyle: .alert)
                alertController.addAction(UIAlertAction.init(title: "generic.ok", style: .default, handler: nil))
                self.present(alertController, animated: true, completion: nil)
                return;
            }
            var items:[Any]? = nil
            let space = " "
            if let shareLink = screenshot.shareLink, let shareURL = URL.init(string: shareLink) {
                items = [introductoryText, space, shareURL]
            }else{
                if let url = URL.init(string: "https://getscreenshop.com/") {
                    let screenshotActivityItemProvider = ScreenshotActivityItemProvider.init(screenshot: screenshot, placeholderURL:url)
                    items = [introductoryText, space, screenshotActivityItemProvider];
                }
            }
            if let items =  items {
                
                let activityViewController = UIActivityViewController.init(activityItems: items, applicationActivities: nil)
                activityViewController.completionWithItemsHandler = { (activityType, completed, returnedItems, activityError) in
                    if (completed) {
                        AnalyticsTrackers.standard.track("Share completed")
                        AnalyticsTrackers.branch.track("Share completed")
                    } else {
                        AnalyticsTrackers.standard.track("Share incomplete")
                    }
                };
                activityViewController.popoverPresentationController?.sourceView = self.view; // so iPads don't crash
                self.present(activityViewController, animated: true, completion: nil)
                AnalyticsTrackers.standard.track("Shared screenshot")
            }
        }
    }
    
    func screenshotCollectionViewCellDidTapDelete(_ cell: ScreenshotCollectionViewCell) {
        if let indexPath = self.collectionView.indexPath(for: cell), let screenshot = self.screenshot(at: indexPath.item) {
            let objectId = screenshot.objectID
        let alertController = UIAlertController.init(title: "Delete Screenshot", message: nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        
        alertController.addAction(UIAlertAction.init(title: "Delete", style: .destructive, handler: { (a) in
            if let screenshot = self.screenshot(at: indexPath.item) {
                if screenshot.objectID.isEqual(objectId) {
                    screenshot.setHide()
                    self.removeScreenshotHelperView()
                    self.collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                    UIView.animate(withDuration: Constants.defaultAnimationDuration, animations: {
                        cell.selectedState = .disabled
                    })
                    AnalyticsTrackers.standard.track("Removed screenshot")
                    
                }else{
                    print("collectionView update when trying to delete item")
                }
            }
        }))
        self.present(alertController, animated: true, completion: nil)
        
        }
    }
    @objc func syncScreenshotCollectionViewCellSelectedState(_ cell:ScreenshotCollectionViewCell) {
        if self.isEditing {
            cell.selectedState = .checked
        }else if cell.isSelected && self.deleteScreenshotObjectIDs.count > 0 {
            cell.selectedState = .disabled
        }else{
            cell.selectedState = .none
        }
    }
}
extension ScreenshotsViewController {
    @objc func syncHelperViewVisibility() {
        if PermissionsManager.shared.hasPermission(for: .photo) {
            if self.helperView.type != .screenshot {
                self.helperView.type = .screenshot
            }
        } else {
            if self.helperView.type != .permission {
                self.helperView.type = .permission
            }
        }
        let hasScreenshots = (self.collectionView.numberOfItems(inSection: ScreenshotsSection.image.rawValue) > 0)
        
        self.helperView.isHidden = (hasScreenshots || self.collectionView.numberOfItems(inSection: ScreenshotsSection.notification.rawValue) > 0)
        self.collectionView.isScrollEnabled = self.helperView.isHidden && (self.collectionView.backgroundView == nil)
        self.editButtonItem.isEnabled = hasScreenshots;
    }
}

extension ScreenshotsViewController : CoreDataPreparationControllerDelegate{
    
    func coreDataPreparationControllerSetup(_ controller: CoreDataPreparationController) {
        self.setupFetchedResultsController()
        self.productsBarController = ProductsBarController()
        self.productsBarController.setup()
        self.productsBarController.delegate = self
        if DataModel.sharedInstance.isCoreDataStackReady {
            self.collectionView.reloadData()
            self.syncHelperViewVisibility()
        }
    }
    
    func coreDataPreparationController(_ controller: CoreDataPreparationController, presentLoader loader: UIView){
        loader.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(loader)
        loader.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        loader.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        loader.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        loader.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
    }
    func coreDataPreparationController(_ controller: CoreDataPreparationController, dismissLoader loader: UIView) {
        loader.removeFromSuperview()

    }

}
//Notification cell
extension ScreenshotsViewController {
    @objc func newScreenshotsCount() -> Int {
        return AccumulatorModel.sharedInstance.getNewScreenshotsCount()
    }
    
    @objc func canDisplayNotificationCell() -> Bool {
        return self.hasNewScreenshot && !self.isEditing
    }
    
    @objc func screenshotNotificationCollectionViewCellDidTapReject(_ cell: ScreenshotNotificationCollectionViewCell){
        let screenshotsCount = self.newScreenshotsCount()
        AccumulatorModel.sharedInstance.resetNewScreenshotsCount()
        self.dismissNotificationCell()
        self.syncHelperViewVisibility()
        AnalyticsTrackers.standard.track("Screenshot notification cancelled", properties: ["Screenshot count": screenshotsCount])
        
    }
    @objc func screenshotNotificationCollectionViewCellDidTapConfirm(_ cell: ScreenshotNotificationCollectionViewCell){
        let screenshotsCount = self.newScreenshotsCount()
        AccumulatorModel.sharedInstance.resetNewScreenshotsCount()

        if (cell.contentText == .importSingleScreenshot) {
            AssetSyncModel.sharedInstance.refetchLastScreenshot()
            
        } else if (cell.contentText == .importMultipleScreenshots) {
            self.delegate.screenshotsViewControllerWants(toPresentPicker: self)
        }
        self.dismissNotificationCell()
        self.syncHelperViewVisibility()
        AnalyticsTrackers.standard.track("Screenshot notification accepted", properties: ["Screenshot count": screenshotsCount])
    }
    
    @objc func presentNotificationCell(assetId:String){
        if AccumulatorModel.sharedInstance.getNewScreenshotsCount() > 0 {
            self.hasNewScreenshot = true
            self.notificationCellAssetId = assetId
            let indexPath = IndexPath.init(row: 0, section: ScreenshotsSection.notification.rawValue)
            
            if self.collectionView.numberOfItems(inSection: ScreenshotsSection.notification.rawValue) == 0{
                self.collectionView.insertItems(at: [indexPath])
                self.collectionView.scrollToItem(at: indexPath, at: .top, animated: true)
            } else {
                self.collectionView.reloadItems(at: [indexPath])
            }
            
            self.syncHelperViewVisibility()
        }
    }
    
    @objc func dismissNotificationCell(){
        self.hasNewScreenshot = false
        if self.collectionView.numberOfItems(inSection: ScreenshotsSection.notification.rawValue) > 0{
            self.collectionView.deleteItems(at: [IndexPath.init(row: 0, section: ScreenshotsSection.notification.rawValue)])
        }
    }
}

extension ScreenshotsViewController:UICollectionViewDelegateFlowLayout {
    func numberOfCollectionViewImageColumns() -> Int {
        return 2
    }
    
    
    @objc func collectionViewInteritemOffset() -> CGPoint {
        let shadowInsets = ScreenshotCollectionViewCell.shadowInsets
        let x = Geometry.padding - shadowInsets.left - shadowInsets.right
        let y = Geometry.padding - shadowInsets.top - shadowInsets.bottom
        return CGPoint.init(x: x, y: y)
    }
    
    @objc func notificationContentText() -> ScreenshotNotificationCollectionViewCellContentText {
        let count = self.newScreenshotsCount()
        
        if (count == 1) {
            return .importSingleScreenshot;
            
        } else if (count > 1) {
            return .importMultipleScreenshots;
            
        } else {
            return .none;
        }
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var size = CGSize.zero
        
        if (indexPath.section == ScreenshotsSection.product.rawValue) {
            size.width = collectionView.bounds.size.width - collectionView.contentInset.left - collectionView.contentInset.right;
            size.height = 138;
        }
        else {
            let minimumSpacing = self.collectionViewInteritemOffset()
            
            if (indexPath.section == ScreenshotsSection.notification.rawValue) {
                size.width = floor(collectionView.bounds.size.width - (minimumSpacing.x * 2));
                size.height = ScreenshotNotificationCollectionViewCell.height(withCellWidth: size.width, contentText: self.notificationContentText(), contentType: .labelWithButtons)
            } else if (indexPath.section == ScreenshotsSection.image.rawValue) {
                let columns = CGFloat(self.numberOfCollectionViewImageColumns())
                
                size.width = floor((collectionView.bounds.size.width - (minimumSpacing.x * (columns + 1))) / columns);
                size.height = ceil(size.width * Screenshot.ratio.height);
            }
        }
        
        return size;
    }
    public func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        if (indexPath.section == ScreenshotsSection.notification.rawValue && self.isEditing) {
            return false
        }
        else {
            return true
        }
    }
    public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
        if (indexPath.section == ScreenshotsSection.image.rawValue && self.isEditing) {
            if let screenshot = self.screenshot(at: indexPath.item) {
                self.deleteScreenshotObjectIDs.remove(screenshot.objectID)
                self.updateDeleteButtonCount()
            }
        }
        
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == ScreenshotsSection.image.rawValue {
            if let screenshot = self.screenshot(at: indexPath.item) {
                if (self.isEditing) {
                    self.deleteScreenshotObjectIDs.add(screenshot.objectID)
                    self.updateDeleteButtonCount()
                } else {
                    if (self.deleteScreenshotObjectIDs.count > 0 && self.deleteScreenshotObjectIDs.contains(screenshot.objectID)) {
                        return
                    }
                    collectionView.deselectItem(at: indexPath, animated: false)
                    self.delegate.screenshotsViewController(self, didSelectItemAt: indexPath)
                    
                    if let uploadedImageURL = screenshot.uploadedImageURL {
                        AnalyticsTrackers.standard.track("Tapped on screenshot", properties: ["screenshot":uploadedImageURL])
                    }
                }
            }
        }
    }
 }
