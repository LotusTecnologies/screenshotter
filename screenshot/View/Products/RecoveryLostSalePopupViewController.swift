//
//  RecoveryLostSalePopupViewController.swift
//  screenshot
//
//  Created by Jonathan Rose on 7/5/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class RecoveryLostSalePopupViewController: UIViewController {

//    let emailProductAction:(()->())
//    let dismissAction:(()->())

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .crazeRed
        
        let container = UIView()
        container.backgroundColor = UIColor.blue.withAlphaComponent(0.5)
        container.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(container)
        container.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        container.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        container.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        
        let titleLabel = UILabel.init()
        titleLabel.textColor = .white
        titleLabel.text = "product.sale_recovery.alert.message".localized
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(titleLabel)
        titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: .padding).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: .padding).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -.padding).isActive = true

        let emailProductButton = UIButton.init(type: .custom)
        emailProductButton.setTitle("product.sale_recovery.alert.email_me".localized, for: .normal)
        emailProductButton.backgroundColor = .clear
        emailProductButton.titleLabel?.textColor = .white
        emailProductButton.layer.borderColor = UIColor.white.cgColor
        emailProductButton.layer.borderWidth = 2.0
        emailProductButton.layer.cornerRadius = 5.0
        emailProductButton.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(emailProductButton)
        titleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: .padding).isActive = true
        emailProductButton.centerXAnchor.constraint(equalTo: container.centerXAnchor).isActive = true


        let dissmissButton = UIButton.init(type: .custom)
        let string = NSAttributedString.init(string: "product.sale_recovery.alert.dissmis".localized, attributes: [.underlineStyle:NSUnderlineStyle.styleSingle.rawValue, .underlineColor: UIColor.white, .foregroundColor:UIColor.white])
        dissmissButton.setAttributedTitle(string, for: .normal)
        dissmissButton.backgroundColor = .clear
        dissmissButton.titleLabel?.textColor = .white
        dissmissButton.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(dissmissButton)
        dissmissButton.topAnchor.constraint(equalTo: emailProductButton.bottomAnchor, constant: .padding).isActive = true
        dissmissButton.centerXAnchor.constraint(equalTo: container.centerXAnchor).isActive = true
        dissmissButton.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -.padding).isActive = true
        

    }


}
