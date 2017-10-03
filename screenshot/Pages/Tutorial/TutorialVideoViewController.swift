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

protocol TutorialVideoViewControllerDelegate : class {
    func tutorialVideoDidPause()
    func tutorialVideoDidPlay()
    func tutorialVideoDidEnd()
    
    // Call when the “Done” button is tapped
    func tutorialVideoWantsToDismiss()
}

class TutorialVideoViewController : UIViewController {
    let overlayViewController = TutorialVideoOverlayViewController()
    
    weak var delegate: TutorialVideoViewControllerDelegate?
    
    private let playerLayer: AVPlayerLayer
    private let player: AVPlayer
    private var ended = false
    
    init(video: TutorialVideo) {
        let playerItem = AVPlayerItem(url: video.url)

        player = AVPlayer(playerItem: playerItem)
        player.allowsExternalPlayback = false
        playerLayer = AVPlayerLayer(player: player)
        
        super.init(nibName: nil, bundle: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
            self.delegate?.tutorialVideoWantsToDismiss()
        }

        // Add tap gesture recognizer
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        view.addGestureRecognizer(tap)
        
        player.play()
        delegate?.tutorialVideoDidPlay()
    }
    
    @objc private func handleTap() {
        guard ended == false else {
            return
        }
        
        // Toggle playback state.
        if player.rate == 0 {
            player.play()
            delegate?.tutorialVideoDidPlay()
        } else {
            delegate?.tutorialVideoDidPause()
            player.pause()
        }
    }
    
    @objc private func playerDidFinishPlaying() {
        ended = true
        delegate?.tutorialVideoDidEnd()
    }
}
