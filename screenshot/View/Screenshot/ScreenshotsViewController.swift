//
//  ScreenshotsViewController.swift
//  screenshot
//
//  Created by Jonathan Rose on 2/18/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import Foundation
import CoreData
import SafariServices
import FBSDKCoreKit
import Photos
import PromiseKit

protocol ScreenshotsViewControllerDelegate : NSObjectProtocol{
    func screenshotsViewController(_  viewController:ScreenshotsViewController, didSelectItemAt:IndexPath)
    func screenshotsViewControllerWantsToPresentPicker(_  viewController:ScreenshotsViewController, openScreenshots:Bool)
}

class ScreenshotsViewController: BaseViewController {
    enum Section : Int {
        case notification
        case image
    }

    weak var delegate:ScreenshotsViewControllerDelegate?
    
    var screenshotFrcManager:FetchedResultsControllerManager<Screenshot>?
    var collectionView:CollectionView!
    var deleteScreenshotObjectIDs:[NSManagedObjectID] = []
    var deleteButton:ScreenshotsDeleteButton?
    var refreshControl:UIRefreshControl?
    var emptyListView:ScreenshotsHelperView?
    var hasNewScreenshotSection = false
    
    fileprivate var screenshotPreviewingContext: UIViewControllerPreviewing?
    
    init() {
        super.init(nibName: nil, bundle: nil)
        
        title = "screenshots.title".localized
            
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground(_:)), name: .UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground(_:)), name: .UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(contentSizeCategoryDidChange(_:)), name: .UIContentSizeCategoryDidChange, object: nil)
        
        self.editButtonItem.target = self
        self.editButtonItem.action = #selector(editButtonAction)
        self.navigationItem.backBarButtonItem = UIBarButtonItem.init(title: "", style: .plain, target: nil, action: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.screenshotFrcManager = DataModel.sharedInstance.screenshotFrc(delegate: self)
        
        self.setupViews()
        self.syncEmptyListView()
        NotificationCenter.default.addObserver(self, selector: #selector(accumulatorModelNumberDidChange(_:)), name: .accumulatorModelDidUpdate, object: nil)
        
        enableScreenshotPreviewing()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        syncEmptyListView()
        self.updateHasNewScreenshot()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.removeScreenshotHelperView()
        if self.isEditing {
            self.setEditing(false, animated: animated)
        }
    }
    
    @objc func applicationDidEnterBackground(_ notification:Notification) {
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
            let notificationSection = self.indexFor(section: .notification )
            if self.collectionView.numberOfItems(inSection: notificationSection ) > 0 {
                self.collectionView.reloadItems(at: [IndexPath(item: 0, section: notificationSection )])
                
            }
        }
    }
    
    deinit {
        if isViewLoaded {
            self.collectionView?.delegate = nil
            self.collectionView?.dataSource = nil
        }
        NotificationCenter.default.removeObserver(self)
    }
}

extension ScreenshotsViewController{
    
    func sectionFor(index:Int) -> Section? {
        return Section.init(rawValue: index)
    }
    func indexFor(section:Section) -> Int {
        return section.rawValue
    }
    
    public func screenshot(at index:Int) -> Screenshot?{
        return self.screenshotFrcManager?.object(at: IndexPath.init(item: index, section: 0))
    }
    public func indexOf(screenshot:Screenshot) -> Int? {
        return self.screenshotFrcManager?.indexPath(forObject: screenshot)?.item
    }
    
    func scrollToTop(){
        if let collectionView = self.collectionView {
            if self.isViewLoaded {
                if collectionView.numberOfItems(inSection: self.indexFor(section: .image) ) > 0 {
                    collectionView.contentOffset = CGPoint.init(x: collectionView.contentInset.left, y: -collectionView.contentInset.top)
                }
            }
        }
    }
}

//Setup view
extension ScreenshotsViewController {
    
    @objc func pinch( gesture:UIPinchGestureRecognizer) {
        if CrazeImageZoom.shared.isHandlingGesture, let imageView = CrazeImageZoom.shared.hostedImageView  {
            CrazeImageZoom.shared.gestureStateChanged(gesture, imageView: imageView)
            return
        }
        let point = gesture.location(in: self.collectionView)
        if let indexPath = self.collectionView.indexPathForItem(at: point), let cell = self.collectionView.cellForItem(at: indexPath){
            if let cell = cell as? ScreenshotCollectionViewCell {
                
                var transform:((UIImageView)->UIView)?
                let imageView = cell.imageView
                
                if  let superView = imageView.superview {
                    let frame = superView.bounds.aspectFit(in: UIScreen.main.bounds.applying(CGAffineTransform(scaleX: 2, y: 2)))
                    
                    let container = UIView.init(frame: frame)
                    
                    let newImageView = UIImageView.init(image: imageView.image)
                    newImageView.contentMode = imageView.contentMode
                    let scaledBy = frame.width / superView.frame.width
                    newImageView.frame =  imageView.frame.applying(CGAffineTransform(scaleX: scaledBy, y: scaledBy))
                    container.addSubview(newImageView)
                    
                    
                    if let snapshot = container.snapshotView(afterScreenUpdates: true) {
                        snapshot.center = superView.convert(superView.center, to: nil)
                        snapshot.bounds = superView.bounds
                        
                        transform = { imageView in
                            return snapshot
                        }
                    }
                }
                
                CrazeImageZoom.shared.gestureStateChanged(gesture, imageView: imageView,  popViewTransform:transform)
            }
        }
    }
    
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
            
            collectionView.register(ScreenshotNotificationCollectionViewCell.self, forCellWithReuseIdentifier: "notification")
            collectionView.register(ScreenshotCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
            
            collectionView.register(ScreenshotsActionsCollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "header")
            collectionView.register(ScreenshotsActionsCollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: "footer")
            
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
            emptyListView.permissionButton.addTarget(self, action: #selector(emptyListViewAllowAccessAction), for:.touchUpInside)
            emptyListView.uploadButton.addTarget(self, action: #selector(emptyListViewUploadAction), for:.touchUpInside)
            emptyListView.discoverButton.addTarget(self, action: #selector(emptyListViewDiscoverAction), for:.touchUpInside)
            collectionView.emptyView = emptyListView
            return emptyListView
        }()
        self.emptyListView = emptyListView
        
        let pinchZoom = UIPinchGestureRecognizer.init(target: self, action: #selector(pinch(gesture:)))
        self.view.addGestureRecognizer(pinchZoom)

    }
    
    @objc func refreshControlAction(_ refreshControl:UIRefreshControl){
        if (refreshControl.isRefreshing) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                refreshControl.endRefreshing()
            }
        }
    }
    
    @objc fileprivate func emptyListViewAllowAccessAction() {
        PermissionsManager.shared.requestPermission(for: .photo, openSettingsIfNeeded: true) { (granted) in
            self.syncEmptyListView()
        }
    }
    
    @objc fileprivate func emptyListViewUploadAction() {
        self.delegate?.screenshotsViewControllerWantsToPresentPicker(self, openScreenshots: false)
    }
    
    @objc fileprivate func emptyListViewDiscoverAction() {
        if let tabBarController = tabBarController as? MainTabBarController {
            tabBarController.goTo(tab: .discover)
        }
    }
    
    @objc private func headerFooterUploadAction() {
        self.delegate?.screenshotsViewControllerWantsToPresentPicker(self, openScreenshots: false)
    }
}

extension ScreenshotsViewController : FetchedResultsControllerManagerDelegate {
    func managerDidChangeContent(_ controller: NSObject, change: FetchedResultsControllerManagerChange) {
        change.shiftIndexSections(by: Section.image.rawValue)
        change.applyChanges(collectionView: collectionView)
        syncEmptyListView()
        
        if collectionView.numberOfItems(inSection: indexFor(section: .image)) != 1 {
            removeScreenshotHelperView()
        }
    }
}

//Helper view
extension ScreenshotsViewController {
    func insertScreenshotHelperViewIfNeeded() {
        let hasPresented = UserDefaults.standard.bool(forKey: UserDefaultsKeys.onboardingPresentedScreenshotHelper)
        let has1Screenshot = self.collectionView.numberOfItems(inSection: self.indexFor(section: .image )) == 1
        
        if !hasPresented && has1Screenshot && !self.hasNewScreenshotSection {
            UserDefaults.standard.set(true, forKey: UserDefaultsKeys.onboardingPresentedScreenshotHelper)
            if let layout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                let backgroundView = UIView()
                
                self.collectionView.backgroundView = backgroundView
                
                let contentView = UIView()
                contentView.translatesAutoresizingMaskIntoConstraints = false
                backgroundView.addSubview(contentView)
                
                let topConstant = collectionViewImageReferenceSize(section: Section.image.rawValue).height + layout.minimumLineSpacing
                    
                contentView.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor, constant: topConstant).isActive = true
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
        
        if editing {
            disableScreenshotPreviewing()
        }
        else {
            enableScreenshotPreviewing()
        }
        
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
            
            self.collectionView.collectionViewLayout.invalidateLayout()
            
            self.deleteButton?.alpha = editing ? 1 : 0
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
        
        if (editing) {
            self.editButtonItem.title = "generic.cancel".localized
            
            self.deleteScreenshotObjectIDs = []
        }else {
            self.updateHasNewScreenshot()
        }
        
        updateDeleteButtonCount()
    }
    
    func deselectDeletedScreenshots() {
        // Deselect all cells
        self.collectionView.selectItem(at: nil, animated: true, scrollPosition: [])
        
        self.deleteScreenshotObjectIDs = []
    }
    
    func updateDeleteButtonCount() {
        self.deleteButton?.deleteCount = self.deleteScreenshotObjectIDs.count
    }
    
    @objc func deleteButtonAction() {
        setEditing(false, animated: true)
        
        if deleteScreenshotObjectIDs.count > 0 {
            DataModel.sharedInstance.hide(screenshotOIDArray: deleteScreenshotObjectIDs, kind: .multi)
        }
        self.deleteScreenshotObjectIDs.removeAll()
    }
}

//Screenshot cell
extension ScreenshotsViewController : ScreenshotCollectionViewCellDelegate{
    func screenshotCollectionViewCellDidTapShare(_ cell: ScreenshotCollectionViewCell) {
        if let indexPath = self.collectionView?.indexPath(for: cell),  let screenshot = self.screenshot(at: indexPath.item) {
            ScreenshotShareManager.share(screenshot: screenshot, in: self)
        }
    }
        
    @objc func thankYouForSharingViewDidClose(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
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
        
        let hasScreenshots = collectionView.numberOfItems(inSection: self.indexFor(section: .image )) > 0
        editButtonItem.isEnabled = hasScreenshots
    }
}

//Notification cell
extension ScreenshotsViewController:ScreenshotNotificationCollectionViewCellDelegate {
    func newScreenshotsCount() -> Int {
        return AccumulatorModel.screenshot.newCount
    }
    
    func screenshotNotificationCollectionViewCellDidTapReject(_ cell: ScreenshotNotificationCollectionViewCell){
        let screenshotsCount = self.newScreenshotsCount()
        AccumulatorModel.screenshot.resetNewCount()
        
        self.dismissNotificationCell()
        syncEmptyListView()
        
        Analytics.trackScreenshotNotificationCancelled(screenshotCount: screenshotsCount)
    }
    
    func notificationCellAssetId() -> String?{
        return AccumulatorModel.screenshot.assetIds.first
    }
    
    func screenshotNotificationCollectionViewCellDidTapConfirm(_ cell: ScreenshotNotificationCollectionViewCell){
        let screenshotsCount = self.newScreenshotsCount()
        AccumulatorModel.screenshot.resetNewCount()

        switch cell.contentText {
            case .importSingleScreenshot:
                if let assetId = self.notificationCellAssetId() {
                    AccumulatorModel.screenshotUninformed.decrementUninformedCount(by:1)
                    AssetSyncModel.sharedInstance.importPhotosToScreenshot(assetIds: [assetId], source: .screenshot)
                }else{
                    self.delegate?.screenshotsViewControllerWantsToPresentPicker(self, openScreenshots: true)
                }
            case .importMultipleScreenshots, .importVeryManyScreenshots:
                self.delegate?.screenshotsViewControllerWantsToPresentPicker(self, openScreenshots: true)
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
        self.hasNewScreenshotSection = (AccumulatorModel.screenshot.newCount > 0) && !self.isEditing
        if hadSection != self.hasNewScreenshotSection {
            let indexPath = IndexPath.init(row: 0, section: self.indexFor(section: .notification ))
            if self.hasNewScreenshotSection {
                if self.collectionView.numberOfItems(inSection: self.indexFor(section: .notification )) == 0{
                    self.collectionView.insertItems(at: [indexPath])
                    self.collectionView.scrollToItem(at: indexPath, at: .top, animated: true)
                    self.removeScreenshotHelperView()
                }
            }else{
                if self.collectionView.numberOfItems(inSection: self.indexFor(section: .notification )) == 1{
                    self.collectionView.deleteItems(at: [indexPath])
                    self.insertScreenshotHelperViewIfNeeded()
                }
            }
        }
        
    }
    
    @objc func accumulatorModelNumberDidChange( _ notification: Notification) {
        if self.hasNewScreenshotSection  && AccumulatorModel.screenshot.newCount > 0 {  //Already has a new screenshot section -  just do an update
            let indexPath = IndexPath.init(row: 0, section: self.indexFor(section: .notification ))
            if self.collectionView.numberOfItems(inSection: self.indexFor(section: .notification )) == 1{
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
        
        if let sectionType = self.sectionFor(index: section) {
            switch sectionType {
            case .notification:
                if self.hasNewScreenshotSection && !isEditing {
                    return defaultInset
                }
                
            case .image:
                return defaultInset
            }
        }
        return .zero
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? ScreenshotCollectionViewCell {
            // The editing state can be out of sync. because the state is set for all visible cells and new cells that are created - BUT there are cells that are created but not yet put into the view that are not in a correct editing state.
            self.setupScreenshot(cell: cell, collectionView: collectionView, indexPath: indexPath)
        }
        
        if let sectionType = self.sectionFor(index:  indexPath.section) {
            switch sectionType {
            case .notification:
                break
            case .image:
                if indexPath.item == 0 {
                    self.insertScreenshotHelperViewIfNeeded()
                }
            }
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var size = CGSize.zero
        
        if let sectionType =  self.sectionFor(index: indexPath.section) {
            switch sectionType {
            case .notification:
                let minimumSpacing = self.collectionViewInteritemOffset()
                size.width = floor(collectionView.bounds.size.width - (minimumSpacing.x * 2))
                size.height = isEditing ? 0.1 : ScreenshotNotificationCollectionViewCell.height(withCellWidth: size.width, contentText: self.notificationContentText(), contentType: .labelWithButtons)
                
            case .image :
                let minimumSpacing = self.collectionViewInteritemOffset()
                let columns = CGFloat(self.numberOfCollectionViewImageColumns())
                size.width = floor((collectionView.bounds.size.width - (minimumSpacing.x * (columns + 1))) / columns)
                size.height = ceil(size.width * Screenshot.ratio.height)
            }
        }
        return size
    }
    
    public func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        if let sectionType = self.sectionFor(index: indexPath.section){
            if sectionType == .notification &&   self.isEditing {
                return false
            }
        }
        return true
    }
    
    public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if let sectionType =  self.sectionFor(index: indexPath.section){
            if (sectionType == .image && self.isEditing) {
                if let screenshot = self.screenshot(at: indexPath.item) {
                    if let index = self.deleteScreenshotObjectIDs.index(of: screenshot.objectID) {
                        self.deleteScreenshotObjectIDs.remove(at: index)
                        self.updateDeleteButtonCount()
                    }
                }
            }
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let sectionType =  self.sectionFor(index: indexPath.section),
            sectionType == .image,
            let screenshot = self.screenshot(at: indexPath.item) {
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

extension ScreenshotsViewController: UICollectionViewDataSource {
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
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == Section.image.rawValue {
            return collectionViewImageReferenceSize(section: section)
        }
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if section == Section.image.rawValue {
            return collectionViewImageReferenceSize(section: section, isFooter: true)
        }
        return .zero
    }
    
    private func collectionViewImageReferenceSize(section: Int, isFooter: Bool = false) -> CGSize {
        if section == Section.image.rawValue {
            var size: CGSize = .zero
            size.width = view.bounds.size.width
            
            if isEditing || collectionView.numberOfItems(inSection: section) == 0 {
                size.height = 0.1
            }
            else {
                var canProgress = true
                
                if isFooter {
                    let numberOfImages = self.collectionView(collectionView, numberOfItemsInSection: section)
                    canProgress = numberOfImages > 2
                }
                
                if canProgress {
                    let height = ScreenshotsActionsCollectionReusableView.contentHeight
                    let minimumSpacing = collectionViewInteritemOffset()
                    size.height = height + minimumSpacing.y
                }
                else {
                    size.height = 0.1
                }
            }
            return size
        }
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if indexPath.section == Section.image.rawValue {
            var identifier: String? = nil
            
            if kind == UICollectionElementKindSectionHeader {
                identifier = "header"
            }
            else if kind == UICollectionElementKindSectionFooter {
                identifier = "footer"
            }
            
            if let identifier = identifier,
                let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: identifier, for: indexPath) as? ScreenshotsActionsCollectionReusableView
            {
                view.uploadButton.addTarget(self, action: #selector(headerFooterUploadAction), for: .touchUpInside)
                
                let minimumSpacing = self.collectionViewInteritemOffset()
                
                var layoutMargins: UIEdgeInsets = .zero
                layoutMargins.top = minimumSpacing.y
                layoutMargins.left = minimumSpacing.x
                layoutMargins.right = minimumSpacing.x
                view.layoutMargins = layoutMargins
                
                return view
            }
        }
        
        return UICollectionReusableView()
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let sectionType =  self.sectionFor(index: indexPath.section) {
            switch sectionType {
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
        if let sectionType =  self.sectionFor(index: section) {
            switch sectionType {
            case .notification:
                return self.hasNewScreenshotSection ? 1 : 0
            case .image:
                return self.screenshotFrcManager?.fetchedObjectsCount ?? 0
            }
        }
        return 0
    }
}

extension ScreenshotsViewController: UIViewControllerPreviewingDelegate {
    fileprivate func enableScreenshotPreviewing() {
        if traitCollection.forceTouchCapability == .available {
            screenshotPreviewingContext = registerForPreviewing(with: self, sourceView: collectionView)
        }
    }
    
    fileprivate func disableScreenshotPreviewing() {
        if traitCollection.forceTouchCapability == .available, let context = screenshotPreviewingContext {
            unregisterForPreviewing(withContext: context)
        }
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        if let indexPath = collectionView.indexPathForItem(at: location),
            let sectionType =  self.sectionFor(index: indexPath.section),
            sectionType == .image,
            let screenshot = screenshot(at: indexPath.item),
            let cell = collectionView.cellForItem(at: indexPath)
        {
            Analytics.trackFeatureScreenshotPreviewPeek(screenshot: screenshot)
            
            previewingContext.sourceRect = cell.frame
            
            let viewController = ScreenshotDisplayViewController()
            viewController.screenshot = screenshot
            return viewController
        }
        
        return nil
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        guard let viewController = viewControllerToCommit as? ScreenshotDisplayViewController else {
            return
        }
        
        Analytics.trackFeatureScreenshotPreviewPop(screenshot: viewController.screenshot)
        
        let navigationController = ScreenshotDisplayNavigationController()
        navigationController.screenshotDisplayViewController.screenshot = viewController.screenshot
        showDetailViewController(navigationController, sender: self)
    }
}
