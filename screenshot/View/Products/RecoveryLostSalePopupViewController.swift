//
//  RecoveryLostSalePopupViewController.swift
//  screenshot
//
//  Created by Jonathan Rose on 7/5/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class RecoveryLostSalePopupViewController: UIViewController {

    let emailProductBlock:(()->())
    let dismissBlock:(()->())

    init(emailProductAction:@escaping(()->()),dismissAction:@escaping (()->()) ) {
        self.emailProductBlock = emailProductAction
        self.dismissBlock = dismissAction
        super.init(nibName: nil, bundle: nil)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .crazeRed
        
        
        let titleLabel = UILabel.init()
        titleLabel.textColor = .white
        titleLabel.text = "product.sale_recovery.alert.message".localized
        titleLabel.font = UIFont.screenshopFont(.quicksandMedium, size: 18.0)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        view.addSubview(titleLabel)
        titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: .padding).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: .extendedPadding).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -.extendedPadding).isActive = true

        let emailProductButton = UIButton.init(type: .custom)
        emailProductButton.setTitle("product.sale_recovery.alert.email_me".localized, for: .normal)
        emailProductButton.backgroundColor = .clear
        emailProductButton.titleLabel?.textColor = .white
        emailProductButton.contentEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10)
        emailProductButton.setContentCompressionResistancePriority(.required, for: .vertical)
        emailProductButton.layer.borderColor = UIColor.white.cgColor
        emailProductButton.titleLabel?.font = UIFont.screenshopFont(.quicksandBold, size: 18.0)
        emailProductButton.layer.borderWidth = 1.0
        emailProductButton.layer.cornerRadius = 5.0
        emailProductButton.addTarget(self, action: #selector(emailAction(_:)), for: .touchUpInside)
        emailProductButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emailProductButton)
        emailProductButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: .padding).isActive = true
        emailProductButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: .extendedPadding).isActive = true
        emailProductButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -.extendedPadding).isActive = true


        let dismissButton = UIButton.init(type: .custom)
        let string = NSAttributedString.init(string: "product.sale_recovery.alert.dissmis".localized, attributes: [.underlineStyle:NSUnderlineStyle.styleSingle.rawValue, .underlineColor: UIColor.white, .foregroundColor:UIColor.white, .font: UIFont.screenshopFont(.quicksand, size: 18.0)])
        dismissButton.setAttributedTitle(string, for: .normal)
        dismissButton.backgroundColor = .clear
        dismissButton.addTarget(self, action: #selector(dissmissAction(_ :)), for: .touchUpInside)
        dismissButton.titleLabel?.textColor = .white
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dismissButton)
        dismissButton.topAnchor.constraint(equalTo: emailProductButton.bottomAnchor, constant: .padding).isActive = true
        dismissButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        view.bottomAnchor.constraint(equalTo: dismissButton.bottomAnchor, constant: .padding).isActive = true

    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let size = self.view.systemLayoutSizeFitting(UILayoutFittingCompressedSize, withHorizontalFittingPriority: .defaultLow, verticalFittingPriority: .defaultHigh)
        self.preferredContentSize = size
    }


    @objc func emailAction(_ sender:Any){
        emailProductBlock()
    }
    @objc func dissmissAction(_ sender:Any){
        dismissBlock()
    }

}
