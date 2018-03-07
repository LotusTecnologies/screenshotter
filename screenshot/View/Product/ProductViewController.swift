//
//  ProductViewController.swift
//  screenshot
//
//  Created by Corey Werner on 1/25/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit
import CoreData

class ProductViewController : BaseViewController {
    enum State {
        case loading
        case product
        case empty
    }
    
    fileprivate var cartBarButtonItem: ProductCartBarButtonItem?
    fileprivate var productView: ProductView?
    fileprivate var productEmptyView: UIView?
    fileprivate var loadingView: Loader?
    
    fileprivate var cartItemFrc: FetchedResultsControllerManager<CartItem>?
    fileprivate var structuredProduct: StructuredProduct?
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init(productOID: NSManagedObjectID) {
        super.init(nibName: nil, bundle: nil)
        
        ShoppingCartModel.shared.populateVariants(productOID: productOID)
            .then { product -> Void in
                self.state = .product
                self.structuredProduct = StructuredProduct(product)
                self.applyStructuredProductIfPossible()
            }
            .catch { error in
                self.state = .empty
        }
        
        cartItemFrc = DataModel.sharedInstance.cartItemFrc(delegate: self)
        
        cartBarButtonItem = ProductCartBarButtonItem(target: self, action: #selector(presentCart))
        navigationItem.rightBarButtonItem = cartBarButtonItem
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        syncState()
        syncCartItemCount()
    }
    
    // MARK: State
    
    fileprivate var state: ProductViewController.State = .loading {
        didSet {
            if isViewLoaded {
                syncState()
            }
        }
    }
    
    fileprivate func syncState() {
        switch state {
        case .empty:
            guard self.productEmptyView == nil else {
                return
            }
            
            loadingView?.removeFromSuperview()
            loadingView = nil
            productView?.removeFromSuperview()
            productView = nil
            
            let productEmptyView = UIView()
            productEmptyView.translatesAutoresizingMaskIntoConstraints = false
            productEmptyView.backgroundColor = .orange
            view.addSubview(productEmptyView)
            productEmptyView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
            productEmptyView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            productEmptyView.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor).isActive = true
            productEmptyView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
            self.productEmptyView = productEmptyView
            
        case .loading:
            guard self.loadingView == nil else {
                return
            }
            
            productView?.removeFromSuperview()
            productView = nil
            productEmptyView?.removeFromSuperview()
            productEmptyView = nil
            
            let loadingView = Loader()
            loadingView.translatesAutoresizingMaskIntoConstraints = false
            loadingView.startAnimation()
            view.addSubview(loadingView)
            loadingView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
            loadingView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
            self.loadingView = loadingView
            
        case .product:
            guard self.productView == nil else {
                return
            }
            
            loadingView?.removeFromSuperview()
            loadingView = nil
            productEmptyView?.removeFromSuperview()
            productEmptyView = nil
            
            let productView = ProductView()
            productView.translatesAutoresizingMaskIntoConstraints = false
            productView.scrollView.delegate = self
            productView.selectionControl.addTarget(self, action: #selector(selectionButtonTouchUpInside), for: .touchUpInside)
            productView.selectionControl.addTarget(self, action: #selector(selectionButtonValueChanged), for: .valueChanged)
            productView.cartButton.addTarget(self, action: #selector(cartButtonAction), for: .touchUpInside)
//            productView.buyButton.addTarget(self, action: #selector(buyButtonAction), for: .touchUpInside)
            productView.websiteButton.addTarget(self, action: #selector(pushMerchantURL), for: .touchUpInside)
            view.addSubview(productView)
            productView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            productView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            productView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            productView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
            self.productView = productView
        }
    }
}

typealias ProductViewControllerProductView = ProductViewController
fileprivate extension ProductViewControllerProductView {
    // MARK: Labels
    
    func setOriginalPrice(_ price: String?) {
        guard let productView = productView else {
            return
        }
        
        if let text = price {
            productView.priceLabel.textColor = .crazeRed
            productView.originalPriceLabel.attributedText = NSAttributedString(string: text, attributes: [
                NSStrikethroughStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue,
                NSStrikethroughColorAttributeName: productView.originalPriceLabel.textColor
                ])
        }
        else {
            productView.priceLabel.textColor = .gray3
            productView.originalPriceLabel.text = price
        }
    }
    
    // MARK: Selection
    
    @objc func selectionButtonTouchUpInside() {
//        guard let productView = productView else {
//            return
//        }
        
        // ???: need analytics here
    }
    
    @objc func selectionButtonValueChanged() {
        guard let productView = productView, let selectedItem = productView.selectionControl.selectedItem else {
            return
        }
        
        selectedItem.resetBorderColor()
        
        if selectedItem == productView.selectionColorItem {
            guard let structuredColorVariant = structuredProduct?.structuredColorVariant(forColor: selectedItem.selectedPickerItem) else {
                return
            }
            
            productView.selectionSizeItem?.disabledPickerItems = structuredProduct?.subtractingSizes(of: structuredColorVariant)
            
            if let imageURL = structuredProduct?.imageURL(forColor: structuredColorVariant.color) {
                productView.scrollGalleryImages(toURL: imageURL)
            }
        }
    }
    
    // MARK: Cart
    
    @objc func cartButtonAction() {
        guard let productView = productView else {
            return
        }
        
        var errorItems: [SegmentedDropDownItem] = []
        
        productView.selectionControl.items.forEach { item in
            if item.selectedPickerItem == nil {
                errorItems.append(item)
            }
        }
        
        if errorItems.isEmpty {
            guard let variant = selectedVariant() else {
                return
            }
            
            let quantity = max(1, Int(productView.selectionQuantityItem?.selectedPickerItem ?? "") ?? 1)
            
            ShoppingCartModel.shared.update(variant: variant, quantity: Int16(quantity))
        }
        else {
            func displayErrorItems() {
                errorItems.forEach { item in
                    item.setBorderErrorColor()
                }
            }
            
            let adjustedContentInsetTop: CGFloat
            
            if #available(iOS 11.0, *) {
                adjustedContentInsetTop = productView.scrollView.adjustedContentInset.top
            }
            else {
                adjustedContentInsetTop = topLayoutGuide.length
            }
            
            let currentOffsetY = productView.scrollView.contentOffset.y + adjustedContentInsetTop
            let minOffsetY = productView.selectionControl.frame.minY
            
            if currentOffsetY > minOffsetY {
                UIView.animate(withDuration: .defaultAnimationDuration, animations: {
                    productView.scrollView.contentOffset = CGPoint(x: 0, y: minOffsetY - adjustedContentInsetTop - .padding)
                    
                }, completion: { completed in
                    displayErrorItems()
                })
            }
            else {
                displayErrorItems()
            }
        }
    }
    
    @objc func buyButtonAction() {
        // TODO:
    }
    
    // MARK: Web
    
    func setWebsiteMerchant(_ merchant: String?) {
        guard let productView = productView else {
            return
        }
        
        if let name = merchant, !name.isEmpty {
            let color = productView.websiteButton.titleColor(for: .normal) ?? .crazeGreen
            
            let title = NSAttributedString(string: "product.website".localized(withFormat: name), attributes: [
                NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue,
                NSUnderlineColorAttributeName: color,
                NSForegroundColorAttributeName: color,
                NSFontAttributeName: UIFont.systemFont(ofSize: UIFont.buttonFontSize, weight: UIFontWeightBold)
                ])
            
            productView.websiteButton.setAttributedTitle(title, for: .normal)
            productView.websiteButton.isHidden = false
        }
        else {
            productView.websiteButton.setTitle(nil, for: .normal)
            productView.websiteButton.isHidden = true
        }
    }
    
    @objc func pushMerchantURL() {
        let url: String?
        
        if let variantUrl = selectedVariant()?.url {
            url = variantUrl
        }
        else {
            url = structuredProduct?.product.url
        }
        
        OpenWebPage.present(urlString: url, fromViewController: self)
    }
}

typealias ProductViewControllerStructuredProduct = ProductViewController
fileprivate extension ProductViewControllerStructuredProduct {
    func applyStructuredProductIfPossible() {
        guard let structuredProduct = structuredProduct else {
            return
        }
        
        let product = structuredProduct.product
        
        let imageURLs: [URL]? = {
            if let structuredProductImageURLs = structuredProduct.imageURLs {
                return structuredProductImageURLs
            }
            else if let productImageURL = URL(string: product.imageURL ?? "") {
                return [productImageURL]
            }
            else {
                return nil
            }
        }()
        
        if let imageURLs = imageURLs {
            let imageURL = structuredProduct.imageURL(forColor: product.color)
            productView?.setGalleryImages(urls: imageURLs, selectedURL: imageURL)
        }
        
        productView?.unavailableImageView.isHidden = structuredProduct.isAvailable
        productView?.titleLabel.text = product.productTitle()
        productView?.priceLabel.text = product.price
        productView?.contentTextView.text = product.detailedDescription
        
        setWebsiteMerchant(product.merchant)
        
        if product.isSale() {
            setOriginalPrice(product.originalPrice)
        }
        
        if let colors = structuredProduct.colors {
            let colorItem = SegmentedDropDownItem(pickerItems: colors, selectedPickerItem: product.color)
            var sizeItem: SegmentedDropDownItem?
            
            if let sizes = structuredProduct.sizes {
                sizeItem = SegmentedDropDownItem(pickerItems: sizes)
                
                if colorItem.selectedPickerItem == nil {
                    // Disabled until color is selected
                    sizeItem?.disabledPickerItems = structuredProduct.sizes
                }
            }
            
            productView?.setSelection(colorItem: colorItem, sizeItem: sizeItem)
        }
        
        repositionScrollView()
    }
    
    func selectedVariant() -> Variant? {
        let color = productView?.selectionColorItem?.selectedPickerItem
        let size = productView?.selectionSizeItem?.selectedPickerItem
        return structuredProduct?.variant(forColor: color, size: size)
    }
}

typealias ProductViewControllerCart = ProductViewController
fileprivate extension ProductViewControllerCart {
    @objc func presentCart() {
        let navigationController = ModalNavigationController(rootViewController: CartViewController())
        present(navigationController, animated: true, completion: nil)
    }
    
    func syncCartItemCount() {
        cartBarButtonItem?.count = UInt(cartItemFrc?.fetchedObjectsCount ?? 0)
    }
}

extension ProductViewController : UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if scrollView.keyboardDismissMode == .onDrag {
            productView?.resignSelectionControl()
        }
    }
    
    fileprivate func repositionScrollView() {
        view.layoutIfNeeded()
        
        let y: CGFloat = {
            if #available(iOS 11.0, *) {
                return productView?.scrollView.adjustedContentInset.top ?? 0
            }
            else {
                return navigationController?.navigationBar.frame.maxY ?? 0
            }
        }()
        
        productView?.scrollView.contentOffset = CGPoint(x: 0, y: -y)
    }
}

extension ProductViewController: FetchedResultsControllerManagerDelegate {
    func managerDidChangeContent(_ controller: NSObject, change: FetchedResultsControllerManagerChange) {
        syncCartItemCount()
    }
}

fileprivate class StructuredProduct: NSObject {
    let product: Product
    private(set) var structuredColorVariants: [StructuredColorVariant]?
    private(set) var colors: [String]?
    private(set) var sizes: [String]?
    private(set) var isAvailable = false
    
    init(_ product: Product) {
        self.product = product
        super.init()
        
        guard let variants = product.availableVariants?.allObjects as? [Variant] else {
            return
        }
        
        isAvailable = true
        
        var structuredColorVariantsDict: [String : StructuredColorVariant] = [:]
        var colors: Set<String> = Set()
        var sizes: Set<String> = Set()
        imageURLDict = [:]
        
        variants.forEach { variant in
            guard let color = variant.color else {
                return
            }
            
            // TODO: if the color is NA and the image url already exists in a variant with a real color, remove the na variant
//            if ["N/A", "NA"].contains(color.uppercased()) {
//                variant.parsedImageURLs().first
//            }
            
            colors.insert(color)
            let structuredColorVariant = structuredColorVariantsDict[color] ?? StructuredColorVariant(color: color)
            
            structuredColorVariant.variantSet.insert(variant)
            
            if let size = variant.size {
                sizes.insert(size)
                structuredColorVariant.sizeSet.insert(size)
            }
            
            structuredColorVariantsDict[color] = structuredColorVariant
            
            if imageURLDict?[color] == nil, let imageURL = variant.parsedImageURLs().first {
                imageURLDict?[color] = imageURL
            }
        }
        
        structuredColorVariants = Array(structuredColorVariantsDict.values)
        
        let sortedSizes = ["X-Small", "Small", "Medium", "Large", "X-Large"]
        
        self.colors = colors.sorted()
        self.sizes = sizes.sorted(by: { (a, b) -> Bool in
            let aIndex = (sortedSizes.index(of: a) ?? Int.max)
            let bIndex = (sortedSizes.index(of: b) ?? Int.max)
            
            if aIndex == Int.max && bIndex == Int.max {
                return a.localizedStandardCompare(b) == .orderedAscending
            }
            
            return aIndex < bIndex
        })
    }
    
    // MARK: Variant
    
    func structuredColorVariant(forColor color: String?) -> StructuredColorVariant? {
        return structuredColorVariants?.first { structuredColorVariant -> Bool in
            return structuredColorVariant.color == color
        }
    }
    
    func variant(forColor color: String?, size: String?) -> Variant? {
        return structuredColorVariant(forColor: color)?.variant(forSize: size)
    }
    
    func subtractingSizes(of structuredColorVariant: StructuredColorVariant) -> [String] {
        return Array(Set(sizes ?? []).subtracting(structuredColorVariant.sizes))
    }
    
    // MARK: Image
    
    private var imageURLDict: [String: URL]?
    
    func imageURL(forColor color: String?) -> URL? {
        return imageURLDict?[color ?? ""]
    }
    
    var imageURLs: [URL]? {
        return imageURLDict?.sorted { $0.key < $1.key }.map { $0.value }
    }
}

fileprivate class StructuredColorVariant: NSObject {
    let color: String?
    
    fileprivate var sizeSet: Set<String> = Set()
    var sizes: [String] {
        return Array(sizeSet)
    }
    
    fileprivate var variantSet: Set<Variant> = Set()
    var variants: [Variant] {
        return Array(variantSet)
    }
    
    init(color: String?) {
        self.color = color
        super.init()
    }
    
    func variant(forSize size: String?) -> Variant? {
        return variants.first { variant -> Bool in
            return variant.size == size
        }
    }
}
