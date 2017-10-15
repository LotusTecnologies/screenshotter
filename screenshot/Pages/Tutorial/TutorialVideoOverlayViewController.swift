//
//  TutorialVideoOverlayViewController.swift
//  screenshot
//
//  Created by Jacob Relkin on 10/2/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import UIKit

class TutorialVideoOverlayViewController : UIViewController {
    private var doneButton: UIButton!
    private var replayButton: UIButton!
    private var pauseButton: UIButton!
    
    // Closure to be executed when the done button is tapped
    var doneButtonTapped: (() -> Void)?

    // Closure to be executed when the replay button is tapped
    var replayButtonTapped: (() -> Void)?
    
    // MARK: - UIViewController
    override func viewDidLoad() {
        setupDoneButton()
        setupReplayButton()
        setupPauseButton()

        setupDoneButtonConstraints()
    }
    
    func flashPauseOverlay() {
        pauseButton.alpha = 0
        pauseButton.isHidden = false
        
        UIView.animate(withDuration: 0.1, animations: {
            self.pauseButton.alpha = 1
        }, completion: { finished in
            UIView.animate(withDuration: 0.3, animations: {
                self.pauseButton.alpha = 0.0
            }, completion: { finished in
                self.pauseButton.isHidden = true
            })
        })
    }
    
    func showReplayButton() {
        replayButton.alpha = 0
        replayButton.isHidden = false
        
        UIView.animate(withDuration: 0.5) {
            self.replayButton.alpha = 1
        }
    }
    
    func hideReplayButton() {
        replayButton.alpha = 1
        
        UIView.animate(withDuration: 0.5, animations: {
            self.replayButton.alpha = 0
        }, completion: { _ in
            self.replayButton.isHidden = true
        })
    }
    
    // MARK: - Actions
    
    @objc func didTapOnDoneButton() {
        doneButtonTapped?()
    }
    
    @objc func didTapOnReplayButton() {
        replayButtonTapped?()
    }
    
    // MARK: - Private
    
    private func setupPauseButton() {
        pauseButton = UIButton(frame: .zero)
        pauseButton.setImage(UIImage(named: "Pause"), for: .normal)
        pauseButton.isHidden = true
        
        view.addSubview(pauseButton)
        
        pauseButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            pauseButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pauseButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            pauseButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 0),
            pauseButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 0)
        ])
    }
    
    private func setupReplayButton() {
        replayButton = UIButton(frame: .zero)
        replayButton.setImage(UIImage(named: "Replay"), for: .normal)
        replayButton.isHidden = true
        replayButton.addTarget(self, action: #selector(didTapOnReplayButton), for: .touchUpInside)
        
        view.addSubview(replayButton)
        
        replayButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            replayButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            replayButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            replayButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 0),
            replayButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 0)
        ])
    }

    private func setupDoneButtonConstraints() {
        NSLayoutConstraint.activate([
            doneButton.widthAnchor.constraint(equalToConstant: 70),
            doneButton.heightAnchor.constraint(equalToConstant: 35),
            doneButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -10),
            doneButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 25)
        ])
    }
    
    private func setupDoneButton() {
        let effect = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: effect)
        blurView.alpha = 0.6
        blurView.isUserInteractionEnabled = false
        blurView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        doneButton = UIButton(frame: .zero)
        doneButton.backgroundColor = UIColor(white: 0, alpha: 0)
        doneButton.layer.borderColor = UIColor.white.cgColor
        doneButton.layer.borderWidth = 0.8
        doneButton.layer.masksToBounds = true
        doneButton.layer.cornerRadius = 5
        doneButton.insertSubview(blurView, at: 0)
        
        doneButton.titleEdgeInsets = UIEdgeInsetsMake(0, 5, 0, 5)
        doneButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        doneButton.setTitle("Done", for: .normal)
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        doneButton.addTarget(self, action: #selector(didTapOnDoneButton), for: .touchUpInside)
        
        view.addSubview(doneButton)
    }
}

