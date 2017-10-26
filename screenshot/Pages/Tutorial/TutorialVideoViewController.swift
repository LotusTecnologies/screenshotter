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
    
    var url: URL {
        switch self {
        case .Ambassador(let username):
            return URL(string: "https://res.cloudinary.com/crazeapp/video/upload/\(username).mp4")!
        case .Standard:
            return Bundle.main.url(forResource: "Craze_Video", withExtension: "mp4")!
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

class TutorialVideoViewController : BaseViewController {
    var showsReplayButtonUponFinishing: Bool = true
    
    weak var delegate: TutorialVideoViewControllerDelegate?
    
    private(set) var video: TutorialVideo!
    
    private let playerLayer: AVPlayerLayer!
    private let player: AVPlayer!
    
    private let overlayView = TutorialVideoOverlayView(frame: .zero)
    
    private var observers = [NSKeyValueObservation]()
    private var ended = false
    
    // MARK: - Initialization
    
    init(video vid: TutorialVideo) {
        let playerItem = AVPlayerItem(url: vid.url)
        
        player = AVPlayer(playerItem: playerItem)
        player.allowsExternalPlayback = false
        player.actionAtItemEnd = .pause
        player.isMuted = true
        
        playerLayer = AVPlayerLayer(player: player)
        
        super.init(nibName: nil, bundle: nil)
        
        video = vid
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    convenience override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.init(video: .Standard)
    }
    
    deinit {
        endObserving()
    }
    
    // MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = nil
        
        // Add player layer
        view.layer.addSublayer(playerLayer)
        
        // Add overlay view
        view.addSubview(overlayView)

        NSLayoutConstraint.activate([
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        if let item = player.currentItem {
            beginObserving(playerItem: item)
        }

        overlayView.volumeToggleButton.isSelected = true
        overlayView.volumeToggleButton.addTarget(self, action: #selector(volumeToggleButtonTapped), for: .touchUpInside)
        overlayView.replayPauseButton.addTarget(self, action: #selector(replayPauseButtonTapped), for: .touchUpInside)
        overlayView.doneButton.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        
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
            delegate?.tutorialVideoViewControllerDidPlay?(self)
            
            track("Started Tutorial Video")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        hideStatusBar()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.overlayView.scaleInDoneButton()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
      
        player.pause()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        playerLayer.frame = view.bounds
    }
    
    // MARK: - Private
    
    private func beginObserving(playerItem item:AVPlayerItem) {
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: item)

        observers.append(item.observe(\.status, options: [.new, .initial]) { playerItem, change in
            guard let video = self.video, playerItem == self.player.currentItem else {
                return
            }
            
            if case .Ambassador(_) = video,
                playerItem.status == .failed {
                guard let error = playerItem.error as NSError?, error.domain == NSURLErrorDomain, error.code == -1100 else {
                    return
                }
                
                // Ambassador video failed to download, use standard one
                
                self.video = .Standard
                
                let standardPlayerItem = AVPlayerItem(url: TutorialVideo.Standard.url)
                self.player.replaceCurrentItem(with: standardPlayerItem)
                self.beginObserving(playerItem: standardPlayerItem)
                self.player.play()
                self.delegate?.tutorialVideoViewControllerDidPlay?(self)
            }
        })
    }
    
    private func endObserving() {
        observers.forEach { $0.invalidate() }
        
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Actions
    
    @objc private func replayPauseButtonTapped() {
        guard overlayView.replayPauseButton.isSelected == true else {
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
        
        track("Replayed Tutorial Video")
        delegate?.tutorialVideoViewControllerDidPlay?(self)
    }
    
    @objc private func doneButtonTapped() {
        track("User Exited Tutorial Video", properties: ["progressInSeconds": NSNumber(value: Int(self.player.currentTime().seconds))])
        
        delegate?.tutorialVideoViewControllerDoneButtonTapped(self)
    }
    
    @objc private func volumeToggleButtonTapped() {
        let button = overlayView.volumeToggleButton
        
        if AVAudioSession.sharedInstance().outputVolume == 0 && button.isSelected {
            // Volume is muted, ask user to turn up the volume?
            
            let alert = UIAlertController(title: "Turn up the volume!", message: "In order to hear the sound in the video, please turn up the volume on your phone!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
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
            
            track("Paused Tutorial Video")
            delegate?.tutorialVideoViewControllerDidPause?(self)
        } else {
            track("Continued Tutorial Video")
            delegate?.tutorialVideoViewControllerDidPlay?(self)
        }
    }
    
    @objc private func playerDidFinishPlaying() {
        ended = true
        
        if showsReplayButtonUponFinishing {
            overlayView.showReplayButton()
        }
        
        overlayView.hideVolumeToggleButton()
        
        track("Completed Tutorial Video")
        delegate?.tutorialVideoViewControllerDidEnd?(self)
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
