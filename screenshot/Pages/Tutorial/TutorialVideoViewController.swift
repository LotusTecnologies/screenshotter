//
//  TutorialVideoViewController.swift
//  screenshot
//
//  Created by Jacob Relkin on 10/1/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import UIKit
import AVKit

enum TutorialVideo {
    case Standard
    case Ambassador(url: URL)
    
    var url: URL {
        switch self {
        case .Ambassador(let url):
            return url
        case .Standard:
            return URL(string: "http://res.cloudinary.com/crazeapp/video/upload/v1506927835/Craze_App_bcf91q.mp4")!
        }
    }
}

@objc protocol TutorialVideoViewControllerDelegate {
    @objc optional func tutorialVideoViewControllerDidPause(_ viewController:TutorialVideoViewController)
    @objc optional func tutorialVideoViewControllerDidPlay(_ viewController:TutorialVideoViewController)
    @objc optional func tutorialVideoViewControllerDidEnd(_ viewController:TutorialVideoViewController)
    
    func tutorialVideoViewControllerDoneButtonTapped(_ viewController:TutorialVideoViewController)
}

class TutorialVideoViewController : UIViewController {
    let overlayViewController = TutorialVideoOverlayViewController()
    
    weak var delegate: TutorialVideoViewControllerDelegate?
    
    private let playerLayer: AVPlayerLayer!
    private let player: AVPlayer!
    private var ended = false
    
    // MARK: - Initialization
    
    init(video: TutorialVideo) {
        let playerItem = AVPlayerItem(url: video.url)

        player = AVPlayer(playerItem: playerItem)
        player.allowsExternalPlayback = false
        player.actionAtItemEnd = .pause
        playerLayer = AVPlayerLayer(player: player)
        
        super.init(nibName: nil, bundle: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    convenience override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.init(video: .Standard)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - UIViewController

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer.frame = view.bounds
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add player layer
        view.layer.addSublayer(playerLayer)

        // Add overlay VC
        addChildViewController(overlayViewController)
        overlayViewController.didMove(toParentViewController: self)
        view.addSubview(overlayViewController.view)
        
        overlayViewController.doneButtonTapped = {
            self.delegate?.tutorialVideoViewControllerDoneButtonTapped(self)
        }

        // Add tap gesture recognizer
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        view.addGestureRecognizer(tap)
        
        player.play()
        delegate?.tutorialVideoViewControllerDidPlay?(self)
    }
    
    // MARK: - Actions
    
    @objc private func handleTap() {
        guard ended == false else {
            return
        }
        
        if player.togglePlayback() == .paused {
            overlayViewController.flashPauseOverlay()
            
            delegate?.tutorialVideoViewControllerDidPause?(self)
        } else {
            delegate?.tutorialVideoViewControllerDidPlay?(self)
        }
    }
    
    @objc private func playerDidFinishPlaying() {
        ended = true
        
        overlayViewController.replayButtonTapped = replayButtonTapped
        overlayViewController.showReplayButton()
        
        delegate?.tutorialVideoViewControllerDidEnd?(self)
    }
    
    private func replayButtonTapped() {
        overlayViewController.hideReplayButton()
        ended = false
        
        player.seek(to: CMTime(seconds: 0, preferredTimescale: player.currentTime().timescale))
        player.playImmediately(atRate: 1)
    }
}

extension AVPlayer {
    enum PlaybackState {
        case playing
        case paused
    }
    
    func togglePlayback() -> PlaybackState {
        guard rate > 0 else {
            play()
            return .playing
        }
        
        pause()
        return .paused
    }
}
