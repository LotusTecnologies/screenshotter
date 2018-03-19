//
//  DiscoverScreenshotViewController.swift
//  screenshot
//
//  Created by Corey Werner on 1/7/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation
import CoreData
import UIKit

protocol DiscoverScreenshotViewControllerDelegate : NSObjectProtocol {
    func discoverScreenshotViewController(_ viewController: DiscoverScreenshotViewController, didSelectItemAtIndexPath indexPath: IndexPath)
}

class DiscoverScreenshotViewController : BaseViewController {
    fileprivate let coreDataPreparationController = CoreDataPreparationController()
    fileprivate let collectionView = UICollectionView(frame: .zero, collectionViewLayout: DiscoverScreenshotCollectionViewLayout())
    fileprivate var matchstickFrc: FetchedResultsControllerManager<Matchstick>?
    fileprivate var matchsticks:[Matchstick] = []
    fileprivate let passButton = UIButton()
    fileprivate let addButton = UIButton()
    fileprivate var cardHelperView: DiscoverScreenshotHelperView?
    fileprivate let emptyView = HelperView()
    
    weak var delegate: DiscoverScreenshotViewControllerDelegate?
    
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
        
        restorationIdentifier = String(describing: type(of: self))
        
        coreDataPreparationController.delegate = self
        
        addNavigationItemLogo()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        automaticallyAdjustsScrollViewInsets = false
        
        if let layout = collectionView.collectionViewLayout as? DiscoverScreenshotCollectionViewLayout {
            layout.delegate = self
        }
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .clear
        collectionView.contentInset = UIEdgeInsets(top: .padding, left: .padding, bottom: .padding, right: .padding)
        collectionView.scrollsToTop = false
        collectionView.register(DiscoverScreenshotCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        view.addSubview(collectionView)
        collectionView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
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
        emptyView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        emptyView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        emptyView.bottomAnchor.constraint(equalTo: passButton.topAnchor).isActive = true
        emptyView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        coreDataPreparationController.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        syncEmptyListViews()
    }
    
    deinit {
        coreDataPreparationController.delegate = nil
        
        if let layout = collectionView.collectionViewLayout as? DiscoverScreenshotCollectionViewLayout {
            layout.delegate = nil
        }
        
        collectionView.dataSource = nil
        collectionView.delegate = nil
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
                matchStick.pass()
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
                    emptyView.alpha = abs(percent)
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
                    AnalyticsTrackers.standard.track(.matchsticksAdd, properties: [
                        "by": "swipe",
                        "url": currentMatchstick?.imageUrl ?? ""
                        ])
                    
                    decidedToAdd()
                }
                else {
                    AnalyticsTrackers.standard.track(.matchsticksSkip, properties: [
                        "by": "swipe",
                        "url": currentMatchstick?.imageUrl ?? ""
                        ])
                    
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
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.defaultAnimationDuration) {
            self.tempButtonDisable = false
            self.syncInteractionElements()
        }
    }
    
    @objc fileprivate func passButtonAction() {
        setInteractiveElementsOnOff()
        
        AnalyticsTrackers.standard.track(.matchsticksSkip, properties: [
            "by": "tap",
            "url": currentMatchstick?.imageUrl ?? ""
            ])
        
        decidedToPass()
    }
    
    @objc fileprivate func addButtonAction() {
        setInteractiveElementsOnOff()
        
        AnalyticsTrackers.standard.track(.matchsticksAdd, properties: [
            "by": "tap",
            "url": currentMatchstick?.imageUrl ?? ""
            ])
        
        decidedToAdd()
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
        
        UIView.animate(withDuration: Constants.defaultAnimationDuration, animations: {
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
        
        AnalyticsTrackers.standard.track(.matchsticksFlagged, properties: [
            "url": currentMatchstick?.imageUrl ?? "",
            "why": "Inappropriate"
            ])
    }
    
    fileprivate func presentCopyrightAlertController() {
        let alertController = UIAlertController(title: "discover.screenshot.flag.copyright.title".localized, message: "discover.screenshot.flag.copyright.message".localized, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "legal.terms_of_service".localized, style: .default, handler: { action in
            self.presentTermsOfServiceViewController()
        }))
        alertController.addAction(UIAlertAction(title: "generic.done".localized, style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
        
        AnalyticsTrackers.standard.track(.matchsticksFlagged, properties: [
            "url": currentMatchstick?.imageUrl ?? "",
            "why": "Copyright"
            ])
    }
    
    fileprivate func presentTermsOfServiceViewController() {
        if let viewController = LegalViewControllerFactory.termsOfServiceViewController(withDoneTarget: self, action: #selector(dismissViewController)) {
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
        return self.matchsticks[index.item]
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        
        if let cell = cell as? DiscoverScreenshotCollectionViewCell {
            cell.flagButton.addTarget(self, action: #selector(presentReportAlertController), for: .touchUpInside)
            
            let matchstick = matchstickAt(index: indexPath)
            
            if let imageData = matchstick?.imageData as Data? {
                cell.image = UIImage(data: imageData)
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
        AnalyticsTrackers.standard.track(.matchsticksAdd, properties: [
            "by": "open",
            "url": currentMatchstick?.imageUrl ?? ""
            ])
        AnalyticsTrackers.standard.track(.matchsticksOpenedScreenshot)
        
        delegate?.discoverScreenshotViewController(self, didSelectItemAtIndexPath: indexPath)
    }
}

extension DiscoverScreenshotViewController : CoreDataPreparationControllerDelegate {
    func coreDataPreparationControllerSetup(_ controller: CoreDataPreparationController) {
        matchstickFrc = DataModel.sharedInstance.matchstickFrc(delegate:self)
        self.matchsticks = matchstickFrc?.fetchedObjects ?? []
        
        self.collectionView.reloadData()
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

extension DiscoverScreenshotViewController : FetchedResultsControllerManagerDelegate {
    func managerDidChangeContent(_ controller: NSObject, change: FetchedResultsControllerManagerChange) {
        if isViewLoaded {
            if change.insertedRows.count > 0 {
                self.matchsticks = self.matchstickFrc?.fetchedObjects ?? []
                self.collectionView.reloadData()
                syncEmptyListViews()
            }
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
