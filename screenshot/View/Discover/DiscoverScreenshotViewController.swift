//
//  DiscoverScreenshotViewController.swift
//  screenshot
//
//  Created by Corey Werner on 1/7/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import Foundation
import CoreData
import UIKit

protocol DiscoverScreenshotViewControllerDelegate : NSObjectProtocol {
    func discoverScreenshotViewController(_ viewController: DiscoverScreenshotViewController, didSelectItemAtIndexPath indexPath: IndexPath)
}

class DiscoverScreenshotViewController : BaseViewController, AsyncOperationMonitorDelegate {
    
    fileprivate let collectionView = UICollectionView(frame: .zero, collectionViewLayout: DiscoverScreenshotCollectionViewLayout())
    fileprivate var matchstickFrc: FetchedResultsControllerManager<Matchstick>?
    fileprivate var matchsticks:[Matchstick] = []
    fileprivate let passButton = UIButton()
    fileprivate let addButton = UIButton()
    fileprivate let retryButton = UIButton()
    fileprivate var cardHelperView: DiscoverScreenshotHelperView?
    fileprivate let emptyView = HelperView()
    fileprivate let clearFilterView = HelperView()

    fileprivate let discoverFilterControl = DiscoverFilterControl()

    weak var delegate: DiscoverScreenshotViewControllerDelegate?
    
    private var loading = Loader()
    
    var filterReloadMonitor:AsyncOperationMonitor?
    
    override var title: String? {
        set {}
        get {
            return "discover.title".localized
        }
    }
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)        
    }
    
    func updateViewsLoadingState(){
        if self.matchsticks.count == 0 {
            let isFilterReloading = (self.filterReloadMonitor?.didStart ?? false) || DiscoverManager.shared.processing
            passButton.isHidden = isFilterReloading
            addButton.isHidden = isFilterReloading
            collectionView.isHidden = isFilterReloading
            loading.isHidden = !isFilterReloading
            if DiscoverManager.shared.isUnfiltered {
                emptyView.isHidden = isFilterReloading
                clearFilterView.isHidden = true
            }else{
                emptyView.isHidden = true
                clearFilterView.isHidden = isFilterReloading
                let name = discoverFilterControl.selectedCategory.displayName
                clearFilterView.titleLabel.text = "discover.no_more".localized(withFormat: name)
                
            }
            if isFilterReloading {
                loading.startAnimation()
            }else{
                loading.stopAnimation()
            }
        }else{
            passButton.isHidden = false
            addButton.isHidden = false
            collectionView.isHidden = false
            loading.isHidden = true
            emptyView.isHidden = true
            clearFilterView.isHidden = true
            loading.stopAnimation()
        }
        
    }
    func asyncOperationMonitorDidChange(_ monitor: AsyncOperationMonitor) {
        updateViewsLoadingState()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.filterReloadMonitor = DiscoverManager.shared.createFilterChangingMonitor(delegate: self)

        matchstickFrc = DataModel.sharedInstance.matchstickFrc(delegate:self)
        self.matchsticks = matchstickFrc?.fetchedObjects ?? []
        
        
        automaticallyAdjustsScrollViewInsets = false
        
        if let layout = collectionView.collectionViewLayout as? DiscoverScreenshotCollectionViewLayout {
            layout.delegate = self
        }

        loading.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(loading)
        loading.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        loading.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        
        discoverFilterControl.addTarget(self, action: #selector(didChangeCategoryFilter(_:)), for: .valueChanged)
        discoverFilterControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(discoverFilterControl)
        discoverFilterControl.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor, constant:5.0).isActive = true
        
        discoverFilterControl.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        discoverFilterControl.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        discoverFilterControl.heightAnchor.constraint(equalToConstant: DiscoverFilterControl.defaultHeight).isActive = true
        
        /*
         * FIXME: Hiding and disabling interaction with discoverFilterControl for now while we figure out how it
         * will work with new server side queue generation. If we want to remove it permenantly we should clean up
         * all code here and in Discover Manager that leverages the filter rather than the below hack.
         * out.
         */
        discoverFilterControl.selectAllFilter()
        discoverFilterControl.isUserInteractionEnabled = false
        discoverFilterControl.isHidden = true
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .clear
        collectionView.contentInset = UIEdgeInsets(top: .padding, left: .padding, bottom: .padding, right: .padding)
        collectionView.scrollsToTop = false
        collectionView.register(DiscoverScreenshotCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        view.addSubview(collectionView)
        collectionView.topAnchor.constraint(equalTo: discoverFilterControl.bottomAnchor).isActive = true
        collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(collectionViewPanGestureAction(_:)))
        collectionView.addGestureRecognizer(panGesture)

        let image = UIImage(named: "DiscoverScreenshotArrow")
        let arrowPadding: CGFloat = 18
        
        passButton.translatesAutoresizingMaskIntoConstraints = false
        passButton.setTitle("discover.screenshot.pass".localized, for: .normal)
        passButton.setTitleColor(.gray3, for: .normal)
        passButton.setImage(image, for: .normal)
        passButton.titleLabel?.font = .screenshopFont(.hindMedium, textStyle: .subheadline, staticSize: true)
        passButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -arrowPadding, bottom: 0, right: arrowPadding)
        passButton.contentEdgeInsets = UIEdgeInsets(top: .padding, left: arrowPadding, bottom: .padding, right: .padding)
        passButton.addTarget(self, action: #selector(passButtonAction), for: .touchUpInside)
        passButton.adjustsImageWhenDisabled = false
        passButton.isExclusiveTouch = true
        view.addSubview(passButton)
        passButton.topAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: -.padding).isActive = true
        passButton.leadingAnchor.constraint(greaterThanOrEqualTo: view.layoutMarginsGuide.leadingAnchor).isActive = true
        passButton.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor).isActive = true
        passButton.trailingAnchor.constraint(equalTo: view.centerXAnchor, constant: -.padding).isActive = true
        
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.setTitle("discover.screenshot.add".localized, for: .normal)
        addButton.setTitleColor(.gray3, for: .normal)
        addButton.setImage(image, for: .normal)
        addButton.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        addButton.titleLabel?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        addButton.titleLabel?.font = .screenshopFont(.hindMedium, textStyle: .subheadline, staticSize: true)
        addButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -arrowPadding, bottom: 0, right: arrowPadding)
        addButton.contentEdgeInsets = UIEdgeInsets(top: .padding, left: arrowPadding, bottom: .padding, right: .padding)
        addButton.addTarget(self, action: #selector(addButtonAction), for: .touchUpInside)
        addButton.adjustsImageWhenDisabled = false
        addButton.isExclusiveTouch = true
        view.addSubview(addButton)
        addButton.topAnchor.constraint(equalTo: passButton.topAnchor).isActive = true
        addButton.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: .padding).isActive = true
        addButton.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor).isActive = true
        addButton.trailingAnchor.constraint(lessThanOrEqualTo: view.layoutMarginsGuide.trailingAnchor).isActive = true
        
        emptyView.translatesAutoresizingMaskIntoConstraints = false
        emptyView.titleLabel.text = "discover.screenshot.empty.title".localized
        emptyView.subtitleLabel.text = "discover.screenshot.empty.detail".localized
        emptyView.contentImage = UIImage(named: "DiscoverScreenshotEmptyListGraphic")
        emptyView.layoutMargins = UIEdgeInsets(top: .extendedPadding, left: .extendedPadding, bottom: .extendedPadding, right: .extendedPadding)
        view.insertSubview(emptyView, belowSubview: collectionView)
        emptyView.topAnchor.constraint(equalTo: discoverFilterControl.bottomAnchor).isActive = true
        emptyView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        emptyView.bottomAnchor.constraint(equalTo: passButton.topAnchor).isActive = true
        emptyView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        retryButton.translatesAutoresizingMaskIntoConstraints = false
        //retryButton.setTitle("discover.screenshot.retry".localized, for: .normal)
        retryButton.setTitle("Retry", for: .normal)
        retryButton.setTitleColor(.black, for: .normal)
        retryButton.layer.borderWidth = 1
        retryButton.layer.borderColor = UIColor.black.cgColor
        retryButton.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        retryButton.titleLabel?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        retryButton.titleLabel?.font = .screenshopFont(.hindMedium, textStyle: .subheadline, staticSize: true)
        retryButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        retryButton.contentEdgeInsets = UIEdgeInsets(top: .padding, left: .padding, bottom: .padding, right: .padding)
        retryButton.addTarget(self, action: #selector(retryButtonAction), for: .touchUpInside)
        retryButton.adjustsImageWhenDisabled = false
        retryButton.isExclusiveTouch = true
        emptyView.addSubview(retryButton)
        retryButton.topAnchor.constraint(equalTo: emptyView.subtitleLabel.bottomAnchor, constant: 20).isActive = true
        retryButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0).isActive = true
        retryButton.layer.cornerRadius = 60 / 2.0
        retryButton.backgroundColor = .white
        
        clearFilterView.translatesAutoresizingMaskIntoConstraints = false
        clearFilterView.titleLabel.text = "discover.no_more.default".localized
        clearFilterView.contentImage = UIImage(named: "DiscoverNoMoreInFilter")
        let button = MainButton()
        button.addTarget(self, action: #selector(selectAllFilter(_:)), for: .touchUpInside)
        button.backgroundColor = .crazeRed
        button.setTitle("discover.no_more.show_all".localized, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        clearFilterView.controlView.addSubview( button )
        button.topAnchor.constraint(equalTo: clearFilterView.controlView.topAnchor).isActive = true
        button.leadingAnchor.constraint(equalTo: clearFilterView.controlView.leadingAnchor).isActive = true
        button.trailingAnchor.constraint(equalTo: clearFilterView.controlView.trailingAnchor).isActive = true
        button.bottomAnchor.constraint(equalTo: clearFilterView.controlView.bottomAnchor).isActive = true
        clearFilterView.layoutMargins = UIEdgeInsets(top: .extendedPadding, left: .extendedPadding, bottom: .extendedPadding, right: .extendedPadding)
        view.insertSubview(clearFilterView, belowSubview: collectionView)
        clearFilterView.topAnchor.constraint(equalTo: discoverFilterControl.bottomAnchor).isActive = true
        clearFilterView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        clearFilterView.bottomAnchor.constraint(equalTo: passButton.topAnchor).isActive = true
        clearFilterView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        
        
//        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "NavigationBarFilter"), style: .plain, target: self, action: #selector(showGenderPopup(_:)))

        let isFilterReloading = true
        passButton.isHidden = isFilterReloading
        addButton.isHidden = isFilterReloading
        collectionView.isHidden = isFilterReloading
        loading.isHidden = !isFilterReloading
        emptyView.isHidden = isFilterReloading
        clearFilterView.isHidden = isFilterReloading
        
        let pinchZoom = UIPinchGestureRecognizer.init(target: self, action: #selector(pinch(gesture:)))
        self.view.addGestureRecognizer(pinchZoom)
        updateViewsLoadingState()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        DiscoverManager.shared.discoverViewDidAppear()
        syncEmptyListViews()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        discoverFilterControl.scrollToSelected()
        
        let campaignKey = UserDefaultsKeys.CampaignCompleted.campaign_2018_12_01.rawValue
        
        if UserDefaults.standard.string(forKey: UserDefaultsKeys.lastCampaignCompleted) != campaignKey {
            UserDefaults.standard.set(campaignKey, forKey: UserDefaultsKeys.lastCampaignCompleted)
            
            let campaign = CampaignPromotionViewController(modal: true)
            campaign.delegate = self
            present(campaign, animated: true, completion: nil)
            DataModel.sharedInstance.performBackgroundTask { (context) in
                let now = Date()
                let expireDate = Date.init(timeIntervalSince1970: 1548979200) // feb 1, 2019
                InboxMessage.createUpdateWith(lookupDict: nil, actionType: InboxMessage.ActionType.link.rawValue, actionValue: "https://www.instagram.com/screenshopit/", buttonText: "Learn More", image:"https://s3.amazonaws.com/search-bar/daily-discover-notification-image%403x.png", title: "Introducing our Daily Discover Contest! Follow us on Instagram and swipe on Discover for full rules and regulations!", uuid: campaignKey, expireDate: expireDate, date: now, showAfterDate: now, tracking: nil, create: true, update: false, context: context)
                context.saveIfNeeded()
            }
            
        }

    }
    @objc func selectAllFilter(_ sender:Any){
        self.discoverFilterControl.selectAllFilter()
        DiscoverManager.shared.updateFilter(category: nil)
        DiscoverManager.shared.updateGender(gender: "")

        self.updateViewsLoadingState()
    }

    @objc func showGenderPopup(_ sender:Any){
        if let sender = sender as? UIBarButtonItem {
            let vc = DiscoverGenderOptionViewController.init()
            vc.modalPresentationStyle = .popover
            
            vc.popoverPresentationController?.permittedArrowDirections = [.up, .down]
            vc.popoverPresentationController?.delegate = self
            vc.popoverPresentationController?.barButtonItem = sender
            
            self.present(vc, animated: true) {
                
            }
        }
    }
    @objc func didChangeCategoryFilter(_ sender:Any){
        let category = self.discoverFilterControl.selectedCategory
        self.matchsticks = []
        self.collectionView.reloadData()
        if category.filterName == "" {
            DiscoverManager.shared.updateFilter(category: nil)
        }else{
            DiscoverManager.shared.updateFilter(category: category.filterName)
        }
         if category.genderName == "male"{
            DiscoverManager.shared.updateGender(gender: "male")
         }else if category.genderName == "female" {
            DiscoverManager.shared.updateGender(gender: "female")
         }else{
            DiscoverManager.shared.updateGender(gender: "")
        }
        
        self.updateViewsLoadingState()
        
    }
    
    deinit {
        if isViewLoaded {
            if let layout = collectionView.collectionViewLayout as? DiscoverScreenshotCollectionViewLayout {
                layout.delegate = nil
            }
            
            collectionView.dataSource = nil
            collectionView.delegate = nil
        }
    }
    
    // MARK:
    
    @objc func pinch( gesture:UIPinchGestureRecognizer) {
        if CrazeImageZoom.shared.isHandlingGesture, let imageView = CrazeImageZoom.shared.hostedImageView  {
            CrazeImageZoom.shared.gestureStateChanged(gesture, imageView: imageView)
            return
        }
        let point = gesture.location(in: self.collectionView)
        if let indexPath = self.collectionView.indexPathForItem(at: point), let cell = self.collectionView.cellForItem(at: indexPath) as? DiscoverScreenshotCollectionViewCell{
            CrazeImageZoom.shared.gestureStateChanged(gesture, imageView: cell.imageView)
        }
    }
    
    fileprivate var currentIndexPath: IndexPath {
        return IndexPath(item: 0, section: 0)
    }
    
    fileprivate var currentMatchstick: Matchstick? {
        guard collectionView.numberOfItems(inSection: 0) > 0 else {
            return nil
        }
        
        return matchstickAt(index: currentIndexPath)
    }
    
    // MARK: Decision
    
    fileprivate var isAdding = false
    fileprivate var needsToReloadAfterDecision = false
    fileprivate let decisionValueMultiplier: CGFloat = 3
    
    fileprivate func decisionValueThreshold(_ percent: CGFloat) -> CGFloat {
        return percent * decisionValueMultiplier
    }

    func decidedToPass() {
        isAdding = false
        
        if let matchStick = currentMatchstick {
            removeCurrentMatchstickIfPossible()
            matchStick.pass()
        }
    }
    
    private var needsToCompleteDecision = false

    func completeDecision() {
        if needsToCompleteDecision {
            needsToCompleteDecision = false
            
            if let matchStick = currentMatchstick {
                removeCurrentMatchstickIfPossible()
                screenshotsTabPulseAnimation()
                matchStick.delayedAdd()
            }
        }
    }
    
    func decidedToAdd(callback: ((_ screenshot: Screenshot) -> ())? = nil) {
        isAdding = true
        
        if let matchStick = currentMatchstick {
            if callback == nil {
                removeCurrentMatchstickIfPossible()
                screenshotsTabPulseAnimation()
            }
            else {
                tempButtonDisable = true
                syncInteractionElements()
            }
            
            matchStick.add(callback: callback)
            needsToCompleteDecision = callback != nil
        }
    }
    
    fileprivate func removeCurrentMatchstickIfPossible() {
        guard currentMatchstick != nil else {
            return
        }
        
        matchsticks.remove(at: currentIndexPath.item)
        
        collectionView.performBatchUpdates({
            collectionView.deleteItems(at: [currentIndexPath])
        })
        
        updateViewsLoadingState()
        setInteractiveElementsOffWithDelay()
    }
    
    // MARK: Cell
    
    fileprivate func updateCell(atIndexPath indexPath: IndexPath, percent: CGFloat) {
        guard let collectionViewLayout = collectionView.collectionViewLayout as? DiscoverScreenshotCollectionViewLayout else {
            return
        }
        
        if let cell = collectionView.cellForItem(at: indexPath) as? DiscoverScreenshotCollectionViewCell,
            let attributes = collectionViewLayout.finalLayoutAttributesForDisappearingItem(at: indexPath)
        {
            let percent = min(1, max(-1, percent))
            
            // Only the first cell should move in the expected direction
            let direction = CGFloat(indexPath.item == 0 ? 0 : 1)
            let itemPercent = abs(direction - abs(percent))
            
            if indexPath.item == 0 {
                cell.decisionValue = decisionValueThreshold(percent)
            }
            
            collectionViewLayout.progressFinalAttributes(attributes, cell: cell, percent: itemPercent)
        }
    }
    
    // MARK: User Interaction
    
    private var canPanScreenshot = false
    private var didDismissHelperView = false

    @objc private func collectionViewPanGestureAction(_ panGesture: UIPanGestureRecognizer) {
        var translation = panGesture.translation(in: panGesture.view)
        var percent: CGFloat {
            return min(1, max(-1, (translation.x / 2) / collectionView.center.x))
        }
        
        switch panGesture.state {
        case .began:
            canPanScreenshot = false
            
        case .changed:
            let location = panGesture.location(in: panGesture.view)
            let indexPathAtLocation = collectionView.indexPathForItem(at: location)
            
            if !canPanScreenshot && indexPathAtLocation != nil {
                canPanScreenshot = true
                panGesture.setTranslation(.zero, in: panGesture.view)
                translation = panGesture.translation(in: panGesture.view)
                
                if cardHelperView != nil {
                    dismissHelperView()
                    didDismissHelperView = true
                }
            }
            
            isAdding = translation.x > 0
            
            if canPanScreenshot {
                collectionView.indexPathsForVisibleItems.forEach { indexPath in
                    updateCell(atIndexPath: indexPath, percent: percent)
                }
                
                if self.matchsticks.count == 1 {
                    
                    emptyView.alpha =  abs(percent)
                    clearFilterView.alpha = abs(percent)
                   
                }
                
                if !tempButtonDisable {
                    tempButtonDisable = true
                    syncInteractionElements()
                }
            }
            
        case .ended, .cancelled:
            guard canPanScreenshot else {
                return
            }
            
            func repositionAnimation() {
                UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.8, options: [.allowUserInteraction, .beginFromCurrentState], animations: {
                    self.updateCell(atIndexPath: self.currentIndexPath, percent: 0)
                    
                })
                
                setInteractiveElementsOffWithDelay()
            }
            
            guard !didDismissHelperView else {
                didDismissHelperView = false
                repositionAnimation()
                return
            }
            
            let decisionValueThreshold = self.decisionValueThreshold(percent)
            let velocity = panGesture.velocity(in: self.view)
            let velocityIsNegative = (velocity.x < 0)
            let positionIsNegative = (decisionValueThreshold < 0)
            let velocityAndPositionIsInSameDirection = (decisionValueThreshold == 0 || velocityIsNegative == positionIsNegative)
            let velocityOrPositionPassedThreshhold = (abs(velocity.x) > 700 || abs(decisionValueThreshold) >= 1)

            let direction:Int = {
                if decisionValueThreshold > 0 {
                    return 1
                }else if decisionValueThreshold < 0 {
                    return -1
                }else if velocity.x > 0 {
                    return 1
                }else {
                    return -1
                }
            }()
            
            if velocityAndPositionIsInSameDirection && velocityOrPositionPassedThreshhold {
                if direction == 1 {
                    Analytics.trackMatchsticksAdd(matchstick: currentMatchstick, by: .swipe)
                    
                    decidedToAdd()
                }
                else {
                    Analytics.trackMatchsticksSkip(matchstick: currentMatchstick, by: .swipe)
                    
                    decidedToPass()
                }
            }
            else {
                repositionAnimation()
            }
            
        default:
            break
        }
    }
    
    fileprivate var tempButtonDisable = false
    
    fileprivate func setInteractiveElementsOnOff() {
        tempButtonDisable = true
        syncInteractionElements()
        setInteractiveElementsOffWithDelay()
    }
    
    fileprivate func setInteractiveElementsOffWithDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + .defaultAnimationDuration) {
            self.tempButtonDisable = false
            self.syncInteractionElements()
        }
    }
    
    @objc fileprivate func passButtonAction() {
        setInteractiveElementsOnOff()
        
        Analytics.trackMatchsticksSkip(matchstick: currentMatchstick, by: .tap)
        
        decidedToPass()
    }
    
    @objc fileprivate func addButtonAction() {
        setInteractiveElementsOnOff()
        Analytics.trackMatchsticksAdd(matchstick: currentMatchstick, by: .tap)
        
        decidedToAdd()
    }
    
    @objc fileprivate func retryButtonAction() {
        let dm = DiscoverManager.shared
        dm.failureStop = false
        dm.discoverViewDidAppear()
    }
    
    // MARK: Helper View
    
    fileprivate func showHelperView(inCell cell: DiscoverScreenshotCollectionViewCell) {
        let helper = DiscoverScreenshotHelperView()
        helper.translatesAutoresizingMaskIntoConstraints = false
        cell.mainView.addSubview(helper)
        helper.topAnchor.constraint(equalTo: cell.mainView.topAnchor).isActive = true
        helper.leadingAnchor.constraint(equalTo: cell.mainView.leadingAnchor).isActive = true
        helper.bottomAnchor.constraint(equalTo: cell.mainView.bottomAnchor).isActive = true
        helper.trailingAnchor.constraint(equalTo: cell.mainView.trailingAnchor).isActive = true
        helper.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissHelperView)))
        cardHelperView = helper
        
        passButton.isDisabled(true)
        addButton.isDisabled(true)
    }
    
    @objc fileprivate func dismissHelperView() {
        UserDefaults.standard.set(true, forKey: UserDefaultsKeys.discoverScreenshotPresentedHelper)
        
        UIView.animate(withDuration: .defaultAnimationDuration, animations: {
            self.cardHelperView?.alpha = 0
            self.passButton.isDisabled(false)
            self.addButton.isDisabled(false)
            
        }) { completion in
            self.cardHelperView?.removeFromSuperview()
            self.cardHelperView = nil
        }
    }
    
    // MARK: Empty View
    
    fileprivate func syncInteractionElements() {
        let isInteractionEnabled = !isListEmpty
        let isButtonEnabled = isInteractionEnabled && cardHelperView == nil
        
        passButton.isDisabled(!isButtonEnabled || tempButtonDisable)
        addButton.isDisabled(!isButtonEnabled || tempButtonDisable)
        collectionView.isUserInteractionEnabled = isInteractionEnabled
    }
    
    fileprivate func syncEmptyListViews() {
        emptyView.alpha = isListEmpty ? 1 : 0
        clearFilterView.alpha = isListEmpty ? 1 : 0
        clearFilterView.titleLabel.text = "No more \(self.discoverFilterControl.selectedCategory.displayName) outfits"
        syncInteractionElements()
    }
    
    fileprivate var isListEmpty:Bool {
        get {
            if self.matchsticks.count > 0 {
                return false
            }
            
            return true
        }
    }
    
    // MARK: Flag
    
    @objc fileprivate func presentReportAlertController() {
        let alertController = UIAlertController(title: "discover.screenshot.flag.title".localized, message: "discover.screenshot.flag.message".localized, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "discover.screenshot.flag.inappropriate".localized, style: .default, handler: { action in
            self.decidedToPass()
            self.presentInappropriateAlertController()
        }))
        alertController.addAction(UIAlertAction(title: "discover.screenshot.flag.copyright".localized, style: .default, handler: { action in
            self.presentCopyrightAlertController()
        }))
        alertController.addAction(UIAlertAction(title: "generic.cancel".localized, style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    fileprivate func presentInappropriateAlertController() {
        let alertController = UIAlertController(title: "discover.screenshot.flag.inappropriate.title".localized, message: "discover.screenshot.flag.inappropriate.message".localized, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "generic.ok".localized, style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
        
        if let id = currentMatchstick?.remoteId {
            DiscoverManager.shared.reportDiscoverPhoto(discoverPictureID: id)
        }
        
        Analytics.trackMatchsticksFlagged(matchstick: currentMatchstick, why: .inappropriate)
    }
    
    fileprivate func presentCopyrightAlertController() {
        let alertController = UIAlertController(title: "discover.screenshot.flag.copyright.title".localized, message: "discover.screenshot.flag.copyright.message".localized, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "legal.terms_of_service".localized, style: .default, handler: { action in
            self.presentTermsOfServiceViewController()
        }))
        alertController.addAction(UIAlertAction(title: "generic.done".localized, style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
        
        Analytics.trackMatchsticksFlagged(matchstick: currentMatchstick, why: .copyright)
    }
    
    fileprivate func presentTermsOfServiceViewController() {
        if let viewController = LegalViewControllerFactory.termsOfServiceViewController() {
            present(viewController, animated: true, completion: nil)
        }
    }
    
    @objc fileprivate func dismissViewController() {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: Screenshot Tab
    
    fileprivate func screenshotsTabPulseAnimation() {
        if let tabBarController = tabBarController as? MainTabBarController {
            tabBarController.screenshotsTabPulseAnimation()
        }
    }
}

extension DiscoverScreenshotViewController : UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.matchsticks.count
    }
    
    func matchstickAt(index:IndexPath) -> Matchstick? {
        if self.matchsticks.count > index.item {
            return self.matchsticks[index.item]
        }
        return nil
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        
        if let cell = cell as? DiscoverScreenshotCollectionViewCell {
            cell.flagButton.addTarget(self, action: #selector(presentReportAlertController), for: .touchUpInside)
            
            let matchstick = matchstickAt(index: indexPath)
            if let imageData = matchstick?.imageData as Data? {
                cell.image = UIImage(data: imageData)
            }else{
                cell.image = nil
            }
        }
        
        return cell
    }
}

extension DiscoverScreenshotViewController : UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? DiscoverScreenshotCollectionViewCell else {
            return
        }
        
        if self.cardHelperView == nil && !UserDefaults.standard.bool(forKey: UserDefaultsKeys.discoverScreenshotPresentedHelper) {
            showHelperView(inCell: cell)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        Analytics.trackMatchsticksAdd(matchstick: currentMatchstick, by: .open)
        delegate?.discoverScreenshotViewController(self, didSelectItemAtIndexPath: indexPath)
    }
}

extension DiscoverScreenshotViewController : FetchedResultsControllerManagerDelegate {
    func managerDidChangeContent(_ controller: NSObject, change: FetchedResultsControllerManagerChange) {
        if isViewLoaded {
            
            if change.insertedRows.count > 0 || self.matchstickFrc?.fetchedObjectsCount ?? 0 == 0 {
                let hadMatchsticks = self.matchsticks.count > 0
                self.matchsticks = self.matchstickFrc?.fetchedObjects ?? []
                let nowHasMatchsticks = (self.matchsticks.count > 0)
                self.collectionView.reloadData()
                if hadMatchsticks != nowHasMatchsticks {
                    updateViewsLoadingState()
                }
            }
            syncEmptyListViews()

        }
    }
}

extension DiscoverScreenshotViewController : DiscoverScreenshotCollectionViewLayoutDelegate {
    func discoverScreenshotCollectionViewLayoutIsAdding(_ layout: DiscoverScreenshotCollectionViewLayout) -> Bool {
        return isAdding
    }
}

fileprivate extension UIButton {
    func isDisabled(_ disabled: Bool) {
        isEnabled = !disabled
        alpha = disabled ? 0.5 : 1
    }
}


extension DiscoverScreenshotViewController :UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController){
        if let optionsVC = popoverPresentationController.presentedViewController as? DiscoverGenderOptionViewController {
            if let updatedGender = optionsVC.updatedGender {
                if optionsVC.gender != updatedGender {
                    DiscoverManager.shared.updateGender(gender: updatedGender)
                    self.updateViewsLoadingState()
                }
            }
        }
    }
}


extension DiscoverScreenshotViewController: CampaignPromotionViewControllerDelegate {
    func campaignPromotionViewControllerDidPressLearnMore(_ viewController: CampaignPromotionViewController) {
        dismiss(animated: false, completion: nil)
    }
    
    func campaignPromotionViewControllerDidPressSkip(_ viewController: CampaignPromotionViewController) {
        dismiss(animated: true, completion: nil)
    }
}
