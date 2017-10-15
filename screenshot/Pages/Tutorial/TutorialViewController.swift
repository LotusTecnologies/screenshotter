//
//  TutorialViewController.swift
//  screenshot
//
//  Created by Jacob Relkin on 10/14/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import UIKit

@objc protocol TutorialViewControllerDelegate : class {
    func tutorialDidComplete(_ viewController: TutorialViewController)
}

class TutorialViewController : UIViewController {
    enum StartMode {
        case Standard
        case AmbassadorLink(url: URL)
        case Replay
        
        var tutorialVideo: TutorialVideo? {
            switch self {
            case .AmbassadorLink(let url):
                return .Ambassador(url: url)
            case .Standard:
                return .Standard
            case .Replay:
                return nil
            }
        }
    }

    weak var delegate: TutorialViewControllerDelegate?
    
    var updatePromptHandler: UpdatePromptHandler!
    
    var startMode: StartMode
    var scrollView: UIScrollView!
    var contentView = UIView()
    var contentLayoutMargins: UIEdgeInsets {
        get {
            return contentView.layoutMargins
        } set {
            contentView.layoutMargins = newValue
        }
    }
    
    private var didPresentDeterminePushAlertController:Bool = false
    fileprivate var scrollViewIsScrollingAnimation:Bool = false
    
    // MARK: Slides
    
    var slides = [TutorialBaseSlideView]()
    
    private func buildSlides() -> [TutorialBaseSlideView] {
        let welcomeSlide = TutorialWelcomeSlideView()
        welcomeSlide.delegate = self
        
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
    
    fileprivate var currentSlide: TutorialBaseSlideView {
        return slides[currentSlideIndex]
    }
    
    // MARK: - Initialization
    
    override convenience init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.init(startMode: .Replay)
    }
    
    public init(startMode mode: StartMode) {
        startMode = mode

        super.init(nibName: nil, bundle: nil)
        
        slides = buildSlides()
        updatePromptHandler = UpdatePromptHandler(containerViewController: self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updatePromptHandler.start()
        
        view.backgroundColor = .white
        
        scrollView = buildScrollView()
        view.addSubview(scrollView)
        addScrollViewConstraints()
        
        scrollView.addSubview(contentView)
        addContentViewConstraints()
        
        prepareSlideViews()
        presentTutorialVideo()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        track("Started Tutorial")
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
    
    // MARK: -
    
    private func presentTutorialVideo() {
        guard let video = startMode.tutorialVideo else {
            return
        }
        
        let vc = TutorialVideoViewController(video: video)
        vc.delegate = self
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    fileprivate func scrollToNextSlide(animated: Bool = true) {
        guard scrollViewIsScrollingAnimation == false else {
            return
        }
        
        scrollViewIsScrollingAnimation = true
        currentSlide.willLeaveSlide()
        
        var offset:CGPoint = .zero
        offset.x = scrollView.bounds.size.width + scrollView.contentOffset.x
        scrollView.setContentOffset(offset, animated: animated)
    }
    
    private func prepareSlideViews() {
        let padding = Geometry.padding()
        let top = contentView.layoutMargins.top
        
        slides.enumerated().forEach { i, slide in
            slide.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(slide)
            
            slide.layoutMargins = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
            
            [slide.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
             slide.heightAnchor.constraint(equalTo: scrollView.heightAnchor, constant: -top),
             slide.topAnchor.constraint(equalTo: contentView.topAnchor)].forEach {
                $0.isActive = true
            }
            
            if i == 0 {
                slide.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
                slide.didEnterSlide()
            } else if i == slides.count - 1 {
                slide.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
            }
        
            if i > 0 {
                let previousSlide = slides[i - 1]
                slide.leadingAnchor.constraint(equalTo: previousSlide.trailingAnchor).isActive = true
            }
        }
    }
    
    private func addContentViewConstraints() {
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        [contentView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor),
         contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
         contentView.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor),
         contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
         contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: CGFloat(slides.count)),
         contentView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)].forEach {
            $0.isActive = true
        }
    }
    
    private func addScrollViewConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        [scrollView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor),
         scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
         scrollView.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor),
         scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
         scrollView.widthAnchor.constraint(greaterThanOrEqualToConstant: 0),
         scrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: 0)].forEach {
            $0.isActive = true
        }
        
    }
    
    private func buildScrollView() -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.delegate = self
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.isPagingEnabled = true
        scrollView.isScrollEnabled = false
        return scrollView
    }
}

extension TutorialViewController : UIScrollViewDelegate {
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        scrollViewIsScrollingAnimation = false
        
        currentSlide.didEnterSlide()
    }
}

extension TutorialViewController : TutorialWelcomeSlideViewDelegate, TutorialEmailSlideViewDelegate, TutorialTrySlideViewDelegate {
    func tutorialTrySlideViewDidComplete(_ slideView: TutorialTrySlideView!) {
        slideView.delegate = nil
        
        UserDefaults.standard.set(true, forKey: UserDefaultsKeys.tutorialCompleted)
        
        delegate?.tutorialDidComplete(self)
        track("Finished Tutorial")
    }
    
    func tutorialWelcomeSlideViewDidComplete(_ slideView: TutorialWelcomeSlideView!) {
        slideView.delegate = nil
        
        if UserDefaults.standard.bool(forKey: UserDefaultsKeys.tutorialCompleted) {
            delegate?.tutorialDidComplete(self)
        } else {
            scrollToNextSlide()
        }
    }
    
    func tutorialEmailSlideViewDidComplete(_ slideView: TutorialEmailSlideView!) {
        slideView.delegate = nil
        scrollToNextSlide()
    }
    
    func tutorialEmailSlideViewDidTapPrivacyPolicy(_ slideView: TutorialEmailSlideView!) {
        if let vc = TutorialEmailSlideView.privacyPolicyViewController(withDoneTarget: self, doneAction: #selector(dismissViewController)) {
            present(vc, animated: true, completion: nil)
        }
    }
    
    func tutorialEmailSlideViewDidTapTerms(ofService slideView: TutorialEmailSlideView!) {
        if let vc = TutorialEmailSlideView.privacyPolicyViewController(withDoneTarget: self,  doneAction:#selector(dismissViewController)) {
            present(vc, animated: true, completion: nil)
        }
    }
    
    @objc fileprivate func dismissViewController() {
        dismiss(animated: true, completion: nil)
    }
}

extension TutorialViewController : TutorialVideoViewControllerDelegate {
    func tutorialVideoWantsToDismiss() {
        dismissViewController()
    }
}
