//
//  TutorialViewController.swift
//  screenshot
//
//  Created by Jacob Relkin on 10/14/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import UIKit

@objc protocol TutorialViewControllerDelegate : class {
    func tutoriaViewControllerDidComplete(_ viewController: TutorialViewController)
}

class TutorialViewController : UIViewController {
    weak var delegate: TutorialViewControllerDelegate?
    
    var video = TutorialVideo.Standard
    var updatePromptHandler: UpdatePromptHandler!
    let scrollView = UIScrollView()
    let contentView = UIView()
    
    var contentLayoutMargins: UIEdgeInsets {
        get {
            return contentView.layoutMargins
        } set {
            contentView.layoutMargins = newValue
        }
    }
    
    private var didPresentDeterminePushAlertController = false
    fileprivate var scrollViewIsScrollingAnimation = false
    
    // MARK: Slides
    
    var slides = [UIView]()
    
    private func buildSlides() -> [UIView] {
        let welcomeSlide = TutorialWelcomeSlideView()
        welcomeSlide.getStartedButtonTapped = presentVideo
        
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
    
    // MARK: - Initialization
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        slides = buildSlides()
        updatePromptHandler = UpdatePromptHandler(containerViewController: self)
    }
    
    // MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        track("Started Tutorial")
        
        updatePromptHandler.start()
        
        view.backgroundColor = .white
        
        // Setup scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.delegate = self
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.isPagingEnabled = true
        scrollView.isScrollEnabled = false
        view.addSubview(scrollView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        // Setup content view
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // TODO: better small screen layout
        let is480h = UIDevice.is480h
        
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: is480h ? topLayoutGuide.topAnchor : topLayoutGuide.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: CGFloat(slides.count)),
            contentView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
        
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
    
    // MARK: - Public
    
    func presentVideo() {
        let vc = TutorialVideoViewController(video: video)
        vc.modalTransitionStyle = .crossDissolve
        vc.delegate = self
        present(vc, animated: true, completion: nil)
    }
    
    // MARK: - Private
    
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
        let padding = Geometry.padding
        let top = contentView.layoutMargins.top
        
        slides.enumerated().forEach { i, slide in
            slide.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(slide)
            
            slide.layoutMargins = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
            
            NSLayoutConstraint.activate([
                slide.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
                slide.heightAnchor.constraint(equalTo: scrollView.heightAnchor, constant: -top),
                slide.topAnchor.constraint(equalTo: contentView.topAnchor, constant: top)
                ])
            
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

extension TutorialViewController : TutorialVideoViewControllerDelegate {
    func tutorialVideoViewControllerDoneButtonTapped(_ viewController: TutorialVideoViewController) {
        dismissViewController()
        scrollToNextSlide()
    }
}

extension TutorialViewController : TutorialEmailSlideViewDelegate {
    func tutorialEmailSlideViewDidComplete(_ slideView: TutorialEmailSlideView) {
        slideView.delegate = nil
        scrollToNextSlide()
    }
    
    func tutorialEmailSlideViewDidTapPrivacyPolicy(_ slideView: TutorialEmailSlideView) {
        if let vc = TutorialEmailSlideView.privacyPolicyViewController(withDoneTarget: self, action: #selector(dismissViewController)) {            present(vc, animated: true, completion: nil)
        }
    }
    
    func tutorialEmailSlideViewDidTapTermsOfService(_ slideView: TutorialEmailSlideView) {
        if let vc = TutorialEmailSlideView.termsOfServiceViewController(withDoneTarget: self, action: #selector(dismissViewController)) {
            present(vc, animated: true, completion: nil)
        }
    }
}

extension TutorialViewController : TutorialTrySlideViewDelegate {
    func tutorialTrySlideViewDidComplete(_ slideView: TutorialTrySlideView) {
        slideView.delegate = nil
        
        UserDefaults.standard.set(true, forKey: UserDefaultsKeys.onboardingCompleted)
        track("Finished Tutorial")
        AnalyticsTrackers.branch.track("Finished Tutorial")
        
        delegate?.tutoriaViewControllerDidComplete(self)
    }
}
