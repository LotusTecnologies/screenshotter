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

class TutorialVideoViewController : UIViewController {
    let overlayViewController = TutorialVideoOverlayViewController()
    
    private let playerLayer: AVPlayerLayer
    private let player: AVPlayer
    
    init(video: TutorialVideo) {
        player = AVPlayer(url: video.url)
        player.allowsExternalPlayback = false
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspect
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        playerLayer.frame = view.bounds
        self.view.layer.addSublayer(playerLayer)
        
        self.addChildViewController(overlayViewController)
        overlayViewController.didMove(toParentViewController: self)
        self.view.addSubview(overlayViewController.view)
        
        player.play()
    }
}
