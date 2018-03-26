//
//  CartNavigationController.swift
//  screenshot
//
//  Created by Corey Werner on 2/19/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class CartNavigationController: UINavigationController {
    let cartViewController = CartViewController()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    convenience init() {
        self.init(nibName: nil, bundle: nil)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        restorationIdentifier = String(describing: type(of: self))
        
        // !!!: DEBUG
        var formRows: [FormRow] = []
        
        let text = Form.Text()
        text.placeholder = "Placeholder 1"
        formRows.append(text)
        
        let email = Form.Email()
        email.placeholder = "Placeholder 2"
        formRows.append(email)
        
        let formViewController = FormViewController(with: Form(with: formRows))
        viewControllers = [
            formViewController
//            cartViewController
        ]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .background
    }
}
