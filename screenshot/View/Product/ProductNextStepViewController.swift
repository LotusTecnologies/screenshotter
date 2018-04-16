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
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        transitioningDelegate = transitioning
        modalPresentationStyle = .custom
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        let layoutGuide = UIView()
        layoutGuide.translatesAutoresizingMaskIntoConstraints = false
        layoutGuide.isHidden = true
        view.addSubview(layoutGuide)
        layoutGuide.topAnchor.constraint(equalTo: view.topAnchor, constant: .padding).isActive = true
        layoutGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: .padding).isActive = true
        layoutGuide.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -.padding).isActive = true
        layoutGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -.padding).isActive = true
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .gray3
        label.font = .screenshopFont(.hindMedium, textStyle: .title2, staticSize: true)
        label.text = "product.next_step.added".localized
        label.numberOfLines = 0
        view.addSubview(label)
        label.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        label.setContentHuggingPriority(UILayoutPriority.required, for: .vertical)
        label.topAnchor.constraint(equalTo: layoutGuide.topAnchor).isActive = true
        label.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor).isActive = true
        
        let imageView = UIImageView(image: UIImage(named: "ProductCheck"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        view.addSubview(imageView)
        imageView.topAnchor.constraint(greaterThanOrEqualTo: layoutGuide.topAnchor).isActive = true
        imageView.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: label.leadingAnchor, constant: -.padding).isActive = true
        imageView.centerYAnchor.constraint(equalTo: label.centerYAnchor).isActive = true
        
        cartButton.translatesAutoresizingMaskIntoConstraints = false
        cartButton.backgroundColor = .crazeGreen
        cartButton.setTitle("product.next_step.cart".localized, for: .normal)
        view.addSubview(cartButton)
        cartButton.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        cartButton.setContentHuggingPriority(UILayoutPriority.required, for: .vertical)
        cartButton.topAnchor.constraint(equalTo: label.bottomAnchor, constant: .padding).isActive = true
        cartButton.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor).isActive = true
        cartButton.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor).isActive = true
        
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.backgroundColor = .crazeGreen
        continueButton.setTitle("product.next_step.continue".localized, for: .normal)
        view.addSubview(continueButton)
        continueButton.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        continueButton.setContentHuggingPriority(UILayoutPriority.required, for: .vertical)
        continueButton.topAnchor.constraint(equalTo: cartButton.bottomAnchor, constant: .padding).isActive = true
        continueButton.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor).isActive = true
        continueButton.bottomAnchor.constraint(equalTo: layoutGuide.bottomAnchor).isActive = true
        continueButton.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor).isActive = true
    }
}
