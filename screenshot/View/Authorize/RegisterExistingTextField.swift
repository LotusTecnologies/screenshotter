//
//  RegisterExistingTextField.swift
//  screenshot
//
//  Created by Corey Werner on 6/5/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation

class RegisterExistingTextField: UnderlineTextField {
    enum Exists {
        case unknown
        case yes
        case no
    }
    
    var exists: Exists = .unknown {
        didSet {
            let image: UIImage?
            
            switch exists {
            case .unknown:
                image = nil
            case .yes:
                image = UIImage(named: "AuthorizeRegisterCheck")
            case .no:
                image = UIImage(named: "AuthorizeRegisterNew")
            }
            
            existsImageView.image = image
            existsImageView.sizeToFit()
            rightView = nil
            rightView = existsImageView
        }
    }
    
    private let existsImageView = UIImageView()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        rightViewMode = .unlessEditing
        existsImageView.contentMode = .scaleAspectFit
    }
}
