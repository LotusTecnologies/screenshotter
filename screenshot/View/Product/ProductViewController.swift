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
    fileprivate var cartBarButtonItem: ProductCartBarButtonItem?
    fileprivate var cartItemFrc: FetchedResultsControllerManager<CartItem>?
    fileprivate var structuredProduct: StructuredProduct?
    fileprivate var didSaveVariants = false
    
    var similarProducts: [Product]? {
        didSet {
            guard var products = similarProducts else {
                return
            }
            
            if let structuredProduct = structuredProduct,
                let productIndex = products.index(of: structuredProduct.product)
            {
                products.remove(at: productIndex)
            }
            
            productView.setSimilarProducts(products)
            productView.similarProductsCollectionView?.delegate = self
        }
    }
    
    // MARK: Views
    
    fileprivate var productView: ProductView {
        return view as! ProductView
    }
    
    override func loadView() {
        let productView = ProductView()
        productView.selectionControl.addTarget(self, action: #selector(selectionButtonTouchUpInside), for: .touchUpInside)
        productView.selectionControl.addTarget(self, action: #selector(selectionButtonValueChanged), for: .valueChanged)
        productView.cartButton.addTarget(self, action: #selector(cartButtonAction), for: .touchUpInside)
//            productView.buyButton.addTarget(self, action: #selector(buyButtonAction), for: .touchUpInside)
        productView.favoriteButton.addTarget(self, action: #selector(favoriteAction), for: .touchUpInside)
        productView.websiteButton.addTarget(self, action: #selector(pushWebsiteURL), for: .touchUpInside)
        view = productView
    }
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init(productOID: NSManagedObjectID) {
        super.init(nibName: nil, bundle: nil)
        
        ShoppingCartModel.shared.populateVariants(productOID: productOID)
            .then { [weak self] product, didSaveVariants -> Void in
                self?.didSaveVariants = didSaveVariants
                
                if didSaveVariants {
                    self?.setup(with: product)
                }
            }
            .catch { [weak self] error in
                self?.productView.setUnavailableImageViewAlpha(1)
        }
        
        cartItemFrc = DataModel.sharedInstance.cartItemFrc(delegate: self)
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: nil, style: .plain, target: nil, action: nil)
        
        cartBarButtonItem = ProductCartBarButtonItem(target: self, action: #selector(presentCart))
        navigationItem.rightBarButtonItem = cartBarButtonItem
    }
    
    convenience init(product: Product) {
        self.init(productOID: product.objectID)
        title = product.displayTitle
        setup(with: product)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        syncCartItemCount()
    }
    
    func setup(with product: Product) {
        structuredProduct = StructuredProduct(product)
        applyStructuredProductIfPossible()
    }
}

typealias ProductViewControllerProductView = ProductViewController
fileprivate extension ProductViewControllerProductView {
    // MARK: Labels
    
    func setOriginalPrice(_ price: String?) {
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
        // ???: need analytics here
    }
    
    @objc func selectionButtonValueChanged() {
        guard let selectedItem = productView.selectionControl.selectedItem else {
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
            
            presentNextStep()
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
                    self.productView.scrollView.contentOffset = CGPoint(x: 0, y: minOffsetY - adjustedContentInsetTop - .padding)
                    
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
    
    fileprivate func presentNextStep() {
        let nextStepViewController = ProductNextStepViewController()
        nextStepViewController.cartButton.addTarget(self, action: #selector(presentCart), for: .touchUpInside)
        nextStepViewController.continueButton.addTarget(self, action: #selector(dismissNextStep), for: .touchUpInside)
        present(nextStepViewController, animated: true, completion: nil)
    }
    
    @objc fileprivate func dismissNextStep() {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: Favorite
    
    @objc func favoriteAction() {
        guard let product = structuredProduct?.product else {
            return
        }
        
        let isFavorited = productView.favoriteButton.isSelected
        product.setFavorited(toFavorited: isFavorited)

        AnalyticsTrackers.standard.trackFavorited(isFavorited, product: product, onPage: "Product")
    }
    
    // MARK: Web
    
    func setWebsiteMerchant(_ merchant: String?) {
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
    
    @objc func pushWebsiteURL() {
        let url: String?
        
        if let variantUrl = selectedVariant()?.url {
            url = variantUrl
        }
        else {
            url = structuredProduct?.product.offer
        }
        
        OpenWebPage.present(urlString: url, fromViewController: self)
    }
}

extension ProductViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == productView.similarProductsCollectionView {
            guard let products = productView.similarProductsCollectionView?.products,
                products.count > indexPath.item
                else {
                    return
            }
            
            if let productViewController = presentProduct(products[indexPath.item], atLocation: .productSimilar) {
                productViewController.similarProducts = products
                
                let rootItem = UIBarButtonItem(image: UIImage(named: "NavigationBarDoubleArrow"), style: .plain, target: self, action: #selector(navigateToProductsViewController))
                
                let backItem = UIBarButtonItem(image: UIImage(named: "NavigationBarArrow"), style: .plain, target: self, action: #selector(navigateToPreviousViewController))
                
                productViewController.navigationItem.leftBarButtonItems = [rootItem, backItem]
            }
        }
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
            productView.setGalleryImages(urls: imageURLs, selectedURL: imageURL)
        }
        
        if didSaveVariants {
            // Prevent a jarring UX by showing this only once we have confirmed data
            productView.setUnavailableImageViewAlpha(structuredProduct.isAvailable ? 0 : 1)
        }
        
        productView.titleLabel.text = product.productTitle()
        productView.priceLabel.text = product.price
        productView.contentTextView.text = product.detailedDescription
        productView.favoriteButton.isSelected = structuredProduct.product.isFavorite
        
        setWebsiteMerchant(product.merchant)
        
        if product.isSale() {
            setOriginalPrice(product.originalPrice)
        }
        
        if let colors = structuredProduct.colors {
            let selectedColor = product.color ?? (colors.count == 1 ? colors.first : nil)
            let colorItem = SegmentedDropDownItem(pickerItems: colors, selectedPickerItem: selectedColor)
            var sizeItem: SegmentedDropDownItem?
            
            if let sizes = structuredProduct.sizes {
                sizeItem = SegmentedDropDownItem(pickerItems: sizes)
                
                if colorItem.selectedPickerItem == nil {
                    // Disabled until color is selected
                    sizeItem?.disabledPickerItems = structuredProduct.sizes
                }
                else if let structuredColorVariant = structuredProduct.structuredColorVariant(forColor: selectedColor) {
                    sizeItem?.disabledPickerItems = structuredProduct.subtractingSizes(of: structuredColorVariant)
                }
            }
            
            productView.setSelection(colorItem: colorItem, sizeItem: sizeItem)
        }
    }
    
    func selectedVariant() -> Variant? {
        let color = productView.selectionColorItem?.selectedPickerItem
        let size = productView.selectionSizeItem?.selectedPickerItem
        return structuredProduct?.variant(forColor: color, size: size)
    }
}

typealias ProductViewControllerCart = ProductViewController
fileprivate extension ProductViewControllerCart {
    @objc func presentCart() {
        if presentedViewController != nil {
            dismiss(animated: true, completion: nil)
        }
        
        let navigationController = ModalNavigationController(rootViewController: CartViewController())
        present(navigationController, animated: true, completion: nil)
    }
    
    func syncCartItemCount() {
        cartBarButtonItem?.count = UInt(cartItemFrc?.fetchedObjectsCount ?? 0)
    }
}

extension ProductViewController: FetchedResultsControllerManagerDelegate {
    func managerDidChangeContent(_ controller: NSObject, change: FetchedResultsControllerManagerChange) {
        syncCartItemCount()
    }
}

typealias ProductViewControllerNavigation = ProductViewController
extension ProductViewControllerNavigation {
    @objc fileprivate func navigateToPreviousViewController() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc fileprivate func navigateToProductsViewController() {
        guard let navigationController = navigationController else {
            return
        }
        
        for viewController in navigationController.viewControllers {
            if let productsViewController = viewController as? ProductsViewController {
                navigationController.popToViewController(productsViewController, animated: true)
                return
            }
        }
        
        navigationController.popToRootViewController(animated: true)
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
        
        guard let variants = product.availableVariants?.allObjects as? [Variant], !variants.isEmpty else {
            return
        }
        
        isAvailable = true
        
        var structuredColorVariantsDict: [String : StructuredColorVariant] = [:]
        var colors: Set<String> = Set()
        var sizes: Set<String> = Set()
        var imageURLDict: [String: URL] = [:]
        
        for variant in variants {
            guard let color = variant.color,
                !hasDuplicateVariantAsNA(variants: variants, currentVariant: variant)
                else {
                    continue
            }
            
            colors.insert(color)
            let structuredColorVariant = structuredColorVariantsDict[color] ?? StructuredColorVariant(color: color)
            
            structuredColorVariant.variantSet.insert(variant)
            
            if let size = variant.size {
                sizes.insert(size)
                structuredColorVariant.sizeSet.insert(size)
            }
            
            structuredColorVariantsDict[color] = structuredColorVariant
            
            if imageURLDict[color] == nil, let imageURL = variant.parsedImageURLs().first {
                imageURLDict[color] = imageURL
            }
        }
        
        if !structuredColorVariantsDict.isEmpty {
            structuredColorVariants = Array(structuredColorVariantsDict.values)
        }
        
        if !colors.isEmpty {
            self.colors = colors.sorted()
        }
        
        if !sizes.isEmpty {
            let sortedSizes = ["X-Small", "Small", "Medium", "Large", "X-Large"]
            
            self.sizes = sizes.sorted(by: { (a, b) -> Bool in
                let aIndex = (sortedSizes.index(of: a) ?? Int.max)
                let bIndex = (sortedSizes.index(of: b) ?? Int.max)
                
                if aIndex == Int.max && bIndex == Int.max {
                    return a.localizedStandardCompare(b) == .orderedAscending
                }
                
                return aIndex < bIndex
            })
        }
        
        if !imageURLDict.isEmpty {
            self.imageURLDict = imageURLDict
        }
    }
    
    // MARK: Variant
    
    /// If a variant color is NA, check if it's image exists in another variant
    private func hasDuplicateVariantAsNA(variants: [Variant], currentVariant: Variant) -> Bool {
        guard let currentColor = currentVariant.color else {
            return false
        }
        
        var hasDuplicateVariantAsNA = false
        
        func isColorNA(_ color: String) -> Bool {
            return ["N/A", "NA"].contains(color.uppercased())
        }
        
        if isColorNA(currentColor), let imageURL = currentVariant.parsedImageURLs().first {
            for variant in variants {
                guard let color2 = variant.color, !isColorNA(color2) else {
                    continue
                }
                
                if variant.parsedImageURLs().first == imageURL {
                    hasDuplicateVariantAsNA = true
                    break
                }
            }
        }
        
        return hasDuplicateVariantAsNA
    }
    
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
