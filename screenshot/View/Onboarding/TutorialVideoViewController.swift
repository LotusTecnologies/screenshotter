//
//  TutorialVideoViewController.swift
//  screenshot
//
//  Created by Jacob Relkin on 10/1/17.
//  Copyright (c) 2017 crazeapp. All rights reserved.
//

import UIKit
import AVFoundation


class TutorialVideoViewController : BaseViewController {
    var showsReplayButtonUponFinishing: Bool = true
    
    weak var delegate: VideoDisplayingViewControllerDelegate?
    
    private let playerLayer: AVPlayerLayer!
    private let player: AVPlayer!
    
    private let overlayView = TutorialVideoOverlayView()
    
    private var observers = [NSKeyValueObservation]()
    private var ended = false
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        let playerItem = AVPlayerItem(url: Bundle.main.url(forResource: "Craze_Video", withExtension: "mp4")!)
        
        player = AVPlayer(playerItem: playerItem)
        player.allowsExternalPlayback = false
        player.actionAtItemEnd = .pause
        player.isMuted = true
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        } catch let error as NSError {
            Analytics.trackError(type: nil, domain: error.domain, code: error.code, localizedDescription: error.localizedDescription)
        }
        
        playerLayer = AVPlayerLayer(player: player)
        
        super.init(nibName: nil, bundle: nil)
    }
    
    deinit {
        endObserving()
    }
    
    // MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = nil
        
        view.layer.addSublayer(playerLayer)
        
        if let item = player.currentItem {
            beginObserving(playerItem: item)
        }
        
        overlayView.volumeToggleButton.isSelected = true
        overlayView.volumeToggleButton.addTarget(self, action: #selector(volumeToggleButtonTapped), for: .touchUpInside)
        overlayView.replayPauseButton.addTarget(self, action: #selector(replayPauseButtonTapped), for: .touchUpInside)
        overlayView.doneButton.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlayView)
        overlayView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        observers.append(AVAudioSession.sharedInstance().observe(\.outputVolume, options: [.new]) { session, change in
            let shouldMute = (change.newValue ?? 1) == 0
            
            self.overlayView.volumeToggleButton.isSelected = shouldMute
            self.player.isMuted = shouldMute
        })
        
        // Add tap gesture recognizer
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        view.addGestureRecognizer(tap)
        
        if player.playbackState == .paused {
            player.play()
            delegate?.videoDisplayingViewControllerDidPlay(self)
            Analytics.trackStartedTutorialVideo()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        hideStatusBar()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.overlayView.scaleInDoneButton()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
      
        player.pause()
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient)
        } catch let error as NSError {
            Analytics.trackError(type: nil, domain: error.domain, code: error.code, localizedDescription: error.localizedDescription)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        playerLayer.frame = view.bounds
    }
    
    // MARK: - Private
    
    private func beginObserving(playerItem item:AVPlayerItem) {
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: item)
    }
    
    private func endObserving() {
        observers.forEach { $0.invalidate() }
        
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Actions
    
    @objc private func replayPauseButtonTapped() {
        guard overlayView.replayPauseButton.isSelected == false else {
            // Ensure we are in the replay state before doing anything.
            return
        }
        
        overlayView.hideReplayButton()
        ended = false
        
        player.seek(to: CMTime(seconds: 0, preferredTimescale: player.currentTime().timescale)) { finished in
            if finished {
                self.player.play()
                self.overlayView.showVolumeToggleButton()
            }
        }
        
        Analytics.trackReplayedTutorialVideo()

        delegate?.videoDisplayingViewControllerDidPlay(self)
    }
    
    @objc private func doneButtonTapped() {
        Analytics.trackUserExitedTutorialVideo(progressInSeconds: self.player.currentTime().seconds)
        delegate?.videoDisplayingViewControllerDidTapDone(self)
    }
    
    @objc private func volumeToggleButtonTapped() {
        let button = overlayView.volumeToggleButton
        let isVolumeMute = AVAudioSession.sharedInstance().outputVolume == 0
        
        if isVolumeMute && button.isSelected {
            let alert = UIAlertController(title: "tutorial.video.mute.title".localized, message: "tutorial.video.mute.detail".localized, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "generic.ok".localized, style: .default, handler: nil))
            present(alert, animated: true)
            
            return
        }
        
        button.isSelected = !button.isSelected
        player.isMuted = button.isSelected
        
    }
    
    
    @objc private func handleTap() {
        guard ended == false else {
            return
        }
        
        if player.togglePlayback() == .paused {
            overlayView.flashPauseOverlay()
            Analytics.trackPausedTutorialVideo()

            delegate?.videoDisplayingViewControllerDidPause(self)
            
        } else {
            Analytics.trackContinuedTutorialVideo()
            delegate?.videoDisplayingViewControllerDidPlay(self)
        }
    }
    
    @objc private func playerDidFinishPlaying() {
        ended = true
        
        if showsReplayButtonUponFinishing {
            overlayView.showReplayButton()
        }
        
        overlayView.hideVolumeToggleButton()
        Analytics.trackCompletedTutorialVideo()
        delegate?.videoDisplayingViewControllerDidEnd(self)
    }
}

extension AVPlayer {
    enum PlaybackState {
        case playing
        case paused
    }
    
    var playbackState: PlaybackState {
        return rate > 0 ? .playing : .paused
    }
    
    func togglePlayback() -> PlaybackState {
        rate == 0 ? play() : pause()
        
        return playbackState
    }
}
