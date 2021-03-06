//
//  CampainPromotionViewController.swift
//  screenshot
//
//  Created by Jonathan Rose on 4/17/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//
import UIKit
import AVFoundation
import ActiveLabel

protocol CampaignPromotionViewControllerDelegate: class {
    func campaignPromotionViewControllerDidPressLearnMore(_ viewController:CampaignPromotionViewController)
    func campaignPromotionViewControllerDidPressSkip(_ viewController:CampaignPromotionViewController)
    
}

class CampaignPromotionViewController: UIViewController {
    /*
        To re-use this viewController change the CampaignDescription
     */
    let campaign = CampaignDescription.init(
            headline: "Visit our Instagram to learn how to participate!",
            byline: "",
            buttonText: "Follow Us",
            videoName: "campaign_video_2018_12_01",
            thumbName: "campaign_thumb_2018_12_01",
            videoRatio: 1080.0 / 608.0)

    var showsReplayButtonUponFinishing: Bool = true
    var willPresentInModal:Bool = false
    private(set) var playPauseButton = UIButton()
    private var playerLayer: AVPlayerLayer?
    private var player: AVPlayer?

    var imageView:UIImageView?
    
    weak var delegate: CampaignPromotionViewControllerDelegate?
    private let transitioning = ViewControllerTransitioningDelegate.init(presentation: .intrinsicContentSize, transition: .modal)
    
    init(modal:Bool) {
        super.init(nibName: nil, bundle: nil)
        self.willPresentInModal = modal

        if modal {
            transitioningDelegate = transitioning
            modalPresentationStyle = .custom
        }

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let container:UIView = {
            if willPresentInModal {
                self.view.layer.masksToBounds = true
                self.view.layer.cornerRadius = 8
                self.view.backgroundColor = .white
                return self.view
            }else{
                self.view.backgroundColor = .gray9
                let c = UIView.init()
                c.backgroundColor = .white
                let layer = c.layer
                layer.masksToBounds = true
                layer.shadowColor = Shadow.basic.color.cgColor
                layer.shadowOffset = Shadow.basic.offset
                layer.shadowRadius = Shadow.basic.radius
                layer.cornerRadius = 8
                c.translatesAutoresizingMaskIntoConstraints = false
                self.view.addSubview(c)
                if UIDevice.is320w {
                    c.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 15).isActive = true
                    c.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -15).isActive = true
                    c.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor, constant: 20).isActive = true
                    c.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -20).isActive = true
                }else{
                    c.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 34).isActive = true
                    c.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -34).isActive = true
                    c.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor, constant: 40).isActive = true
                    c.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -40).isActive = true
                }
                return c
            }
        }()
        if UIDevice.is320w {
            container.layoutMargins = UIEdgeInsets(top: 5, left: 15, bottom: 5, right: 15)
        }else{
            container.layoutMargins = UIEdgeInsets(top: 25, left: 25, bottom: 25, right: 25)
        }
        let skipButton = UIButton.init()
        skipButton.translatesAutoresizingMaskIntoConstraints = false
        skipButton.titleLabel?.textAlignment = .center
        skipButton.titleLabel?.font = UIFont.screenshopFont(.hind, textStyle: .body, staticSize: true)
        skipButton.addTarget(self, action: #selector(tappedSecondaryButton), for: .touchUpInside)
        skipButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 30, bottom: 10, right: 30)
        container.addSubview(skipButton)
        skipButton.setTitle("skip", for: .normal)
        skipButton.setTitleColor(.gray3, for: .normal)
        skipButton.setTitleColor(.gray5, for: .highlighted)
        skipButton.centerXAnchor.constraint(equalTo: container.centerXAnchor).isActive = true
        skipButton.bottomAnchor.constraint(equalTo: container.layoutMarginsGuide.bottomAnchor, constant: -skipButton.contentEdgeInsets.bottom).isActive = true
        skipButton.setContentCompressionResistancePriority(.required, for: .vertical)
        skipButton.isHidden = !willPresentInModal
        
        let mainButton = MainButton.init()
        mainButton.translatesAutoresizingMaskIntoConstraints = false
        mainButton.backgroundColor = .crazeRed
        mainButton.addTarget(self, action: #selector(tappedLearnMoreButton), for: .touchUpInside)
        container.addSubview(mainButton)
        mainButton.setTitle(self.campaign.buttonText, for: .normal)
        mainButton.leadingAnchor.constraint(equalTo: container.layoutMarginsGuide.leadingAnchor).isActive = true
        mainButton.trailingAnchor.constraint(equalTo: container.layoutMarginsGuide.trailingAnchor).isActive = true
        mainButton.bottomAnchor.constraint(equalTo: skipButton.topAnchor).isActive = true
        mainButton.setContentCompressionResistancePriority(.required, for: .vertical)
        
        let explainationLabel = ActiveLabel()
        explainationLabel.attributedText = NSAttributedString.init(string: self.campaign.byline, attributes: [.font:UIFont.screenshopFont(.hind, textStyle: .body, staticSize: true)])
        explainationLabel.translatesAutoresizingMaskIntoConstraints = false
        explainationLabel.textAlignment = .center
        explainationLabel.numberOfLines = 0
        container.addSubview(explainationLabel)
        explainationLabel.leadingAnchor.constraint(equalTo: container.layoutMarginsGuide.leadingAnchor).isActive = true
        explainationLabel.trailingAnchor.constraint(equalTo: container.layoutMarginsGuide.trailingAnchor).isActive = true
        explainationLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        explainationLabel.isUserInteractionEnabled = true

        explainationLabel.handleMentionTap { userHandle in
            if let url = URL.init(string: "https://www.instagram.com/screenshopit/"),  UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
        
        let headlineLabel = UILabel()
        headlineLabel.font = UIFont.screenshopFont(.hind, textStyle: .title3, staticSize: true)
        headlineLabel.text = self.campaign.headline
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        headlineLabel.textAlignment = .center
        headlineLabel.numberOfLines = 0
        container.addSubview(headlineLabel)
        headlineLabel.leadingAnchor.constraint(equalTo: container.layoutMarginsGuide.leadingAnchor).isActive = true
        headlineLabel.trailingAnchor.constraint(equalTo: container.layoutMarginsGuide.trailingAnchor).isActive = true
        headlineLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        
        let imageView = UIImageView.init()
        imageView.isUserInteractionEnabled = true
        imageView.clipsToBounds = true
        imageView.image = UIImage.init(named: self.campaign.thumbName)
        let gesture = UITapGestureRecognizer.init(target: self, action: #selector(tappedVideo))
        imageView.addGestureRecognizer(gesture)
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .black
        container.addSubview(imageView)
        imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: container.trailingAnchor).isActive = true
        imageView.topAnchor.constraint(equalTo: container.topAnchor).isActive = true
        imageView.heightAnchor.constraint(greaterThanOrEqualTo: container.heightAnchor, multiplier: 0.5).isActive = true
        imageView.heightAnchor.constraint(lessThanOrEqualTo: container.heightAnchor, multiplier: 0.75).isActive = true
        
        let asBigAsPossible = imageView.heightAnchor.constraint(equalTo: container.heightAnchor)
        asBigAsPossible.priority = .defaultLow
        asBigAsPossible.isActive = true

        let ratio = imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: self.campaign.videoRatio )
        ratio.priority = .init(800)
        ratio.isActive = true
        
        self.imageView = imageView
        
        playPauseButton.translatesAutoresizingMaskIntoConstraints = false
        playPauseButton.adjustsImageWhenHighlighted = true
        playPauseButton.isUserInteractionEnabled = false
        playPauseButton.imageView?.contentMode = .scaleAspectFit
        playPauseButton.setImage(UIImage(named: "playCircle"), for: .normal)
        playPauseButton.alpha = 1.0
        container.addSubview(playPauseButton)
        playPauseButton.centerXAnchor.constraint(equalTo: imageView.centerXAnchor).isActive = true
        playPauseButton.centerYAnchor.constraint(equalTo: imageView.centerYAnchor).isActive = true
        
        
        let pad1 = UIView.init()
        pad1.isHidden = true
        pad1.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(pad1)
        pad1.topAnchor.constraint(equalTo: imageView.bottomAnchor).isActive = true
        pad1.bottomAnchor.constraint(equalTo: headlineLabel.topAnchor).isActive = true
        
        let pad2 = UIView.init()
        pad2.isHidden = true
        pad2.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(pad2)
        pad2.topAnchor.constraint(equalTo: headlineLabel.bottomAnchor).isActive = true
        pad2.bottomAnchor.constraint(equalTo: explainationLabel.topAnchor).isActive = true
        
        let pad3 = UIView.init()
        pad3.isHidden = true
        pad3.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(pad3)
        pad3.topAnchor.constraint(equalTo: explainationLabel.bottomAnchor).isActive = true
        pad3.bottomAnchor.constraint(equalTo: mainButton.topAnchor).isActive = true
        
        pad1.heightAnchor.constraint(equalTo: pad2.heightAnchor).isActive = true
        pad3.heightAnchor.constraint(equalTo: pad2.heightAnchor).isActive = true
        
        let idealSpacing = pad3.heightAnchor.constraint(greaterThanOrEqualToConstant: 25)
        idealSpacing.priority = .init(700)  //would rather the correct ratio over this spacing
        idealSpacing.isActive = true
    
        let requiredSpacing = pad3.heightAnchor.constraint(greaterThanOrEqualToConstant: 5)
        requiredSpacing.priority = .init(900)  
        requiredSpacing.isActive = true
        
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let player = self.player {
            if player.timeControlStatus != .paused {
                self.player?.pause()
                self.showReplayButton()
            }
        }
    }
    
    @objc func tappedLearnMoreButton() {
        if let player = self.player {
            if player.timeControlStatus != .paused {
                self.player?.pause()
                self.showReplayButton()
            }
        }
        Analytics.trackOnboardingCampaignVideoShopAtBoohoo(campaign: .campaign20180920)
        let affiliateLink = "https://www.instagram.com/screenshopit/"
        if let url = URL.init(string:affiliateLink) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:]) { (sucess) in
                    self.delegate?.campaignPromotionViewControllerDidPressLearnMore(self)
                }
            }
        }
    }
    
   
    
    @objc func tappedSecondaryButton() {
        Analytics.trackOnboardingCampaignVideoSkip(campaign: .campaign20180920)
        self.delegate?.campaignPromotionViewControllerDidPressSkip(self)
    }
    
    @objc func tappedVideo(){
        if self.player == nil {
            let playerItem = AVPlayerItem(url: Bundle.main.url(forResource: self.campaign.videoName, withExtension: "mp4")!)
            let player = AVPlayer(playerItem: playerItem)
            player.allowsExternalPlayback = false
            do {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            } catch let error as NSError {
                Analytics.trackError(type: nil, domain: error.domain, code: error.code, localizedDescription: error.localizedDescription)
            }
            player.actionAtItemEnd = .pause
            self.player = player
            let layer = AVPlayerLayer(player: player)
            layer.videoGravity = .resizeAspect
            layer.backgroundColor = UIColor.white.cgColor
            if  let imageView = self.imageView {
                layer.frame = imageView.bounds
                imageView.layer.addSublayer(layer)
            }
            beginObserving(playerItem: playerItem)
            Analytics.trackOnboardingCampaignVideoPlay(campaign: .campaign20180920)
        }
        if let player = self.player {
            if player.timeControlStatus == .paused {
                player.playImmediately(atRate: 1.0)
                self.hideReplayButton()
            }else{
                self.player?.pause()
                self.showReplayButton()
            }
        }        
    }
    private func beginObserving(playerItem item:AVPlayerItem) {
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: item)
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    @objc private func playerDidFinishPlaying() {
        
        self.playerLayer?.removeFromSuperlayer()
        self.playerLayer = nil
        self.player = nil
        showReplayButton()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let layer = self.playerLayer, let imageView = self.imageView {
            layer.frame = imageView.bounds
        }
    }

    
    func showReplayButton() {
        playPauseButton.isSelected = false
        
        guard playPauseButton.alpha < 1 else {
            return
        }
        
        UIView.animate(withDuration: .defaultAnimationDuration) {
            self.playPauseButton.alpha = 1
        }
    }
    
    func hideReplayButton() {
        guard playPauseButton.alpha > 0 else {
            return
        }
        
        UIView.animate(withDuration: .defaultAnimationDuration) {
            self.playPauseButton.alpha = 0
        }
    }

    struct CampaignDescription {
        var headline:String
        var byline:String
        var buttonText:String
        var videoName:String
        var thumbName:String
        var videoRatio:CGFloat
    }
}
