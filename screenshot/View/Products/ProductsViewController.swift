//
//  ProductsViewController.swift
//  screenshot
//
//  Created by Jonathan Rose on 2/11/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation
import UIKit
import CoreData

enum ProductsSection : Int {
    case tooltip = 0
    case product = 1
    
    var section: Int {
        return self.rawValue
    }
}

enum ProductsViewControllerState : Int {
    case loading
    case products
    case retry
    case empty
}

class ProductsViewController: BaseViewController, ProductsOptionsDelegate, UIToolbarDelegate, ShoppablesToolbarDelegate {
    var screenshot:Screenshot
    var screenshotController: FetchedResultsControllerManager<Screenshot>
    fileprivate var productsFRC: FetchedResultsControllerManager<Product>?
    
    var products:[Product] = []
    
    var loader:Loader?
    var noItemsHelperView:HelperView?
    var collectionView:UICollectionView?
    var shoppablesToolbar:ShoppablesToolbar?
    var productsOptions:ProductsOptions = ProductsOptions()
    var scrollRevealController:ScrollRevealController?
    var rateView:ProductsRateView!
    var productsRateNegativeFeedbackSubmitAction:UIAlertAction?
    var productsRateNegativeFeedbackTextField:UITextField?
    
    var productsUnfilteredCount:Int = 0
    var image:UIImage!
    var state:ProductsViewControllerState = .loading {
        didSet {
            self.syncViewsAfterStateChange()
        }
    }
    
    
    init( screenshot s:Screenshot) {
        screenshot = s
        screenshotController = DataModel.sharedInstance.singleScreenshotFrc(delegate: nil, screenshot: screenshot)

        super.init(nibName: nil, bundle: nil)
        screenshotController.delegate = self
        
        self.title = "products.title".localized
        self.restorationIdentifier = "ProductsViewController"
        
        NotificationCenter.default.addObserver(self, selector: #selector(contentSizeCategoryDidChange(_:)), name: .UIContentSizeCategoryDidChange, object: nil)
        
        self.productsOptions.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let toolbar:ShoppablesToolbar = {
            let margin:CGFloat = 8.5 // Anything other then 8 will display horizontal margin
            let shoppableHeight:CGFloat = 60
            
            let toolbar = ShoppablesToolbar.init(screenshot: self.screenshot)
            toolbar.frame = CGRect(x: 0, y: 0, width: 0, height: margin*2+shoppableHeight)
            toolbar.translatesAutoresizingMaskIntoConstraints = false
            toolbar.delegate = self
            toolbar.shoppableToolbarDelegate = self
            toolbar.barTintColor = .white
            toolbar.isHidden = self.shouldHideToolbar()
            self.view.addSubview(toolbar)
            
            toolbar.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor).isActive = true
            toolbar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
            toolbar.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
            toolbar.heightAnchor.constraint(equalToConstant: toolbar.bounds.size.height).isActive = true
            return toolbar
        }()
        
        self.shoppablesToolbar = toolbar
        
        let collectionView:UICollectionView = {
            let minimumSpacing = self.collectionViewMinimumSpacing()
            
            let layout = UICollectionViewFlowLayout()
            layout.minimumInteritemSpacing = minimumSpacing.x
            layout.minimumLineSpacing = minimumSpacing.y
            
            let collectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: layout)
            
            collectionView.translatesAutoresizingMaskIntoConstraints = false
            collectionView.delegate = self
            collectionView.dataSource = self
            collectionView.contentInset = UIEdgeInsets(top: self.shoppablesToolbar?.bounds.size.height ?? 0, left: 0.0, bottom: minimumSpacing.y, right: 0.0)
            collectionView.scrollIndicatorInsets = UIEdgeInsets(top: self.shoppablesToolbar?.bounds.size.height ?? 0, left: 0.0, bottom: 0.0, right: 0.0)
            
            collectionView.backgroundColor = self.view.backgroundColor
            // TODO: set the below to interactive and comment the dismissal in -scrollViewWillBeginDragging.
            // Then test why the control view (products options view) jumps before being dragged away.
            collectionView.keyboardDismissMode = .onDrag
            collectionView.register(ProductsTooltipCollectionViewCell.self, forCellWithReuseIdentifier: "tooltip")
            collectionView.register(ProductsCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
            
            
            self.view.insertSubview(collectionView, at: 0)
            collectionView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
            collectionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
            collectionView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
            collectionView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
            return collectionView
        }()
        self.collectionView = collectionView
        
        let rateView:ProductsRateView = {
            let view = ProductsRateView.init(frame: .zero)
            view.translatesAutoresizingMaskIntoConstraints = false
            view.voteUpButton.addTarget(self, action: #selector(productsRatePositiveAction), for: .touchUpInside)
            view.voteDownButton.addTarget(self, action: #selector(productsRateNegativeAction), for: .touchUpInside)
            view.talkToYourStylistButton.addTarget(self, action: #selector(talkToYourStylistAction), for: .touchUpInside)
            return view
        }()
        self.rateView = rateView
        
        let scrollRevealController = ScrollRevealController(edge: .bottom)
        scrollRevealController.adjustedContentInset = UIEdgeInsets(top: self.navigationController?.navigationBar.frame.maxY ?? 0, left: 0, bottom: 0, right: 0)
        scrollRevealController.insertAbove(collectionView)

        scrollRevealController.view.addSubview(rateView)
        self.scrollRevealController = scrollRevealController
        
        rateView.topAnchor.constraint(equalTo:scrollRevealController.view.topAnchor).isActive = true
        rateView.leadingAnchor.constraint(equalTo:scrollRevealController.view.leadingAnchor).isActive = true
        rateView.bottomAnchor.constraint(equalTo:scrollRevealController.view.bottomAnchor).isActive = true
        rateView.trailingAnchor.constraint(equalTo:scrollRevealController.view.trailingAnchor).isActive = true
        
        
        var height = self.rateView.intrinsicContentSize.height
        
        let isAlreadyShamrock = self.screenshot.isShamrockVersion
        if !isAlreadyShamrock {
            let p = CGFloat.padding
            
            let fab = FloatingActionButton()
            fab.translatesAutoresizingMaskIntoConstraints = false
            fab.setImage(UIImage(named:"Shamrock"), for: .normal)
            fab.backgroundColor = .shamrockGreen
            fab.contentEdgeInsets = UIEdgeInsetsMake(20, 20, 20, 20)
            fab.adjustsImageWhenHighlighted = false
            fab.addTarget(self, action: #selector(shamrockAction(_:)), for: .touchUpInside)
            view.addSubview(fab)
            fab.bottomAnchor.constraint(equalTo: rateView.topAnchor, constant: -p / 2).isActive = true
            fab.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -p / 2).isActive = true
        }
        
        if #available(iOS 11.0, *) {
            height += UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0
        }
        self.rateView.heightAnchor.constraint(equalToConstant: height).isActive = true
        
        self.syncScreenshotRelatedObjects()
        
        if self.screenshotController.first?.shoppablesCount == -1  {
            self.state = .retry
            AnalyticsTrackers.standard.track(.screenshotOpenedWithoutShoppables)
        }
        else {
            self.shoppablesToolbar?.selectFirstShoppable()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !self.hasShoppables() && self.noItemsHelperView == nil {
            self.state = .loading
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.shoppablesToolbar?.didViewControllerAppear = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.dismissOptions()
    }
    
    func contentSizeCategoryDidChange(_ notification: Notification) {
        if self.view.window != nil && self.collectionView?.numberOfItems(inSection: ProductsSection.tooltip.section) ?? 0 > 0 {
            self.collectionView?.reloadItems(at: [IndexPath(item: 0, section: ProductsSection.tooltip.section)])
        }
    }
    
    deinit {
        self.shoppablesToolbar?.delegate = nil
        self.shoppablesToolbar?.shoppableToolbarDelegate = nil
        NotificationCenter.default.removeObserver(self)
    }
    
    func displayScreenshotAction() {
        let navigationController = ScreenshotDisplayNavigationController(nibName: nil, bundle: nil)
        navigationController.screenshotDisplayViewController.image = self.image
        navigationController.screenshotDisplayViewController.shoppables = self.shoppablesToolbar?.shoppablesController.fetchedObjects
        self.present(navigationController, animated: true, completion: nil)
    }
}

private typealias ProductsViewControllerScrollViewDelegate = ProductsViewController
extension ProductsViewControllerScrollViewDelegate: UIScrollViewDelegate {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.dismissOptions()
        self.scrollRevealController?.scrollViewWillBeginDragging(scrollView)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.scrollRevealController?.scrollViewDidScroll(scrollView)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        self.scrollRevealController?.scrollViewDidEndDragging(scrollView, will: decelerate)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.scrollRevealController?.scrollViewDidEndDecelerating(scrollView)
    }
}

extension ProductsViewController {
    func shamrockAction(_ sender:Any) {
        AssetSyncModel.sharedInstance.findOrCreateShamrockVersion(screenshot: self.screenshot) { (objectId) in
            if let objectId = objectId, let screenshot = Screenshot.findWith(objectId: objectId), let navVC = self.navigationController as? ScreenshotsNavigationController{
                navVC.popViewController(animated: false)
                let productsViewController = ProductsViewController.init(screenshot: screenshot)
                
                productsViewController.lifeCycleDelegate = navVC
                productsViewController.hidesBottomBarWhenPushed = true
                navVC.pushViewController(productsViewController, animated: false)
                
                if (screenshot.isNew) {
                    screenshot.setViewed()
                }
            }
        }
    }

    func clearProductListAndStateLoading(){
        self.products = []
        self.productsUnfilteredCount = 0
        self.state = .loading
        self.collectionView?.reloadData()
    }
    func productsOptionsDidComplete(_ productsOptions: ProductsOptions, withChange changed: Bool) {
        
        if changed {
            if  let shoppable = self.shoppablesToolbar?.selectedShoppable(){
                shoppable.set(productsOptions: productsOptions, callback:  {
                    if  let shoppable = self.shoppablesToolbar?.selectedShoppable(){
                        self.reloadProductsFor(shoppable: shoppable)
                    }else{
                        self.clearProductListAndStateLoading()
                    }
                })
            }
        }
        self.dismissOptions()
    }
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
    
    func shoppablesToolbarDidChange(toolbar: ShoppablesToolbar) {
        if self.isViewLoaded  {
            if  let selectedShoppable = self.shoppablesToolbar?.selectedShoppable(){
                if let currentShoppable = self.products.first?.shoppable, currentShoppable == selectedShoppable {
                    //already synced
                }else{
                    self.reloadProductsFor(shoppable: selectedShoppable)
                }
            }else{
                clearProductListAndStateLoading()
            }
        }
    }
    
    func shoppablesToolbarDidChangeSelectedShoppable(toolbar:ShoppablesToolbar, shoppable:Shoppable){
        self.reloadProductsFor(shoppable: shoppable)
    }
    
    func shouldHideToolbar()->Bool{
        return !self.hasShoppables()
    }
    
}

private typealias ProductsViewControllerCollectionView = ProductsViewController
extension ProductsViewControllerCollectionView : UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    var numberOfCollectionViewProductColumns: Int {
        return 2
    }
    
    func productSectionType(forSection:Int) -> ProductsSection {
        return ProductsSection(rawValue: forSection) ?? .tooltip
    }
    
    func collectionViewToShoppablesFrcIndexPath(_ index:Int) ->IndexPath {
        return IndexPath(item: index, section: 0)
    }
    
    func shoppablesFrcToCollectionViewIndexPath(_ index:Int) -> IndexPath {
        return IndexPath(item: index, section: ProductsSection.product.section)
    }
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionType = productSectionType(forSection: section)
        if sectionType == .tooltip {
            let shouldPresentTooldtip = !UserDefaults.standard.bool(forKey: UserDefaultsKeys.productCompletedTooltip)
            let hasProducts = (self.products.count > 0)
            return (shouldPresentTooldtip && hasProducts) ? 1 : 0
            
        } else if sectionType == .product {
            return self.products.count
            
        } else {
            return 0
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        var size:CGSize = .zero
        let shadowInsets = ScreenshotCollectionViewCell.shadowInsets
        let padding: CGFloat = .padding - shadowInsets.left - shadowInsets.right
        let sectionType = productSectionType(forSection: indexPath.section)

        if sectionType == .tooltip {
            size.width = collectionView.bounds.size.width
            size.height = ProductsTooltipCollectionViewCell.height(withCellWidth: size.width)
            
        } else if sectionType == .product {
            let columns = CGFloat(numberOfCollectionViewProductColumns)
            size.width = floor((collectionView.bounds.size.width - (padding * (columns + 1))) / columns)
            size.height = ProductsCollectionViewCell.cellHeight(for: size.width)
        }
        
        return size
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let sectionType = productSectionType(forSection: indexPath.section)

        if sectionType == .tooltip {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "tooltip", for: indexPath)
            return cell
        }
        else if sectionType == .product {
            let product = self.productAtIndex(indexPath.item)
            
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? ProductsCollectionViewCell {
                cell.contentView.backgroundColor = collectionView.backgroundColor
                cell.title = product.displayTitle
                cell.price = product.price
                cell.originalPrice = product.originalPrice
                cell.imageUrl = product.imageURL
                cell.isSale = product.isSale()
                cell.favoriteControl.isSelected = product.isFavorite
                cell.favoriteControl.addTarget(self, action: #selector(productCollectionViewCellFavoriteAction(_:event:)), for: .touchUpInside)
                return cell
            }
        }
        
        return UICollectionViewCell()
    }
    
    public func collectionViewMinimumSpacing() -> CGPoint {
        let shadowInsets = ScreenshotCollectionViewCell.shadowInsets
        let p: CGFloat = .padding
        return CGPoint(x: p - shadowInsets.left - shadowInsets.right, y: p - shadowInsets.top - shadowInsets.bottom)
    }
    
    public func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        let sectionType = productSectionType(forSection: indexPath.section)
        return sectionType != .tooltip
    }
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let sectionType = productSectionType(forSection: section)

        if sectionType == .product {
            let minimumSpacing:CGPoint = self.collectionViewMinimumSpacing()
            return UIEdgeInsets(top: minimumSpacing.y, left: minimumSpacing.x, bottom: 0.0, right: minimumSpacing.x)
        } else {
            return .zero
        }
    }
   
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let sectionType = productSectionType(forSection: indexPath.section)

        if sectionType == .product {
            let product = self.productAtIndex(indexPath.item)
            product.recordViewedProduct()
            
            if let productViewController = presentProduct(product, from:"Products") {
                productViewController.similarProducts = products
            }
        }
    }
    
    func productCollectionViewCellFavoriteAction(_ favoriteControl: FavoriteControl, event: UIEvent) {
        guard let indexPath = collectionView?.indexPath(for: event) else {
            return
        }
        
        let isFavorited = favoriteControl.isSelected
        let product = self.productAtIndex(indexPath.item)
        
        product.setFavorited(toFavorited: isFavorited)
        AnalyticsTrackers.standard.trackFavorited(isFavorited, product: product, onPage: "Products")
    }
}

private typealias ProductsViewControllerOptionsView = ProductsViewController
extension ProductsViewControllerOptionsView {
    
    func updateOptionsView() {
        if self.hasShoppables() {
            if self.navigationItem.titleView == nil {
                let label = UILabel()
                label.adjustsFontSizeToFitWidth = true
                label.minimumScaleFactor = 0.7
                
                var attributes = UINavigationBar.appearance().titleTextAttributes
                attributes?[NSForegroundColorAttributeName] = UIColor.crazeGreen
                
                let attributedString = NSMutableAttributedString(string: "products.options.title".localized, attributes: attributes)
                
                let offset:CGFloat = 3
                attributes?[NSBaselineOffsetAttributeName] = offset
                
                let arrowString = NSAttributedString(string: "⌄", attributes: attributes)
                attributedString.append(arrowString)
                
                label.attributedText = attributedString
                label.sizeToFit()
                
                var rect = label.frame
                rect.origin.y -= offset
                label.frame = rect
                
                let container = ProductsViewControllerControl(frame:label.bounds)
                container.addTarget(self, action: #selector(presentOptions(_:)), for: .touchUpInside)
                container.addSubview(label)
                self.navigationItem.titleView = container
            }
        }
        else {
            self.navigationItem.titleView = nil
        }
    }
    
    func presentOptions(_ control:ProductsViewControllerControl) {
        
        if control.isFirstResponder {
            control.resignFirstResponder()
        }
        else {
            AnalyticsTrackers.standard.track(.openedFiltersView, properties:nil)
            
            if  let shoppable = self.shoppablesToolbar?.selectedShoppable(){
                self.productsOptions.syncOptions(withMask: shoppable.getLast())
            }
            control.customInputView = self.productsOptions.view
            control.becomeFirstResponder()
        }
    }
    
    func dismissOptions() {
        self.navigationItem.titleView?.endEditing(true)
    }
}

private typealias ProductsViewControllerShoppables = ProductsViewController
extension ProductsViewControllerShoppables: FetchedResultsControllerManagerDelegate {
    func managerDidChangeContent(_ controller: NSObject, change: FetchedResultsControllerManagerChange) {
        if controller == self.screenshotController {
            if let screenShot = self.screenshotController.first {
                if screenShot.shoppablesCount == 0 {
                    
                }else if screenShot.shoppablesCount == -1 {
                    if self.noItemsHelperView == nil {
                        self.state = .retry
                    }
                }
            }
        }
        else if controller == productsFRC {
            if view.window == nil, let collectionView = collectionView {
                collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
            }
        }
    }
    
    func hasShoppables() -> Bool {
        return (self.shoppablesToolbar?.shoppablesController.fetchedObjectsCount ?? 0 ) > 0
    }
}

private typealias ProductsViewControllerProducts = ProductsViewController
extension ProductsViewControllerProducts{
    func productAtIndex(_ index: Int) -> Product {
        return self.products[index]
    }
    
    func indexForProduct(_ product: Product) -> Int? {
        return self.products.index(of: product)
    }
    
    func reloadProductsFor(shoppable:Shoppable) {
        self.products = []
        self.productsUnfilteredCount = 0
        self.scrollRevealController?.resetViewOffset()
        
        if shoppable.productFilterCount == -1 {
            self.state = .retry
        } else {
            self.products = self.productsForShoppable(shoppable)
            
            if shoppable.productFilterCount == 0 && self.productsUnfilteredCount == 0 {
                self.state = .loading
            } else {
                self.state = (self.products.count == 0) ? .empty : .products
            }
        }
        
        self.collectionView?.reloadData()
        self.rateView.setRating(UInt(shoppable.getRating()), animated: false)
        
        productsFRC = DataModel.sharedInstance.productFrc(delegate: self, shoppableOID: shoppable.objectID)
        
        if self.collectionView?.numberOfItems(inSection: ProductsSection.tooltip.section) ?? 0 > 0 {
            self.collectionView?.scrollToItem(at: IndexPath(item: 0, section: ProductsSection.tooltip.section), at: .top, animated: false)
            
        } else if self.collectionView?.numberOfItems(inSection: ProductsSection.product.section) ?? 0 > 0 {
            self.collectionView?.scrollToItem(at: IndexPath(item: 0, section: ProductsSection.product.section), at: .top, animated: false)
        }
    }
    
    func productsForShoppable(_ shoppable:Shoppable) -> [Product] {
        let descriptors: [NSSortDescriptor]
        switch self.productsOptions.sort {
        case .similar :
            descriptors = [NSSortDescriptor(key: "order", ascending: true)]
        case .priceAsc :
            descriptors = [NSSortDescriptor(key: "floatPrice", ascending: true)]
        case .priceDes :
            descriptors = [NSSortDescriptor(key: "floatPrice", ascending: false)]
        case .brands :
            descriptors = [NSSortDescriptor(key: "displayTitle", ascending: true, selector:#selector(NSString.localizedCaseInsensitiveCompare(_:) ) ), NSSortDescriptor(key: "order", ascending: true)]
        }
        
        if let mask = shoppable.getLast()?.rawValue,
          var products:Set = shoppable.products?.filtered(using: NSPredicate(format: "(optionsMask & %d) == %d", mask, mask)) as? Set<Product> {
            self.productsUnfilteredCount = products.count
            if self.productsOptions.sale == .sale {
                let filtered = (products as NSSet).filtered(using: NSPredicate(format: "floatPrice < floatOriginalPrice"))
                products = filtered as! Set<Product>
            }
            return  (((products as NSSet).allObjects as NSArray).sortedArray(using: descriptors) as? [Product]) ?? []
        }
        
        return []
    }
}

private typealias ProductsViewControllerLoader = ProductsViewController
extension ProductsViewControllerLoader {
    
    func startAndAddLoader() {
        let loader = self.loader ?? ( {
            let loader = Loader()
            loader.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(loader)
            loader.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
            loader.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
            
            if self.screenshot.isShamrockVersion {
                loader.color = .shamrockGreen
                let text = UILabel.init()
                text.text = "shamrock.loading".localized
                text.textColor = .shamrockGreen
                text.font =  UIFont(name: "Futura-Medium", size: 14) ?? UIFont.systemFont(ofSize: 14)
                text.translatesAutoresizingMaskIntoConstraints = false
                loader.addSubview(text)
                text.centerXAnchor.constraint(equalTo: loader.centerXAnchor).isActive = true
                text.topAnchor.constraint(equalTo: loader.bottomAnchor).isActive = true
            }
            
            
            return loader
        }())
        self.loader = loader
        loader.startAnimation()
    }
    
    func stopAndRemoveLoader() {
        if let loader = self.loader {
            loader.stopAnimation()
            loader.removeFromSuperview()
            self.loader = nil
        }
    }
    
}

private typealias ProductsViewControllerRatings = ProductsViewController
extension ProductsViewControllerRatings: UITextFieldDelegate {
    
    func presentProductsRateNegativeAlert() {
        if !InAppPurchaseManager.sharedInstance.didPurchase(_inAppPurchaseProduct: .personalStylist) {
            InAppPurchaseManager.sharedInstance .loadProductInfoIfNeeded()
        }
        let alertController = UIAlertController(title: "negative_feedback.title".localized, message: "negative_feedback.message".localized, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "negative_feedback.options.send".localized, style: .default, handler: { (a) in
            self.presentProductsRateNegativeFeedbackAlert()
        }))
        alertController.addAction(UIAlertAction(title: "negative_feedback.options.help".localized, style: .default, handler: { (a) in
            if InAppPurchaseManager.sharedInstance.didPurchase(_inAppPurchaseProduct: .personalStylist) {
                self.presentPersonalStylist()
            } else {
                if InAppPurchaseManager.sharedInstance.canPurchase() {
                    let alertController = UIAlertController(title: nil, message: "personal_stylist.loading".localized, preferredStyle: .alert)
                    let action = UIAlertAction(title: "generic.continue".localized, style: .default, handler: { (action) in
                        if let product = InAppPurchaseManager.sharedInstance.productIfAvailable(product: .personalStylist) {
                            InAppPurchaseManager.sharedInstance.buy(product: product, success: {
                                //don't present anything -  if the user stayed on the same page the bottom bar changed to 'talk to your stylist' otherwise don't do anything
                            }, failure: { (error) in
                                //no reason to present alert - Apple does it for us
                            })
                        }
                    })
                    
                    if let product = InAppPurchaseManager.sharedInstance.productIfAvailable(product: .personalStylist) {
                        action.isEnabled = true
                        alertController.message = String(format: "personal_stylist.unlock".localized, product.localizedPriceString())
                    } else {
                        action.isEnabled = false
                        InAppPurchaseManager.sharedInstance.load(product: .personalStylist, success: { (product) in
                            action.isEnabled = true
                            alertController.message = String(format: "personal_stylist.unlock".localized, product.localizedPriceString())
                        }, failure: { (error) in
                            alertController.message = String(format: "personal_stylist.error".localized, error.localizedDescription)
                        })
                        
                    }
                    alertController.addAction(action)
                    alertController.addAction(UIAlertAction(title: "generic.cancel".localized, style: .cancel, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                }else{
                    let errorMessage = "personal_stylist.error.invalid_device".localized
                    let alertController = UIAlertController(title: nil, message: errorMessage, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "generic.ok".localized, style: .cancel, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                    
                }
            }
        }))
        alertController.addAction(UIAlertAction(title: "generic.cancel".localized, style: .cancel, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    func productsRatePositiveAction() {
        if  let shoppable = self.shoppablesToolbar?.selectedShoppable(){
            shoppable.setRating(positive: true)
        }
    }
    
    func productsRateNegativeAction() {
        if  let shoppable = self.shoppablesToolbar?.selectedShoppable(){
            shoppable.setRating(positive: false)
            self.presentProductsRateNegativeAlert()
        }
    }
    
    func talkToYourStylistAction() {
        IntercomHelper.sharedInstance.presentMessagingUI()
    }
    
    func presentPersonalStylist() {
        let shortenedUploadedImageURL = self.screenshot.shortenedUploadedImageURL ?? ""
        AnalyticsTrackers.standard.track(.requestedCustomStylist, properties: ["screenshotImageURL" :  shortenedUploadedImageURL])
        let prefiledMessageTemplate = "products.rate.negative.help_finding_outfit".localized
        let prefilledMessage = String(format: prefiledMessageTemplate, (self.screenshot.shortenedUploadedImageURL ?? "null"))
        IntercomHelper.sharedInstance.presentMessageComposer(withInitialMessage: prefilledMessage)
    }
    
    func presentProductsRateNegativeFeedbackAlert() {
        let alertController = UIAlertController(title: "products.rate.negative.popup.title".localized, message: "products.rate.negative.popup.message".localized, preferredStyle: .alert)
        alertController.addTextField { (textField) in
            textField.delegate = self
            textField.autocapitalizationType = .sentences
            textField.enablesReturnKeyAutomatically = true
            textField.tintColor = .crazeGreen
            self.productsRateNegativeFeedbackTextField = textField
        }
        
        let productsRateNegativeFeedbackSubmitAction = UIAlertAction(title: "generic.submit".localized, style: .default, handler: { (action) in
            if let trimmedText = self.productsRateNegativeFeedbackTextField?.text?.trimmingCharacters(in: .whitespacesAndNewlines) {
                
                if trimmedText.lengthOfBytes(using: .utf8) > 0 {
                    //TODO: why is this only segment?!?!
                    AnalyticsTrackers.segment.track(.shoppableFeedbackNegative, properties:["text": trimmedText])
                }
            }
        })
        
        productsRateNegativeFeedbackSubmitAction.isEnabled = false
        alertController.addAction(productsRateNegativeFeedbackSubmitAction)
        self.productsRateNegativeFeedbackSubmitAction = productsRateNegativeFeedbackSubmitAction
        alertController.preferredAction = self.productsRateNegativeFeedbackSubmitAction
        alertController.addAction(UIAlertAction(title: "generic.cancel".localized, style: .cancel, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        var isEnabled = false
        if let text = textField.text,
            let textRange = Range(range, in: text) {
            let updatedText = text.replacingCharacters(in: textRange, with: string)
            let trimmedText = updatedText.trimmingCharacters(in: .whitespaces)
            
            if trimmedText.lengthOfBytes(using:.utf8) > 0 {
                isEnabled = true
            }
        }
        
        self.productsRateNegativeFeedbackSubmitAction?.isEnabled = isEnabled
        
        return true
    }
}

extension ProductsViewController {
    
    func syncViewsAfterStateChange() {
        self.updateOptionsView()
        self.shoppablesToolbar?.isHidden = self.shouldHideToolbar()
        
        switch (state) {
        case .loading:
            self.hideNoItemsHelperView()
            self.rateView.isHidden = true
            self.startAndAddLoader()
            
        case .products:
            if #available(iOS 11.0, *) {} else {
                if !self.automaticallyAdjustsScrollViewInsets {
                    // Setting back to YES doesn't update. Need to manually adjust.
                    if let collectionView = collectionView, let shoppablesToolbar = self.shoppablesToolbar {
                        var scrollInsets = collectionView.scrollIndicatorInsets
                        scrollInsets.top = shoppablesToolbar.bounds.size.height + (self.navigationController?.navigationBar.frame.maxY ?? 0)
                        collectionView.scrollIndicatorInsets = scrollInsets
                        
                        var insets = collectionView.contentInset
                        insets.top = scrollInsets.top
                        collectionView.contentInset = insets
                    }
                }
            }
            
            self.stopAndRemoveLoader()
            self.hideNoItemsHelperView()
            self.rateView.isHidden = false
            
        case .retry, .empty:
            if #available(iOS 11.0, *) {} else {
                self.automaticallyAdjustsScrollViewInsets = false
            }
            
            self.stopAndRemoveLoader()
            self.rateView.isHidden = true
            self.hideNoItemsHelperView()
            self.showNoItemsHelperView()
        }
    }
    
    func syncScreenshotRelatedObjects() {
        if let data = self.screenshot.imageData, let i = UIImage(data: data as Data) {
            self.image = i
        } else {
            self.image = UIImage()
        }
        
        self.navigationItem.rightBarButtonItem = {
            let buttonSize:CGFloat = 32
            
            let button = UIButton(type: UIButtonType.custom)
            button.frame = CGRect(x: 0, y: 0, width: buttonSize, height: buttonSize)
            button.imageView?.contentMode = .scaleAspectFill
            button.setImage(self.image, for: .normal)
            
            button.addTarget(self, action: #selector(displayScreenshotAction), for: .touchUpInside)
            
            button.layer.borderColor = UIColor.crazeGreen.cgColor
            button.layer.borderWidth = 1
            
            let barButtonItem = UIBarButtonItem(customView: button)
            button.widthAnchor.constraint(equalToConstant: button.bounds.size.width).isActive = true
            button.heightAnchor.constraint(equalToConstant: button.bounds.size.height).isActive = true
            
            
            return barButtonItem
        }()
    }
    
}

private typealias ProductsViewControllerNoItemsHelperView = ProductsViewController
extension ProductsViewControllerNoItemsHelperView{
    
    func showNoItemsHelperView() {
        let verPadding: CGFloat = .extendedPadding
        let horPadding: CGFloat = .padding
        var topOffset: CGFloat = 0
        
        if let shoppablesToolbar = self.shoppablesToolbar, !shoppablesToolbar.isHidden {
            topOffset = shoppablesToolbar.bounds.size.height
        }
        
        let helperView = HelperView()
        helperView.translatesAutoresizingMaskIntoConstraints = false
        helperView.layoutMargins = UIEdgeInsets(top: verPadding, left: horPadding, bottom: verPadding, right: horPadding)
        helperView.titleLabel.text = "products.helper.title".localized
        helperView.subtitleLabel.text = "products.helper.message".localized
        helperView.contentImage = UIImage(named: "ProductsEmptyListGraphic")
        self.view.addSubview(helperView)
        
        helperView.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor, constant:topOffset).isActive = true
        helperView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        helperView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        helperView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        self.noItemsHelperView = helperView
        
        if self.state == .retry {
            let retryButton = MainButton()
            retryButton.translatesAutoresizingMaskIntoConstraints = false
            retryButton.backgroundColor = .crazeGreen
            retryButton.setTitle("products.helper.retry".localized, for: .normal)
            retryButton.addTarget(self, action: #selector(noItemsRetryAction), for: .touchUpInside)
            helperView.controlView.addSubview(retryButton)
            retryButton.topAnchor.constraint(equalTo: helperView.controlView.topAnchor).isActive = true
            retryButton.leadingAnchor.constraint(greaterThanOrEqualTo: helperView.controlView.layoutMarginsGuide.leadingAnchor).isActive = true
            retryButton.bottomAnchor.constraint(equalTo: helperView.controlView.bottomAnchor).isActive = true
            retryButton.trailingAnchor.constraint(greaterThanOrEqualTo: helperView.controlView.layoutMarginsGuide.trailingAnchor).isActive = true
            retryButton.centerXAnchor.constraint(equalTo: helperView.contentView.centerXAnchor).isActive = true
        }
    }
    
    func hideNoItemsHelperView() {
        self.noItemsHelperView?.removeFromSuperview()
        self.noItemsHelperView = nil
    }
    
    func noItemsRetryAction() {
        let alert = UIAlertController(title: "products.helper.retry.title".localized, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "products.helper.retry.fashion".localized, style: .default, handler: { (a) in
            AssetSyncModel.sharedInstance.refetchShoppables(screenshot: self.screenshot, classificationString: "h")
            self.state = .loading
        }))
        alert.addAction(UIAlertAction(title: "products.helper.retry.furniture".localized, style: .default, handler: { (a) in
            AssetSyncModel.sharedInstance.refetchShoppables(screenshot: self.screenshot, classificationString: "f")
            self.state = .loading
        }))
        alert.addAction(UIAlertAction(title: "generic.cancel".localized, style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
