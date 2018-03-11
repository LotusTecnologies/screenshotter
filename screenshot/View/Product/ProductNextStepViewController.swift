//
//  ProductNextStepViewController.swift
//  screenshot
//
//  Created by Corey Werner on 3/11/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

fileprivate class ProductNextStepView: UIView {
    let cartButton = MainButton()
    let continueButton = MainButton()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
        layoutMargins = UIEdgeInsets(top: .padding, left: .padding, bottom: .padding, right: .padding)
        
        cartButton.translatesAutoresizingMaskIntoConstraints = false
        cartButton.backgroundColor = .crazeGreen
        cartButton.setTitle("Go to Cart", for: .normal)
        cartButton.titleLabel?.minimumScaleFactor = 0.7
        cartButton.titleLabel?.adjustsFontSizeToFitWidth = true
        addSubview(cartButton)
        cartButton.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
        cartButton.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        cartButton.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor).isActive = true
        
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.backgroundColor = .crazeGreen
        continueButton.setTitle("Continue Shopping", for: .normal)
        continueButton.titleLabel?.minimumScaleFactor = 0.7
        continueButton.titleLabel?.adjustsFontSizeToFitWidth = true
        addSubview(continueButton)
        continueButton.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
        continueButton.leadingAnchor.constraint(equalTo: cartButton.trailingAnchor, constant: 10).isActive = true
        continueButton.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor).isActive = true
        continueButton.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
    }
}

class ProductNextStepViewController: UIViewController {
    fileprivate var productNextStepView: ProductNextStepView {
        return view as! ProductNextStepView
    }
    
    fileprivate let transitioning = ViewControllerTransitioningDelegate(presentation: .intrinsicContentSize, transition: .modal)
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        transitioningDelegate = transitioning
        modalPresentationStyle = .custom
    }
    
    override func loadView() {
        view = ProductNextStepView()
    }
    
    var cartButton: MainButton {
        return productNextStepView.cartButton
    }
    
    var continueButton: MainButton {
        return productNextStepView.continueButton
    }
}
