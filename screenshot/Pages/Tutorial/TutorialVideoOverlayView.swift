//
//  TutorialVideoOverlayView.swift
//  screenshot
//
//  Created by Jacob Relkin on 10/2/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import UIKit

// TODO: Use @corey's new constant for default animation duration
fileprivate let animationDuration = 0.3

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
        
        UIView.animateKeyframes(withDuration: 0.2, delay: 0, options: [.calculationModeCubic], animations: {
            self.doneButton.alpha = 1
            self.doneButton.transform = .identity
        }, completion: nil)
    }
    
    func hideVolumeToggleButton() {
        UIView.animate(withDuration: animationDuration) {
            self.volumeToggleButton.alpha = 0
        }
    }
    
    func showVolumeToggleButton() {
        UIView.animate(withDuration: animationDuration) {
            self.volumeToggleButton.alpha = 1
        }
    }
    
    func flashPauseOverlay() {
        replayPauseButton.isSelected = false
        replayPauseButton.alpha = 0
        
        UIView.animate(withDuration: animationDuration / 2, animations: {
            self.replayPauseButton.alpha = 1
        }, completion: { finished in
            UIView.animate(withDuration: animationDuration, animations: {
                self.replayPauseButton.alpha = 0.0
            })
        })
    }
    
    func showReplayButton() {
        replayPauseButton.isSelected = true

        guard replayPauseButton.alpha < 1 else {
            return
        }
        
        UIView.animate(withDuration: animationDuration) {
            self.replayPauseButton.alpha = 1
        }
    }
    
    func hideReplayButton() {
        guard replayPauseButton.alpha > 0 else {
            return
        }
        
        UIView.animate(withDuration: animationDuration) {
            self.replayPauseButton.alpha = 0
        }
    }
    
    // MARK: - Button Setup
    
    private func setupVolumeToggleButton() {
        volumeToggleButton.setImage(#imageLiteral(resourceName: "TutorialVideoUnmuted"), for: .normal)
        volumeToggleButton.setImage(#imageLiteral(resourceName: "TutorialVideoMuted") , for: .selected)
        volumeToggleButton.setImage(#imageLiteral(resourceName: "TutorialVideoMuted"), for: [.highlighted, .selected])
        volumeToggleButton.translatesAutoresizingMaskIntoConstraints = false
        volumeToggleButton.showsTouchWhenHighlighted = true
        
        addSubview(volumeToggleButton)
    }
    
    private func setupReplayPauseButton() {
        replayPauseButton.translatesAutoresizingMaskIntoConstraints = false
        replayPauseButton.showsTouchWhenHighlighted = true
        replayPauseButton.setImage(#imageLiteral(resourceName: "TutorialVideoPause"), for: .normal)
        replayPauseButton.setImage(#imageLiteral(resourceName: "TutorialVideoReplay"), for: .selected)
        replayPauseButton.setImage(#imageLiteral(resourceName: "TutorialVideoReplay"), for: [.highlighted, .selected])
        replayPauseButton.alpha = 0
        
        addSubview(replayPauseButton)
    }
    
    private func setupDoneButton() {
        let effect = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: effect)
        blurView.alpha = 0.6
        blurView.isUserInteractionEnabled = false
        blurView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        doneButton = UIButton(frame: .zero)
        doneButton.alpha = 0
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        doneButton.layer.borderColor = UIColor.white.cgColor
        doneButton.layer.borderWidth = 0.8
        doneButton.layer.masksToBounds = true
        doneButton.layer.cornerRadius = 5
        doneButton.contentEdgeInsets = UIEdgeInsetsMake(8, 8, 8, 8)
        doneButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        doneButton.setTitle("Done", for: .normal)
        
        doneButton.insertSubview(blurView, at: 0)
        addSubview(doneButton)
    }
}

