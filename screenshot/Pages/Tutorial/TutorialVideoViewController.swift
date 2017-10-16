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
    case Ambassador(username: String)
    
    var playerItem: AVPlayerItem {
        switch self {
        case .Ambassador(let username):
            return AVPlayerItem(url: URL(string: "https://res.cloudinary.com/crazeapp/video/upload/\(username).mp4")!)
        case .Standard:
            return AVPlayerItem(url: URL(string: "https://res.cloudinary.com/crazeapp/video/upload/v1506927835/Craze_App_bcf91q.mp4")!)
        }
    }
}

@objc protocol TutorialVideoViewControllerDelegate {
    @objc optional func tutorialVideoViewControllerDidPause(_ viewController:TutorialVideoViewController)
    @objc optional func tutorialVideoViewControllerDidPlay(_ viewController:TutorialVideoViewController)
    @objc optional func tutorialVideoViewControllerDidEnd(_ viewController:TutorialVideoViewController)
    
    func tutorialVideoViewControllerDoneButtonTapped(_ viewController:TutorialVideoViewController)
}

// This factory is necessary to hide the `TutorialVideo` Swift enum from ObjC
class TutorialVideoViewControllerFactory : NSObject {
    class var replayViewController: TutorialVideoViewController {
        let username = UserDefaults.standard.string(forKey: UserDefaultsKeys.ambasssadorUsername)
        let video: TutorialVideo = (username != nil) ? .Ambassador(username: username!) : .Standard
        return TutorialVideoViewController(video: video)
    }
}

class TutorialVideoViewController : UIViewController {
    let overlayViewController = TutorialVideoOverlayViewController()
    
    weak var delegate: TutorialVideoViewControllerDelegate?
    
    private(set) var video: TutorialVideo!
    
    private let playerLayer: AVPlayerLayer!
    private let player: AVPlayer!
    private var ended = false
    
    // MARK: - Initialization
    
    init(video vid: TutorialVideo) {
        let playerItem = vid.playerItem
        
        player = AVPlayer(playerItem: playerItem)
        player.allowsExternalPlayback = false
        player.actionAtItemEnd = .pause
        
        playerLayer = AVPlayerLayer(player: player)
        
        super.init(nibName: nil, bundle: nil)
        
        video = vid
        beginObserving(playerItem: playerItem)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    convenience override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.init(video: .Standard)
    }
    
    deinit {
        player.currentItem?.removeObserver(self, forKeyPath: "status")
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if player.rate == 0 {
            player.playImmediately(atRate: 1)
            delegate?.tutorialVideoViewControllerDidPlay?(self)
        }
    }
    
    // MARK: - Player state observation
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let video = video,
            let playerItem = object as? AVPlayerItem,
            playerItem == player.currentItem else {
            return
        }
        
        if case .Ambassador(_) = video,
            playerItem.status == .failed {
            guard let error = playerItem.error as NSError?, error.domain == NSURLErrorDomain, error.code == -1100 else {
                return
            }

            // Ambassador video failed to download, use standard one.
            playerItem.removeObserver(self, forKeyPath: "status")

            self.video = .Standard
            
            let standardPlayerItem = self.video.playerItem
            player.replaceCurrentItem(with: standardPlayerItem)
            beginObserving(playerItem: standardPlayerItem)
            player.playImmediately(atRate: 1)
            delegate?.tutorialVideoViewControllerDidPlay?(self)
        }
    }
    
    // MARK: - Private
    
    private func beginObserving(playerItem item:AVPlayerItem) {
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: item)
        
        item.addObserver(self, forKeyPath: "status", options: [.new], context: nil)
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
        delegate?.tutorialVideoViewControllerDidPlay?(self)
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
        if rate == 0 {
            play()
        } else {
            pause()
        }
        
        return playbackState
    }
}
