//
//  ProductNextStepViewController.swift
//  screenshot
//
//  Created by Corey Werner on 3/11/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class ProductNextStepViewController: UIViewController {
    let cartButton = MainButton()
    let continueButton = MainButton()
    
    fileprivate let transitioning = ViewControllerTransitioningDelegate(presentation: .intrinsicContentSize, transition: .modal)
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        transitioningDelegate = transitioning
        modalPresentationStyle = .custom
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .gray3
        label.font = UIFont.preferredFont(forTextStyle: .title2)
        label.adjustsFontForContentSizeCategory = true // TODO: test this
        label.text = "product.next_step.added".localized
        label.numberOfLines = 0
        view.addSubview(label)
        label.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        label.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
        label.topAnchor.constraint(equalTo: view.topAnchor, constant: .padding).isActive = true
        label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -.padding).isActive = true
        
        let imageView = UIImageView(image: UIImage(named: "ProductCheck"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        view.addSubview(imageView)
        imageView.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
        imageView.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        imageView.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor, constant: .padding).isActive = true
        imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: .padding).isActive = true
        imageView.trailingAnchor.constraint(equalTo: label.leadingAnchor, constant: -.padding).isActive = true
        imageView.centerYAnchor.constraint(equalTo: label.centerYAnchor).isActive = true
        
        cartButton.translatesAutoresizingMaskIntoConstraints = false
        cartButton.backgroundColor = .crazeGreen
        cartButton.setTitle("product.next_step.cart".localized, for: .normal)
        cartButton.titleLabel?.font = UIFont.systemFont(ofSize: UIFont.buttonFontSize * 0.8)
        cartButton.titleLabel?.minimumScaleFactor = 0.7
        cartButton.titleLabel?.baselineAdjustment = .alignCenters
        cartButton.titleLabel?.adjustsFontSizeToFitWidth = true
        view.addSubview(cartButton)
        cartButton.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        cartButton.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
        cartButton.topAnchor.constraint(equalTo: label.bottomAnchor, constant: .padding).isActive = true
        cartButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: .padding).isActive = true
        cartButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -.padding).isActive = true
        
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.backgroundColor = .crazeGreen
        continueButton.setTitle("product.next_step.continue".localized, for: .normal)
        continueButton.titleLabel?.font = UIFont.systemFont(ofSize: UIFont.buttonFontSize * 0.8)
        continueButton.titleLabel?.minimumScaleFactor = 0.7
        continueButton.titleLabel?.baselineAdjustment = .alignCenters
        continueButton.titleLabel?.adjustsFontSizeToFitWidth = true
        view.addSubview(continueButton)
        continueButton.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        continueButton.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
        continueButton.topAnchor.constraint(equalTo: label.bottomAnchor, constant: .padding).isActive = true
        continueButton.leadingAnchor.constraint(equalTo: cartButton.trailingAnchor, constant: 10).isActive = true
        continueButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -.padding).isActive = true
        continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -.padding).isActive = true
    }
}
