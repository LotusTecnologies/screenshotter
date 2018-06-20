//
//  AlertTemplate.swift
//  screenshot
//
//  Created by Corey Werner on 5/16/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import UIKit

class AlertTemplateView: UIView {
    let titleLabel = UILabel()
    let contentLayoutGuide = UILayoutGuide()
    let continueButton = MainButton()
    let cancelButton = UIButton()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
        
        let paddingLayoutGuide = UILayoutGuide()
        addLayoutGuide(paddingLayoutGuide)
        paddingLayoutGuide.topAnchor.constraint(equalTo: topAnchor, constant: .padding).isActive = true
        paddingLayoutGuide.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .padding).isActive = true
        paddingLayoutGuide.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -.padding).isActive = true
        paddingLayoutGuide.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.padding).isActive = true
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = .gray3
        titleLabel.textAlignment = .center
        titleLabel.font = .screenshopFont(.hindMedium, size: UIDevice.is320w ? 24 : 28)
        titleLabel.minimumScaleFactor = 0.7
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.baselineAdjustment = .alignCenters
        addSubview(titleLabel)
        titleLabel.topAnchor.constraint(equalTo: paddingLayoutGuide.topAnchor).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: paddingLayoutGuide.leadingAnchor).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: paddingLayoutGuide.trailingAnchor).isActive = true
        
        let contentPadding: CGFloat = .padding * 2.2
        
        addLayoutGuide(contentLayoutGuide)
        contentLayoutGuide.topAnchor.constraint(equalTo: titleLabel.lastBaselineAnchor, constant: contentPadding).isActive = true
        contentLayoutGuide.leadingAnchor.constraint(equalTo: paddingLayoutGuide.leadingAnchor).isActive = true
        contentLayoutGuide.trailingAnchor.constraint(equalTo: paddingLayoutGuide.trailingAnchor).isActive = true
        
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.backgroundColor = .crazeGreen
        addSubview(continueButton)
        continueButton.topAnchor.constraint(equalTo: contentLayoutGuide.bottomAnchor, constant: contentPadding).isActive = true
        continueButton.leadingAnchor.constraint(equalTo: paddingLayoutGuide.leadingAnchor).isActive = true
        continueButton.trailingAnchor.constraint(equalTo: paddingLayoutGuide.trailingAnchor).isActive = true
        
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.setTitleColor(.gray3, for: .normal)
        cancelButton.titleLabel?.font = .screenshopFont(.hindMedium, size: UIFont.buttonFontSize)
        cancelButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 0, bottom: 6, right: 0)
        addSubview(cancelButton)
        cancelButton.topAnchor.constraint(equalTo: continueButton.bottomAnchor, constant: .padding).isActive = true
        cancelButton.leadingAnchor.constraint(equalTo: paddingLayoutGuide.leadingAnchor).isActive = true
        cancelButton.bottomAnchor.constraint(equalTo: paddingLayoutGuide.bottomAnchor).isActive = true
        cancelButton.trailingAnchor.constraint(equalTo: paddingLayoutGuide.trailingAnchor).isActive = true
    }
}

class AlertTemplateViewController: UIViewController {
    fileprivate let transitioning = ViewControllerTransitioningDelegate(presentation: .intrinsicContentSize, transition: .modal)
    
    // MARK: View
    
    fileprivate var _view: AlertTemplateView {
        return view as! AlertTemplateView
    }
    
    var titleLabel: UILabel {
        return _view.titleLabel
    }
    
    var contentLayoutGuide: UILayoutGuide {
        return _view.contentLayoutGuide
    }
    
    var continueButton: MainButton {
        return _view.continueButton
    }
    
    var cancelButton: UIButton {
        return _view.cancelButton
    }
    
    override func loadView() {
        view = AlertTemplateView()
    }
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        transitioningDelegate = transitioning
        modalPresentationStyle = .custom
    }
}
