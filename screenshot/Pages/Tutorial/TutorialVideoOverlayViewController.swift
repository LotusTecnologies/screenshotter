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
    
    // Closure to be executed when the done button is tapped
    var doneButtonTapped: (() -> Void)?

    // Closure to be executed when the replay button is tapped
    var replayButtonTapped: (() -> Void)?
    
    // MARK: - UIViewController
    override func viewDidLoad() {
        setupDoneButton()
        setupReplayButton()

        view.setNeedsLayout()
        
        setupDoneButtonConstraints()
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
    
    // MARK - Private
    
    private func setupReplayButton() {
        replayButton = UIButton(frame: .zero)
        replayButton.setTitle("Replay", for: .normal)
        replayButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .title3)
        replayButton.layer.borderColor = UIColor.white.cgColor
        replayButton.layer.borderWidth = 2
        replayButton.layer.masksToBounds = true
        replayButton.layer.cornerRadius = 5
        replayButton.titleEdgeInsets = UIEdgeInsetsMake(0, 5, 0, 5)
        replayButton.isHidden = true
        replayButton.addTarget(self, action: #selector(didTapOnReplayButton), for: .touchUpInside)
        
        view.addSubview(replayButton)
        
        replayButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            replayButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            replayButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            replayButton.widthAnchor.constraint(equalToConstant: 130),
            replayButton.heightAnchor.constraint(equalToConstant: 100)
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
        doneButton = UIButton(frame: .zero)
        doneButton.layer.borderColor = UIColor.white.cgColor
        doneButton.layer.borderWidth = 2
        doneButton.layer.masksToBounds = true
        doneButton.layer.cornerRadius = 5
        
        doneButton.titleEdgeInsets = UIEdgeInsetsMake(0, 5, 0, 5)
        doneButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        doneButton.setTitle("Done", for: .normal)
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        doneButton.addTarget(self, action: #selector(didTapOnDoneButton), for: .touchUpInside)
        
        view.addSubview(doneButton)
    }
}
