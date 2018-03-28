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
        
        let text = FormRow.Text()
        text.placeholder = "Text"
        formRows.append(text)
        
        let selection = FormRow.Selection()
        selection.placeholder = "Selection"
        selection.options = [
            "United States",
            "Agartha",
            "Antartica",
            "Atlantis",
            "Bermuda",
            "Categat",
            "Pangea"
        ]
        formRows.append(selection)
        
        let email = FormRow.Email()
        email.placeholder = "Email"
        formRows.append(email)
        
        let section = FormSection()
        section.rows = formRows
        
        let formViewController = FormViewController(with: Form(with: [section]))
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
