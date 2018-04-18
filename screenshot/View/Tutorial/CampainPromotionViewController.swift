//
//  CampainPromotionViewController.swift
//  screenshot
//
//  Created by Jonathan Rose on 4/17/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit
import AVFoundation

class CampainPromotionViewController: UIViewController {
    var showsReplayButtonUponFinishing: Bool = true
    var willDisplayInPopover:Bool = false
    private(set) var playPauseButton = UIButton()
    private var playerLayer: AVPlayerLayer?
    private var player: AVPlayer?

    var imageView:UIImageView?
    
    weak var delegate: VideoDisplayingViewControllerDelegate?
    private let transitioning = ViewControllerTransitioningDelegate.init(presentation: .intrinsicContentSize, transition: .modal)
    
    init(modal:Bool) {
        super.init(nibName: nil, bundle: nil)
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
            if willDisplayInPopover {
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
                c.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 34).isActive = true
                c.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -34).isActive = true
                c.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor, constant: 40).isActive = true
                c.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -40).isActive = true
                return c
            }
        }()
        
        
        
      
        
        let soundsGoodButton = MainButton.init()
        soundsGoodButton.translatesAutoresizingMaskIntoConstraints = false
        soundsGoodButton.backgroundColor = .crazeRed
        soundsGoodButton.addTarget(self, action: #selector(tappedButton), for: .touchUpInside)
        container.addSubview(soundsGoodButton)
        soundsGoodButton.setTitle("2018_04_20_campain.button".localized, for: .normal)
        soundsGoodButton.leftAnchor.constraint(equalTo: container.leftAnchor, constant: 25).isActive = true
        soundsGoodButton.rightAnchor.constraint(equalTo: container.rightAnchor, constant: -25).isActive = true
        soundsGoodButton.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -25).isActive = true
        soundsGoodButton.heightAnchor.constraint(equalToConstant: 46).isActive = true
        
        let explainationLabel = UILabel()
        explainationLabel.font = UIFont.preferredFont(forTextStyle: .body)
        explainationLabel.text = "2018_04_20_campain.body".localized
        explainationLabel.translatesAutoresizingMaskIntoConstraints = false
        explainationLabel.textAlignment = .center
        explainationLabel.numberOfLines = 0
        container.addSubview(explainationLabel)
        explainationLabel.leftAnchor.constraint(equalTo: container.leftAnchor, constant: 25).isActive = true
        explainationLabel.rightAnchor.constraint(equalTo: container.rightAnchor, constant: -25).isActive = true
        explainationLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        
        let headlineLabel = UILabel()
        headlineLabel.font = UIFont.preferredFont(forTextStyle: .title2)
        headlineLabel.text = "2018_04_20_campain.headline".localized
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        headlineLabel.textAlignment = .center
        headlineLabel.numberOfLines = 0
        container.addSubview(headlineLabel)
        headlineLabel.leftAnchor.constraint(equalTo: container.leftAnchor, constant: 25).isActive = true
        headlineLabel.rightAnchor.constraint(equalTo: container.rightAnchor, constant: -25).isActive = true
        headlineLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        
        let imageView = UIImageView.init()
        imageView.isUserInteractionEnabled = true
        let gesture = UITapGestureRecognizer.init(target: self, action: #selector(tappedVideo))
        imageView.addGestureRecognizer(gesture)
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .black
        container.addSubview(imageView)
        imageView.leftAnchor.constraint(equalTo: container.leftAnchor).isActive = true
        imageView.rightAnchor.constraint(equalTo: container.rightAnchor).isActive = true
        imageView.topAnchor.constraint(equalTo: container.topAnchor).isActive = true
        imageView.heightAnchor.constraint(greaterThanOrEqualTo: container.heightAnchor, multiplier: 0.5).isActive = true
        imageView.heightAnchor.constraint(lessThanOrEqualTo: container.heightAnchor, multiplier: 0.75).isActive = true
        
        let asBigAsPossible = imageView.heightAnchor.constraint(equalTo: container.heightAnchor)
        asBigAsPossible.priority = .defaultLow
        asBigAsPossible.isActive = true

        let ratio = imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 1920.0 / 1080.0 )
        ratio.priority = .init(800)
        ratio.isActive = true
        
        self.imageView = imageView
        
        playPauseButton.translatesAutoresizingMaskIntoConstraints = false
        playPauseButton.adjustsImageWhenHighlighted = true
        playPauseButton.isUserInteractionEnabled = false
        playPauseButton.imageView?.contentMode = .scaleAspectFit
        playPauseButton.setImage(UIImage(named: "playCircle"), for: .normal)
        playPauseButton.setImage(UIImage(named: "pauseCircle"), for: .selected)
        playPauseButton.setImage(UIImage(named: "pauseCircle"), for: [.highlighted, .selected])
        playPauseButton.alpha = 1.0
        container.addSubview(playPauseButton)
        playPauseButton.centerXAnchor.constraint(equalTo: imageView.centerXAnchor).isActive = true
        playPauseButton.centerYAnchor.constraint(equalTo: imageView.centerYAnchor).isActive = true
        
        
        let pad1 = UIView.init()
        pad1.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(pad1)
        pad1.centerXAnchor.constraint(equalTo: container.centerXAnchor).isActive = true
        pad1.widthAnchor.constraint(equalToConstant: 100).isActive = true
        pad1.topAnchor.constraint(equalTo: imageView.bottomAnchor).isActive = true
        pad1.bottomAnchor.constraint(equalTo: headlineLabel.topAnchor).isActive = true
        
        let pad2 = UIView.init()
        pad2.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(pad2)
        pad2.centerXAnchor.constraint(equalTo: container.centerXAnchor).isActive = true
        pad2.widthAnchor.constraint(equalToConstant: 100).isActive = true
        pad2.topAnchor.constraint(equalTo: headlineLabel.bottomAnchor).isActive = true
        pad2.bottomAnchor.constraint(equalTo: explainationLabel.topAnchor).isActive = true
        
        let pad3 = UIView.init()
        pad3.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(pad3)
        pad3.centerXAnchor.constraint(equalTo: container.centerXAnchor).isActive = true
        pad3.widthAnchor.constraint(equalToConstant: 100).isActive = true
        pad3.topAnchor.constraint(equalTo: explainationLabel.bottomAnchor).isActive = true
        pad3.bottomAnchor.constraint(equalTo: soundsGoodButton.topAnchor).isActive = true
        
        
        pad1.heightAnchor.constraint(equalTo: pad2.heightAnchor).isActive = true
        pad3.heightAnchor.constraint(equalTo: pad2.heightAnchor).isActive = true
        
        let idealSpacing = pad3.heightAnchor.constraint(greaterThanOrEqualToConstant: 25)
        idealSpacing.priority = .init(700)  //would rather the correct ratio over this spacing
        idealSpacing.isActive = true
    
        let requiredSpacing = pad3.heightAnchor.constraint(greaterThanOrEqualToConstant: 5)
        requiredSpacing.priority = .init(900)  
        requiredSpacing.isActive = true
        
    }
    
    @objc func tappedButton() {
        UserDefaults.standard.set(true, forKey: UserDefaultsKeys.sawVideoForCampaign_2018_04_20)
        self.delegate?.videoDisplayingViewControllerDidTapDone(self)
    }
    
    @objc func tappedVideo(){
        if self.player == nil {
            let playerItem = AVPlayerItem(url: Bundle.main.url(forResource: "Craze_Video", withExtension: "mp4")!)
            let player = AVPlayer(playerItem: playerItem)
            player.allowsExternalPlayback = false
            
            player.actionAtItemEnd = .pause
            self.player = player
            let layer = AVPlayerLayer(player: player)
            layer.videoGravity = .resizeAspectFill
            if  let imageView = self.imageView {
                layer.frame = imageView.bounds
                imageView.layer.addSublayer(layer)
            }
            beginObserving(playerItem: playerItem)
        }
        if let player = self.player {
            if player.playbackState == .paused {
                player.play()
                self.hideReplayButton()
            }else{
                self.player?.pause()
                self.flashPauseOverlay()
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
    
    func flashPauseOverlay() {
        playPauseButton.isSelected = true
        playPauseButton.alpha = 0
        
        UIView.animateKeyframes(withDuration: Constants.defaultAnimationDuration * 3, delay: 0, options: UIViewKeyframeAnimationOptions(rawValue: 0), animations: {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.33, animations: {
                self.playPauseButton.alpha = 1
            })
            UIView.addKeyframe(withRelativeStartTime: 0.66, relativeDuration: 1, animations: {
                self.playPauseButton.alpha = 0.0
            })
        })
    }
    
    func showReplayButton() {
        playPauseButton.isSelected = false
        
        guard playPauseButton.alpha < 1 else {
            return
        }
        
        UIView.animate(withDuration: Constants.defaultAnimationDuration) {
            self.playPauseButton.alpha = 1
        }
    }
    
    func hideReplayButton() {
        guard playPauseButton.alpha > 0 else {
            return
        }
        
        UIView.animate(withDuration: Constants.defaultAnimationDuration) {
            self.playPauseButton.alpha = 0
        }
    }
    
    

}
