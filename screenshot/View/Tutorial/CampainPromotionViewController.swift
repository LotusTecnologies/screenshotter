//
//  CampainPromotionViewController.swift
//  screenshot
//
//  Created by Jonathan Rose on 4/17/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class CampainPromotionViewController: UIViewController {
    var showsReplayButtonUponFinishing: Bool = true
    var willDisplayInPopover:Bool = false
    
    
    weak var delegate: TutorialVideoViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        let conatinerView:UIView = {
            if willDisplayInPopover {
                self.view.backgroundColor = .white
                return self.view
            }else{
                self.view.backgroundColor = .gray9
                let c = UIView.init()
                c.backgroundColor = .white
                let layer = c.layer
                layer.shadowColor = Shadow.basic.color.cgColor
                layer.shadowOffset = Shadow.basic.offset
                layer.shadowRadius = Shadow.basic.radius
                layer.cornerRadius = 8
                c.translatesAutoresizingMaskIntoConstraints = false
                self.view.addSubview(c)
                c.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 34).isActive = true
                c.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -34).isActive = true
                c.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 40).isActive = true
                c.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -40).isActive = true
                return c
            }
        }()
        
        let headlineLabel = UILabel()
        headlineLabel.text = "Shop And Win!"
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        headlineLabel.textAlignment = .center
        headlineLabel.numberOfLines = 0
        conatinerView.addSubview(headlineLabel)
        headlineLabel.leftAnchor.constraint(equalTo: conatinerView.leftAnchor, constant: 25).isActive = true
        headlineLabel.rightAnchor.constraint(equalTo: conatinerView.rightAnchor, constant: -25).isActive = true
        
        
        let explainationLabel = UILabel()
        explainationLabel.text = "100 people who make their first purchase on Screenshop will win $1,000!"
        explainationLabel.translatesAutoresizingMaskIntoConstraints = false
        explainationLabel.textAlignment = .center
        explainationLabel.numberOfLines = 0
        conatinerView.addSubview(explainationLabel)
        explainationLabel.leftAnchor.constraint(equalTo: conatinerView.leftAnchor, constant: 25).isActive = true
        explainationLabel.rightAnchor.constraint(equalTo: conatinerView.rightAnchor, constant: -25).isActive = true
        
        
        let soundsGoodButton = MainButton.init()
        soundsGoodButton.translatesAutoresizingMaskIntoConstraints = false
        soundsGoodButton.backgroundColor = .crazeRed
        soundsGoodButton.addTarget(self, action: #selector(tappedButton), for: .touchUpInside)
        conatinerView.addSubview(soundsGoodButton)
        soundsGoodButton.setTitle("Sound Good".localized, for: .normal)
        soundsGoodButton.leftAnchor.constraint(equalTo: conatinerView.leftAnchor, constant: 25).isActive = true
        soundsGoodButton.rightAnchor.constraint(equalTo: conatinerView.rightAnchor, constant: -25).isActive = true
        soundsGoodButton.bottomAnchor.constraint(equalTo: conatinerView.bottomAnchor, constant: -25).isActive = true
        soundsGoodButton.heightAnchor.constraint(equalToConstant: 46).isActive = true
        
        explainationLabel.bottomAnchor.constraint(equalTo: soundsGoodButton.topAnchor, constant: -25)
        headlineLabel.bottomAnchor.constraint(equalTo: explainationLabel.topAnchor, constant: -25)

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
//        let playerItem = AVPlayerItem(url: Bundle.main.url(forResource: "Craze_Video", withExtension: "mp4")!)
//
//        player = AVPlayer(playerItem: playerItem)
//        player.allowsExternalPlayback = false
//        player.actionAtItemEnd = .pause
//        player.isMuted = true
//
//        playerLayer = AVPlayerLayer(player: player)
        
        super.init(nibName: nil, bundle: nil)
    }
    
    @objc func tappedButton() {
        self.delegate?.tutorialVideoViewControllerDidTapDone(nil)
    }

}
