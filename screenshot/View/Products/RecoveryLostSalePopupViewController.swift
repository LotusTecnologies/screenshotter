//
//  RecoveryLostSalePopupViewController.swift
//  screenshot
//
//  Created by Jonathan Rose on 7/5/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit
import GameKit

class RecoveryLostSalePopupViewController: UIViewController {

    struct ABTest {
        var backgroundColor:UIColor
        var foregroundColor:UIColor
        var headlineText:String
        var buttonText:String
        
        init(seed:UInt64) {
            backgroundColor = .crazeRed
            foregroundColor = .white
            
            let colorsRandomSource = GKMersenneTwisterRandomSource()
            colorsRandomSource.seed = seed
            let randomColorNumber = GKRandomDistribution(randomSource: colorsRandomSource, lowestValue: 0, highestValue: 2).nextInt()
            if randomColorNumber == 0 {
                backgroundColor = .crazeRed
                foregroundColor = .white
            }else if randomColorNumber == 1 {
                backgroundColor = .white
                foregroundColor = .black
            }else{
                backgroundColor = .crazeGreen
                foregroundColor = .white
            }
            
            let headlineRandomSource = GKMersenneTwisterRandomSource()
            headlineRandomSource.seed = seed + 1
            let randomHeadlineNumber = GKRandomDistribution(randomSource: colorsRandomSource, lowestValue: 1, highestValue: 4).nextInt()
            headlineText = "product.sale_recovery.alert.message_\(randomHeadlineNumber)".localized

            let buttonTextRandomSource = GKMersenneTwisterRandomSource()
            buttonTextRandomSource.seed = seed + 2
            let buttonTextNumber = GKRandomDistribution(randomSource: colorsRandomSource, lowestValue: 1, highestValue: 4).nextInt()
            buttonText = "product.sale_recovery.alert.email_me_\(buttonTextNumber)".localized

            
        }
    }
    
    let abTest:ABTest
    let emailProductBlock:(()->())
    let dismissBlock:(()->())

    init(abTest:ABTest, emailProductAction:@escaping(()->()),dismissAction:@escaping (()->()) ) {
        self.emailProductBlock = emailProductAction
        self.dismissBlock = dismissAction
        self.abTest = abTest
        super.init(nibName: nil, bundle: nil)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = self.abTest.backgroundColor
        
        
        let titleLabel = UILabel.init()
        titleLabel.textColor = self.abTest.foregroundColor
        titleLabel.text = self.abTest.headlineText
        titleLabel.font = UIFont.screenshopFont(.quicksandMedium, size: 18.0)
        titleLabel.minimumScaleFactor = 0.3
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        view.addSubview(titleLabel)
        titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: .padding).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: .padding).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -.padding).isActive = true

        let emailProductButton = UIButton.init(type: .custom)
        emailProductButton.setTitle(self.abTest.buttonText, for: .normal)
        emailProductButton.backgroundColor = .clear
        emailProductButton.setTitleColor(self.abTest.foregroundColor, for: .normal)
        emailProductButton.contentEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10)
        emailProductButton.setContentCompressionResistancePriority(.required, for: .vertical)
        emailProductButton.layer.borderColor = self.abTest.foregroundColor.cgColor
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
        let string = NSAttributedString.init(string: "product.sale_recovery.alert.dissmis".localized, attributes: [.underlineStyle:NSUnderlineStyle.styleSingle.rawValue, .underlineColor: abTest.foregroundColor, .foregroundColor: abTest.foregroundColor, .font: UIFont.screenshopFont(.quicksand, size: 18.0)])
        dismissButton.setAttributedTitle(string, for: .normal)
        dismissButton.backgroundColor = .clear
        dismissButton.addTarget(self, action: #selector(dissmissAction(_ :)), for: .touchUpInside)
        dismissButton.titleLabel?.textColor = abTest.foregroundColor
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dismissButton)
        dismissButton.topAnchor.constraint(equalTo: emailProductButton.bottomAnchor, constant: .padding).isActive = true
        dismissButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        view.bottomAnchor.constraint(equalTo: dismissButton.bottomAnchor, constant: .padding).isActive = true

    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        var size = self.view.systemLayoutSizeFitting(UILayoutFittingCompressedSize, withHorizontalFittingPriority: .defaultLow, verticalFittingPriority: .defaultHigh)
        let minWidth = UIScreen.main.bounds.size.width * 0.9
        if size.width < minWidth {
            size.width = minWidth
        }

        self.preferredContentSize = size
    }


    @objc func emailAction(_ sender:Any){
        emailProductBlock()
    }
    @objc func dissmissAction(_ sender:Any){
        dismissBlock()
    }

}
