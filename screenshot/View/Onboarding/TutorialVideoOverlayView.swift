//
//  TutorialVideoOverlayView.swift
//  screenshot
//
//  Created by Jacob Relkin on 10/2/17.
//  Copyright (c) 2017 crazeapp. All rights reserved.
//

import UIKit

class TutorialVideoOverlayView : UIView {
    private(set) var doneButton = UIButton()
    private(set) var replayPauseButton = UIButton()
    private(set) var volumeToggleButton = UIButton()
    
    
    // MARK: - Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        replayPauseButton.translatesAutoresizingMaskIntoConstraints = false
        replayPauseButton.adjustsImageWhenHighlighted = true
        replayPauseButton.imageView?.contentMode = .scaleAspectFit
        replayPauseButton.setImage(UIImage(named: "PlayerPlay"), for: .normal)
        replayPauseButton.setImage(UIImage(named: "PlayerPause"), for: .selected)
        replayPauseButton.setImage(UIImage(named: "PlayerPause"), for: [.highlighted, .selected])
        replayPauseButton.alpha = 0
        addSubview(replayPauseButton)
        replayPauseButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        replayPauseButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        let effect = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: effect)
        blurView.alpha = 0.9
        blurView.isUserInteractionEnabled = false
        blurView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        doneButton = UIButton()
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        doneButton.alpha = 0
        doneButton.contentEdgeInsets = UIEdgeInsetsMake(8, 12, 8, 12)
        doneButton.setTitle("generic.done".localized, for: .normal)
        doneButton.layer.borderColor = UIColor.white.cgColor
        doneButton.layer.borderWidth = 1
        doneButton.layer.masksToBounds = true
        doneButton.layer.cornerRadius = 5
        doneButton.insertSubview(blurView, at: 0)
        addSubview(doneButton)
        doneButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.padding).isActive = true
        doneButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -.padding).isActive = true
        
        volumeToggleButton.translatesAutoresizingMaskIntoConstraints = false
        volumeToggleButton.adjustsImageWhenHighlighted = true
        volumeToggleButton.contentEdgeInsets = layoutMargins
        volumeToggleButton.imageView?.contentMode = .scaleAspectFit
        volumeToggleButton.setImage(UIImage(named: "PlayerSound"), for: .normal)
        volumeToggleButton.setImage(UIImage(named: "PlayerMute"), for: .selected)
        volumeToggleButton.setImage(UIImage(named: "PlayerMute"), for: [.highlighted, .selected])
        addSubview(volumeToggleButton)
        volumeToggleButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .padding).isActive = true
        volumeToggleButton.centerYAnchor.constraint(equalTo: doneButton.centerYAnchor).isActive = true
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
        UIView.animate(withDuration: .defaultAnimationDuration) {
            self.volumeToggleButton.alpha = 0
        }
    }
    
    func showVolumeToggleButton() {
        UIView.animate(withDuration: .defaultAnimationDuration) {
            self.volumeToggleButton.alpha = 1
        }
    }
    
    func flashPauseOverlay() {
        replayPauseButton.isSelected = true
        replayPauseButton.alpha = 0
        
        UIView.animateKeyframes(withDuration: .defaultAnimationDuration * 3, delay: 0, options: UIViewKeyframeAnimationOptions(rawValue: 0), animations: {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.33, animations: {
                self.replayPauseButton.alpha = 1
            })
            UIView.addKeyframe(withRelativeStartTime: 0.66, relativeDuration: 1, animations: {
                self.replayPauseButton.alpha = 0.0
            })
        })
    }
    
    func showReplayButton() {
        replayPauseButton.isSelected = false

        guard replayPauseButton.alpha < 1 else {
            return
        }
        
        UIView.animate(withDuration: .defaultAnimationDuration) {
            self.replayPauseButton.alpha = 1
        }
    }
    
    func hideReplayButton() {
        guard replayPauseButton.alpha > 0 else {
            return
        }
        
        UIView.animate(withDuration: .defaultAnimationDuration) {
            self.replayPauseButton.alpha = 0
        }
    }
}
