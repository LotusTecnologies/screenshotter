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
import PromiseKit

enum ProductsSection : Int {
    case product = 0
    case relatedLooks = 1

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
    var screenshotController: FetchedResultsControllerManager<Screenshot>?
    fileprivate var productsFRC: FetchedResultsControllerManager<Product>?
    
    var products:[Product] = []
    var relatedLooks:Promise<[String]>?
    func loadRelatedLooksIfNeeded() {
        if self.relatedLooks == nil {
            let promise = Promise.init(resolvers: { (fulfil, reject) in
                DispatchQueue.main.asyncAfter(deadline: .now()+10, execute: {
                    fulfil(self.relatedLooksArrayReuslt);
                })
            })
            promise.always(on: .main) {
                let section = self.sectionIndex(forProductType: .relatedLooks)
                self.collectionView?.reloadSections(IndexSet.init(integer: section))
            }
            self.relatedLooks = promise
        }
    }
    var relatedLooksArrayReuslt =   [
        "https://s3.amazonaws.com/syte-dev-storage/mns-ctl-instagram/17882982_1916411428577436_8154856183031660544_n.jpg",
        "https://s3.amazonaws.com/syte-dev-storage/mns-ctl-instagram/21294572_778446935649976_284911831015751680_n.jpg",
        "https://s3.amazonaws.com/syte-dev-storage/mns-ctl-instagram/17882465_386110208440068_813241092446093312_n.jpg",
        "https://s3.amazonaws.com/syte-dev-storage/mns-ctl-instagram/13741426_1717054188543060_1040489109_n.jpg",
        "https://s3.amazonaws.com/syte-dev-storage/mns-ctl-instagram/21227656_944219765717780_3372714225569890304_n.jpg",
        "https://s3.amazonaws.com/syte-dev-storage/mns-ctl-instagram/18380193_142648489609504_4906023335562838016_n.jpg",
        "https://s3.amazonaws.com/syte-dev-storage/mns-ctl-instagram/13534361_912881562168430_213000940_n.jpg",
        "https://s3.amazonaws.com/syte-dev-storage/mns-ctl-instagram/21296543_105334746873270_9172771996348448768_n.jpg",
        "https://s3.amazonaws.com/syte-dev-storage/mns-ctl-instagram/18011458_1865589167049389_6438160207246786560_n.jpg",
        "https://s3.amazonaws.com/syte-dev-storage/mns-ctl-instagram/21294619_121516448503164_3529480441679577088_n.jpg",
        "https://s3.amazonaws.com/syte-dev-storage/mns-ctl-instagram/22157823_839614326211580_1912553442329493504_n.jpg",
        "https://s3.amazonaws.com/syte-dev-storage/mns-ctl-instagram/21371947_1127149297429133_5267684522761125888_n.jpg",
        "https://s3.amazonaws.com/syte-dev-storage/mns-ctl-instagram/10903226_1520319674897261_992439649_n.jpg",
        "https://s3.amazonaws.com/syte-dev-storage/mns-ctl-instagram/26186718_144393056231252_8548036700696215552_n.jpg",
        "https://s3.amazonaws.com/syte-dev-storage/mns-ctl-instagram/11909371_1700908866806204_1796268346_n.jpg",
        "https://s3.amazonaws.com/syte-dev-storage/mns-ctl-instagram/22427367_1809768332369924_1520569231970664448_n.jpg",
        "https://s3.amazonaws.com/syte-dev-storage/mns-ctl-instagram/13651708_269435350091628_406024557_n.jpg",
        "https://s3.amazonaws.com/syte-dev-storage/mns-ctl-instagram/17493843_753716978118816_8518453180709732352_n.jpg",
        "https://s3.amazonaws.com/syte-dev-storage/mns-ctl-instagram/11111475_799661776779935_1433968858_n.jpg",
        "https://s3.amazonaws.com/syte-dev-storage/mns-ctl-instagram/20346864_429856740747363_3701678745866731520_n.jpg",
        "https://s3.amazonaws.com/syte-dev-storage/mns-ctl-instagram/21296799_120232581970248_5229337959525777408_n.jpg",
        "https://s3.amazonaws.com/syte-dev-storage/mns-ctl-instagram/17267546_583890535142492_6253413344355549184_n.jpg",
        "https://s3.amazonaws.com/syte-dev-storage/mns-ctl-instagram/14624468_1854003298166551_9014731407607463936_n.jpg",
        "https://s3.amazonaws.com/syte-dev-storage/mns-ctl-instagram/27893605_505602579841108_1814352481145061376_n.jpg",
        "https://s3.amazonaws.com/syte-dev-storage/mns-ctl-instagram/14726299_1043776192406099_991395073163788288_n.jpg",
        "https://s3.amazonaws.com/syte-dev-storage/mns-ctl-instagram/17596372_267353487055815_3494021926123208704_n.jpg",
        "https://s3.amazonaws.com/syte-dev-storage/mns-ctl-instagram/1517078_561645047257601_1263719982_n.jpg",
        "https://s3.amazonaws.com/syte-dev-storage/mns-ctl-instagram/10632156_878466062177528_1707889987_n.jpg",
        "https://s3.amazonaws.com/syte-dev-storage/mns-ctl-instagram/21294901_114385985916978_7185887681035894784_n.jpg",
        "https://s3.amazonaws.com/syte-dev-storage/mns-ctl-instagram/13724483_1743966922510450_993567476_n.jpg",
        "https://s3.amazonaws.com/syte-dev-storage/mns-ctl-instagram/18723391_443831265973491_5106348096376274944_n.jpg",
        "https://s3.amazonaws.com/syte-dev-storage/mns-ctl-instagram/11199632_841020505965855_442868542_n.jpg",
        "https://s3.amazonaws.com/syte-dev-storage/mns-ctl-instagram/17881726_1170291863093828_1911868012793692160_n.jpg",
        "https://s3.amazonaws.com/syte-dev-storage/mns-ctl-instagram/21227358_115024339217604_1892186247850360832_n.jpg",
        "https://s3.amazonaws.com/syte-dev-storage/mns-ctl-instagram/27576629_392018501240099_7840576533876965376_n.jpg",
        "https://s3.amazonaws.com/syte-dev-storage/mns-ctl-instagram/26187209_179344236147799_1212080706264498176_n.jpg",
        "https://s3.amazonaws.com/syte-dev-storage/mns-ctl-instagram/22351998_532980693701111_4334103239864614912_n.jpg",
        "https://s3.amazonaws.com/syte-dev-storage/mns-ctl-instagram/17333996_398106220551395_977448627158908928_n.jpg",
        "https://s3.amazonaws.com/syte-dev-storage/mns-ctl-instagram/10453912_312933792199064_1394767148_n.jpg",
        "https://s3.amazonaws.com/syte-dev-storage/mns-ctl-instagram/23823570_1930365280313467_6505824492122537984_n.jpg",
        "https://s3.amazonaws.com/syte-dev-storage/mns-ctl-instagram/11272040_869422876440949_1768764987_n.jpg",
        "https://s3.amazonaws.com/syte-dev-storage/mns-ctl-instagram/18381041_813645912125179_6199767871388647424_n.jpg",
        "https://s3.amazonaws.com/syte-dev-storage/mns-ctl-instagram/12930976_1756601797908049_44598166_n.jpg",
        "https://s3.amazonaws.com/syte-dev-storage/mns-ctl-instagram/14718213_194532787671443_7846066545758306304_n.jpg",
        "https://s3.amazonaws.com/syte-dev-storage/mns-ctl-instagram/16464921_189832344831278_6346774706326077440_n.jpg",
        "https://s3.amazonaws.com/syte-dev-storage/mns-ctl-instagram/13628326_168442330247432_430333845_n.jpg",
        "https://s3.amazonaws.com/syte-dev-storage/mns-ctl-instagram/12093561_554158741433403_1065597627_n.jpg",
        "https://s3.amazonaws.com/syte-dev-storage/mns-ctl-instagram/19624835_654273358103465_3947611790166196224_n.jpg",
        "https://s3.amazonaws.com/syte-dev-storage/mns-ctl-instagram/928645_1499963033574808_1101628008_n.jpg",
        "https://s3.amazonaws.com/syte-dev-storage/mns-ctl-instagram/19052283_2015319452072475_6773187782551535616_n.jpg"]

    var loader:Loader?
    var noItemsHelperView:HelperView?
    var collectionView:UICollectionView?
    var shoppablesToolbar:ShoppablesToolbar?
    var productsOptions:ProductsOptions = ProductsOptions()
    var scrollRevealController:ScrollRevealController?
    var rateView:ProductsRateView!
    var productsRateNegativeFeedbackSubmitAction:UIAlertAction?
    var productsRateNegativeFeedbackTextField:UITextField?
    var shamrockButton : FloatingActionButton?
    var productsUnfilteredCount:Int = 0
    var state:ProductsViewControllerState = .loading {
        didSet {
            self.syncViewsAfterStateChange()
        }
    }
    var shareToDiscoverPrompt:UIView?
    fileprivate let filterView = CustomInputtableView()
    
    init(screenshot: Screenshot) {
        self.screenshot = screenshot
    
        super.init(nibName: nil, bundle: nil)
        
        self.title = "products.title".localized
        self.restorationIdentifier = "ProductsViewController"
        
        self.productsOptions.delegate = self
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "NavigationBarFilter"), style: .plain, target: self, action: #selector(presentOptions))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        screenshotController = DataModel.sharedInstance.singleScreenshotFrc(delegate: self, screenshot: screenshot)
        
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
            
            let layout = SectionBackgroundCollectionViewFlowLayout()
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
            collectionView.register(ProductsCollectionViewCell.self, forCellWithReuseIdentifier: "cell")

            collectionView.register(RelatedLooksCollectionViewCell.self, forCellWithReuseIdentifier: "relatedLooks")
            collectionView.register(SpinnerCollectionViewCell.self, forCellWithReuseIdentifier: "relatedLooks-spinner")
            collectionView.register(ErrorRetryableCollectionViewCell.self, forCellWithReuseIdentifier: "relatedLooks-error-retry")
            collectionView.register(ErrorNotRetryableCollectionViewCell.self, forCellWithReuseIdentifier: "relatedLooks-error-no-retry")
            collectionView.register(ProductsViewHeaderReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "header")
            collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: SectionBackgroundCollectionViewFlowLayout.ElementKindSectionSectionBackground, withReuseIdentifier: "background")
            
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
        scrollRevealController.hasBottomBar = !hidesBottomBarWhenPushed
        scrollRevealController.adjustedContentInset = {
            let top = navigationController?.navigationBar.frame.maxY ?? 0
            var bottom = tabBarController?.tabBar.bounds.height ?? 0
            
            if !scrollRevealController.hasBottomBar {
                bottom = 0
            }
            
            return UIEdgeInsets(top: top, left: 0, bottom: bottom, right: 0)
        }()
        scrollRevealController.insertAbove(collectionView)

        scrollRevealController.view.addSubview(rateView)
        self.scrollRevealController = scrollRevealController
        
        rateView.topAnchor.constraint(equalTo:scrollRevealController.view.topAnchor).isActive = true
        rateView.leadingAnchor.constraint(equalTo:scrollRevealController.view.leadingAnchor).isActive = true
        rateView.bottomAnchor.constraint(equalTo:scrollRevealController.view.bottomAnchor).isActive = true
        rateView.trailingAnchor.constraint(equalTo:scrollRevealController.view.trailingAnchor).isActive = true
        
        view.addSubview(filterView)
        
        if !scrollRevealController.hasBottomBar {
            var height = self.rateView.intrinsicContentSize.height
            
            if #available(iOS 11.0, *) {
                height += UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0
            }
            self.rateView.heightAnchor.constraint(equalToConstant: height).isActive = true
        }
        
        if self.screenshotController?.first?.shoppablesCount == -1 {
            self.state = .retry
            Analytics.trackScreenshotOpenedWithoutShoppables(screenshot: screenshot)
        }
        else {
            self.shoppablesToolbar?.selectFirstShoppable()
        }
        
        let pinchZoom = UIPinchGestureRecognizer.init(target: self, action: #selector(pinch(gesture:)))
        self.view.addGestureRecognizer(pinchZoom)

    }
    
    @objc func pinch( gesture:UIPinchGestureRecognizer) {
        if CrazeImageZoom.shared.isHandlingGesture, let imageView = CrazeImageZoom.shared.hostedImageView  {
            CrazeImageZoom.shared.gestureStateChanged(gesture, imageView: imageView)
            return
        }
        let point = gesture.location(in: self.collectionView)
        if let collectionView = self.collectionView, let indexPath = collectionView.indexPathForItem(at: point),  let cell = collectionView.cellForItem(at: indexPath){
            
            if let cell = cell as? ProductsCollectionViewCell, let imageView = cell.productImageView {
                CrazeImageZoom.shared.gestureStateChanged(gesture, imageView: imageView)
            }else if let cell = cell as? RelatedLooksCollectionViewCell {
                let imageView = cell.imageView
                CrazeImageZoom.shared.gestureStateChanged(gesture, imageView: imageView)
            }
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
        hideShareToDiscoverPrompt()
    }
    
    deinit {
        self.shoppablesToolbar?.delegate = nil
        self.shoppablesToolbar?.shoppableToolbarDelegate = nil
    }
}

private typealias ProductsViewControllerScrollViewDelegate = ProductsViewController
extension ProductsViewControllerScrollViewDelegate: UIScrollViewDelegate {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.dismissOptions()
        self.scrollRevealController?.scrollViewWillBeginDragging(scrollView)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if self.loader == nil {
            let scrollViewHeight = scrollView.frame.size.height;
            let scrollContentSizeHeight = scrollView.contentSize.height;
            let scrollOffset = scrollView.contentOffset.y;
            let startLoadingDistance:CGFloat = 500
            
            
            if (scrollOffset + scrollViewHeight + startLoadingDistance >= scrollContentSizeHeight){
                self.loadRelatedLooksIfNeeded()
            }
        }
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
        return ProductsSection(rawValue: forSection) ?? .product
    }
    func sectionIndex(forProductType:ProductsSection) -> Int {
        return forProductType.rawValue
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
        if sectionType == .product {
            return self.products.count
            
        } else {
            if self.products.count > 0  {
//                if product is not load then related looks does not appear at all
                if let relatedLooks = self.relatedLooks?.value {
                    return relatedLooks.count
                }else{
                    return 1 // loading or error message
                }
            }
            
        }
        return 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let sectionType = productSectionType(forSection: section)

        if sectionType == .relatedLooks {
            if self.products.count > 0  {
                return CGSize.init(width: collectionView.bounds.size.width, height: 80)
            }
        }
        
        return .zero;
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        var size:CGSize = .zero
        let shadowInsets = ScreenshotCollectionViewCell.shadowInsets
        let padding: CGFloat = .padding - shadowInsets.left - shadowInsets.right
        let sectionType = productSectionType(forSection: indexPath.section)

        if sectionType == .product {
            let columns = CGFloat(numberOfCollectionViewProductColumns)
            size.width = floor((collectionView.bounds.size.width - (padding * (columns + 1))) / columns)
            size.height = ProductsCollectionViewCell.cellHeight(for: size.width, withBottomLabel: true)
        }else if sectionType == .relatedLooks {
            if let _ = self.relatedLooks?.value {
                let columns = CGFloat(numberOfCollectionViewProductColumns)
                size.width = floor((collectionView.bounds.size.width - (padding * (columns + 1))) / columns)
                size.height = size.width * CGFloat(Double.goldenRatio)
            }else if let _ = relatedLooks?.error {
                size.width = collectionView.bounds.size.width
                size.height = 300
            }else { // is pending or nil
                size.width = collectionView.bounds.size.width
                size.height = 150
            }
        }
        
        return size
    }
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let sectionType = productSectionType(forSection: indexPath.section)
        if kind == UICollectionElementKindSectionHeader {
            if let cell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "header", for: indexPath) as? ProductsViewHeaderReusableView{
                if sectionType == .relatedLooks {
                    cell.label.text = "Simliar Looks"
                }
                
                return cell
            }
        }else if kind == SectionBackgroundCollectionViewFlowLayout.ElementKindSectionSectionBackground {
            let cell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "background", for: indexPath)
            if sectionType == .product {
                cell.backgroundColor = self.view.backgroundColor
            }else if sectionType == .relatedLooks{
                if let image = UIImage.init(named: "confetti") {
                    cell.backgroundColor = UIColor.init(patternImage: image )
                    
                }
            }
            return cell
            
        }
        return UICollectionReusableView()
        
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let sectionType = productSectionType(forSection: indexPath.section)

        if sectionType == .product {
            let product = self.productAtIndex(indexPath.item)
            
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? ProductsCollectionViewCell {
                cell.contentView.backgroundColor = collectionView.backgroundColor
                cell.title = product.calculatedDisplayTitle
                cell.price = product.price
                cell.originalPrice = product.originalPrice
                cell.imageUrl = product.imageURL
                cell.isSale = product.isSale()
                cell.favoriteControl.isSelected = product.isFavorite
                cell.favoriteControl.addTarget(self, action: #selector(productCollectionViewCellFavoriteAction(_:event:)), for: .touchUpInside)
                cell.hasBuyLabel = true
                cell.hasExternalPreview = (product.partNumber == nil)
                return cell
            }
        }else if sectionType == .relatedLooks {
            if let relatedLooks = self.relatedLooks?.value, relatedLooks.count > indexPath.row {
                if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "relatedLooks", for: indexPath) as? RelatedLooksCollectionViewCell {
                    let imageString = relatedLooks[indexPath.row]
                    let url = URL.init(string: imageString)
                    
                    cell.imageView.sd_setImage(with: url, completed: nil)
                    cell.flagButton.addTarget(self, action: #selector(pressedFlagButton(_:)), for: .touchUpInside)
                    
                    return cell
                }
            }else if let error = self.relatedLooks?.error {
                if self.isErrorRetryable(error:error) {
                    if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "relatedLooks-error-retry", for: indexPath) as? ErrorRetryableCollectionViewCell {
                        
                        
                        return cell
                    }
                }else{
                    if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "relatedLooks-error-no-retry", for: indexPath) as? ErrorNotRetryableCollectionViewCell {
                        
                        
                        return cell
                    }
                }
            }else {
                //show spinner cell
                if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "relatedLooks-spinner", for: indexPath) as? SpinnerCollectionViewCell{
                    cell.spinner.color = .gray2
                    return cell
                }
                
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
        return true
    }
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let sectionType = productSectionType(forSection: section)

        if sectionType == .product {
            let minimumSpacing:CGPoint = self.collectionViewMinimumSpacing()
            return UIEdgeInsets(top: minimumSpacing.y, left: minimumSpacing.x, bottom: 30, right: minimumSpacing.x)
        }else if sectionType == .relatedLooks {
            if let _  = self.relatedLooks?.value {
                let minimumSpacing:CGPoint = self.collectionViewMinimumSpacing()
                return UIEdgeInsets(top: 0, left: minimumSpacing.x, bottom: 30.0, right: minimumSpacing.x)
            }else if let _ = self.relatedLooks?.error {
                return .zero
            }else { // spinner
                return .zero
            }
        }
        
        return .zero
        
    }
   
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let sectionType = productSectionType(forSection: indexPath.section)

        if sectionType == .product {
            let product = self.productAtIndex(indexPath.item)
            product.recordViewedProduct()
            
            if let productViewController = presentProduct(product, atLocation: .products) {
                productViewController.similarProducts = products
            }
        }else if sectionType == .relatedLooks {
            if let relatedLooks = self.relatedLooks?.value {
                if relatedLooks.count > indexPath.row {
                    let url = relatedLooks[indexPath.row]
                    Analytics.trackScreenshotRelatedLookAdd(url: url)
                    AssetSyncModel.sharedInstance.addFromRelatedLook(urlString: url, callback: { (screenshot) in
                        Analytics.trackOpenedScreenshot(screenshot: screenshot, source: .relatedLooks)
                        let productsViewController = ProductsViewController.init(screenshot: screenshot)
                        self.present(productsViewController, animated: true, completion: {
                            
                        })
                        if screenshot.isNew {
                            screenshot.setViewed()
                        }

                    })
                }
            }
        }
    }
    
    @objc func productCollectionViewCellFavoriteAction(_ favoriteControl: FavoriteControl, event: UIEvent) {
        guard let indexPath = collectionView?.indexPath(for: event) else {
            return
        }
        
        let isFavorited = favoriteControl.isSelected
        let product = self.productAtIndex(indexPath.item)
        
        product.setFavorited(toFavorited: isFavorited)
        if isFavorited {
            Analytics.trackProductFavorited(product: product, page: .productList)
        }else{
            Analytics.trackProductUnfavorited(product: product, page: .productList)
        }
    }
}

private typealias ProductsViewControllerOptionsView = ProductsViewController
extension ProductsViewControllerOptionsView {
    @objc func presentOptions() {
        if filterView.isFirstResponder {
            filterView.resignFirstResponder()
        }
        else {
            Analytics.trackOpenedFiltersView()
            
            if let shoppable = self.shoppablesToolbar?.selectedShoppable() {
                self.productsOptions.syncOptions(withMask: shoppable.getLast())
            }
            filterView.customInputView = self.productsOptions.view
            filterView.becomeFirstResponder()
        }
    }
    
    func dismissOptions() {
        filterView.endEditing(true)
    }
}

private typealias ProductsViewControllerShoppables = ProductsViewController
extension ProductsViewControllerShoppables: FetchedResultsControllerManagerDelegate {
    func managerDidChangeContent(_ controller: NSObject, change: FetchedResultsControllerManagerChange) {
        if controller == self.screenshotController {
            if let screenShot = self.screenshotController?.first {
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
        
        if self.collectionView?.numberOfItems(inSection: ProductsSection.product.section) ?? 0 > 0 {
            self.collectionView?.scrollToItem(at: IndexPath(item: 0, section: ProductsSection.product.section), at: .top, animated: false)
        }
    }
    
    func productsForShoppable(_ shoppable:Shoppable) -> [Product] {
        if let mask = shoppable.getLast()?.rawValue,
          var products = shoppable.products?.filtered(using: NSPredicate(format: "(optionsMask & %d) == %d", mask, mask)) as? Set<Product> {
            self.productsUnfilteredCount = products.count
            if self.productsOptions.sale == .sale {
                products = products.filter { $0.floatPrice < $0.floatOriginalPrice }
            }
            let productArray: [Product]
            switch self.productsOptions.sort {
            case .similar :
                productArray = products.sorted { $0.order < $1.order }
            case .priceAsc :
                productArray = products.sorted { $0.floatPrice < $1.floatPrice }
            case .priceDes :
                productArray = products.sorted(by: { $0.floatPrice > $1.floatPrice })
            case .brands :
                productArray = products.sorted { (a, b) -> Bool in
                    if let aDisplayTitle = a.calculatedDisplayTitle?.lowercased(),
                      let bDisplayTitle = b.calculatedDisplayTitle?.lowercased(),
                      aDisplayTitle != bDisplayTitle {
                        return aDisplayTitle < bDisplayTitle
                    } else if a.calculatedDisplayTitle == nil && b.calculatedDisplayTitle != nil {
                        return false // Empty brands at end
                    } else if a.calculatedDisplayTitle != nil && b.calculatedDisplayTitle == nil {
                        return true // Empty brands at end
                    }
                    return a.order < b.order // Secondary sort
                }
            }
            return productArray
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
    
    @objc func productsRatePositiveAction() {
        if  let shoppable = self.shoppablesToolbar?.selectedShoppable(){
            shoppable.setRating(positive: true)
            
            if self.screenshot.canSubmitToDiscover {
                let sharePrompt = ShareToDiscoverPrompt.init()
                sharePrompt.translatesAutoresizingMaskIntoConstraints = false
                sharePrompt.alpha = 0
                self.view.addSubview(sharePrompt)
                sharePrompt.addButton.addTarget(self, action: #selector(submitToDiscoverAndPresentThankYouForSharingView), for: .touchUpInside)
                sharePrompt.closeButton.addTarget(self, action: #selector(hideShareToDiscoverPrompt), for: .touchUpInside)
                sharePrompt.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
                sharePrompt.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier:0.9).isActive = true
                sharePrompt.bottomAnchor.constraint(equalTo: self.rateView.topAnchor, constant: 0).isActive = true
                self.shareToDiscoverPrompt = sharePrompt
                
                UIView.animate(withDuration: .defaultAnimationDuration, animations: {
                    sharePrompt.alpha = 1
                    self.shamrockButton?.alpha = 0
                })
            }
        }
    }
    
    @objc func productsRateNegativeAction() {
        if  let shoppable = self.shoppablesToolbar?.selectedShoppable(){
            shoppable.setRating(positive: false)
            self.presentProductsRateNegativeAlert()
        }
    }
    
    @objc func talkToYourStylistAction() {
        IntercomHelper.sharedInstance.presentMessagingUI()
    }
    
    func presentPersonalStylist() {
        let shoppable = self.shoppablesToolbar?.selectedShoppable()
        Analytics.trackRequestedCustomStylist(shoppable: shoppable)
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
                    let shoppable = self.shoppablesToolbar?.selectedShoppable()
                    Analytics.trackShoppableFeedbackNegative(shoppable:shoppable , text: trimmedText)
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

typealias ProductsViewControllerShareToDiscoverPrompt = ProductsViewController
extension ProductsViewControllerShareToDiscoverPrompt {
    @objc func hideShareToDiscoverPrompt (){
        UIView.animate(withDuration: .defaultAnimationDuration, animations: {
            self.shareToDiscoverPrompt?.alpha = 0
            self.shamrockButton?.alpha = 1
        }) { completed in
            self.shareToDiscoverPrompt?.removeFromSuperview()
            self.shareToDiscoverPrompt = nil
        }
    }
    
    @objc func submitToDiscoverAndPresentThankYouForSharingView() {
        self.hideShareToDiscoverPrompt()
        
        self.screenshot.submitToDiscover()
        
        let thankYou = ThankYouForSharingViewController()
        thankYou.closeButton.addTarget(self, action: #selector(thankYouForSharingViewDidClose(_:)), for: .touchUpInside)
        self.present(thankYou, animated: true, completion: nil)
    }
    
    @objc func thankYouForSharingViewDidClose(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension ProductsViewController {
    func syncViewsAfterStateChange() {
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
    
    @objc func noItemsRetryAction() {
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

extension ProductsViewController {
    
    @objc fileprivate func pressedFlagButton(_ sender:Any) {
        if let button = sender as? UIView, let collectionView = self.collectionView {
            let rect = collectionView.convert(button.bounds, from: button)
            let point = rect.center
            if let indexpath = collectionView.indexPathForItem(at: point) {
                let sectionType = self.productSectionType(forSection: indexpath.section)
                if sectionType == .relatedLooks {
                    if let relatedLooksArray = self.relatedLooks?.value {
                        if relatedLooksArray.count > indexpath.row {
                            let url = relatedLooksArray[indexpath.row]
                            self.presentReportAlertController(url:url)

                        }
                    }
                }
            }
        }
    }
    fileprivate func presentReportAlertController(url:String) {
        let alertController = UIAlertController(title: "discover.screenshot.flag.title".localized, message: "discover.screenshot.flag.message".localized, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "discover.screenshot.flag.inappropriate".localized, style: .default, handler: { action in
            self.presentInappropriateAlertController(url:url)
        }))
        alertController.addAction(UIAlertAction(title: "discover.screenshot.flag.copyright".localized, style: .default, handler: { action in
            self.presentCopyrightAlertController(url:url)
        }))
        
        alertController.addAction(UIAlertAction(title: "discover.screenshot.flag.duplicate".localized, style: .default, handler: { action in
            self.presentDuplicateAlertController(url:url)
        }))
        alertController.addAction(UIAlertAction(title: "generic.cancel".localized, style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    fileprivate func presentInappropriateAlertController(url:String) {
        let alertController = UIAlertController(title: "discover.screenshot.flag.inappropriate.title".localized, message: "discover.screenshot.flag.inappropriate.message".localized, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "generic.ok".localized, style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
        Analytics.trackScreenshotRelatedLookFlagged(url: url, why: .inappropriate)
    }
    
    fileprivate func presentCopyrightAlertController(url:String) {
        let alertController = UIAlertController(title: "discover.screenshot.flag.copyright.title".localized, message: "discover.screenshot.flag.copyright.message".localized, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "legal.terms_of_service".localized, style: .default, handler: { action in
            self.presentTermsOfServiceViewController()
        }))
        alertController.addAction(UIAlertAction(title: "generic.done".localized, style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
        
        Analytics.trackScreenshotRelatedLookFlagged(url: url, why: .copyright)
    }
    fileprivate func presentDuplicateAlertController(url:String) {
        let alertController = UIAlertController(title: "discover.screenshot.flag.inappropriate.title".localized, message: "discover.screenshot.flag.inappropriate.message".localized, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "generic.ok".localized, style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
        
        Analytics.trackScreenshotRelatedLookFlagged(url: url, why: .duplicate)
    }
    
    fileprivate func presentTermsOfServiceViewController() {
        if let viewController = LegalViewControllerFactory.termsOfServiceViewController() {
            present(viewController, animated: true, completion: nil)
        }
    }
}

extension ProductsViewController {
    @objc func didPresetRetryRelatedLooks(_ sender:Any) {
        self.relatedLooks = nil
        self.loadRelatedLooksIfNeeded()
        let section = self.sectionIndex(forProductType: .relatedLooks)
        self.collectionView?.reloadSections(IndexSet.init(integer: section))
    }
    
    func isErrorRetryable(error:Error) -> Bool {
        return true
    }
}
