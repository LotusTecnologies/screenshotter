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


class ProductView: UIScrollView {
    let galleryScrollView = UIScrollView()
    let galleryScrollContentView = UIView()
    let pageControl = UIPageControl()
    
    let titleLabel = UILabel()
    let priceLabel = UILabel()
    let originalPriceLabel = UILabel()
    
    let selectionButton = SegmentedDropDownButton()
    let cartButton = MainButton()
    let buyButton = MainButton()
    let websiteButton = UIButton()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
        layoutMargins = UIEdgeInsets(top: .padding, left: .padding, bottom: .padding, right: .padding)
        keyboardDismissMode = .onDrag
        
        galleryScrollView.translatesAutoresizingMaskIntoConstraints = false
        galleryScrollView.scrollsToTop = false
        galleryScrollView.isPagingEnabled = true
        galleryScrollView.showsHorizontalScrollIndicator = false
        galleryScrollView.bounces = false
        addSubview(galleryScrollView)
        galleryScrollView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        galleryScrollView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        galleryScrollView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        galleryScrollView.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        galleryScrollView.heightAnchor.constraint(equalToConstant: 370).isActive = true
        
        galleryScrollContentView.translatesAutoresizingMaskIntoConstraints = false
        galleryScrollView.addSubview(galleryScrollContentView)
        galleryScrollContentView.topAnchor.constraint(equalTo: galleryScrollView.topAnchor).isActive = true
        galleryScrollContentView.leadingAnchor.constraint(equalTo: galleryScrollView.leadingAnchor).isActive = true
        galleryScrollContentView.bottomAnchor.constraint(equalTo: galleryScrollView.bottomAnchor).isActive = true
        galleryScrollContentView.trailingAnchor.constraint(equalTo: galleryScrollView.trailingAnchor).isActive = true
        galleryScrollContentView.heightAnchor.constraint(equalTo: galleryScrollView.heightAnchor).isActive = true
        
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.hidesForSinglePage = true
        pageControl.pageIndicatorTintColor = UIColor.black.withAlphaComponent(0.5)
        pageControl.currentPageIndicatorTintColor = .crazeGreen
        addSubview(pageControl)
        pageControl.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .padding).isActive = true
        pageControl.bottomAnchor.constraint(equalTo: galleryScrollView.bottomAnchor).isActive = true
        pageControl.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.padding).isActive = true
        pageControl.centerXAnchor.constraint(equalTo: galleryScrollView.centerXAnchor).isActive = true
        
        let labelContainerView = UIView()
        labelContainerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(labelContainerView)
        labelContainerView.topAnchor.constraint(equalTo: galleryScrollView.bottomAnchor, constant: .padding).isActive = true
        labelContainerView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        labelContainerView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        priceLabel.font = UIFont.preferredFont(forTextStyle: .title1)
        priceLabel.textColor = .gray3
        priceLabel.adjustsFontForContentSizeCategory = true
        labelContainerView.addSubview(priceLabel)
        priceLabel.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
        priceLabel.topAnchor.constraint(equalTo: labelContainerView.topAnchor).isActive = true
        priceLabel.trailingAnchor.constraint(equalTo: labelContainerView.trailingAnchor).isActive = true
        
        originalPriceLabel.translatesAutoresizingMaskIntoConstraints = false
        originalPriceLabel.font = UIFont.preferredFont(forTextStyle: .title2)
        originalPriceLabel.textColor = .gray7
        originalPriceLabel.adjustsFontForContentSizeCategory = true
        labelContainerView.addSubview(originalPriceLabel)
        originalPriceLabel.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
        originalPriceLabel.topAnchor.constraint(equalTo: priceLabel.bottomAnchor).isActive = true
        originalPriceLabel.bottomAnchor.constraint(lessThanOrEqualTo: labelContainerView.bottomAnchor).isActive = true
        originalPriceLabel.trailingAnchor.constraint(equalTo: labelContainerView.trailingAnchor).isActive = true
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.preferredFont(forTextStyle: .title2)
        titleLabel.textColor = .gray3
        titleLabel.numberOfLines = 0
        titleLabel.adjustsFontForContentSizeCategory = true
        labelContainerView.addSubview(titleLabel)
        titleLabel.setContentHuggingPriority(UILayoutPriorityDefaultLow, for: .horizontal)
        titleLabel.topAnchor.constraint(equalTo: labelContainerView.topAnchor).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: labelContainerView.leadingAnchor).isActive = true
        titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: labelContainerView.bottomAnchor).isActive = true
        titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: priceLabel.leadingAnchor, constant: -.padding).isActive = true
        titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: originalPriceLabel.leadingAnchor, constant: -.padding).isActive = true
        
        // TODO: how does UI look when all variants are out of stock
        selectionButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(selectionButton)
        selectionButton.topAnchor.constraint(equalTo: labelContainerView.bottomAnchor, constant: .padding).isActive = true
        selectionButton.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        selectionButton.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        selectionButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        cartButton.translatesAutoresizingMaskIntoConstraints = false
        cartButton.backgroundColor = .crazeGreen
        cartButton.setTitle("product.add".localized, for: .normal)
        cartButton.setTitleColor(.white, for: .normal)
        addSubview(cartButton)
        cartButton.topAnchor.constraint(equalTo: selectionButton.bottomAnchor, constant: .padding).isActive = true
        cartButton.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        cartButton.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        buyButton.translatesAutoresizingMaskIntoConstraints = false
        buyButton.backgroundColor = .crazeGreen
        buyButton.setTitle("product.buy".localized, for: .normal)
        buyButton.setTitleColor(.white, for: .normal)
        addSubview(buyButton)
        buyButton.topAnchor.constraint(equalTo: cartButton.bottomAnchor, constant: .padding).isActive = true
        buyButton.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        buyButton.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        websiteButton.translatesAutoresizingMaskIntoConstraints = false
        websiteButton.setTitleColor(.crazeGreen, for: .normal)
        websiteButton.isHidden = true
        addSubview(websiteButton)
        websiteButton.topAnchor.constraint(equalTo: buyButton.bottomAnchor, constant: .padding).isActive = true
        websiteButton.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        websiteButton.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        let contentTextView = UITextView()
        contentTextView.translatesAutoresizingMaskIntoConstraints = false
        contentTextView.backgroundColor = .green
        contentTextView.isScrollEnabled = false
        contentTextView.scrollsToTop = false
        addSubview(contentTextView)
        contentTextView.topAnchor.constraint(equalTo: websiteButton.bottomAnchor, constant: .padding).isActive = true
        contentTextView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        contentTextView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -.padding).isActive = true
        contentTextView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        contentTextView.heightAnchor.constraint(equalToConstant: 500).isActive = true
    }
    
    func setSelection(colorItem: SegmentedDropDownItem?, sizeItem: SegmentedDropDownItem?) {
        let hasColorItem = colorItem != nil
        let hasSizeItem = sizeItem != nil
        
        guard hasColorItem || hasSizeItem else {
            return
        }
        
        var items: [SegmentedDropDownItem] = []
        let widthRatio: CGFloat = (hasColorItem && hasSizeItem) ? 0.4 : 0.8
        
        if let colorItem = colorItem {
            colorItem.placeholderTitle = "product.color.default".localized
            colorItem.widthRatio = widthRatio
            items.append(colorItem)
        }
        
        if let sizeItem = sizeItem {
            sizeItem.placeholderTitle = "product.size.default".localized
            sizeItem.widthRatio = widthRatio
            items.append(sizeItem)
        }
        
        // TODO: keep this value synced with the CartViewController stepper.maxValue
        let quantityItem = SegmentedDropDownItem(pickerItems: (1...10).map { "\($0)" })
        items.append(quantityItem)
        
        selectionButton.items = items
    }
}


class ProductViewController : BaseViewController {
    enum State {
        case loading
        case product
        case empty
    }
    
    fileprivate var productView: ProductView?
    fileprivate var loadingView: Loader?
    
    fileprivate var productFrc: FetchedResultsControllerManager<Product>?
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init(productOID: NSManagedObjectID) {
        super.init(nibName: nil, bundle: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide(_:)), name: .UIKeyboardDidHide, object: nil)
        
        productFrc = DataModel.sharedInstance.productFrc(delegate: self, productOID: productOID)
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
            break
            
        case .loading:
            guard self.loadingView == nil else {
                return
            }
            
            productView?.removeFromSuperview()
            productView = nil
            
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
            
            let productView = ProductView()
            productView.translatesAutoresizingMaskIntoConstraints = false
            productView.selectionButton.addTarget(self, action: #selector(selectionButtonTouchUpInside), for: .touchUpInside)
            productView.selectionButton.addTarget(self, action: #selector(selectionButtonValueChanged), for: .valueChanged)
            productView.galleryScrollView.delegate = self
            productView.pageControl.addTarget(self, action: #selector(pageControlDidChange), for: .valueChanged)
            productView.cartButton.addTarget(self, action: #selector(cartButtonAction), for: .touchUpInside)
            productView.buyButton.addTarget(self, action: #selector(buyButtonAction), for: .touchUpInside)
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
extension ProductViewControllerProductView {
    // MARK: Gallery
    
    fileprivate func setImages(urls: [URL]) {
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
    
    @objc fileprivate func pageControlDidChange() {
        guard let productView = productView else {
            return
        }
        
        var point: CGPoint = .zero
        point.x = productView.galleryScrollView.bounds.width * CGFloat(productView.pageControl.currentPage)
        productView.galleryScrollView.setContentOffset(point, animated: true)
    }
    
    fileprivate var currentPage: Int {
        guard let productView = productView else {
            return 0
        }
        
        return Int(productView.galleryScrollView.contentOffset.x / productView.galleryScrollView.bounds.width)
    }
    
    // MARK: Labels
    
    fileprivate func setProductTitle(_ title: String?) {
        guard let productView = productView else {
            return
        }
        
        productView.titleLabel.text = title
    }
    
    fileprivate func setPrice(_ price: String?) {
        guard let productView = productView else {
            return
        }
        
        productView.priceLabel.text = price
    }
    
    fileprivate func setOriginalPrice(_ price: String?) {
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
    
    fileprivate func setWebsiteMerchant(_ merchant: String?) {
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
    
    @objc fileprivate func selectionButtonTouchUpInside() {
//        guard let productView = productView else {
//            return
//        }
        
        // ???: need analytics here
    }
    
    @objc fileprivate func selectionButtonValueChanged() {
        guard let productView = productView else {
            return
        }
        
        productView.selectionButton.selectedItem?.resetBorderColor()
    }
    
    @objc fileprivate func cartButtonAction() {
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
                adjustedContentInsetTop = productView.adjustedContentInset.top
            }
            else {
                adjustedContentInsetTop = topLayoutGuide.length
            }
            
            let currentOffsetY = productView.contentOffset.y + adjustedContentInsetTop
            let minOffsetY = productView.selectionButton.frame.minY
            
            if currentOffsetY > minOffsetY {
                UIView.animate(withDuration: Constants.defaultAnimationDuration, animations: {
                    productView.contentOffset = CGPoint(x: 0, y: minOffsetY - adjustedContentInsetTop - .padding)
                    
                }, completion: { completed in
                    displayErrorItems()
                })
            }
            else {
                displayErrorItems()
            }
        }
    }
    
    @objc fileprivate func buyButtonAction() {
        //        guard let productView = productView else {
        //            return
        //        }
        
        // TODO:
    }
    
    @objc fileprivate func pushMerchantURL() {
        //        guard let productView = productView else {
        //            return
        //        }
        
        // TODO:
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
                return productView.adjustedContentInset.top
            }
            else {
                return navigationController?.navigationBar.frame.maxY ?? 0
            }
        }()
        
        productView.contentOffset = CGPoint(x: 0, y: -y)
    }
}

extension ProductViewController : FetchedResultsControllerManagerDelegate {
    func managerDidChangeContent(_ controller: NSObject, change: FetchedResultsControllerManagerChange) {
        guard let product = productFrc?.fetchedResultsController.fetchedObjects?.first else {
            state = .empty
            return
        }
        
        let structuredVariants = product.structuredVariants()
        
        print("||| \(structuredVariants)")
        
        
        state = .product
        title = product.displayTitle
        setImages(urls: product.imageURLs())
        setWebsiteMerchant(product.merchant)
        setProductTitle(product.productDescription)
        setPrice(product.price)
        
        if product.isSale() {
            setOriginalPrice(product.originalPrice)
        }
        
        
        let colorItem = SegmentedDropDownItem(pickerItems: [
            "Brown", "Red", "Blue", "Yellow", "Pink", "Purple", "Green"
            ])
        colorItem.disabledPickerItems = ["Brown", "Yellow"]
        
        let sizeItem = SegmentedDropDownItem(pickerItems: [
            "Medium", "Small", "Large"
            ])
        
        productView?.setSelection(colorItem: colorItem, sizeItem: sizeItem)
        
        repositionScrollView()
    }
}
