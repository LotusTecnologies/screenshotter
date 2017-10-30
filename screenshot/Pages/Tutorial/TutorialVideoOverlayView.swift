//
//  TutorialVideoOverlayView.swift
//  screenshot
//
//  Created by Jacob Relkin on 10/2/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import UIKit

class TutorialVideoOverlayView : UIView {
    private(set) var doneButton = UIButton()
    private(set) var replayPauseButton = UIButton()
    private(set) var volumeToggleButton = UIButton()
    
    // MARK: - UIView
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        translatesAutoresizingMaskIntoConstraints = false
        setupVolumeToggleButton()
        setupReplayPauseButton()
        setupDoneButton()
        
        NSLayoutConstraint.activate([
            volumeToggleButton.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            volumeToggleButton.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            
            replayPauseButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            replayPauseButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            doneButton.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            doneButton.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            doneButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 0)
        ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public
    
    func scaleInDoneButton() {
        self.doneButton.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0, options: UIViewAnimationOptions(rawValue: 0), animations: {
            self.doneButton.alpha = 1
            self.doneButton.transform = .identity
        })
    }
    
    func hideVolumeToggleButton() {
        UIView.animate(withDuration: Constants.defaultAnimationDuration) {
            self.volumeToggleButton.alpha = 0
        }
    }
    
    func showVolumeToggleButton() {
        UIView.animate(withDuration: Constants.defaultAnimationDuration) {
            self.volumeToggleButton.alpha = 1
        }
    }
    
    func flashPauseOverlay() {
        replayPauseButton.isSelected = false
        replayPauseButton.alpha = 0
        
        UIView.animateKeyframes(withDuration: Constants.defaultAnimationDuration * 3, delay: 0, options: UIViewKeyframeAnimationOptions(rawValue: 0), animations: {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.33, animations: {
                self.replayPauseButton.alpha = 1
            })
            UIView.addKeyframe(withRelativeStartTime: 0.66, relativeDuration: 1, animations: {
                self.replayPauseButton.alpha = 0.0
            })
        })
    }
    
    func showReplayButton() {
        replayPauseButton.isSelected = true

        guard replayPauseButton.alpha < 1 else {
            return
        }
        
        UIView.animate(withDuration: Constants.defaultAnimationDuration) {
            self.replayPauseButton.alpha = 1
        }
    }
    
    func hideReplayButton() {
        guard replayPauseButton.alpha > 0 else {
            return
        }
        
        UIView.animate(withDuration: Constants.defaultAnimationDuration) {
            self.replayPauseButton.alpha = 0
        }
    }
    
    // MARK: - Button Setup
    
    private func setupVolumeToggleButton() {
        volumeToggleButton.setImage(#imageLiteral(resourceName: "PlayerSound"), for: .normal)
        volumeToggleButton.setImage(#imageLiteral(resourceName: "PlayerMute") , for: .selected)
        volumeToggleButton.setImage(#imageLiteral(resourceName: "PlayerMute"), for: [.highlighted, .selected])
        volumeToggleButton.translatesAutoresizingMaskIntoConstraints = false
        volumeToggleButton.showsTouchWhenHighlighted = true
        
        addSubview(volumeToggleButton)
    }
    
    private func setupReplayPauseButton() {
        replayPauseButton.translatesAutoresizingMaskIntoConstraints = false
        replayPauseButton.showsTouchWhenHighlighted = true
        replayPauseButton.setImage(#imageLiteral(resourceName: "PlayerPause"), for: .normal)
        replayPauseButton.setImage(#imageLiteral(resourceName: "PlayerPlay"), for: .selected)
        replayPauseButton.setImage(#imageLiteral(resourceName: "PlayerPlay"), for: [.highlighted, .selected])
        replayPauseButton.alpha = 0
        
        addSubview(replayPauseButton)
    }
    
    private func setupDoneButton() {
        let effect = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: effect)
        blurView.alpha = 0.9
        blurView.isUserInteractionEnabled = false
        blurView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        doneButton = UIButton()
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        doneButton.alpha = 0
        doneButton.contentEdgeInsets = UIEdgeInsetsMake(8, 8, 8, 8)
        doneButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        doneButton.setTitle("Done", for: .normal)
        doneButton.layer.borderColor = UIColor.white.cgColor
        doneButton.layer.borderWidth = 0.8
        doneButton.layer.masksToBounds = true
        doneButton.layer.cornerRadius = 5
        
        doneButton.insertSubview(blurView, at: 0)
        addSubview(doneButton)
    }
}
