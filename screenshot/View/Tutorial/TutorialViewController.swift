//
//  TutorialViewController.swift
//  screenshot
//
//  Created by Corey Werner on 10/14/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import UIKit

@objc protocol TutorialViewControllerDelegate : class {
    func tutoriaViewControllerDidComplete(_ viewController: TutorialViewController)
}

class TutorialViewController : UIViewController {
    weak var delegate: TutorialViewControllerDelegate?
    
    let scrollView = UIScrollView()
    let contentView = UIView()
    
    private var didPresentDeterminePushAlertController = false
    fileprivate var scrollViewIsScrollingAnimation = false
    
    // MARK: - Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(contentSizeCategoryDidChange(_:)), name: .UIContentSizeCategoryDidChange, object: nil)
        
        slides = buildSlides()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        track("Started Tutorial")
        
        view.backgroundColor = .white
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.delegate = self
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.isPagingEnabled = true
        scrollView.isScrollEnabled = false
        view.addSubview(scrollView)
        scrollView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        contentView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor).isActive = true
        contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor).isActive = true
        contentView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: CGFloat(slides.count)).isActive = true
        contentView.heightAnchor.constraint(equalTo: scrollView.heightAnchor).isActive = true
        
        prepareSlideViews()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        let currentSlideIdx = currentSlideIndex
        coordinator.animate(alongsideTransition: { context in
            var offset = self.scrollView.contentOffset
            offset.x = size.width * CGFloat(currentSlideIdx)
            self.scrollView.contentOffset = offset
        }, completion: nil)
    }
    
    func contentSizeCategoryDidChange(_ notification: Notification) {
        slides.forEach { slide in
            slide.layoutMargins = slideLayoutMargins
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Slides
    
    var slides = [UIView]()
    
    private func buildSlides() -> [UIView] {
        let welcomeSlide = TutorialWelcomeSlideView()
        welcomeSlide.button.addTarget(self, action: #selector(tutorialWelcomeSlideViewDidComplete), for: .touchUpInside)
        
        let emailSlide = TutorialEmailSlideView()
        emailSlide.delegate = self
        
        let trySlide = TutorialTrySlideView()
        trySlide.delegate = self
        
        return [welcomeSlide, emailSlide, trySlide]
    }
    
    fileprivate var currentSlideIndex: Int {
        guard scrollView.bounds != .zero else {
            return 0
        }
        
        return Int(ceil(scrollView.contentOffset.x / scrollView.bounds.size.width))
    }
    
    fileprivate var currentSlide: UIView {
        return slides[currentSlideIndex]
    }
    
    fileprivate func scrollToNextSlide(animated: Bool = true) {
        guard scrollViewIsScrollingAnimation == false else {
            return
        }
        
        scrollViewIsScrollingAnimation = true
        (currentSlide as? TutorialSlideView)?.willLeaveSlide()
        
        var offset = CGPoint.zero
        offset.x = scrollView.bounds.size.width + scrollView.contentOffset.x
        scrollView.setContentOffset(offset, animated: animated)
    }
    
    private func prepareSlideViews() {
        slides.enumerated().forEach { i, slide in
            slide.translatesAutoresizingMaskIntoConstraints = false
            slide.layoutMargins = slideLayoutMargins
            contentView.addSubview(slide)
            slide.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
            slide.heightAnchor.constraint(equalTo: scrollView.heightAnchor).isActive = true
            slide.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
            
            if i == 0 {
                slide.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
                (slide as? TutorialSlideView)?.didEnterSlide()
                
            } else if i == slides.count - 1 {
                slide.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
            }
            
            if i > 0 {
                let previousSlide = slides[i - 1]
                slide.leadingAnchor.constraint(equalTo: previousSlide.trailingAnchor).isActive = true
            }
        }
    }
    
    private var slideLayoutMargins: UIEdgeInsets {
        var extraTop = CGFloat(0)
        var extraBottom = CGFloat(0)
        
        if !UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory {
            if UIDevice.is812h || UIDevice.is736h {
                extraTop = .extendedPadding
                extraBottom = .extendedPadding
                
            } else if UIDevice.is667h {
                extraTop = .padding
                extraBottom = .padding
            }
        }
        
        return UIEdgeInsets(top: .padding + extraTop, left: .padding, bottom: .padding + extraBottom, right: .padding)
    }
    
    // MARK: - Video
    
    @objc fileprivate func dismissViewController() {
        dismiss(animated: true, completion: nil)
    }
}

extension TutorialViewController : UIScrollViewDelegate {
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        scrollViewIsScrollingAnimation = false
        
        (currentSlide as? TutorialSlideView)?.didEnterSlide()
    }
}

extension TutorialViewController : TutorialVideoViewControllerDelegate, TutorialEmailSlideViewDelegate, TutorialTrySlideViewDelegate {
    @objc fileprivate func tutorialWelcomeSlideViewDidComplete() {
        let viewController = TutorialVideoViewController()
        viewController.modalTransitionStyle = .crossDissolve
        viewController.delegate = self
        present(viewController, animated: true, completion: nil)
    }
    
    func tutorialVideoViewControllerDidTapDone(_ viewController: TutorialVideoViewController) {
        viewController.delegate = nil
        dismissViewController()
        scrollToNextSlide()
    }
    
    func tutorialEmailSlideViewDidComplete(_ slideView: TutorialEmailSlideView) {
        slideView.delegate = nil
        scrollToNextSlide()
    }
    
    func tutorialEmailSlideViewDidTapPrivacyPolicy(_ slideView: TutorialEmailSlideView) {
        if let vc = TutorialEmailSlideView.privacyPolicyViewController(withDoneTarget: self, action: #selector(dismissViewController)) {
            present(vc, animated: true, completion: nil)
        }
    }
    
    func tutorialEmailSlideViewDidTapTermsOfService(_ slideView: TutorialEmailSlideView) {
        if let vc = TutorialEmailSlideView.termsOfServiceViewController(withDoneTarget: self, action: #selector(dismissViewController)) {
            present(vc, animated: true, completion: nil)
        }
    }
    
    func tutorialTrySlideViewDidComplete(_ slideView: TutorialTrySlideView) {
        slideView.delegate = nil
        
        UserDefaults.standard.set(true, forKey: UserDefaultsKeys.onboardingCompleted)
        track("Finished Tutorial")
        AnalyticsTrackers.branch.track("Finished Tutorial")
        
        delegate?.tutoriaViewControllerDidComplete(self)
    }
}
