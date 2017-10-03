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
    
    // Closure to be executed when the done button is tapped
    var doneButtonTapped: (() -> Void)?

    // MARK: - UIViewController
    override func viewDidLoad() {
        setupDoneButton()
        setupDoneButtonConstraints()
    }
    
    // MARK: - Actions
    
    @objc func didTapOnDoneButton() {
        doneButtonTapped?()
    }
    
    // MARK - Private
    
    private func setupDoneButtonConstraints() {
        doneButton.widthAnchor.constraint(equalToConstant: 70).isActive = true
        doneButton.heightAnchor.constraint(equalToConstant: 35).isActive = true
        doneButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -10).isActive = true
        doneButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 25).isActive = true
    }
    
    private func setupDoneButton() {
        doneButton = UIButton(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        doneButton.layer.borderColor = UIColor.white.cgColor
        doneButton.layer.borderWidth = 2
        
        if #available(iOS 11.0, *) {
            doneButton.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner, .layerMaxXMinYCorner, .layerMinXMinYCorner]
        } else {
            doneButton.layer.cornerRadius = 5
        }
        
        doneButton.titleEdgeInsets = UIEdgeInsetsMake(0, 5, 0, 5)
        doneButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        doneButton.setTitle("Done", for: .normal)
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        doneButton.addTarget(self, action: #selector(didTapOnDoneButton), for: .touchUpInside)
        
        view.addSubview(doneButton)
    }
}
