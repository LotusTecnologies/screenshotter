//
//  OnboardingDetailsViewController.swift
//  screenshot
//
//  Created by Corey Werner on 5/24/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class OnboardingDetailsView: UIScrollView, UINavigationBarDelegate {
    let navigationItem = UINavigationItem()
    let userButton = RoundButton()
    
    let _layoutMargins = UIEdgeInsets(top: .padding, left: .padding, bottom: .padding, right: .padding)
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        if let backgroundImage = UIImage(named: "BrandConfettiFullBackground") {
            backgroundColor = UIColor(patternImage: backgroundImage)
        }
        
        let navigationBar = UINavigationBar()
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        navigationBar.delegate = self
        navigationBar.items = [navigationItem]
        addSubview(navigationBar)
        navigationBar.topAnchor.constraint(equalTo: topAnchor).isActive = true
        navigationBar.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        navigationBar.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        navigationBar.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        
        let contentView = ContentContainerView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        contentView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        contentView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        contentView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        
        let defaultUserImage = UIImage(named: "DefaultUser")
        
        userButton.translatesAutoresizingMaskIntoConstraints = false
        userButton.setBackgroundImage(defaultUserImage, for: .selected)
        userButton.setBackgroundImage(defaultUserImage, for: [.selected, .highlighted])
        userButton.setImage(UIImage(named: "UserCamera"), for: .selected)
        userButton.isSelected = true
        userButton.layer.borderColor = UIColor.gray6.cgColor
        userButton.layer.borderWidth = 2
        addSubview(userButton)
        userButton.topAnchor.constraint(equalTo: navigationBar.bottomAnchor, constant: .extendedPadding).isActive = true
        userButton.widthAnchor.constraint(equalToConstant: 90).isActive = true
        userButton.heightAnchor.constraint(equalTo: userButton.widthAnchor).isActive = true
        userButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        userButton.centerYAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layoutMargins = _layoutMargins
    }
    
    // MARK: Navigation Bar
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}

class OnboardingDetailsViewController: UIViewController {
    var classForView: OnboardingDetailsView.Type {
        return OnboardingDetailsView.self
    }
    
    var _view: OnboardingDetailsView {
        return view as! OnboardingDetailsView
    }
    
    override func loadView() {
        view = classForView.self.init()
    }
    
    // MARK: Life Cycle
    
    override var title: String? {
        didSet {
            _view.navigationItem.title = title
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        title = "Your Details"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
}
