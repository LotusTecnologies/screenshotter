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
    fileprivate let scrollContentView = UIView()
    fileprivate let pageControl = UIPageControl()
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.delegate = self
        scrollView.backgroundColor = .red
        scrollView.scrollsToTop = false
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        scrollView.heightAnchor.constraint(equalToConstant: 300).isActive = true
        
        scrollContentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(scrollContentView)
        scrollContentView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        scrollContentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor).isActive = true
        scrollContentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
        scrollContentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor).isActive = true
        scrollContentView.heightAnchor.constraint(equalTo: scrollView.heightAnchor).isActive = true
        
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.hidesForSinglePage = true
        pageControl.pageIndicatorTintColor = UIColor.black.withAlphaComponent(0.5)
        pageControl.currentPageIndicatorTintColor = .crazeGreen
        pageControl.addTarget(self, action: #selector(pageControlDidChange), for: .valueChanged)
        view.addSubview(pageControl)
        pageControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: .padding).isActive = true
        pageControl.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
        pageControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -.padding).isActive = true
        pageControl.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        
        setImages([ UIImage(), UIImage(), UIImage(), UIImage() ])
    }
    
    // MARK: Image
    
    func setImages(_ images: [UIImage]) {
        scrollContentView.subviews.forEach { subview in
            subview.removeFromSuperview()
        }
        
        var rand: CGFloat {
            return CGFloat(arc4random()) / CGFloat(UInt32.max)
        }
        
        pageControl.numberOfPages = images.count
        pageControl.currentPage = 0
        
        images.enumerated().forEach { (index: Int, image: UIImage) in
            let previousImageView = scrollContentView.subviews.last
            
            let imageView = UIImageView()
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.backgroundColor = UIColor(red: rand, green: rand, blue: rand, alpha: 1)
            scrollContentView.addSubview(imageView)
            
            imageView.topAnchor.constraint(equalTo: scrollContentView.topAnchor).isActive = true
            imageView.bottomAnchor.constraint(equalTo: scrollContentView.bottomAnchor).isActive = true
            imageView.widthAnchor.constraint(equalToConstant: self.view.bounds.width).isActive = true
            
            if index == 0 {
                imageView.leadingAnchor.constraint(equalTo: scrollContentView.leadingAnchor).isActive = true
                
            } else {
                if let previousImageView = previousImageView {
                    imageView.leadingAnchor.constraint(equalTo: previousImageView.trailingAnchor).isActive = true
                }
            }
            
            if index == images.count - 1 {
                imageView.trailingAnchor.constraint(equalTo: scrollContentView.trailingAnchor).isActive = true
            }
        }
    }
    
    // MARK: Page Control
    
    @objc private func pageControlDidChange() {
        var point = CGPoint.zero
        point.x = scrollView.bounds.width * CGFloat(pageControl.currentPage)
        scrollView.setContentOffset(point, animated: true)
    }
    
    fileprivate var currentPage: Int {
        return Int(scrollView.contentOffset.x / scrollView.bounds.width)
    }
}

extension ProductViewController : UIScrollViewDelegate {
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            pageControl.currentPage = currentPage
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        pageControl.currentPage = currentPage
    }
}
