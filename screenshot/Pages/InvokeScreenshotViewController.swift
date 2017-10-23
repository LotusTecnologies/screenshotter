//
//  InvokeScreenshotViewController.swift
//  screenshot
//
//  Created by Jacob Relkin on 10/23/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import UIKit

struct AttributedStringData {
    let text:String
    let attributes:[String : Any]?
}

struct SocialApp {
    let image: UIImage
    let urlScheme: String
    let appStoreID: String
}

class InvokeScreenshotViewController : UIViewController {
    private var socialApps = [
        SocialApp(image: #imageLiteral(resourceName: "SettingsScreenshot"), urlScheme: "snapchat", appStoreID: "447188370"),
        SocialApp(image: #imageLiteral(resourceName: "SettingsInstagram"), urlScheme: "instagram", appStoreID: "389801252"),
        SocialApp(image: #imageLiteral(resourceName: "SettingsFacebook"), urlScheme: "fb", appStoreID: "284882215"),
        SocialApp(image: #imageLiteral(resourceName: "SettingsScreenshot"), urlScheme: "google", appStoreID: "284815942")
    ]
    
    private var label = UILabel()
    private var buttonView = UIView()
    private var notificationLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        setupLabel()
        setupNotificationView()
        setupButtons()
    }
    
    private func setupLabel() {
        let attributedText = NSMutableAttributedString()
        let attributedStringData = [
            AttributedStringData(text: "Now leave the app!\n\n", attributes: [ NSFontAttributeName : UIFont.preferredFont(forTextStyle: .title1), NSForegroundColorAttributeName : UIColor.red ]),
            AttributedStringData(text: "No, seriously. ", attributes:[ NSFontAttributeName : UIFont.preferredFont(forTextStyle: .title2), NSForegroundColorAttributeName : UIColor.gray ]),
            AttributedStringData(text: "Close this app.\n\n", attributes:[ NSFontAttributeName : UIFont.preferredFont(forTextStyle: .title2), NSForegroundColorAttributeName : UIColor.black ]),
            AttributedStringData(text: "Go to your favorite places for\nfashion inspiration - Instagram,\nSnapchat, Google, anywhere -\n", attributes: [ NSFontAttributeName : UIFont.preferredFont(forTextStyle: .title2), NSForegroundColorAttributeName : UIColor.gray ]),
            AttributedStringData(text: "take screenshots", attributes: [ NSFontAttributeName : UIFont.preferredFont(forTextStyle: .title2), NSForegroundColorAttributeName : UIColor.black ]),
            AttributedStringData(text: ", then come back\nand ", attributes: [ NSFontAttributeName : UIFont.preferredFont(forTextStyle: .title2), NSForegroundColorAttributeName : UIColor.gray ]),
            AttributedStringData(text: "shop them here!", attributes: [ NSFontAttributeName : UIFont.preferredFont(forTextStyle: .title2), NSForegroundColorAttributeName : UIColor.black ])
        ]
        
        var currentStringIndex = 0
        attributedStringData.forEach { data in
            let string = NSAttributedString(string: data.text, attributes: data.attributes ?? [:])
            attributedText.insert(string, at: currentStringIndex)
            currentStringIndex += data.text.count
        }
        
        label.translatesAutoresizingMaskIntoConstraints = false
        label.attributedText = attributedText
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor, constant: 20),
            label.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            label.widthAnchor.constraint(equalTo: view.layoutMarginsGuide.widthAnchor),
            label.heightAnchor.constraint(greaterThanOrEqualToConstant: 0)
        ])
    }
    
    private func setupButtons() {
        let stackView = UIStackView()
        stackView.alignment = .center
        stackView.axis = .horizontal
        stackView.distribution = .equalCentering
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stackView)
        
        var constraints = [NSLayoutConstraint]()
        socialApps.enumerated().forEach { i, app in
            let button = UIButton()
            button.tag = i
            button.translatesAutoresizingMaskIntoConstraints = false
            button.setImage(app.image, for: .normal)
            button.addTarget(self, action: #selector(socialButtonTapped(button:)), for: .touchUpInside)
            
            stackView.addArrangedSubview(button)
            
            constraints.append(contentsOf: [
                button.widthAnchor.constraint(greaterThanOrEqualToConstant: 0),
                button.heightAnchor.constraint(greaterThanOrEqualToConstant: 0)
            ])
        }
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 50),
            stackView.heightAnchor.constraint(greaterThanOrEqualToConstant: 0)
        ] + constraints)
    }
    
    private func setupNotificationView() {
        let attributedText = NSMutableAttributedString()
        let firstLine = "Enable notifications\n\n"
        attributedText.insert(NSAttributedString(string: firstLine), at: 0)
        attributedText.insert(NSAttributedString(string: "We'll send you a notification when your\nscreenshot is ready to be shopped.", attributes: [ NSFontAttributeName : UIFont.preferredFont(forTextStyle: .subheadline), NSForegroundColorAttributeName : UIColor.gray]), at: firstLine.count)
        
        notificationLabel.translatesAutoresizingMaskIntoConstraints = false
        notificationLabel.attributedText = attributedText
        notificationLabel.numberOfLines = 0
        view.addSubview(notificationLabel)
        
        let notificationSwitch = UISwitch()
        notificationSwitch.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(notificationSwitch)
        
        NSLayoutConstraint.activate([
            notificationLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            notificationLabel.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor, constant: -10),
            notificationLabel.trailingAnchor.constraint(equalTo: notificationSwitch.leadingAnchor, constant: -10),
            
            notificationSwitch.topAnchor.constraint(equalTo: notificationLabel.topAnchor, constant: 0),
            notificationSwitch.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor, constant: -10),
            notificationSwitch.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor, constant: -10),
        ])
    }
    
    // MARK: Actions
    
    @objc func socialButtonTapped(button: UIButton) {
        guard button.tag < socialApps.count else {
            return
        }
    
        let app = socialApps[button.tag]
        guard let schemeURL = URL(string: "\(app.urlScheme)://"), UIApplication.shared.canOpenURL(schemeURL) else {
            if let appStoreURL = URL(string:"itms://itunes.apple.com/us/app/apple-store/id\(app.appStoreID)") {
                UIApplication.shared.open(appStoreURL, options: [:], completionHandler: nil)
            }
            
            return
        }
    
        UIApplication.shared.open(schemeURL, options: [:], completionHandler: nil)
    }
}
