//
//  FacebookButton.swift
//  screenshot
//
//  Created by Corey Werner on 5/21/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class FacebookButton: LoadingButton {
    enum ActionCopy {
        case register
        case connect
        
        var localizedString: String {
            switch self {
            case .register:
                return "facebook.register".localized
            case .connect:
                return "facebook.connect".localized
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setTitleColor(.gray5, for: .highlighted)
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 48, bottom: 0, right: 40)
        layer.shadowColor = Shadow.basic.color.cgColor
        layer.shadowOffset = Shadow.basic.offset
        layer.shadowRadius = Shadow.basic.radius
        layer.shadowOpacity = 1
        heightAnchor.constraint(equalToConstant: 48).isActive = true
        
        syncActionCopy()
        syncHasArrow()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: 6).cgPath
    }
    
    var actionCopy: ActionCopy = .register {
        didSet {
            syncActionCopy()
        }
    }
    
    private func syncActionCopy() {
        setTitle(actionCopy.localizedString, for: .normal)
    }
    
    
    var hasArrow = true {
        didSet {
            syncHasArrow()
        }
    }
    
    private func syncHasArrow() {
        let imageNamed = hasArrow ? "OnboardingFacebookButton" : "ProfileFacebookButton"
        let backgroundImage = UIImage(named: imageNamed)?.resizableImage(withCapInsets: UIEdgeInsets(top: 0, left: 49, bottom: 0, right: 49))
        
        setBackgroundImage(backgroundImage, for: .normal)
    }
    
    override var isLoading: Bool {
        didSet {
            if isLoading {
                setTitle(nil, for: .normal)
            }
            else {
                syncActionCopy()
            }
        }
    }
}
