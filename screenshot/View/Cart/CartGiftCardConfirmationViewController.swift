//
//  CartGiftCardConfirmationViewController.swift
//  screenshot
//
//  Created by Corey Werner on 5/9/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class CartGiftCardConfirmationViewController: UIViewController {
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
        
        
    }
}
