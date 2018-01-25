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
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .white
        scrollView.layoutMargins = UIEdgeInsets(top: .padding, left: .padding, bottom: .padding, right: .padding) // TODO: check on ios 10
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
        view.addSubview(pageControl)
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
        
        let priceLabel = UILabel()
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        priceLabel.backgroundColor = .gray9
        priceLabel.font = UIFont.preferredFont(forTextStyle: .title1)
        priceLabel.textColor = .gray3
        priceLabel.text = "$85"
        priceLabel.adjustsFontForContentSizeCategory = true // TODO: test
        labelContainerView.addSubview(priceLabel)
        priceLabel.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
        priceLabel.topAnchor.constraint(equalTo: labelContainerView.topAnchor).isActive = true
        priceLabel.bottomAnchor.constraint(lessThanOrEqualTo: labelContainerView.bottomAnchor).isActive = true
        priceLabel.trailingAnchor.constraint(equalTo: labelContainerView.trailingAnchor).isActive = true
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.backgroundColor = .gray9
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
        titleLabel.trailingAnchor.constraint(equalTo: priceLabel.leadingAnchor, constant: -.padding).isActive = true
        
        let selectionView = UIView()
        selectionView.translatesAutoresizingMaskIntoConstraints = false
        selectionView.backgroundColor = .yellow
        scrollView.addSubview(selectionView)
        selectionView.topAnchor.constraint(equalTo: labelContainerView.bottomAnchor, constant: .padding).isActive = true
        selectionView.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor).isActive = true
        selectionView.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor).isActive = true
        selectionView.heightAnchor.constraint(equalToConstant: 60).isActive = true
        
//        let a = UIView()
//        a.translatesAutoresizingMaskIntoConstraints = false
//        a.backgroundColor = .yellow
//        scrollView.addSubview(a)
//        a.topAnchor.constraint(equalTo: galleryScrollView.bottomAnchor, constant: 10).isActive = true
//        a.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
//        a.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
//        a.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
//        a.heightAnchor.constraint(equalToConstant: 500).isActive = true
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
                
            } else {
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
