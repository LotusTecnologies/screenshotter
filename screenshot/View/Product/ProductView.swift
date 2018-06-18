//
//  ProductView.swift
//  screenshot
//
//  Created by Corey Werner on 2/27/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import UIKit
import SDWebImage

class ProductView: UIView {
    let scrollView = UIScrollView()
    
    let galleryScrollView: UIScrollView = ScrollView()
    let galleryScrollContentView = UIView()
    fileprivate let pageControl = UIPageControl()
    
    let unavailableImageView = UIImageView(image: UIImage(named: "ProductUnavailable"))
    let titleLabel = UILabel()
    let priceLabel = UILabel()
    let originalPriceLabel = UILabel()
    let contentTextView = UITextView()
    let favoriteButton = FavoriteButton()
    let stockButton = BorderButton()
    let websiteButton = UIButton()
    
    let selectionControl = SegmentedDropDownControl()
    fileprivate(set) var selectionColorItem: SegmentedDropDownItem?
    fileprivate(set) var selectionSizeItem: SegmentedDropDownItem?
    fileprivate(set) var selectionQuantityItem: SegmentedDropDownItem?
    private(set) var controlContainerBottomConstraint: NSLayoutConstraint?
    let cartButton = MainButton()
//    let buyButton = MainButton()
    
    fileprivate let similarProductsContainerView = UIView()
    fileprivate(set) var similarProductsCollectionView: ProductsCollectionView?
    
    private var completeDetailsConstraints: [NSLayoutConstraint] = []
    private var partialDetailsConstraints: [NSLayoutConstraint] = []
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .white
        scrollView.layoutMargins = UIEdgeInsets(top: .padding, left: .padding, bottom: .padding, right: .padding)
        scrollView.keyboardDismissMode = .onDrag
        addSubview(scrollView)
        scrollView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        scrollView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
        partialDetailsConstraints += [
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]
        
        (galleryScrollView as? ScrollView)?.lifeCycleDelegate = self
        galleryScrollView.translatesAutoresizingMaskIntoConstraints = false
        galleryScrollView.delegate = self
        galleryScrollView.scrollsToTop = false
        galleryScrollView.isPagingEnabled = true
        galleryScrollView.showsHorizontalScrollIndicator = false
        galleryScrollView.bounces = false
        scrollView.addSubview(galleryScrollView)
        galleryScrollView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        galleryScrollView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor).isActive = true
        galleryScrollView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor).isActive = true
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
        pageControl.addTarget(self, action: #selector(pageControlDidChange), for: .valueChanged)
        scrollView.addSubview(pageControl)
        pageControl.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: .padding).isActive = true
        pageControl.bottomAnchor.constraint(equalTo: galleryScrollView.bottomAnchor).isActive = true
        pageControl.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -.padding).isActive = true
        pageControl.centerXAnchor.constraint(equalTo: galleryScrollView.centerXAnchor).isActive = true
        
        unavailableImageView.translatesAutoresizingMaskIntoConstraints = false
        unavailableImageView.contentMode = .scaleAspectFit
        unavailableImageView.alpha = 0
        scrollView.addSubview(unavailableImageView)
        unavailableImageView.topAnchor.constraint(equalTo: galleryScrollView.topAnchor, constant: .padding).isActive = true
        unavailableImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.padding).isActive = true
        
        let labelContainerView = UIView()
        labelContainerView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(labelContainerView)
        labelContainerView.topAnchor.constraint(equalTo: galleryScrollView.bottomAnchor, constant: .padding).isActive = true
        labelContainerView.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor).isActive = true
        labelContainerView.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        priceLabel.textColor = .gray3
        priceLabel.font = UIFont.preferredFont(forTextStyle: .title1)
        priceLabel.minimumScaleFactor = 0.3
        priceLabel.baselineAdjustment = .alignCenters
        priceLabel.adjustsFontSizeToFitWidth = true
        priceLabel.adjustsFontForContentSizeCategory = true
        labelContainerView.addSubview(priceLabel)
        priceLabel.setContentCompressionResistancePriority(UILayoutPriority.required, for: .horizontal)
        priceLabel.topAnchor.constraint(equalTo: labelContainerView.topAnchor).isActive = true
        priceLabel.trailingAnchor.constraint(equalTo: labelContainerView.trailingAnchor).isActive = true
        priceLabel.widthAnchor.constraint(lessThanOrEqualTo: labelContainerView.widthAnchor, multiplier: 0.4).isActive = true
        
        originalPriceLabel.translatesAutoresizingMaskIntoConstraints = false
        originalPriceLabel.textColor = .gray7
        originalPriceLabel.font = UIFont.preferredFont(forTextStyle: .title2)
        originalPriceLabel.minimumScaleFactor = 0.3
        originalPriceLabel.baselineAdjustment = .alignCenters
        originalPriceLabel.adjustsFontSizeToFitWidth = true
        originalPriceLabel.adjustsFontForContentSizeCategory = true
        labelContainerView.addSubview(originalPriceLabel)
        originalPriceLabel.setContentCompressionResistancePriority(UILayoutPriority.required, for: .horizontal)
        originalPriceLabel.topAnchor.constraint(equalTo: priceLabel.bottomAnchor).isActive = true
        originalPriceLabel.bottomAnchor.constraint(lessThanOrEqualTo: labelContainerView.bottomAnchor).isActive = true
        originalPriceLabel.trailingAnchor.constraint(equalTo: labelContainerView.trailingAnchor).isActive = true
        originalPriceLabel.widthAnchor.constraint(lessThanOrEqualTo: labelContainerView.widthAnchor, multiplier: 0.4).isActive = true
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.preferredFont(forTextStyle: .title2)
        titleLabel.textColor = .gray3
        titleLabel.numberOfLines = 0
        titleLabel.adjustsFontForContentSizeCategory = true
        labelContainerView.addSubview(titleLabel)
        titleLabel.setContentHuggingPriority(UILayoutPriority.defaultLow, for: .horizontal)
        titleLabel.topAnchor.constraint(equalTo: labelContainerView.topAnchor).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: labelContainerView.leadingAnchor).isActive = true
        titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: labelContainerView.bottomAnchor).isActive = true
        titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: priceLabel.leadingAnchor, constant: -.padding).isActive = true
        titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: originalPriceLabel.leadingAnchor, constant: -.padding).isActive = true
        
        selectionControl.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(selectionControl)
        selectionControl.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor).isActive = true
        selectionControl.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        completeDetailsConstraints += [
            selectionControl.topAnchor.constraint(equalTo: labelContainerView.bottomAnchor, constant: .padding),
            selectionControl.heightAnchor.constraint(equalToConstant: 50)
        ]
        partialDetailsConstraints += [
            selectionControl.topAnchor.constraint(equalTo: labelContainerView.bottomAnchor)
        ]
        
        favoriteButton.translatesAutoresizingMaskIntoConstraints = false
        favoriteButton.setTitle("cart.favorite.add".localized, for: .normal)
        favoriteButton.setTitle("cart.favorite.remove".localized, for: .selected)
        favoriteButton.setTitle("cart.favorite.remove".localized, for: [.selected, .highlighted])
        favoriteButton.setTitleColor(.crazeRed, for: .normal)
        scrollView.addSubview(favoriteButton)
        favoriteButton.topAnchor.constraint(equalTo: selectionControl.bottomAnchor, constant: .padding).isActive = true
        favoriteButton.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor).isActive = true
        favoriteButton.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor).isActive = true
        favoriteButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        stockButton.translatesAutoresizingMaskIntoConstraints = false
        stockButton.setTitle("product.price_alert_on".localized, for: .normal)
        stockButton.setTitle("product.price_alert_off".localized, for: .selected)
        stockButton.setTitle("product.price_alert_off".localized, for: [.selected, .highlighted])
        stockButton.setTitleColor(.crazeRed, for: .normal)
        stockButton.setTitleColor(.crazeGreen, for: .selected)
        stockButton.setTitleColor(UIColor.crazeGreen.darker(), for: [.selected, .highlighted])
        stockButton.setImage(UIImage(named: "FavoriteBell")?.withRenderingMode(.alwaysTemplate), for: .normal)
        stockButton.adjustInsetsForImage()
        stockButton.alpha = 0
        scrollView.addSubview(stockButton)
        stockButton.topAnchor.constraint(equalTo: favoriteButton.topAnchor).isActive = true
        stockButton.leadingAnchor.constraint(equalTo: favoriteButton.leadingAnchor).isActive = true
        stockButton.bottomAnchor.constraint(equalTo: favoriteButton.bottomAnchor).isActive = true
        stockButton.trailingAnchor.constraint(equalTo: favoriteButton.trailingAnchor).isActive = true
        
        contentTextView.translatesAutoresizingMaskIntoConstraints = false
        contentTextView.backgroundColor = .clear
        contentTextView.isScrollEnabled = false
        contentTextView.scrollsToTop = false
        contentTextView.font = .preferredFont(forTextStyle: .body)
        contentTextView.adjustsFontForContentSizeCategory = true
        contentTextView.isEditable = false
        scrollView.addSubview(contentTextView)
        contentTextView.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor).isActive = true
        contentTextView.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        completeDetailsConstraints += [
            contentTextView.topAnchor.constraint(equalTo: favoriteButton.bottomAnchor, constant: .padding)
        ]
        partialDetailsConstraints += [
            contentTextView.topAnchor.constraint(equalTo: favoriteButton.bottomAnchor),
            contentTextView.heightAnchor.constraint(equalToConstant: 0)
        ]
        
        websiteButton.translatesAutoresizingMaskIntoConstraints = false
        websiteButton.setTitleColor(.crazeGreen, for: .normal)
        websiteButton.isHidden = true
        scrollView.addSubview(websiteButton)
        websiteButton.topAnchor.constraint(equalTo: contentTextView.bottomAnchor, constant: .padding).isActive = true
        websiteButton.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor).isActive = true
        websiteButton.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        similarProductsContainerView.translatesAutoresizingMaskIntoConstraints = false
        similarProductsContainerView.isHidden = true
        similarProductsContainerView.backgroundColor = .background
        scrollView.addSubview(similarProductsContainerView)
        similarProductsContainerView.topAnchor.constraint(equalTo: websiteButton.bottomAnchor, constant: .padding).isActive = true
        similarProductsContainerView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor).isActive = true
        similarProductsContainerView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
        similarProductsContainerView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor).isActive = true
        
        let controlContainerView = UIView()
        controlContainerView.translatesAutoresizingMaskIntoConstraints = false
        controlContainerView.backgroundColor = .white
        controlContainerView.layoutMargins = UIEdgeInsets(top: .padding / 2, left: .padding, bottom: .padding / 2, right: .padding)
        addSubview(controlContainerView)
        controlContainerView.topAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
        controlContainerView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        controlContainerView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        let controlContainerBottomConstraint = controlContainerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        self.controlContainerBottomConstraint = controlContainerBottomConstraint
        
        completeDetailsConstraints += [
            controlContainerBottomConstraint
        ]
        
        controlContainerView.addSubview(BorderView(edge: .top))
        
        cartButton.translatesAutoresizingMaskIntoConstraints = false
        cartButton.backgroundColor = .crazeGreen
        cartButton.setTitle("product.add".localized, for: .normal)
        cartButton.setTitleColor(.white, for: .normal)
        controlContainerView.addSubview(cartButton)
        cartButton.topAnchor.constraint(equalTo: controlContainerView.layoutMarginsGuide.topAnchor).isActive = true
        cartButton.leadingAnchor.constraint(equalTo: controlContainerView.layoutMarginsGuide.leadingAnchor).isActive = true
        cartButton.bottomAnchor.constraint(equalTo: controlContainerView.layoutMarginsGuide.bottomAnchor).isActive = true
//        cartButton.trailingAnchor.constraint(equalTo: controlContainerView.layoutMarginsGuide.centerXAnchor, constant: -.padding / 2).isActive = true
        cartButton.trailingAnchor.constraint(equalTo: controlContainerView.layoutMarginsGuide.trailingAnchor).isActive = true
        
//        buyButton.translatesAutoresizingMaskIntoConstraints = false
//        buyButton.backgroundColor = .crazeGreen
//        buyButton.setTitle("product.buy_now".localized, for: .normal)
//        buyButton.setTitleColor(.white, for: .normal)
//        controlContainerView.addSubview(buyButton)
//        buyButton.topAnchor.constraint(equalTo: controlContainerView.layoutMarginsGuide.topAnchor).isActive = true
//        buyButton.leadingAnchor.constraint(equalTo: controlContainerView.layoutMarginsGuide.centerXAnchor, constant: .padding / 2).isActive = true
//        buyButton.bottomAnchor.constraint(equalTo: controlContainerView.layoutMarginsGuide.bottomAnchor).isActive = true
//        buyButton.trailingAnchor.constraint(equalTo: controlContainerView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        NSLayoutConstraint.activate(partialDetailsConstraints)
    }
    
    fileprivate func syncDetailViewConstraints() {
        let shouldActivatePartial = selectionControl.items.isEmpty
        
        guard let constraint = partialDetailsConstraints.first, constraint.isActive != shouldActivatePartial else {
            return
        }
        
        func changeDetailViewConstraints() {
            if shouldActivatePartial {
                NSLayoutConstraint.deactivate(completeDetailsConstraints)
                NSLayoutConstraint.activate(partialDetailsConstraints)
            }
            else {
                NSLayoutConstraint.deactivate(partialDetailsConstraints)
                NSLayoutConstraint.activate(completeDetailsConstraints)
            }
        }
        
        if window == nil {
            changeDetailViewConstraints()
        }
        else {
            func adjustDetailViewAlpha(_ alpha: CGFloat) {
                selectionControl.alpha = alpha
                contentTextView.alpha = alpha
            }
            
            adjustDetailViewAlpha(0)
            layoutIfNeeded()
            changeDetailViewConstraints()
            
            UIView.animate(withDuration: .defaultAnimationDuration) {
                adjustDetailViewAlpha(1)
                self.layoutIfNeeded()
            }
        }
    }
    
    // MARK: Gallery
    
    private var galleryURLs: [URL]?
    fileprivate var selectedGalleryURL: URL?
    
    func setGalleryImages(urls: [URL], selectedURL: URL?) {
        galleryScrollContentView.subviews.forEach { subview in
            subview.removeFromSuperview()
        }
        galleryURLs = urls
        selectedGalleryURL = selectedURL
        
        pageControl.numberOfPages = urls.count
        pageControl.currentPage = 0
        
        urls.enumerated().forEach { (index: Int, url: URL) in
            let previousImageView = galleryScrollContentView.subviews.last
            
            let imageView = UIImageView()
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.contentMode = .scaleAspectFit
            imageView.backgroundColor = .white
            galleryScrollContentView.addSubview(imageView)
            imageView.topAnchor.constraint(equalTo: galleryScrollContentView.topAnchor).isActive = true
            imageView.bottomAnchor.constraint(equalTo: galleryScrollContentView.bottomAnchor).isActive = true
            imageView.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
            
            if index == 0 {
                imageView.leadingAnchor.constraint(equalTo: galleryScrollContentView.leadingAnchor).isActive = true
            }
            else {
                if let previousImageView = previousImageView {
                    imageView.leadingAnchor.constraint(equalTo: previousImageView.trailingAnchor).isActive = true
                }
            }
            
            if index == urls.count - 1 {
                imageView.trailingAnchor.constraint(equalTo: galleryScrollContentView.trailingAnchor).isActive = true
            }
            
            imageView.sd_setImage(with: url, completed: nil)
        }
    }
    
    func scrollGalleryImages(toPage page: Int, animated: Bool = true) {
        var point: CGPoint = .zero
        point.x = galleryScrollView.bounds.width * CGFloat(page)
        galleryScrollView.setContentOffset(point, animated: animated)
        
        if !animated {
            syncPageControl()
        }
    }
    
    func scrollGalleryImages(toURL url: URL, animated: Bool = true) {
        if let index = galleryURLs?.index(of: url) {
            scrollGalleryImages(toPage: index, animated: animated)
        }
    }
    
    var currentGalleryPage: Int {
        guard galleryScrollView.bounds.width > 0 else {
            return 0
        }
        
        return Int(galleryScrollView.contentOffset.x / galleryScrollView.bounds.width)
    }
    
    fileprivate func syncPageControl() {
        pageControl.currentPage = currentGalleryPage
    }
    
    @objc fileprivate func pageControlDidChange() {
        scrollGalleryImages(toPage: pageControl.currentPage)
    }
    
    func setIsUnavailable(_ isUnavailable: Bool) {
        UIView.animate(withDuration: .defaultAnimationDuration) {
            self.unavailableImageView.alpha = isUnavailable ? 1 : 0
            self.favoriteButton.alpha = isUnavailable ? 0 : 1
            self.stockButton.alpha = isUnavailable ? 1 : 0
        }
    }
    
    // MARK: Selection
    
    func setSelection(colorItem: SegmentedDropDownItem, sizeItem: SegmentedDropDownItem?) {
        var items: [SegmentedDropDownItem] = []
        let hasSizeItem = sizeItem != nil
        let widthRatio: CGFloat = hasSizeItem ? 0.4 : 0.8
        
        colorItem.placeholderTitle = "product.color.default".localized
        colorItem.widthRatio = widthRatio
        items.append(colorItem)
        
        if let sizeItem = sizeItem {
            sizeItem.placeholderTitle = "product.size.default".localized
            sizeItem.widthRatio = widthRatio
            items.append(sizeItem)
        }
        
        let quantityRange = (1...Constants.cartItemMaxQuantity)
        let quantityItem = SegmentedDropDownItem(pickerItems: quantityRange.map { "\($0)" }, selectedPickerItem: "1")
        items.append(quantityItem)
        
        selectionControl.items = items
        selectionColorItem = colorItem
        selectionSizeItem = sizeItem
        selectionQuantityItem = quantityItem
        
        syncDetailViewConstraints()
    }
    
    func resignSelectionControl() {
        if selectionControl.isFirstResponder {
            // Dismiss selected state
            selectionControl.resignFirstResponder()
        }
    }
    
    // MARK: Products Collection View
    
    fileprivate func createProductsCollectionView(title: String, containerView: UIView) -> ProductsCollectionView {
        containerView.isHidden = false
        
        let topBorderView = BorderView(edge: .top)
        topBorderView.backgroundColor = containerView.backgroundColor?.darker()
        containerView.addSubview(topBorderView)
        
        let similarProductsLabel = UILabel()
        similarProductsLabel.translatesAutoresizingMaskIntoConstraints = false
        similarProductsLabel.textColor = .gray3
        similarProductsLabel.text = title
        similarProductsLabel.font = .preferredFont(forTextStyle: .title2)
        similarProductsLabel.adjustsFontForContentSizeCategory = true
        similarProductsLabel.adjustsFontSizeToFitWidth = true
        similarProductsLabel.minimumScaleFactor = 0.7
        containerView.addSubview(similarProductsLabel)
        similarProductsLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: .padding).isActive = true
        similarProductsLabel.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor).isActive = true
        similarProductsLabel.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        let collectionView = ProductsCollectionView()
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = containerView.backgroundColor
        containerView.addSubview(collectionView)
        collectionView.topAnchor.constraint(equalTo: similarProductsLabel.bottomAnchor).isActive = true
        collectionView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor).isActive = true
        return collectionView
    }
    
    func setSimilarProducts(_ products: [Product]) {
        guard !products.isEmpty else {
            return
        }
        
        similarProductsCollectionView = createProductsCollectionView(title: "product.similar_items".localized, containerView: similarProductsContainerView)
        similarProductsCollectionView?.products = products
    }
    
    // MARK: Interaction
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        var shouldResignSelectionControl = true
        
        for subview in selectionControl.subviews {
            if view == subview {
                shouldResignSelectionControl = false
                break
            }
        }
        
        if shouldResignSelectionControl {
            resignSelectionControl()
        }
        
        return view
    }
}

extension ProductView: UIScrollViewDelegate {
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            syncPageControl()
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        syncPageControl()
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        syncPageControl()
    }
}

fileprivate protocol ProductViewScrollViewDelegate: NSObjectProtocol {
    func scrollViewDidLayoutSubviews()
}

extension ProductView: ProductViewScrollViewDelegate {
    fileprivate class ScrollView: UIScrollView {
        weak var lifeCycleDelegate: ProductViewScrollViewDelegate?
        
        override func layoutSubviews() {
            super.layoutSubviews()
            lifeCycleDelegate?.scrollViewDidLayoutSubviews()
        }
    }
    
    fileprivate func scrollViewDidLayoutSubviews() {
        if let selectedGalleryURL = selectedGalleryURL {
            scrollGalleryImages(toURL: selectedGalleryURL, animated: false)
            self.selectedGalleryURL = nil
        }
    }
}
