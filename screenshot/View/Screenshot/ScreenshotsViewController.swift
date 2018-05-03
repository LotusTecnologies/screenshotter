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
import Photos
import PromiseKit

enum ScreenshotsSection : Int {
    case product
    case notification
    case image
}

protocol ScreenshotsViewControllerDelegate : NSObjectProtocol{
    func screenshotsViewController(_  viewController:ScreenshotsViewController, didSelectItemAt:IndexPath)
    func screenshotsViewControllerDeletedLastScreenshot(_  viewController:ScreenshotsViewController)
    func screenshotsViewControllerWantsToPresentPicker(_  viewController:ScreenshotsViewController)
}

class ScreenshotsViewController: BaseViewController {
    weak var delegate:ScreenshotsViewControllerDelegate?
    
    var screenshotFrcManager:FetchedResultsControllerManager<Screenshot>?
    var collectionView:CollectionView!
    var toHideFromProductBarObjectIDs:[NSManagedObjectID] = []
    var deleteScreenshotObjectIDs:[NSManagedObjectID] = []
    var productsBarController:ProductsBarController?
    var deleteButton:ScreenshotsDeleteButton?
    var refreshControl:UIRefreshControl?
    var emptyListView:ScreenshotsHelperView?
    var hasNewScreenshotSection = false
    var hasProductBar = false
    
    init() {
        super.init(nibName: nil, bundle: nil)
        
        self.restorationIdentifier = "ScreenshotsViewController"
        title = "screenshots.title".localized
            
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground(_:)), name: .UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground(_:)), name: .UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(contentSizeCategoryDidChange(_:)), name: .UIContentSizeCategoryDidChange, object: nil)
        
        self.editButtonItem.target = self
        self.editButtonItem.action = #selector(editButtonAction)
        self.navigationItem.backBarButtonItem = UIBarButtonItem.init(title: "", style: .plain, target: nil, action: nil)
        self.addNavigationItemLogo()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.collectionView?.delegate = nil
        self.collectionView?.dataSource = nil
        
        NotificationCenter.default.removeObserver(self)
    }
}

extension ScreenshotsViewController{
    public func screenshot(at index:Int) -> Screenshot?{
        return self.screenshotFrcManager?.object(at: IndexPath.init(item: index, section: 0))
    }
    public func indexOf(screenshot:Screenshot) -> Int? {
        return self.screenshotFrcManager?.indexPath(forObject: screenshot)?.item
    }
    
    func scrollToTop(){
        if let collectionView = self.collectionView {
            if self.isViewLoaded {
                if collectionView.numberOfItems(inSection: ScreenshotsSection.image.rawValue) > 0 {
                    collectionView.contentOffset = CGPoint.init(x: collectionView.contentInset.left, y: -collectionView.contentInset.top)
                }
            }
        }
    }
}

extension ScreenshotsViewController: VideoDisplayingViewControllerDelegate {
    func videoDisplayingViewControllerDidTapDone(_ viewController: UIViewController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.screenshotFrcManager = DataModel.sharedInstance.screenshotFrc(delegate: self)
 
        
        self.hideProductBarIfLessThan4ShowIf4OrMoreWithoutAnimation()

        self.setupViews()
        self.syncEmptyListView()
        NotificationCenter.default.addObserver(self, selector: #selector(accumulatorModelNumberDidChange(_:)), name: .accumulatorModelDidUpdate, object: nil)
        
        
        let productsBarController = ProductsBarController()
        productsBarController.setup()
        productsBarController.delegate = self
        self.productsBarController = productsBarController
        UIView.performWithoutAnimation {
            self.productBarContentChanged(productsBarController)
        }
        

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        syncEmptyListView()
        self.updateHasNewScreenshot()
        if UserDefaults.standard.string(forKey: UserDefaultsKeys.lastCampaignCompleted) != UserDefaultsKeys.CampaignCompleted.campaign_2018_04_20.rawValue {
            let campaign = CampaignPromotionViewController(modal:true)
            campaign.delegate = self
            self.present(campaign, animated: true, completion: nil)
        }
    }
    
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.removeScreenshotHelperView()
        if self.isEditing {
            self.setEditing(false, animated: animated)
        }
        
        self.hideProductBarIfLessThan4ShowIf4OrMoreWithoutAnimation()
    }
    
    @objc func applicationDidEnterBackground(_ notification:Notification){
        if self.isViewLoaded && self.view.window != nil {
            self.removeScreenshotHelperView()
        }
    }
    
    @objc func applicationWillEnterForeground(_ notification:Notification) {
        if self.isViewLoaded && self.view.window != nil {
            syncEmptyListView()
            self.updateHasNewScreenshot()

        }
    }
    
    @objc func contentSizeCategoryDidChange(_ notification:Notification) {
        if self.isViewLoaded && self.view.window != nil {
            if self.collectionView.numberOfItems(inSection: ScreenshotsSection.notification.rawValue) > 0 {
                self.collectionView.reloadItems(at: [IndexPath.init(item: 0, section: ScreenshotsSection.notification.rawValue)])
            }
        }
    }
}

extension ScreenshotsViewController: CampaignPromotionViewControllerDelegate {
    func campaignPromotionViewControllerDidPressLearnMore(_ viewController:CampaignPromotionViewController){
        
    }
    func campaignPromotionViewControllerDidPressSkip(_ viewController:CampaignPromotionViewController){
        self.dismiss(animated: true, completion: nil)
    }

}

//Setup view
extension ScreenshotsViewController {
    func setupViews() {
        let collectionView: CollectionView = {
            let minimumSpacing = self.collectionViewInteritemOffset()
            
            let layout = UICollectionViewFlowLayout()
            layout.minimumInteritemSpacing = minimumSpacing.x
            layout.minimumLineSpacing = minimumSpacing.y
            
            let collectionView = CollectionView(frame: self.view.bounds, collectionViewLayout: layout)
            collectionView.translatesAutoresizingMaskIntoConstraints = false
            collectionView.delegate = self
            collectionView.dataSource = self
            collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: minimumSpacing.y, right: 0)
            collectionView.layoutMargins = UIEdgeInsets(top: .extendedPadding, left: 0, bottom: .extendedPadding, right: 0) // Needed for emptyListView
            collectionView.backgroundColor = self.view.backgroundColor
            collectionView.alwaysBounceVertical = true
            collectionView.isScrollEnabled = false
            collectionView.allowsMultipleSelection = true
            
            collectionView.register(ScreenshotProductBarCollectionViewCell.self, forCellWithReuseIdentifier: "product")
            collectionView.register(ScreenshotNotificationCollectionViewCell.self, forCellWithReuseIdentifier: "notification")
            collectionView.register(ScreenshotCollectionViewCell.self, forCellWithReuseIdentifier: "cell")

            self.view.addSubview(collectionView)
            collectionView.topAnchor.constraint( equalTo: self.view.topAnchor).isActive = true
            collectionView.bottomAnchor.constraint( equalTo: self.view.bottomAnchor).isActive = true
            collectionView.leadingAnchor.constraint( equalTo: self.view.leadingAnchor).isActive = true
            collectionView.trailingAnchor.constraint( equalTo: self.view.trailingAnchor).isActive = true

            return collectionView
        }()
        self.collectionView = collectionView
        
        let refreshControl:UIRefreshControl = {
            let refreshControl = UIRefreshControl()
            refreshControl.tintColor = .crazeRed
            refreshControl.addTarget(self, action: #selector(refreshControlAction(_:)), for:.valueChanged)
            collectionView.addSubview(refreshControl)
            
            // Recenter view
            var rect = refreshControl.subviews[0].frame
            rect.origin.x = -collectionView.contentInset.left / 2.0
            refreshControl.subviews[0].frame = rect
            return refreshControl
        }()
        self.refreshControl = refreshControl
        
        let emptyListView:ScreenshotsHelperView = {
            let emptyListView = ScreenshotsHelperView()
            emptyListView.button.addTarget(self, action: #selector(emptyListViewAllowAccessAction), for:.touchUpInside)
            collectionView.emptyView = emptyListView
            return emptyListView
        }()
        self.emptyListView = emptyListView
        
    }
    
    @objc func refreshControlAction(_ refreshControl:UIRefreshControl){
        
        if (refreshControl.isRefreshing) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                refreshControl.endRefreshing()
            }
        }
    }
    
    @objc func emptyListViewAllowAccessAction() {
        PermissionsManager.shared.requestPermission(for: .photo, openSettingsIfNeeded: true) { (granted) in
            self.syncEmptyListView()
        }
    }
}

extension ScreenshotsViewController : FetchedResultsControllerManagerDelegate {
    func managerDidChangeContent(_ controller: NSObject, change: FetchedResultsControllerManagerChange) {
        change.shiftIndexSections(by: 2)
        change.applyChanges(collectionView: collectionView)
        syncEmptyListView()
    }
}

extension ScreenshotsViewController : ProductsBarControllerDelegate {
    
    func hideProductBarIfLessThan4ShowIf4OrMoreWithoutAnimation() {
        if let controller = self.productsBarController {
            UIView.performWithoutAnimation {
                let count = controller.count
                let shouldHaveproductBar = ( count > 4)
                if self.hasProductBar != shouldHaveproductBar {
                    self.hasProductBar = shouldHaveproductBar
                    syncProductShowOrHide()
                }
            }
        }
    }
    
    func syncProductShowOrHide(){
        if self.hasProductBar {
            if self.collectionView.numberOfItems(inSection: ScreenshotsSection.product.rawValue) == 0{
                self.collectionView.insertItems(at: [IndexPath.init(row: 0, section: ScreenshotsSection.product.rawValue)])
            }
        }else{
            if self.collectionView.numberOfItems(inSection: ScreenshotsSection.product.rawValue) == 1{
                self.collectionView.deleteItems(at: [IndexPath.init(row: 0, section: ScreenshotsSection.product.rawValue)])
            }
        }
    }
    
    func productBarContentChanged(_ controller:ProductsBarController) {
        if self.hasProductBar && controller.count == 0 {
            self.hasProductBar = false
            self.syncProductShowOrHide()
            
        }else if !self.hasProductBar  && controller.count >= 4 {
            self.hasProductBar = true
            self.syncProductShowOrHide()
        }
    }
    
    func productBar(_ controller: ProductsBarController, didTap product: Product) {
        if !self.isEditing {
            self.presentProduct(product, atLocation: .productBar)
        }
        else {
            if let index = self.toHideFromProductBarObjectIDs.index(of: product.objectID){
                self.toHideFromProductBarObjectIDs.remove(at: index)
            }else{
                self.toHideFromProductBarObjectIDs.append(product.objectID)
            }
            
            controller.toUnfavoriteAndUnViewProductObjectIDs = self.toHideFromProductBarObjectIDs
            
            self.updateDeleteButtonCount()
        }
    }
}

//Helper view
extension ScreenshotsViewController {
    func insertScreenshotHelperView() {
        
        let hasPresented = UserDefaults.standard.bool(forKey: UserDefaultsKeys.onboardingPresentedScreenshotHelper)
        if !hasPresented && self.collectionView.numberOfItems(inSection: ScreenshotsSection.image.rawValue) == 1 && !self.hasNewScreenshotSection {
            UserDefaults.standard.set(true, forKey: UserDefaultsKeys.onboardingPresentedScreenshotHelper)
            if let layout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                let backgroundView = UIView()
                
                self.collectionView.backgroundView = backgroundView
                
                let contentView = UIView()
                contentView.translatesAutoresizingMaskIntoConstraints = false
                backgroundView.addSubview(contentView)
                
                contentView.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor, constant:layout.minimumLineSpacing).isActive = true
                contentView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant:-layout.minimumInteritemSpacing).isActive = true
                contentView.widthAnchor.constraint(equalTo: backgroundView.widthAnchor,multiplier:0.5, constant:-layout.minimumInteritemSpacing * 1.5).isActive = true
                contentView.heightAnchor.constraint(equalTo: backgroundView.widthAnchor,multiplier:Screenshot.ratio.height, constant:0).isActive = true
                
                
                let titleLabel = UILabel()
                titleLabel.translatesAutoresizingMaskIntoConstraints = false
                titleLabel.text = "screenshots.helper.title".localized
                titleLabel.font = UIFont.systemFont(ofSize: 22, weight: UIFont.Weight.semibold)
                titleLabel.numberOfLines = 0
                contentView.addSubview(titleLabel)
                titleLabel.topAnchor.constraint(equalTo:contentView.topAnchor).isActive = true
                titleLabel.leadingAnchor.constraint(equalTo:contentView.leadingAnchor).isActive = true
                titleLabel.trailingAnchor.constraint(equalTo:contentView.trailingAnchor).isActive = true
                
                
                let descriptionLabel = UILabel()
                descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
                descriptionLabel.text = "screenshots.helper.byline".localized
                descriptionLabel.font = UIFont.systemFont(ofSize: 22, weight: UIFont.Weight.light)
                
                descriptionLabel.numberOfLines = 0
                contentView.addSubview(descriptionLabel)
                descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: .padding).isActive = true
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
    
    func removeScreenshotHelperView(){
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
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        if (self.tabBarController != nil && editing) {
            var bottom:CGFloat = 0.0
            
            if #available(iOS 11.0, *) {
                if let safeAreaInsetsBottom = UIApplication.shared.keyWindow?.safeAreaInsets.bottom {
                    bottom = safeAreaInsetsBottom / 2.0
                }
            }
            let deleteButton:ScreenshotsDeleteButton = self.deleteButton ??  {
                let deleteButton = ScreenshotsDeleteButton.init()
                deleteButton.autoresizingMask = [.flexibleWidth,.flexibleHeight]
                deleteButton.translatesAutoresizingMaskIntoConstraints = true
                deleteButton.addTarget(self, action: #selector(deleteButtonAction), for: .touchUpInside)
                self.deleteButton = deleteButton
                return deleteButton
            }()
            
            deleteButton.alpha = 0
            deleteButton.contentEdgeInsets = UIEdgeInsets.init(top: 0, left: 0, bottom: bottom, right: 0)
            
            deleteButton.frame = self.tabBarController!.tabBar.bounds
            self.tabBarController?.tabBar.addSubview(deleteButton)
            
        }
        let removeDeleteButton = {
            if (self.tabBarController != nil && !editing) {
                self.deleteButton?.removeFromSuperview()
            }
        }
        
        let cellEditing = {
            for index in self.collectionView.indexPathsForVisibleItems {
                if let cell = self.collectionView.cellForItem(at: index) as? ScreenshotCollectionViewCell {
                    cell.isEditing = editing
                    self.syncScreenshotCollectionViewCellSelectedState(cell)
                }
            }
            
            if (self.hasNewScreenshotSection) {
                self.collectionView.reloadSections(IndexSet.init(integer: ScreenshotsSection.notification.rawValue))
            }
            
            self.deleteButton?.alpha = editing ? 1.0: 0.0
        }
        
        if (animated) {
            UIView.animate(withDuration: .defaultAnimationDuration, animations: {
                cellEditing()
                // TODO:
                ///     putting `removeDeleteButton` here instead of in the completion
                //      prevents animation on the button fading away,
                //      but ALSO fixes a bug where if you take edit cancel
                //      edit cancel very fast you can get into a state
                //      where there no delete button in edit mode
                removeDeleteButton()
            })
        }
        else {
            cellEditing()
            removeDeleteButton()
        }
        
        self.navigationItem.rightBarButtonItem?.isEnabled = !editing
        
        if (editing) {
            self.editButtonItem.title = "generic.cancel".localized
            
            self.deleteScreenshotObjectIDs = []
            self.toHideFromProductBarObjectIDs = []
        }else {
            self.productsBarController?.toUnfavoriteAndUnViewProductObjectIDs = []
            self.updateHasNewScreenshot()
        }
        
        updateDeleteButtonCount()
    }
    
    func deselectDeletedScreenshots() {
        // Deselect all cells
        self.collectionView.selectItem(at: nil, animated: true, scrollPosition: [])
        
        self.deleteScreenshotObjectIDs = []
        self.toHideFromProductBarObjectIDs = []
        self.productsBarController?.toUnfavoriteAndUnViewProductObjectIDs = self.toHideFromProductBarObjectIDs
    }
    
    func updateDeleteButtonCount() {
        self.deleteButton?.deleteCount = self.toHideFromProductBarObjectIDs.count + self.deleteScreenshotObjectIDs.count
    }
    
    @objc func deleteButtonAction() {
        setEditing(false, animated: true)
        
        if deleteScreenshotObjectIDs.count + toHideFromProductBarObjectIDs.count > 0 {
            DataModel.sharedInstance.hide(screenshotOIDArray: deleteScreenshotObjectIDs)
            DataModel.sharedInstance.hideFromProductBar(toHideFromProductBarObjectIDs)
        }
    }
}

//Screenshot cell
extension ScreenshotsViewController : ScreenshotCollectionViewCellDelegate{
    func presentSocailShare(screenshot:Screenshot){
        let introductoryText = "screenshots.share.title".localized

        let screenshotObjectId = screenshot.objectID
        var items:[Any]? = nil
        
        // iOS 11.1 has a bug where copying to clipboard while sharing doesn't put a space between activity items.
        let space = " "
        
        if let shareLink = screenshot.shareLink, let shareURL = URL.init(string: shareLink) {
            items = [introductoryText, space, shareURL]
        }else{
            if let url = URL.init(string: "https://getscreenshop.com/") {
                let screenshotActivityItemProvider = ScreenshotActivityItemProvider.init(screenshot: screenshot, placeholderURL:url)
                items = [introductoryText, space, screenshotActivityItemProvider]
            }
        }
        if let items =  items {
            let activityViewController = UIActivityViewController.init(activityItems: items, applicationActivities: [])
            activityViewController.excludedActivityTypes = [UIActivityType.addToReadingList, UIActivityType.airDrop, UIActivityType.init("com.apple.reminders.RemindersEditorExtension"), UIActivityType.init("com.apple.mobilenotes.SharingExtension")]
            activityViewController.completionWithItemsHandler = { (activityType, completed, returnedItems, activityError) in
                let screenshot = DataModel.sharedInstance.mainMoc().screenshotWith(objectId: screenshotObjectId)
                if (completed) {
                    Analytics.trackShareSocial(screenshot: screenshot)
                } else {
                    Analytics.trackShareIncomplete(screenshot: screenshot)
                }
            }
            activityViewController.popoverPresentationController?.sourceView = self.view // so iPads don't crash
            self.present(activityViewController, animated: true, completion: nil)
        }
    }
        
    func screenshotCollectionViewCellDidTapShare(_ cell: ScreenshotCollectionViewCell) {
        if let indexPath = self.collectionView?.indexPath(for: cell),  let screenshot = self.screenshot(at: indexPath.item) {
            let source = screenshot.source
            let submittedDate = screenshot.submittedDate
            let screenshotObjectId = screenshot.objectID
            let alert = UIAlertController.init(title: "share_to_discover.action_sheet.title".localized, message: "share_to_discover.action_sheet.message".localized, preferredStyle: .actionSheet)
            
            alert.addAction(UIAlertAction.init(title: "share_to_discover.action_sheet.discover".localized, style: .default, handler: { (a) in
                if let screenshot = DataModel.sharedInstance.mainMoc().screenshotWith(objectId: screenshotObjectId) {
                    if !(source == .gallery || source == .share || source == .unknown) || submittedDate != nil {
                        let alert = UIAlertController.init(title: nil, message: "share_to_discover.action_sheet.error.alread_shared".localized, preferredStyle: .alert)
                        
                        alert.addAction(UIAlertAction.init(title: "generic.ok".localized, style: .cancel, handler: { (a) in
                            Analytics.trackShareIncomplete(screenshot: screenshot)
                        }))
                        self.present(alert, animated: true, completion: nil)
                    }else {
                        screenshot.submitToDiscover()
                        let thankYou = ThankYouForSharingViewController()
                        thankYou.closeButton.addTarget(self, action: #selector(self.thankYouForSharingViewDidClose(_:)), for: .touchUpInside)
                        self.present(thankYou, animated: true, completion: nil)
                        Analytics.trackShareDiscover(screenshot: screenshot)
                    }
                }
                
            }))
            alert.addAction(UIAlertAction.init(title: "share_to_discover.action_sheet.social".localized, style: .default, handler: { (a) in
                if let screenshot = DataModel.sharedInstance.mainMoc().screenshotWith(objectId: screenshotObjectId) {
                    self.presentSocailShare(screenshot: screenshot)
                }
            }))
            alert.addAction(UIAlertAction.init(title: "generic.cancel".localized, style: .cancel, handler: { (a) in
                let screenshot = DataModel.sharedInstance.mainMoc().screenshotWith(objectId: screenshotObjectId)
                Analytics.trackShareIncomplete(screenshot: screenshot)

            }))
            alert.popoverPresentationController?.sourceView = self.view
            
            self.present(alert, animated: true, completion: nil)
            
            
            Analytics.trackSharedScreenshotStarted(screenshot: screenshot)
    
        }
        
    }
        
    @objc func thankYouForSharingViewDidClose(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func screenshotCollectionViewCellDidTapDelete(_ cell: ScreenshotCollectionViewCell) {
        if let indexPath = self.collectionView?.indexPath(for: cell), let screenshot = self.screenshot(at: indexPath.item) {
            let objectId = screenshot.objectID
            let alertController = UIAlertController.init(title: "screenshot.delete.title".localized, message: nil, preferredStyle: .alert)
            alertController.addAction(UIAlertAction.init(title: "generic.cancel".localized, style: .cancel, handler: nil))
            alertController.addAction(UIAlertAction.init(title: "generic.delete".localized, style: .destructive, handler: { (a) in
                if let screenshot = DataModel.sharedInstance.mainMoc().screenshotWith(objectId: objectId) {
                    Analytics.trackScreenshotDeleted(screenshot: screenshot, kind: .single)
                    screenshot.setHide()
                    self.removeScreenshotHelperView()
                    self.collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                    UIView.animate(withDuration: .defaultAnimationDuration, animations: {
                        cell.selectedState = .disabled
                    })
                }
            }))
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
    func syncScreenshotCollectionViewCellSelectedState(_ cell:ScreenshotCollectionViewCell) {
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
    func syncEmptyListView() {
        guard let emptyListView = emptyListView else {
            return
        }
        
        if PermissionsManager.shared.hasPermission(for: .photo) {
            if emptyListView.type != .screenshot {
                emptyListView.type = .screenshot
            }
        }
        else {
            if emptyListView.type != .permission {
                emptyListView.type = .permission
            }
        }
        
        let hasScreenshots = collectionView.numberOfItems(inSection: ScreenshotsSection.image.rawValue) > 0
        
        editButtonItem.isEnabled = hasScreenshots || self.hasProductBar
    }
}

//Notification cell
extension ScreenshotsViewController:ScreenshotNotificationCollectionViewCellDelegate {
    func newScreenshotsCount() -> Int {
        return AccumulatorModel.sharedInstance.getNewScreenshotsCount()
    }
    
    func screenshotNotificationCollectionViewCellDidTapReject(_ cell: ScreenshotNotificationCollectionViewCell){
        let screenshotsCount = self.newScreenshotsCount()
        AccumulatorModel.sharedInstance.resetNewScreenshotsCount()
        
        self.dismissNotificationCell()
        syncEmptyListView()
        
    Analytics.trackScreenshotNotificationCancelled(screenshotCount: screenshotsCount)
    }
    func notificationCellAssetId() -> String?{
        return AccumulatorModel.sharedInstance.assetIds.first
    }
    
    func screenshotNotificationCollectionViewCellDidTapConfirm(_ cell: ScreenshotNotificationCollectionViewCell){
        let screenshotsCount = self.newScreenshotsCount()
        AccumulatorModel.sharedInstance.resetNewScreenshotsCount()

        switch cell.contentText {
            case .importSingleScreenshot:
                if let assetId = self.notificationCellAssetId() {
                    AssetSyncModel.sharedInstance.importPhotosToScreenshot(assetIds: [assetId])
                }else{
                    self.delegate?.screenshotsViewControllerWantsToPresentPicker(self)
                }
            case .importMultipleScreenshots, .importVeryManyScreenshots:
                self.delegate?.screenshotsViewControllerWantsToPresentPicker(self)
            case .none:
                //huh?
                break
        }
        
        self.dismissNotificationCell()
        syncEmptyListView()
        
        Analytics.trackScreenshotNotificationAccepted(screenshotCount: screenshotsCount)
    }
    
    func updateHasNewScreenshot(){
        let hadSection = self.hasNewScreenshotSection
        self.hasNewScreenshotSection = (AccumulatorModel.sharedInstance.getNewScreenshotsCount() > 0) && !self.isEditing
        if hadSection != self.hasNewScreenshotSection {
            let indexPath = IndexPath.init(row: 0, section: ScreenshotsSection.notification.rawValue)
            if self.hasNewScreenshotSection {
                if self.collectionView.numberOfItems(inSection: ScreenshotsSection.notification.rawValue) == 0{
                    self.collectionView.insertItems(at: [indexPath])
                    self.collectionView.scrollToItem(at: indexPath, at: .top, animated: true)
                    self.removeScreenshotHelperView()
                }
            }else{
                if self.collectionView.numberOfItems(inSection: ScreenshotsSection.notification.rawValue) == 1{
                    self.collectionView.deleteItems(at: [indexPath])
                    self.insertScreenshotHelperView()
                }
            }
        }
        
    }
    
    @objc func accumulatorModelNumberDidChange( _ notification: Notification) {
        
        if self.hasNewScreenshotSection  && AccumulatorModel.sharedInstance.getNewScreenshotsCount() > 0 {  //Already has a new screenshot section -  just do an update
            let indexPath = IndexPath.init(row: 0, section: ScreenshotsSection.notification.rawValue)
            if self.collectionView.numberOfItems(inSection: ScreenshotsSection.notification.rawValue) == 1{
                self.collectionView.reloadItems(at: [indexPath])
            }
        }else{
            updateHasNewScreenshot()
        }
        
        
        syncEmptyListView()
        
    }
    
    func dismissNotificationCell(){
        updateHasNewScreenshot()
    }
}

extension ScreenshotsViewController:UICollectionViewDelegateFlowLayout {
    func numberOfCollectionViewImageColumns() -> Int {
        return 2
    }
    
    func collectionViewInteritemOffset() -> CGPoint {
        let shadowInsets = ScreenshotCollectionViewCell.shadowInsets
        let x: CGFloat = .padding - shadowInsets.left - shadowInsets.right
        let y: CGFloat = .padding - shadowInsets.top - shadowInsets.bottom
        return CGPoint.init(x: x, y: y)
    }
    
    func notificationContentText() -> ScreenshotNotificationCollectionViewCellContentText {
        let count = self.newScreenshotsCount()
        
        if (count == 1) {
            return .importSingleScreenshot
        }else if (count > Constants.notificationProductToImportCountLimit){
            return .importVeryManyScreenshots
        } else if (count > 1) {
            return .importMultipleScreenshots
        } else {
            return .none
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let minimumSpacing = self.collectionViewInteritemOffset()

        let defaultInset = UIEdgeInsets.init(top: minimumSpacing.y, left: minimumSpacing.x, bottom: 0, right: minimumSpacing.x)
        
        if let sectionType = ScreenshotsSection.init(rawValue: section) {
            switch sectionType {
            case .product:
                return .zero
            case .notification:
                if self.hasNewScreenshotSection {
                    return defaultInset
                }
                
            case .image:
                return defaultInset
            }
        }
        return .zero
    }
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let sectionType = ScreenshotsSection.init(rawValue: indexPath.section) {
            switch sectionType {
            case .product:
                break
            case .notification:
                break
            case .image:
                if indexPath.item == 0 {
                    self.insertScreenshotHelperView()
                }
            }
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var size = CGSize.zero
        
        if let sectionType = ScreenshotsSection.init(rawValue: indexPath.section) {
            switch sectionType {
            case .product:
                size.width = collectionView.bounds.size.width - collectionView.contentInset.left - collectionView.contentInset.right
                size.height = 138
                
            case .notification, .image:
                let minimumSpacing = self.collectionViewInteritemOffset()
                
                if (indexPath.section == ScreenshotsSection.notification.rawValue) {
                    size.width = floor(collectionView.bounds.size.width - (minimumSpacing.x * 2))
                    size.height = ScreenshotNotificationCollectionViewCell.height(withCellWidth: size.width, contentText: self.notificationContentText(), contentType: .labelWithButtons)
                } else if (indexPath.section == ScreenshotsSection.image.rawValue) {
                    let columns = CGFloat(self.numberOfCollectionViewImageColumns())
                    
                    size.width = floor((collectionView.bounds.size.width - (minimumSpacing.x * (columns + 1))) / columns)
                    size.height = ceil(size.width * Screenshot.ratio.height)
                }
            }
        }
        return size
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
                if let index = self.deleteScreenshotObjectIDs.index(of: screenshot.objectID) {
                    self.deleteScreenshotObjectIDs.remove(at: index)
                    self.updateDeleteButtonCount()
                }
            }
        }
        
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == ScreenshotsSection.image.rawValue {
            if let screenshot = self.screenshot(at: indexPath.item) {
                if (self.isEditing) {
                    if !self.deleteScreenshotObjectIDs.contains(screenshot.objectID) {
                        self.deleteScreenshotObjectIDs.append(screenshot.objectID)
                        self.updateDeleteButtonCount()
                    }
                } else {
                    if (self.deleteScreenshotObjectIDs.count > 0 && self.deleteScreenshotObjectIDs.contains(screenshot.objectID)) {
                        return
                    }
                    collectionView.deselectItem(at: indexPath, animated: false)
                    self.delegate?.screenshotsViewController(self, didSelectItemAt: indexPath)
                    
                    Analytics.trackOpenedScreenshot(screenshot: screenshot, source: .list)
                    
                }
            }
        }
    }
 }

extension ScreenshotsViewController: UICollectionViewDataSource {
    func setupScreenshotProductBar(cell:ScreenshotProductBarCollectionViewCell){
        self.productsBarController?.collectionView = cell.collectionView
    }
    func setupScreenshotNotification(cell:ScreenshotNotificationCollectionViewCell, collectionView:UICollectionView, indexPath:IndexPath){
        
        cell.delegate = self
        cell.contentView.backgroundColor = collectionView.backgroundColor
        let contentType = self.notificationContentText()
        cell.contentText = contentType
        cell.setContentType(.labelWithButtons)
        
        cell.iconImage = nil
        if contentType == .importSingleScreenshot, let assetId = self.notificationCellAssetId() {
            //don't change to allowFromICloud: false.  that will cause a syncronous call on the main thread
            PHAsset.assetWith(assetId: assetId)?.image(allowFromICloud: true).then(execute: { (image) -> Void  in
                DispatchQueue.main.async {
                    for cell in self.collectionView.visibleCells {
                        if let c = cell as? ScreenshotNotificationCollectionViewCell {
                            c.iconImage = image
                        }
                    }
                }
            }).catch(execute: { (error) in
                DispatchQueue.main.async {
                    for cell in self.collectionView.visibleCells {
                        if let c = cell as? ScreenshotNotificationCollectionViewCell {
                            c.iconImage = UIImage.init(named:"NotificationSnapshot")
                        }
                    }
                }
            })
        }
        
    }
    func setupScreenshot(cell:ScreenshotCollectionViewCell, collectionView:UICollectionView, indexPath:IndexPath){
        let screenshot = self.screenshot(at: indexPath.item)
        cell.delegate = self
        cell.contentView.backgroundColor = collectionView.backgroundColor
        cell.isShamrock = screenshot?.isShamrockVersion ?? false
        cell.likes = Int(screenshot?.submittedFeedbackCount ?? 0)
        cell.screenshot = screenshot
        cell.isBadgeEnabled = screenshot?.isNew ?? false
        cell.isEditing = self.isEditing
        self.syncScreenshotCollectionViewCellSelectedState(cell)
        
    }
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let sectionType = ScreenshotsSection.init(rawValue: indexPath.section) {
            switch sectionType {
            case .product:
                if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "product", for: indexPath) as? ScreenshotProductBarCollectionViewCell {
                    self.setupScreenshotProductBar(cell: cell)
                    return cell
                }
            case .notification:
                if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "notification", for: indexPath) as? ScreenshotNotificationCollectionViewCell{
                    self.setupScreenshotNotification(cell: cell, collectionView: collectionView, indexPath: indexPath)
                    
                    return cell
                }
            case .image:
                if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? ScreenshotCollectionViewCell{
                    self.setupScreenshot(cell: cell, collectionView: collectionView, indexPath: indexPath)
                    return cell
                }
            }
        }
        
        return UICollectionViewCell()
    }
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 3
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let sectionType = ScreenshotsSection.init(rawValue: section) {
            switch sectionType {
            case .product:
                if self.hasProductBar {
                    return 1
                }else{
                    return 0
                }
            case .notification:
                return self.hasNewScreenshotSection ? 1 :0 
            case .image:
                return self.screenshotFrcManager?.fetchedObjectsCount ?? 0
            }
        }
        return 0
    }
}
