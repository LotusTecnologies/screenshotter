//
//  ProductsViewController.swift
//  screenshot
//
//  Created by Jonathan Rose on 2/11/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation
import FBSDKCoreKit

@objc enum ProductsSection : Int {
    case tooltip = 0
    case product = 1
}
enum ProductsViewControllerState : Int {
    case loading
    case products
    case retry
    case empty
}


class ProductsViewController: BaseViewController, ProductsOptionsDelegate, ViewControllerLifeCycle, ShoppablesControllerDelegate, ProductCollectionViewCellDelegate, UITextFieldDelegate , UIToolbarDelegate, ShoppablesToolbarDelegate {
    var screenshot:Screenshot! {
        didSet {
            if  screenshot != nil {
                self.shoppablesController = ShoppablesController.init(screenshot: screenshot)
            }else{
                self.shoppablesController = nil
            }
            self.shoppablesController.delegate = self;
            
            if self.isViewLoaded {
                self.syncScreenshotRelatedObjects()
                self.reloadProductsForShoppableAtIndex(0)
            }
        }
    }
    var shoppablesController:ShoppablesController!
    var loader:Loader!
    var noItemsHelperView:HelperView?
    var collectionView:UICollectionView!
    var shoppablesToolbar:ShoppablesToolbar!
    var productsOptions:ProductsOptions = ProductsOptions()
    var scrollRevealController:ScrollRevealController?
    var rateView:ProductsRateView!
    var productsRateNegativeFeedbackSubmitAction:UIAlertAction!
    var productsRateNegativeFeedbackTextField:UITextField!

    var products:[Product] = []
    var productsUnfilteredCount:Int = 0
    var image:UIImage!
    var state:ProductsViewControllerState = .loading {
        didSet {
            self.syncViewsAfterStateChange()
        }
    }
    
    
    init() {
        super.init(nibName: nil, bundle: nil)
        self.title = "Products"
        self.restorationIdentifier = "ProductsViewController"
        NotificationCenter.default.addObserver(self, selector: #selector(contentSizeCategoryDidChange), name: .UIContentSizeCategoryDidChange, object: nil)
        
        self.productsOptions.delegate = self;
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.setupShoppableToolbar()
        self.setupCollectionView()
        
        self.rateView = {
            let view = ProductsRateView()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.voteUpButton.addTarget(self, action: #selector(productsRatePositiveAction), for: .touchUpInside)
            view.voteDownButton.addTarget(self, action: #selector(productsRateNegativeAction), for: .touchUpInside)
            view.talkToYourStylistButton.addTarget(self, action: #selector(talkToYourStylistAction), for: .touchUpInside)
            return view;
        }()
        self.setupViews()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.shoppablesToolbar.selectFirstShoppable()
        if !self.hasShoppables() && self.noItemsHelperView == nil {
            self.state = .loading
        }
        //    [ProductWebViewController shared].lifeCycleDelegate = self;
//        [ProductWebViewController shared].delegate = self;

    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.shoppablesToolbar.didViewControllerAppear = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.dismissOptions()
    }

    func viewController(_ viewController: UIViewController, willDisappear animated: Bool) {
        
//        if (viewController == [ProductWebViewController shared] && [self.navigationController.topViewController isKindOfClass:[ProductsViewController class]]) {
//            ProductsViewController *productsViewController = (ProductsViewController *)self.navigationController.topViewController;
//            NSInteger index = [productsViewController indexForProduct:[ProductWebViewController shared].product];
//            [productsViewController reloadProductCellAtIndex:index];
//        }
    }
    func viewController(_ viewController: UIViewController, didDisappear animated: Bool) {
        
//        if (viewController == [ProductWebViewController shared] && ![self.navigationController.viewControllers containsObject:viewController]) {
//            [ProductWebViewController shared].product = nil;
//        }
    }
    func contentSizeCategoryDidChange(notification:Notification){
        if self.view.window != nil && self.collectionView.numberOfItems(inSection: ProductsSection.tooltip.rawValue) > 0 {
            self.collectionView.reloadItems(at: [IndexPath.init(item: 0, section: ProductsSection.tooltip.rawValue)])
        }
    }
    
    deinit {
        
        self.shoppablesToolbar.delegate = nil;
        self.shoppablesToolbar.shoppableToolbarDelegate = nil;
        self.collectionView.delegate = nil;
        self.collectionView.dataSource = nil;
        self.shoppablesController.delegate = nil;
        NotificationCenter.default.removeObserver(self)
        
    }
    
    
    
    func displayScreenshotAction() {
        let navigationController = ScreenshotDisplayNavigationController.init(nibName: nil, bundle: nil)
        navigationController.screenshotDisplayViewController.image = self.image;
        navigationController.screenshotDisplayViewController.shoppables = self.shoppablesController.shoppables()
        self.present(navigationController, animated: true, completion: nil)
    }
    
    
    func productCollectionViewCellDidTapFavorite(cell: ProductCollectionViewCell) {
        
        guard let isFavorited = cell.favoriteButton?.isSelected else{
            return
        }
        guard let indexPath = self.collectionView.indexPath(for: cell) else{
            return
        }
        let product = self.productAtIndex(indexPath.item)
        product.setFavorited(toFavorited: isFavorited)
        AnalyticsTrackers.standard.trackFavorited(isFavorited, product: product, onPage: "Products")
    }
    func reloadProductCell(index:Int){
//        if [self.collectionView.numberOfItemsInSection(ProductsSection.product.rawValue) > index {
//            self.collectionView.reloadItemsAtIndexPaths(self.shoppablesFrcToCollectionViewIndexPath(index))
//        }
    }
    
    
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
    
    func productsOptionsDidComplete(_ productsOptions: ProductsOptions, withChange changed: Bool) {
        
        if changed {
            let shoppable = self.shoppablesController.shoppable(at: self.shoppablesToolbar.selectedShoppableIndex())
            shoppable.set(productsOptions: productsOptions, callback: {
                self.reloadProductsForShoppableAtIndex(self.shoppablesToolbar.selectedShoppableIndex())
            })
            
        }
        self.dismissOptions()
    }
    
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let text = textField.text,
            let textRange = Range(range, in: text){
            
            let updatedText = text.replacingCharacters(in: textRange,  with: string)
            let trimmedText = updatedText.trimmingCharacters(in: CharacterSet.whitespaces)

            self.productsRateNegativeFeedbackSubmitAction.isEnabled = (trimmedText != nil && trimmedText != "")
        }
        return true;


    }
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached;
    }
    
    func shoppablesToolbarDidChange(toolbar: ShoppablesToolbar) {
        if self.products.count == 0 && self.isViewLoaded {
            self.reloadProductsForShoppableAtIndex(0)
        }
    }
    func shoppablesToolbarDidSelectShoppable(toolbar: ShoppablesToolbar, index: Int) {
        UserDefaults.standard.set(true, forKey: UserDefaultsKeys.productCompletedTooltip)
        self.reloadProductsForShoppableAtIndex(index)
        AnalyticsTrackers.standard.track("Tapped on shoppable")
    }
    func shouldHideToolbar()->Bool{
        return !self.hasShoppables()
    }
    
}


extension ProductsViewController {
    @objc func setupShoppableToolbar() {
        self.shoppablesToolbar = {
            let margin:CGFloat = 8.5 // Anything other then 8 will display horizontal margin
            let shoppableHeight:CGFloat = 60
            
            let toolbar = ShoppablesToolbar.init(frame: CGRect.init(x: 0, y: 0, width: 0, height: margin*2+shoppableHeight))
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
            return toolbar;
        }()
    }
    @objc func setupCollectionView(){
        self.collectionView = {
            let minimumSpacing = self.collectionViewMinimumSpacing()
            
            let layout = UICollectionViewFlowLayout()
            layout.minimumInteritemSpacing = minimumSpacing.x;
            layout.minimumLineSpacing = minimumSpacing.y;
            
            let collectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: layout)

            collectionView.translatesAutoresizingMaskIntoConstraints = false
            collectionView.delegate = self;
            collectionView.dataSource = self;
            collectionView.contentInset = UIEdgeInsets.init(top: self.shoppablesToolbar.bounds.size.height, left: 0.0, bottom: minimumSpacing.y, right: 0.0)
            collectionView.scrollIndicatorInsets = UIEdgeInsets.init(top: self.shoppablesToolbar.bounds.size.height, left: 0.0, bottom: 0.0, right: 0.0)
            
            collectionView.backgroundColor = self.view.backgroundColor;
            // TODO: set the below to interactive and comment the dismissal in -scrollViewWillBeginDragging.
            // Then test why the control view (products options view) jumps before being dragged away.
            collectionView.keyboardDismissMode = .onDrag;
            collectionView.register(ProductsTooltipCollectionViewCell.self, forCellWithReuseIdentifier: "tooltip");
            collectionView.register(ProductCollectionViewCell.self, forCellWithReuseIdentifier: "cell");


            self.view.insertSubview(collectionView, at: 0)
            collectionView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
            collectionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
            collectionView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
            collectionView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
            return collectionView
        }()
    }
    @objc func setupViews(){
        let scrollRevealController:ScrollRevealController = {
            let scrollRevealController = ScrollRevealController.init(edge: .top)
            scrollRevealController.adjustedContentInset = UIEdgeInsets.init(top: self.navigationController?.navigationBar.frame.maxY ?? 0, left: 0, bottom: 0, right: 0)
            scrollRevealController.insertAbove(self.collectionView)
            
            
            scrollRevealController.view.addSubview(self.rateView)
            return scrollRevealController
        }()
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
        if (self.shoppablesController == nil) {
            self.state = .loading;
        } else {
            self.syncScreenshotRelatedObjects()

            if self.shoppablesController.shoppableCount() == -1  {
                // TODO: When porting this to swift, the shoppablesToolbar, collectionView,
                // rateView and scrollRevealController can all be lazy loaded. They dont
                // need to exist if this condition is true.
                self.state = .retry;
                AnalyticsTrackers.standard.track("Screenshot Opened Without Shoppables")
            }
            else {
                self.reloadProductsForShoppableAtIndex(0);
            }
        }
    }
}

private typealias ProductsViewControllerCollectionView = ProductsViewController
extension ProductsViewControllerCollectionView : UICollectionViewDelegateFlowLayout, UICollectionViewDataSource{
    func numberOfCollectionViewProductColumns() ->Int {
        return 2
    }
    
    
    func collectionViewToShoppablesFrcIndexPath(_ index:Int) ->IndexPath {
        return IndexPath.init(item: index, section: 0)
    }
    
    func shoppablesFrcToCollectionViewIndexPath(_ index:Int) -> IndexPath{
        return IndexPath.init(item: index, section: ProductsSection.product.rawValue)
    }

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int{
        if (section == ProductsSection.tooltip.rawValue) {
            let shouldPresentTooldtip = !UserDefaults.standard.bool(forKey: UserDefaultsKeys.productCompletedTooltip)
            let hasProducts = (self.products.count > 0)
            return (shouldPresentTooldtip && hasProducts) ? 1 : 0;
            
        } else if (section == ProductsSection.product.rawValue) {
            return self.products.count;
            
        } else {
            return 0;
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        var size:CGSize = .zero
        let shadowInsets = ScreenshotCollectionViewCell.shadowInsets
        let padding = Geometry.padding - shadowInsets.left - shadowInsets.right;
        
        if (indexPath.section == ProductsSection.tooltip.rawValue) {
            size.width = collectionView.bounds.size.width;
            size.height = ProductsTooltipCollectionViewCell.height(withCellWidth: size.width)
            
        } else if (indexPath.section == ProductsSection.product.rawValue) {
            let columns = CGFloat(self.numberOfCollectionViewProductColumns())
            size.width = floor((collectionView.bounds.size.width - (padding * (columns + 1))) / columns);
            size.height = size.width + ProductCollectionViewCell.labelsHeight
        }
        
        return size;
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if (indexPath.section == ProductsSection.tooltip.rawValue) {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "tooltip", for: indexPath)
            return cell;
        } else if (indexPath.section == ProductsSection.product.rawValue) {
            let product = self.productAtIndex(indexPath.item)
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? ProductCollectionViewCell {
                cell.delegate = self;
                cell.contentView.backgroundColor = collectionView.backgroundColor;
                cell.title = product.displayTitle;
                cell.price = product.price;
                cell.originalPrice = product.originalPrice;
                cell.imageUrl = product.imageURL;
                cell.isSale = product.isSale()
                cell.favoriteButton?.isSelected = product.isFavorite;
                return cell;
            }
            
        }
        return UICollectionViewCell();
        
    }

    
    public func collectionViewMinimumSpacing() -> CGPoint {
        let shadowInsets = ScreenshotCollectionViewCell.shadowInsets
        let p = Geometry.padding
        return CGPoint.init(x: p - shadowInsets.left - shadowInsets.right, y: p - shadowInsets.top - shadowInsets.bottom)
    }
    
    public func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return indexPath.section != ProductsSection.tooltip.rawValue
    }
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        
        if section ==  ProductsSection.product.rawValue {
            let minimumSpacing:CGPoint = self.collectionViewMinimumSpacing()
            
            return UIEdgeInsets.init(top: minimumSpacing.y, left: minimumSpacing.x, bottom: 0.0, right: minimumSpacing.x)
        } else {
            return .zero;
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if (indexPath.section == ProductsSection.product.rawValue) {
            let product = self.productAtIndex(indexPath.item)
            
            
            if var urlString = product.offer {
                if (urlString.hasPrefix("//")) {
                    urlString = "https:".appending(urlString)
                }
                if let url = URL.init(string: urlString){
                    if UIApplication.shared.canOpenURL(url){
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    } else {
                        AnalyticsTrackers.standard.track("Can't open url", properties: ["url":urlString])
                    }
                }
            }
            
            
            AnalyticsTrackers.standard.trackTappedOnProduct(product, onPage: "Products")


            let email = UserDefaults.standard.string(forKey: UserDefaultsKeys.email) ?? ""

            if (email.lengthOfBytes(using: .utf8) > 0) {
                let uploadedImageURL = self.screenshot.uploadedImageURL ?? ""
                let merchant = product.merchant ?? ""
                let brand = product.brand ?? ""
                let displayTitle = product.displayTitle ?? ""
                let offer = product.offer ?? ""
                let imageURL = product.imageURL ?? ""
                let price = product.price ?? ""
                let name =  UserDefaults.standard.string(forKey: UserDefaultsKeys.name) ?? ""

                let properties = ["screenshot": uploadedImageURL,
                                  "merchant": merchant,
                                  "brand": brand,
                                  "title": displayTitle,
                                  "url": offer,
                                  "imageUrl": imageURL,
                                  "price": price,
                                  "email": email,
                                  "name": name ]
                AnalyticsTrackers.standard.track("Product for email", properties:properties)
            }
            AnalyticsTrackers.branch.track("Tapped on product")
            FBSDKAppEvents.logEvent(FBSDKAppEventNameViewedContent, parameters:[FBSDKAppEventParameterNameContentID: product.imageURL ?? ""])
        }
    }
}

private typealias ProductsViewControllerOptionsView = ProductsViewController
extension ProductsViewControllerOptionsView {
    @objc func updateOptionsView() {
        if self.hasShoppables() {
            if (self.navigationItem.titleView == nil) {
                self.navigationItem.titleView = { () -> UIView in
                    let label = UILabel()
                    label.adjustsFontSizeToFitWidth = true
                    label.minimumScaleFactor = 0.7
                    
                    var attributes = UINavigationBar.appearance().titleTextAttributes
                    attributes?[NSForegroundColorAttributeName] = UIColor.crazeGreen

                    let attributedString = NSMutableAttributedString.init(string: "Sort & Filter", attributes: attributes)
                    
                    let offset:CGFloat = 3
                    attributes?[NSBaselineOffsetAttributeName] = offset

                    let arrowString = NSAttributedString.init(string: "⌄", attributes: attributes)
                    attributedString.append(arrowString)
                    
                    
                    label.attributedText = attributedString;
                    label.sizeToFit()
                    
                    var rect = label.frame;
                    rect.origin.y -= offset;
                    label.frame = rect;
                    
                    let container = ProductsViewControllerControl.init(frame:label.bounds)
                    container.addTarget(self, action: #selector(presentOptions(_:)), for: .touchUpInside)
                    container.addSubview(label)
                    return container;
                }()
            }
        }else{
            self.navigationItem.titleView = nil;
        }
    }
    
    @objc func presentOptions(_ control:ProductsViewControllerControl){
        
        if control.isFirstResponder {
            control.resignFirstResponder()
        } else {
            AnalyticsTrackers.standard.track("Opened Filters View", properties:nil)
            let shoppable = self.shoppablesController.shoppable(at: self.shoppablesToolbar.selectedShoppableIndex())
            self.productsOptions.syncOptions(withMask: shoppable.getLast() )
            
            control.customInputView = self.productsOptions.view
            control.becomeFirstResponder()
        }
    }
    @objc func dismissOptions(){
        self.navigationItem.titleView?.endEditing(true)
    }
}

private typealias ProductsViewControllerShoppables = ProductsViewController
extension ProductsViewControllerShoppables {
    @objc func hasShoppables() -> Bool {
        return self.shoppablesController.shoppableCount() > 0
    }
    
    @objc func shoppablesControllerIsEmpty(_ controller:ShoppablesController){
        if (self.noItemsHelperView == nil) {
            self.state = .retry
        }
    }
    
    @objc func shoppablesControllerDidReload(_ controller:ShoppablesController){
        self.reloadProductsForShoppableAtIndex(self.shoppablesToolbar.selectedShoppableIndex());

    }

}
private typealias ProductsViewControllerProducts = ProductsViewController
extension ProductsViewControllerProducts{
    @objc func productAtIndex(_ index:Int) -> Product{
        return self.products[index]
    }
    
    @objc func indexForProduct(_ product:Product )-> Int {
        return self.products.index(of: product) ?? NSNotFound
    }
    
    @objc func reloadProductsForShoppableAtIndex(_ index:Int){
        
        self.products = [];
        self.productsUnfilteredCount = 0;
        
        if self.hasShoppables() {
            self.scrollRevealController?.resetViewOffset()
            
            let shoppable = self.shoppablesController.shoppable(at: index)
            
            if (shoppable.productFilterCount == -1) {
                self.state = .retry;
                
            } else {
                self.products = self.productsForShoppable(shoppable)
                
                if (shoppable.productFilterCount == 0 && self.productsUnfilteredCount == 0) {
                    self.state = .loading;
                    
                } else {
                    self.state = (self.products.count == 0) ? .empty : .products;
                }
            }
            
            self.collectionView.reloadData()
            self.rateView.setRating(UInt(shoppable.getRating()), animated: false)
            
            if self.collectionView.numberOfItems(inSection: ProductsSection.tooltip.rawValue) > 0 {
                self.collectionView.scrollToItem(at: IndexPath.init(item: 0, section: ProductsSection.tooltip.rawValue), at: .top, animated: false)
                
            } else if self.collectionView.numberOfItems(inSection: ProductsSection.product.rawValue) > 0 {
                self.collectionView.scrollToItem(at: IndexPath.init(item: 0, section: ProductsSection.product.rawValue), at: .top, animated: false)
            }
            
        } else {
            self.state = .loading;
            self.collectionView.reloadData()
        }
    }
        
    @objc func productsForShoppable(_ shoppable:Shoppable) -> [Product] {
        let descriptors:[NSSortDescriptor] = {
            switch self.productsOptions.sort {
            case .similar :
                return [NSSortDescriptor.init(key: "order", ascending: true)]
            case .priceAsc :
                return [NSSortDescriptor.init(key: "floatPrice", ascending: true)]
            case .priceDes :
                return [NSSortDescriptor.init(key: "floatPrice", ascending: false)]
            case .brands :
                return [NSSortDescriptor.init(key: "displayTitle", ascending: true, selector:#selector(NSString.localizedCaseInsensitiveCompare(_:) ) ), NSSortDescriptor.init(key: "order", ascending: true)]
            }
        }()
        if let mask = shoppable.getLast()?.rawValue , var products:Set = shoppable.products?.filtered(using: NSPredicate.init(format: "(optionsMask & %d) == %d", mask, mask)) as? Set<Product> {
            self.productsUnfilteredCount = products.count
            if self.productsOptions.sale == .sale {
                let filtered = (products as NSSet).filtered(using: NSPredicate.init(format: "floatPrice < floatOriginalPrice"))
                products = filtered as! Set<Product>
            }
            return  (((products as NSSet).allObjects as NSArray).sortedArray(using: descriptors) as? [Product]) ?? []
            
        }
        return []

    }
}
private typealias ProductsViewControllerLoader = ProductsViewController

extension ProductsViewControllerLoader {
    @objc func startAndAddLoader(){
        if self.loader == nil {
            self.loader = Loader()
            self.loader.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(self.loader)
            self.loader.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
            self.loader.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        }
        self.loader.startAnimation()
    }
    @objc func stopAndRemoveLoader(){
        if self.loader != nil {
            self.loader.stopAnimation()
            self.loader .removeFromSuperview()
            self.loader = nil
        }
    }

}

private typealias ProductsViewControllerRatings = ProductsViewController
extension ProductsViewControllerRatings {
    @objc func presentProductsRateNegativeAlert() {
        if !InAppPurchaseManager.sharedInstance.didPurchase(_inAppPurchaseProduct: .personalStylist){
            InAppPurchaseManager.sharedInstance .loadProductInfoIfNeeded()
        }
        let alertController = UIAlertController.init(title: "negativeFeedback.title".localized, message: "negativeFeedback.message".localized, preferredStyle: .alert)
        alertController.addAction(UIAlertAction.init(title: "negativeFeedback.options.sendFeedback".localized, style: .default, handler: { (a) in
            self.presentProductsRateNegativeFeedbackAlert()

        }))
        alertController.addAction(UIAlertAction.init(title: "negativeFeedback.options.fashionHelp".localized, style: .default, handler: { (a) in
            if InAppPurchaseManager.sharedInstance.didPurchase(_inAppPurchaseProduct: .personalStylist) {
                self.presentPersonalSylist()
            }else{
                if InAppPurchaseManager.sharedInstance.canPurchase() {
                   let alertController = UIAlertController.init(title: nil, message: "personalSytlistPopup.loading".localized, preferredStyle: .alert)
                    let action = UIAlertAction.init(title: "personalSytlistPopup.option.continue".localized, style: .default, handler: { (action) in
                        if let product = InAppPurchaseManager.sharedInstance.productIfAvailable(product: .personalStylist) {
                            InAppPurchaseManager.sharedInstance.buy(product: product, success: {
                                //don't present anything -  if the user stayed on the same page the bottom bar changed to 'talk to your stylist' otherwise don't do anything
                            }, failure: { (error) in
                                //no reason to present alert - Apple does it for us
                            })
                        }
                    })
                    
                    if let product = InAppPurchaseManager.sharedInstance.productIfAvailable(product: .personalStylist) {
                        action.isEnabled = true;
                        alertController.message = String.init(format: "personalSytlistPopup.canContinue".localized, product.localizedPriceString())
                    }else{
                        action.isEnabled = false;
                        InAppPurchaseManager.sharedInstance.load(product: .personalStylist, success: { (product) in
                            action.isEnabled = true;
                            alertController.message = String.init(format: "personalSytlistPopup.canContinue".localized, product.localizedPriceString())
                        }, failure: { (error) in
                            alertController.message = String.init(format: "personalSytlistPopup.error".localized, error.localizedDescription)
                        })
                        
                    }
                    alertController.addAction(action)
                    alertController.addAction(UIAlertAction.init(title: "generic.cancel".localized, style: .cancel, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                }else{
                    let errorMessage = "personalSytlistPopup.errorCannotPurchaseOnDevice".localized
                    let alertController = UIAlertController.init(title: nil, message: errorMessage, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction.init(title: "generic.ok".localized, style: .cancel, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                    
                }
            }
        }))
        alertController.addAction(UIAlertAction.init(title: "negativeFeedback.options.close".localized, style: .cancel, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    @objc func productsRatePositiveAction(){
        let shoppable = self.shoppablesController.shoppable(at: self.shoppablesToolbar.selectedShoppableIndex())
        shoppable.setRating(positive: true)
    }
    
    @objc func productsRateNegativeAction(){
        let shoppable = self.shoppablesController.shoppable(at: self.shoppablesToolbar.selectedShoppableIndex())
        shoppable.setRating(positive: false)
        self.presentProductsRateNegativeAlert()
    }
    @objc func talkToYourStylistAction(){
        IntercomHelper.sharedInstance.presentMessagingUI()
    }
    
    @objc func presentPersonalSylist() {
        let shortenedUploadedImageURL = self.screenshot.shortenedUploadedImageURL ?? ""
        AnalyticsTrackers.standard.track("Requested Custom Stylist", properties: ["screenshotImageURL" :  shortenedUploadedImageURL])
        let prefiledMessageTemplate = "I need help finding this outfit... %@"
        let prefilledMessage = String.init(format: prefiledMessageTemplate, (self.screenshot.shortenedUploadedImageURL  ?? "null"))
        IntercomHelper.sharedInstance.presentMessageComposer(withInitialMessage: prefilledMessage)
    }
    @objc func presentProductsRateNegativeFeedbackAlert() {
        let alertController = UIAlertController.init(title: "What’s Wrong Here?", message: "What were you expecting to see and what did you see instead?", preferredStyle: .alert)
        alertController.addTextField { (textField) in
            textField.delegate = self;
            textField.autocapitalizationType = .sentences
            textField.enablesReturnKeyAutomatically = true
            textField.tintColor = .crazeGreen
            self.productsRateNegativeFeedbackTextField = textField;
        }
        
        self.productsRateNegativeFeedbackSubmitAction = UIAlertAction.init(title: "Submit", style: .default, handler: { (action) in
            if let trimmedText = self.productsRateNegativeFeedbackTextField.text?.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines) {
            
                if (trimmedText.lengthOfBytes(using: .utf8) > 0) {
                    AnalyticsTrackers.segment.track("Shoppable Feedback Negative", properties:["text": trimmedText])
                }
            }
        })
        
        self.productsRateNegativeFeedbackSubmitAction.isEnabled = false
        alertController.addAction(self.productsRateNegativeFeedbackSubmitAction)

        alertController.preferredAction = self.productsRateNegativeFeedbackSubmitAction;
        alertController.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
//    @objc public func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
//        if let text = textField.text,
//            let textRange = Range(range, in: text) {
//            let updatedText = text.replacingCharacters(in: textRange, with: string)
//            let trimmedText = updatedText.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
//
//            self.productsRateNegativeFeedbackSubmitAction.isEnabled = (trimmedText.lengthOfBytes(using: .utf8) > 0)
//        }
//
//        return true
//    }
}

extension ProductsViewController {
    
    @objc func syncViewsAfterStateChange(){
        self.updateOptionsView()
        self.shoppablesToolbar.isHidden = self.shouldHideToolbar()
        
        switch (state) {
        case .loading:
            self.hideNoItemsHelperView()
            self.rateView.isHidden = true
            self.startAndAddLoader()
            
        case .products:
            if #available(iOS 11.0, *) {
                //Do nothing
            } else {
                if (!self.automaticallyAdjustsScrollViewInsets) {
                    // Setting back to YES doesn't update. Need to manually adjust.
                    var scrollInsets = self.collectionView.scrollIndicatorInsets;
                    scrollInsets.top = self.shoppablesToolbar.bounds.size.height + (self.navigationController?.navigationBar.frame.maxY ?? 0)
                    self.collectionView.scrollIndicatorInsets = scrollInsets;
                    
                    var insets = self.collectionView.contentInset;
                    insets.top = scrollInsets.top;
                    self.collectionView.contentInset = insets;
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
    
    @objc func syncScreenshotRelatedObjects() {
        if let data = self.screenshot.imageData, let i = UIImage.init(data: data as Data) {
            self.image = i
        }else{
            self.image = UIImage.init()
        }
        
        self.navigationItem.rightBarButtonItem = {
            let buttonSize:CGFloat = 32
            
            let button = UIButton.init(type: UIButtonType.custom)
            button.frame = CGRect.init(x: 0, y: 0, width: buttonSize, height: buttonSize)
            button.imageView?.contentMode = .scaleAspectFill;
            button.setImage(self.image, for: .normal)
            
            button.addTarget(self, action: #selector(displayScreenshotAction), for: .touchUpInside)
            
            button.layer.borderColor = UIColor.crazeGreen.cgColor
            button.layer.borderWidth = 1
            
            let barButtonItem = UIBarButtonItem.init(customView: button)
            button.widthAnchor.constraint(equalToConstant: button.bounds.size.width).isActive = true
            button.heightAnchor.constraint(equalToConstant: button.bounds.size.height).isActive = true
            
            
            return barButtonItem;
        }()
        
        self.shoppablesToolbar.shoppablesController = self.shoppablesController;
        self.shoppablesToolbar.screenshotImage = self.image;
    }

}

private typealias ProductsViewControllerNoItemsHelperView = ProductsViewController
extension ProductsViewControllerNoItemsHelperView{
    @objc func showNoItemsHelperView() {
        
        let verPadding = Geometry.extendedPadding
        let horPadding = Geometry.padding
        let topOffset:CGFloat = self.shoppablesToolbar.isHidden ? 0.0 : self.shoppablesToolbar.bounds.size.height
        
        let helperView = HelperView.init()
        helperView.translatesAutoresizingMaskIntoConstraints = false
        helperView.layoutMargins = UIEdgeInsets.init(top: verPadding, left: horPadding, bottom: verPadding, right: horPadding)
        helperView.titleLabel.text = "No Items Found"
        helperView.subtitleLabel.text = "No visually similar products were detected"
        helperView.contentImage = UIImage.init(named: "ProductsEmptyListGraphic")
        self.view.addSubview(helperView)
        
        helperView.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor, constant:topOffset).isActive = true
        helperView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        helperView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        helperView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        self.noItemsHelperView = helperView
        if self.state == .retry {
            
            let retryButton = MainButton.init()
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
    
    @objc func hideNoItemsHelperView(){
        self.noItemsHelperView?.removeFromSuperview()
        self.noItemsHelperView = nil
    }
    
    @objc func noItemsRetryAction() {
        let alert = UIAlertController.init(title: "Try again as", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction.init(title: "Fashion", style: .default, handler: { (a) in
            self.shoppablesController.refetchShoppablesAsFashion()
            self.state = .loading;

        }))
        alert.addAction(UIAlertAction.init(title: "Furniture", style: .default, handler: { (a) in
                            self.shoppablesController.refetchShoppablesAsFurniture()
            self.state = .loading;

        }))
        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

