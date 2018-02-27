//
//  ProductViewController.swift
//  screenshot
//
//  Created by Corey Werner on 1/25/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit
import SDWebImage
import CoreData

class ProductViewController : BaseViewController {
    enum State {
        case loading
        case product
        case empty
    }
    
    fileprivate var productView: ProductView?
    fileprivate var selectionColorItem: SegmentedDropDownItem?
    fileprivate var selectionSizeItem: SegmentedDropDownItem?
    fileprivate var productEmptyView: UIView?
    fileprivate var loadingView: Loader?
    
    fileprivate var structuredProduct: StructuredProduct?
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init(productOID: NSManagedObjectID) {
        super.init(nibName: nil, bundle: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide(_:)), name: .UIKeyboardDidHide, object: nil)
        
        ShoppingCartModel.shared.populateVariants(productOID: productOID)
            .then { product -> Void in
                self.state = .product
                self.structuredProduct = StructuredProduct(product)
                self.applyStructuredProductIfPossible()
            }
            .catch { error in
                self.state = .empty
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        syncState()
    }
    
    @objc fileprivate func keyboardDidHide(_ notification: Notification) {
        if view.window != nil {
            // The scroll views keyboard dismiss mode can hide the input
            // view without resigning the button. Make sure the buttons
            // stay synced.
            view.endEditing(true)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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
            productView.selectionButton.addTarget(self, action: #selector(selectionButtonTouchUpInside), for: .touchUpInside)
            productView.selectionButton.addTarget(self, action: #selector(selectionButtonValueChanged), for: .valueChanged)
            productView.galleryScrollView.delegate = self
            productView.pageControl.addTarget(self, action: #selector(pageControlDidChange), for: .valueChanged)
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
    // MARK: Gallery
    
    func setImages(urls: [URL]) {
        guard let productView = productView else {
            return
        }
        
        productView.galleryScrollContentView.subviews.forEach { subview in
            subview.removeFromSuperview()
        }
        
        productView.pageControl.numberOfPages = urls.count
        productView.pageControl.currentPage = 0
        
        urls.enumerated().forEach { (index: Int, url: URL) in
            let previousImageView = productView.galleryScrollContentView.subviews.last
            
            let imageView = UIImageView()
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.contentMode = .scaleAspectFit
            imageView.backgroundColor = .white
            productView.galleryScrollContentView.addSubview(imageView)
            imageView.topAnchor.constraint(equalTo: productView.galleryScrollContentView.topAnchor).isActive = true
            imageView.bottomAnchor.constraint(equalTo: productView.galleryScrollContentView.bottomAnchor).isActive = true
            imageView.widthAnchor.constraint(equalToConstant: view.bounds.width).isActive = true
            
            if index == 0 {
                imageView.leadingAnchor.constraint(equalTo: productView.galleryScrollContentView.leadingAnchor).isActive = true
            }
            else {
                if let previousImageView = previousImageView {
                    imageView.leadingAnchor.constraint(equalTo: previousImageView.trailingAnchor).isActive = true
                }
            }
            
            if index == urls.count - 1 {
                imageView.trailingAnchor.constraint(equalTo: productView.galleryScrollContentView.trailingAnchor).isActive = true
            }
            
            imageView.sd_setImage(with: url, completed: nil)
        }
    }
    
    @objc func pageControlDidChange() {
        guard let productView = productView else {
            return
        }
        
        var point: CGPoint = .zero
        point.x = productView.galleryScrollView.bounds.width * CGFloat(productView.pageControl.currentPage)
        productView.galleryScrollView.setContentOffset(point, animated: true)
    }
    
    var currentPage: Int {
        guard let productView = productView else {
            return 0
        }
        
        return Int(productView.galleryScrollView.contentOffset.x / productView.galleryScrollView.bounds.width)
    }
    
    // MARK: Labels
    
    func setProductTitle(_ title: String?) {
        guard let productView = productView else {
            return
        }
        
        productView.titleLabel.text = title
    }
    
    func setProductDescription(_ description: String?) {
        guard let productView = productView else {
            return
        }
        
        productView.contentTextView.text = title
    }
    
    func setPrice(_ price: String?) {
        guard let productView = productView else {
            return
        }
        
        productView.priceLabel.text = price
    }
    
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
    
    // MARK: Actions
    
    @objc func selectionButtonTouchUpInside() {
//        guard let productView = productView else {
//            return
//        }
        
        // ???: need analytics here
    }
    
    @objc func selectionButtonValueChanged() {
        guard let productView = productView, let selectedItem = productView.selectionButton.selectedItem else {
            return
        }
        
        selectedItem.resetBorderColor()
        
        if selectedItem == selectionColorItem {
            guard let variant = structuredProduct?.variant(forColor: selectedItem.title) else {
                return
            }
            
            selectionSizeItem?.disabledPickerItems = structuredProduct?.subtractingSizes(of: variant)
        }
    }
    
    @objc func cartButtonAction() {
        guard let productView = productView else {
            return
        }
        
        var errorItems: [SegmentedDropDownItem] = []
        
        productView.selectionButton.items.forEach { item in
            if item.placeholderTitle == item.title {
                errorItems.append(item)
            }
        }
        
        if errorItems.isEmpty {
            // TODO: do stuff
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
            let minOffsetY = productView.selectionButton.frame.minY
            
            if currentOffsetY > minOffsetY {
                UIView.animate(withDuration: Constants.defaultAnimationDuration, animations: {
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
        //        guard let productView = productView else {
        //            return
        //        }
        
        // TODO:
    }
    
    @objc func pushMerchantURL() {
        //        guard let productView = productView else {
        //            return
        //        }
        
        // TODO:
    }
}

typealias ProductViewControllerStructuredProduct = ProductViewController
fileprivate extension ProductViewControllerStructuredProduct {
    func applyStructuredProductIfPossible() {
        guard let structuredProduct = structuredProduct else {
            return
        }
        
        print("||| \(structuredProduct.product)")
        
        setProductTitle(structuredProduct.title)
        setProductDescription(structuredProduct.title) // TODO:
        setImages(urls: structuredProduct.product.imageURLs())
        setWebsiteMerchant(structuredProduct.product.merchant)
        setPrice(structuredProduct.product.price)
        
        if structuredProduct.product.isSale() {
            setOriginalPrice(structuredProduct.product.originalPrice)
        }
        
        let colorItem = SegmentedDropDownItem(pickerItems: structuredProduct.colors)
        selectionColorItem = colorItem
        
        var sizeItem: SegmentedDropDownItem? = nil
        
        if !structuredProduct.sizes.isEmpty {
            sizeItem = SegmentedDropDownItem(pickerItems: structuredProduct.sizes)
            sizeItem?.disabledPickerItems = structuredProduct.sizes // Disabled until color is selected
            selectionSizeItem = sizeItem
        }
        
        productView?.setSelection(colorItem: colorItem, sizeItem: sizeItem)
        
        repositionScrollView()
    }
}

extension ProductViewController : UIScrollViewDelegate {
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard let productView = productView else {
            return
        }
        
        if scrollView == productView.galleryScrollView {
            if !decelerate {
                productView.pageControl.currentPage = currentPage
            }
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard let productView = productView else {
            return
        }
        
        if scrollView == productView.galleryScrollView {
            productView.pageControl.currentPage = currentPage
        }
    }
    
    fileprivate func repositionScrollView() {
        guard let productView = productView else {
            return
        }
        
        view.layoutIfNeeded()
        
        let y: CGFloat = {
            if #available(iOS 11.0, *) {
                return productView.scrollView.adjustedContentInset.top
            }
            else {
                return navigationController?.navigationBar.frame.maxY ?? 0
            }
        }()
        
        productView.scrollView.contentOffset = CGPoint(x: 0, y: -y)
    }
}

extension ProductViewController {
    fileprivate class StructuredProduct: NSObject {
        let product: Product
        private(set) var title: String?
        private(set) var variants: [StructuredVariant] = []
        private(set) var colors: [String] = []
        private(set) var sizes: [String] = []
        
        init(_ product: Product) {
            self.product = product
            super.init()
            
            self.title = generateTitle(product)
            
            guard let variants = product.availableVariants?.allObjects as? [Variant] else {
                return
            }
            
            var placeholders: [String : StructuredVariantPlaceholder] = [:]
            var colors: Set<String> = Set()
            var sizes: Set<String> = Set()
            
            variants.forEach({ variant in
                guard let color = variant.color else {
                    return
                }
                
                colors.insert(color)
                let placeholder = placeholders[color] ?? StructuredVariantPlaceholder(color: color)
                
                if let size = variant.size {
                    placeholder.sizes.insert(size)
                    sizes.insert(size)
                }
                
                placeholders[color] = placeholder
            })
            
            let sortedSizes = ["X-Small", "Small", "Medium", "Large", "X-Large"]
            var structuredVariants: [StructuredVariant] = []
            
            placeholders.forEach { (color: String, placeholder: StructuredVariantPlaceholder) in
                let color = placeholder.color
                let sizes = Array(placeholder.sizes)
                structuredVariants.append(StructuredVariant(color: color, sizes: sizes))
            }
            
            self.variants = structuredVariants
            self.colors = colors.sorted()
            self.sizes = sizes.sorted(by: { (a, b) -> Bool in
                // TODO: number size should be sorted
                return (sortedSizes.index(of: a) ?? Int.max) < (sortedSizes.index(of: b) ?? Int.max)
            })
        }
        
        func generateTitle(_ product: Product) -> String? {
            return product.productDescription?.split(separator: ",").dropLast().joined(separator: ",")
        }
        
        func variant(forColor color: String?) -> StructuredVariant? {
            return variants.first { variant -> Bool in
                return variant.color == color
            }
        }
        
        func subtractingSizes(of variant: StructuredVariant) -> [String] {
            return Array(Set(sizes).subtracting(variant.sizes))
        }
    }
    
    private class StructuredVariantPlaceholder: NSObject {
        let color: String
        var sizes: Set<String> = Set()
        
        init(color: String) {
            self.color = color
            super.init()
        }
    }
    
    fileprivate struct StructuredVariant {
        let color: String
        let sizes: [String]
    }
}
