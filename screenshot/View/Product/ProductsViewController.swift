//
//  ProductsViewController.swift
//  screenshot
//
//  Created by Jonathan Rose on 2/11/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation


enum ProductsSection : Int {
    case tooltip = 0
    case product = 1
    
    var section:Int {
        get{
            return self.rawValue
        }
    }
}
enum ProductsViewControllerState : Int {
    case loading
    case products
    case retry
    case empty
}



class ProductsViewController: BaseViewController, ProductsOptionsDelegate, ProductCollectionViewCellDelegate, UIToolbarDelegate, ShoppablesToolbarDelegate {
    var screenshot:Screenshot
    var shoppablesController: FetchedResultsControllerManager<Shoppable>
    var screenshotController: FetchedResultsControllerManager<Screenshot>
    
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
    
    
    init( screenshot  s:Screenshot) {
        screenshot = s
        shoppablesController = DataModel.sharedInstance.shoppableFrc(delegate: nil, screenshot: screenshot)
        screenshotController = DataModel.sharedInstance.singleScreenshotFrc(delegate: nil, screenshot: screenshot)

        super.init(nibName: nil, bundle: nil)
        shoppablesController.delegate = self
        screenshotController.delegate = self
        self.title = "Products"
        self.restorationIdentifier = "ProductsViewController"
        NotificationCenter.default.addObserver(self, selector: #selector(contentSizeCategoryDidChange(_:)), name: .UIContentSizeCategoryDidChange, object: nil)
        
        self.productsOptions.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad()
    {
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
            collectionView.register(ProductCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
            
            
            self.view.insertSubview(collectionView, at: 0)
            collectionView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
            collectionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
            collectionView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
            collectionView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
            return collectionView
            
        }()
        self.collectionView = collectionView
        
        let rateView:ProductsRateView = {
            let view = ProductsRateView()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.voteUpButton.addTarget(self, action: #selector(productsRateNegativeAction), for: .touchUpInside)
            view.voteDownButton.addTarget(self, action: #selector(productsRateNegativeAction), for: .touchUpInside)
            view.talkToYourStylistButton.addTarget(self, action: #selector(talkToYourStylistAction), for: .touchUpInside)
            return view
        }()
        self.rateView = rateView
        
        let scrollRevealController = ScrollRevealController(edge: .bottom)
        scrollRevealController.adjustedContentInset = UIEdgeInsets(top: self.navigationController?.navigationBar.frame.maxY ?? 0, left: 0, bottom: 0, right: 0)
        scrollRevealController.insertAbove(collectionView)

        scrollRevealController.view.addSubview(self.rateView)
        self.scrollRevealController = scrollRevealController
        
        self.rateView.topAnchor.constraint(equalTo:scrollRevealController.view.topAnchor).isActive = true
        self.rateView.leadingAnchor.constraint(equalTo:scrollRevealController.view.leadingAnchor).isActive = true
        self.rateView.bottomAnchor.constraint(equalTo:scrollRevealController.view.bottomAnchor).isActive = true
        self.rateView.trailingAnchor.constraint(equalTo:scrollRevealController.view.trailingAnchor).isActive = true
        
        
        var height = self.rateView.intrinsicContentSize.height
        
        if #available(iOS 11.0, *) {
            height += UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0
        }
        self.rateView.heightAnchor.constraint(equalToConstant: height).isActive = true
        
        self.syncScreenshotRelatedObjects()
        
        if self.screenshotController.fetchedResultsController.fetchedObjects?.first?.shoppablesCount == -1  {
            self.state = .retry
            AnalyticsTrackers.standard.track("Screenshot Opened Without Shoppables")
        }
        else {
            self.reloadProductsForShoppable(at: 0)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.shoppablesToolbar?.selectFirstShoppable()
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
        navigationController.screenshotDisplayViewController.shoppables = self.shoppablesController.fetchedResultsController.fetchedObjects
        self.present(navigationController, animated: true, completion: nil)
    }
    
    
    func productCollectionViewCellDidTapFavorite(cell: ProductCollectionViewCell) {
        
        guard let isFavorited = cell.favoriteButton?.isSelected else{
            return
        }
        guard let indexPath = self.collectionView?.indexPath(for: cell) else{
            return
        }
        let product = self.productAtIndex(indexPath.item)
        product.setFavorited(toFavorited: isFavorited)
        AnalyticsTrackers.standard.trackFavorited(isFavorited, product: product, onPage: "Products")
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
    
    func productsOptionsDidComplete(_ productsOptions: ProductsOptions, withChange changed: Bool) {
        
        if changed {
            if let index = self.shoppablesToolbar?.selectedShoppableIndex() {
                let shoppable = self.shoppablesController.fetchedResultsController.object(at: IndexPath.init(row: index, section: 0))
                shoppable.set(productsOptions: productsOptions, callback:  {
                    if let index = self.shoppablesToolbar?.selectedShoppableIndex(){
                        self.reloadProductsForShoppable(at:index)
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
        if self.products.count == 0 && self.isViewLoaded {
            self.reloadProductsForShoppable(at: 0)
        }
    }
    func shoppablesToolbarDidSelectShoppable(toolbar: ShoppablesToolbar, index: Int) {
        UserDefaults.standard.set(true, forKey: UserDefaultsKeys.productCompletedTooltip)
        self.reloadProductsForShoppable(at: index)
        AnalyticsTrackers.standard.track("Tapped on shoppable")
    }
    func shouldHideToolbar()->Bool{
        return !self.hasShoppables()
    }
    
}

private typealias ProductsViewControllerCollectionView = ProductsViewController
extension ProductsViewControllerCollectionView : UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func numberOfCollectionViewProductColumns() ->Int {
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
        let padding = Geometry.padding - shadowInsets.left - shadowInsets.right
        let sectionType = productSectionType(forSection: indexPath.section)

        if sectionType == .tooltip {
            size.width = collectionView.bounds.size.width
            size.height = ProductsTooltipCollectionViewCell.height(withCellWidth: size.width)
            
        } else if sectionType == .product {
            let columns = CGFloat(self.numberOfCollectionViewProductColumns())
            size.width = floor((collectionView.bounds.size.width - (padding * (columns + 1))) / columns)
            size.height = size.width + ProductCollectionViewCell.labelsHeight
        }
        
        return size
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let sectionType = productSectionType(forSection: indexPath.section)

        if sectionType == .tooltip {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "tooltip", for: indexPath)
            return cell
        } else if sectionType == .product {
            let product = self.productAtIndex(indexPath.item)
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? ProductCollectionViewCell {
                cell.delegate = self
                cell.contentView.backgroundColor = collectionView.backgroundColor
                cell.title = product.displayTitle
                cell.price = product.price
                cell.originalPrice = product.originalPrice
                cell.imageUrl = product.imageURL
                cell.isSale = product.isSale()
                cell.favoriteButton?.isSelected = product.isFavorite
                return cell
            }
            
        }
        return UICollectionViewCell()
    }
    
    
    public func collectionViewMinimumSpacing() -> CGPoint {
        let shadowInsets = ScreenshotCollectionViewCell.shadowInsets
        let p = Geometry.padding
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
            OpenProductPage.present(product: product, fromViewController: self, analyticsKey: "Products")
        }
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
        } else {
            self.navigationItem.titleView = nil
        }
    }
    
    func presentOptions(_ control:ProductsViewControllerControl) {
        
        if control.isFirstResponder {
            control.resignFirstResponder()
        } else {
            AnalyticsTrackers.standard.track("Opened Filters View", properties:nil)
            if let index = self.shoppablesToolbar?.selectedShoppableIndex() {
                let shoppable = self.shoppablesController.fetchedResultsController.object(at: IndexPath.init(row: index, section: 0))
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
        if controller == self.shoppablesController {
            if let _ = self.collectionView, let index = self.shoppablesToolbar?.selectedShoppableIndex() {
                self.reloadProductsForShoppable(at: index)
            }
        }else if controller == self.screenshotController {
            if let screenShot = self.screenshotController.fetchedResultsController.fetchedObjects?.first {
                if screenShot.shoppablesCount == 0 {
                    
                }else if screenShot.shoppablesCount == -1 {
                    if self.noItemsHelperView == nil {
                        self.state = .retry
                    }
                }
            }
        }
        
        
    }
    func hasShoppables() -> Bool {
        return self.shoppablesController.fetchedResultsController.fetchedObjectsCount > 0
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
    
    func reloadProductsForShoppable(at index: Int) {
        
        self.products = []
        self.productsUnfilteredCount = 0
        
        if self.hasShoppables() {
            self.scrollRevealController?.resetViewOffset()
            
            let shoppable = self.shoppablesController.fetchedResultsController.object(at: IndexPath.init(row: index, section: 0))
            
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
            
            if self.collectionView?.numberOfItems(inSection: ProductsSection.tooltip.section) ?? 0 > 0 {
                self.collectionView?.scrollToItem(at: IndexPath(item: 0, section: ProductsSection.tooltip.section), at: .top, animated: false)
                
            } else if self.collectionView?.numberOfItems(inSection: ProductsSection.product.section) ?? 0 > 0 {
                self.collectionView?.scrollToItem(at: IndexPath(item: 0, section: ProductsSection.product.section), at: .top, animated: false)
            }
            
        } else {
            self.state = .loading
            self.collectionView?.reloadData()
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
        let alertController = UIAlertController(title: "negativeFeedback.title".localized, message: "negativeFeedback.message".localized, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "negativeFeedback.options.sendFeedback".localized, style: .default, handler: { (a) in
            self.presentProductsRateNegativeFeedbackAlert()
        }))
        alertController.addAction(UIAlertAction(title: "negativeFeedback.options.fashionHelp".localized, style: .default, handler: { (a) in
            if InAppPurchaseManager.sharedInstance.didPurchase(_inAppPurchaseProduct: .personalStylist) {
                self.presentPersonalSylist()
            } else {
                if InAppPurchaseManager.sharedInstance.canPurchase() {
                    let alertController = UIAlertController(title: nil, message: "personalSytlistPopup.loading".localized, preferredStyle: .alert)
                    let action = UIAlertAction(title: "personalSytlistPopup.option.continue".localized, style: .default, handler: { (action) in
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
                        alertController.message = String(format: "personalSytlistPopup.canContinue".localized, product.localizedPriceString())
                    } else {
                        action.isEnabled = false
                        InAppPurchaseManager.sharedInstance.load(product: .personalStylist, success: { (product) in
                            action.isEnabled = true
                            alertController.message = String(format: "personalSytlistPopup.canContinue".localized, product.localizedPriceString())
                        }, failure: { (error) in
                            alertController.message = String(format: "personalSytlistPopup.error".localized, error.localizedDescription)
                        })
                        
                    }
                    alertController.addAction(action)
                    alertController.addAction(UIAlertAction(title: "generic.cancel".localized, style: .cancel, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                }else{
                    let errorMessage = "personalSytlistPopup.errorCannotPurchaseOnDevice".localized
                    let alertController = UIAlertController(title: nil, message: errorMessage, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "generic.ok".localized, style: .cancel, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                    
                }
            }
        }))
        alertController.addAction(UIAlertAction(title: "negativeFeedback.options.close".localized, style: .cancel, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    func productsRatePositiveAction() {
        if let index = self.shoppablesToolbar?.selectedShoppableIndex() {
            let shoppable = self.shoppablesController.fetchedResultsController.object(at: IndexPath.init(row: index, section: 0))
            shoppable.setRating(positive: true)
        }
    }
    
    func productsRateNegativeAction() {
        if let index = self.shoppablesToolbar?.selectedShoppableIndex() {
            let shoppable = self.shoppablesController.fetchedResultsController.object(at: IndexPath.init(row: index, section: 0))
            shoppable.setRating(positive: false)
            self.presentProductsRateNegativeAlert()
        }
    }
    
    func talkToYourStylistAction() {
        IntercomHelper.sharedInstance.presentMessagingUI()
    }
    
    func presentPersonalSylist() {
        let shortenedUploadedImageURL = self.screenshot.shortenedUploadedImageURL ?? ""
        AnalyticsTrackers.standard.track("Requested Custom Stylist", properties: ["screenshotImageURL" :  shortenedUploadedImageURL])
        let prefiledMessageTemplate = "products.rate.negative.prefiledMessageTemplate".localized
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
        
        let productsRateNegativeFeedbackSubmitAction = UIAlertAction(title: "Submit", style: .default, handler: { (action) in
            if let trimmedText = self.productsRateNegativeFeedbackTextField?.text?.trimmingCharacters(in: .whitespacesAndNewlines) {
                
                if trimmedText.lengthOfBytes(using: .utf8) > 0 {
                    AnalyticsTrackers.segment.track("Shoppable Feedback Negative", properties:["text": trimmedText])
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
            if #available(iOS 11.0, *) {
                //Do nothing
            } else {
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
            
            if #available(iOS 11.0, *) {
                //do nothing
            } else {
                self.automaticallyAdjustsScrollViewInsets = false
            }
            
            self.stopAndRemoveLoader()
            self.rateView.isHidden = true
            self.hideNoItemsHelperView()
            self.showNoItemsHelperView()
        }
    }
    
    func syncScreenshotRelatedObjects() {
        if let data = self.screenshot.imageData,
          let i = UIImage(data: data as Data) {
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
        
        let verPadding = Geometry.extendedPadding
        let horPadding = Geometry.padding
        var topOffset:CGFloat = 0
        if let shoppablesToolbar = self.shoppablesToolbar {
            if shoppablesToolbar.isHidden == false {
                topOffset = shoppablesToolbar.bounds.size.height
            }
        }
        
        let helperView = HelperView()
        helperView.translatesAutoresizingMaskIntoConstraints = false
        helperView.layoutMargins = UIEdgeInsets(top: verPadding, left: horPadding, bottom: verPadding, right: horPadding)
        helperView.titleLabel.text = "No Items Found"
        helperView.subtitleLabel.text = "No visually similar products were detected"
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
            retryButton.setTitle("Try Again", for: .normal)
            retryButton.addTarget(self, action: #selector(noItemsRetryAction), for: .touchUpInside)
            helperView.controlView.addSubview(retryButton)
            
            retryButton.topAnchor.constraint(equalTo: helperView.controlView.topAnchor).isActive = true
            retryButton.bottomAnchor.constraint(equalTo: helperView.controlView.bottomAnchor).isActive = true
            retryButton.centerXAnchor.constraint(equalTo: helperView.contentView.centerXAnchor).isActive = true
        }
    }
    
    func hideNoItemsHelperView() {
        self.noItemsHelperView?.removeFromSuperview()
        self.noItemsHelperView = nil
    }
    
    func noItemsRetryAction() {
        let alert = UIAlertController(title: "Try again as", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Fashion", style: .default, handler: { (a) in
            AssetSyncModel.sharedInstance.refetchShoppables(screenshot: self.screenshot, classificationString: "h")
            self.state = .loading
            
        }))
        alert.addAction(UIAlertAction(title: "Furniture", style: .default, handler: { (a) in
            AssetSyncModel.sharedInstance.refetchShoppables(screenshot: self.screenshot, classificationString: "f")
            self.state = .loading
            
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
