//
//  ProductViewController.swift
//  screenshot
//
//  Created by Corey Werner on 1/25/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation

class ProductViewController : BaseViewController {
    fileprivate let scrollView = UIScrollView()
    
    fileprivate let galleryScrollView = UIScrollView()
    fileprivate let galleryScrollContentView = UIView()
    fileprivate let pageControl = UIPageControl()
    
    fileprivate let titleLabel = UILabel()
    fileprivate let priceLabel = UILabel()
    fileprivate let originalPriceLabel = UILabel()
    
    fileprivate let websiteButton = UIButton()
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide(_:)), name: .UIKeyboardDidHide, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .white
        scrollView.layoutMargins = UIEdgeInsets(top: .padding, left: .padding, bottom: .padding, right: .padding)
        scrollView.keyboardDismissMode = .onDrag
        view.addSubview(scrollView)
        scrollView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        galleryScrollView.translatesAutoresizingMaskIntoConstraints = false
        galleryScrollView.delegate = self
        galleryScrollView.scrollsToTop = false
        galleryScrollView.isPagingEnabled = true
        galleryScrollView.showsHorizontalScrollIndicator = false
        galleryScrollView.bounces = false
        scrollView.addSubview(galleryScrollView)
        galleryScrollView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        galleryScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        galleryScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
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
        pageControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: .padding).isActive = true
        pageControl.bottomAnchor.constraint(equalTo: galleryScrollView.bottomAnchor).isActive = true
        pageControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -.padding).isActive = true
        pageControl.centerXAnchor.constraint(equalTo: galleryScrollView.centerXAnchor).isActive = true
        
        setImages([ UIImage(), UIImage(), UIImage(), UIImage() ])
        
        let labelContainerView = UIView()
        labelContainerView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(labelContainerView)
        labelContainerView.topAnchor.constraint(equalTo: galleryScrollView.bottomAnchor, constant: .padding).isActive = true
        labelContainerView.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor).isActive = true
        labelContainerView.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        priceLabel.font = UIFont.preferredFont(forTextStyle: .title1)
        priceLabel.textColor = .gray3
        priceLabel.text = "$85"
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
//        originalPrice = "$1"
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.preferredFont(forTextStyle: .title2)
        titleLabel.textColor = .gray3
        titleLabel.text = "Cashmire & Tweed Brown Long-Sleeve Jacket"
        titleLabel.numberOfLines = 0
        titleLabel.adjustsFontForContentSizeCategory = true
        labelContainerView.addSubview(titleLabel)
        titleLabel.setContentHuggingPriority(UILayoutPriorityDefaultLow, for: .horizontal)
        titleLabel.topAnchor.constraint(equalTo: labelContainerView.topAnchor).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: labelContainerView.leadingAnchor).isActive = true
        titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: labelContainerView.bottomAnchor).isActive = true
        titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: priceLabel.leadingAnchor, constant: -.padding).isActive = true
        titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: originalPriceLabel.leadingAnchor, constant: -.padding).isActive = true
        
        let borderColor: UIColor = .gray8
        let selectionColor: UIColor = .gray6
        
        let selectionView = UIView()
        selectionView.translatesAutoresizingMaskIntoConstraints = false
        selectionView.backgroundColor = .white
        selectionView.layer.borderColor = borderColor.cgColor
        selectionView.layer.borderWidth = 1
        selectionView.layer.cornerRadius = CGFloat.defaultCornerRadius
        selectionView.layer.masksToBounds = true
        scrollView.addSubview(selectionView)
        selectionView.topAnchor.constraint(equalTo: labelContainerView.bottomAnchor, constant: .padding).isActive = true
        selectionView.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor).isActive = true
        selectionView.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor).isActive = true
        selectionView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        let colorButton = DropDownButton()
        colorButton.translatesAutoresizingMaskIntoConstraints = false
        colorButton.titleLabel.text = "product.color.default".localized
        colorButton.titleLabel.textColor = selectionColor
        colorButton.addTarget(self, action: #selector(selectionButtonAction(_:)), for: .touchUpInside)
        colorButton.pickerItems = ["Brown", "Red", "Blue", "Yellow", "Pink", "Purple", "Green"]
        selectionView.addSubview(colorButton)
        colorButton.topAnchor.constraint(equalTo: selectionView.topAnchor).isActive = true
        colorButton.leadingAnchor.constraint(equalTo: selectionView.leadingAnchor).isActive = true
        colorButton.bottomAnchor.constraint(equalTo: selectionView.bottomAnchor).isActive = true
        colorButton.widthAnchor.constraint(equalTo: selectionView.widthAnchor, multiplier: 0.4).isActive = true
        
        let sizeButton = DropDownButton()
        sizeButton.translatesAutoresizingMaskIntoConstraints = false
        sizeButton.titleLabel.text = "product.size.default".localized
        sizeButton.titleLabel.textColor = selectionColor
        sizeButton.addTarget(self, action: #selector(selectionButtonAction(_:)), for: .touchUpInside)
        sizeButton.pickerItems = ["Medium", "Small", "Large"]
        selectionView.addSubview(sizeButton)
        sizeButton.topAnchor.constraint(equalTo: selectionView.topAnchor).isActive = true
        sizeButton.leadingAnchor.constraint(equalTo: colorButton.trailingAnchor).isActive = true
        sizeButton.bottomAnchor.constraint(equalTo: selectionView.bottomAnchor).isActive = true
        sizeButton.widthAnchor.constraint(equalTo: selectionView.widthAnchor, multiplier: 0.4).isActive = true
        
        let divider1 = UIView()
        divider1.translatesAutoresizingMaskIntoConstraints = false
        divider1.backgroundColor = borderColor
        divider1.isUserInteractionEnabled = false
        selectionView.addSubview(divider1)
        divider1.topAnchor.constraint(equalTo: selectionView.topAnchor).isActive = true
        divider1.leadingAnchor.constraint(equalTo: sizeButton.leadingAnchor).isActive = true
        divider1.bottomAnchor.constraint(equalTo: selectionView.bottomAnchor).isActive = true
        divider1.widthAnchor.constraint(equalToConstant: selectionView.layer.borderWidth).isActive = true
        
        let quantityButton = DropDownButton()
        quantityButton.translatesAutoresizingMaskIntoConstraints = false
        quantityButton.titleLabel.textColor = selectionColor
        quantityButton.addTarget(self, action: #selector(selectionButtonAction(_:)), for: .touchUpInside)
        quantityButton.pickerItems = (1...10).map { "\($0)" }
        selectionView.addSubview(quantityButton)
        quantityButton.topAnchor.constraint(equalTo: selectionView.topAnchor).isActive = true
        quantityButton.leadingAnchor.constraint(equalTo: sizeButton.trailingAnchor).isActive = true
        quantityButton.bottomAnchor.constraint(equalTo: selectionView.bottomAnchor).isActive = true
        quantityButton.trailingAnchor.constraint(equalTo: selectionView.trailingAnchor).isActive = true
        
        let divider2 = UIView()
        divider2.translatesAutoresizingMaskIntoConstraints = false
        divider2.backgroundColor = borderColor
        divider2.isUserInteractionEnabled = false
        selectionView.addSubview(divider2)
        divider2.topAnchor.constraint(equalTo: selectionView.topAnchor).isActive = true
        divider2.leadingAnchor.constraint(equalTo: quantityButton.leadingAnchor).isActive = true
        divider2.bottomAnchor.constraint(equalTo: selectionView.bottomAnchor).isActive = true
        divider2.widthAnchor.constraint(equalToConstant: selectionView.layer.borderWidth).isActive = true
        
        let cartButton = MainButton()
        cartButton.translatesAutoresizingMaskIntoConstraints = false
        cartButton.backgroundColor = .crazeGreen
        cartButton.setTitle("product.add".localized, for: .normal)
        cartButton.setTitleColor(.white, for: .normal)
        scrollView.addSubview(cartButton)
        cartButton.topAnchor.constraint(equalTo: selectionView.bottomAnchor, constant: .padding).isActive = true
        cartButton.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor).isActive = true
        cartButton.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        let buyButton = MainButton()
        buyButton.translatesAutoresizingMaskIntoConstraints = false
        buyButton.backgroundColor = .crazeGreen
        buyButton.setTitle("product.buy".localized, for: .normal)
        buyButton.setTitleColor(.white, for: .normal)
        scrollView.addSubview(buyButton)
        buyButton.topAnchor.constraint(equalTo: cartButton.bottomAnchor, constant: .padding).isActive = true
        buyButton.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor).isActive = true
        buyButton.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        websiteButton.translatesAutoresizingMaskIntoConstraints = false
        websiteButton.setTitleColor(.crazeGreen, for: .normal)
        websiteButton.isHidden = true
        scrollView.addSubview(websiteButton)
        websiteButton.topAnchor.constraint(equalTo: buyButton.bottomAnchor, constant: .padding).isActive = true
        websiteButton.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor).isActive = true
        websiteButton.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        merchantName = "Nordstrom"
        
        let contentTextView = UITextView()
        contentTextView.translatesAutoresizingMaskIntoConstraints = false
        contentTextView.backgroundColor = .green
        contentTextView.isScrollEnabled = false
        contentTextView.scrollsToTop = false
        scrollView.addSubview(contentTextView)
        contentTextView.topAnchor.constraint(equalTo: websiteButton.bottomAnchor, constant: .padding).isActive = true
        contentTextView.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor).isActive = true
        contentTextView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -.padding).isActive = true
        contentTextView.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor).isActive = true
        contentTextView.heightAnchor.constraint(equalToConstant: 100).isActive = true
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
    
    // MARK: Gallery
    
    func setImages(_ images: [UIImage]) {
        galleryScrollContentView.subviews.forEach { subview in
            subview.removeFromSuperview()
        }
        
        var rand: CGFloat {
            return CGFloat(arc4random()) / CGFloat(UInt32.max)
        }
        
        pageControl.numberOfPages = images.count
        pageControl.currentPage = 0
        
        images.enumerated().forEach { (index: Int, image: UIImage) in
            let previousImageView = galleryScrollContentView.subviews.last
            
            let imageView = UIImageView()
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.contentMode = .scaleAspectFit
            imageView.backgroundColor = UIColor(red: rand, green: rand, blue: rand, alpha: 1)
            galleryScrollContentView.addSubview(imageView)
            
            imageView.topAnchor.constraint(equalTo: galleryScrollContentView.topAnchor).isActive = true
            imageView.bottomAnchor.constraint(equalTo: galleryScrollContentView.bottomAnchor).isActive = true
            imageView.widthAnchor.constraint(equalToConstant: self.view.bounds.width).isActive = true
            
            if index == 0 {
                imageView.leadingAnchor.constraint(equalTo: galleryScrollContentView.leadingAnchor).isActive = true
            }
            else {
                if let previousImageView = previousImageView {
                    imageView.leadingAnchor.constraint(equalTo: previousImageView.trailingAnchor).isActive = true
                }
            }
            
            if index == images.count - 1 {
                imageView.trailingAnchor.constraint(equalTo: galleryScrollContentView.trailingAnchor).isActive = true
            }
        }
    }
    
    @objc private func pageControlDidChange() {
        var point = CGPoint.zero
        point.x = galleryScrollView.bounds.width * CGFloat(pageControl.currentPage)
        galleryScrollView.setContentOffset(point, animated: true)
    }
    
    fileprivate var currentPage: Int {
        return Int(galleryScrollView.contentOffset.x / galleryScrollView.bounds.width)
    }
    
    // MARK: Labels
    
    var headline: String? {
        set {
            titleLabel.text = newValue
        }
        get {
            return titleLabel.text
        }
    }
    
    var price: String? {
        set {
            priceLabel.text = newValue
        }
        get {
            return priceLabel.text
        }
    }
    
    var originalPrice: String? {
        set {
            if let text = newValue {
                priceLabel.textColor = .crazeRed
                originalPriceLabel.attributedText = NSAttributedString(string: text, attributes: [
                    NSStrikethroughStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue,
                    NSStrikethroughColorAttributeName: originalPriceLabel.textColor
                    ])
            }
            else {
                priceLabel.textColor = .gray3
                originalPriceLabel.text = newValue
            }
        }
        get {
            return originalPriceLabel.text
        }
    }
    
    var merchantName: String? {
        didSet {
            if let name = merchantName, name.count > 0 {
                let color = websiteButton.titleColor(for: .normal) ?? .crazeGreen
                
                let title = NSAttributedString(string: "product.website".localized(withFormat: name), attributes: [
                    NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue,
                    NSUnderlineColorAttributeName: color,
                    NSForegroundColorAttributeName: color,
                    NSFontAttributeName: UIFont.systemFont(ofSize: UIFont.buttonFontSize, weight: UIFontWeightBold)
                    ])
                
                websiteButton.setAttributedTitle(title, for: .normal)
                websiteButton.isHidden = false
            }
            else {
                websiteButton.setTitle(nil, for: .normal)
                websiteButton.isHidden = true
            }
        }
    }
    
    // MARK: Selection
    
    @objc fileprivate func selectionButtonAction(_ button: UIButton) {
        if button.isFirstResponder {
            button.resignFirstResponder()
        }
        else {
            button.becomeFirstResponder()
        }
    }
}

extension ProductViewController : UIScrollViewDelegate {
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView == galleryScrollView {
            if !decelerate {
                pageControl.currentPage = currentPage
            }
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView == galleryScrollView {
            pageControl.currentPage = currentPage
        }
    }
}
