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
    let appStoreID: Int
    let notInstalled: (InvokeScreenshotViewController) -> Void
    
    private var appStoreURL: URL {
        return URL(string:"itms://itunes.apple.com/us/app/apple-store/id\(appStoreID)")!
    }

    private var appOpenURL: URL {
        return URL(string: "\(urlScheme)://")!
    }
    
    var isInstalled: Bool {
        return UIApplication.shared.canOpenURL(appOpenURL)
    }
    
    func open(completion: @escaping (Bool) -> Void = { _ in }) {
        UIApplication.shared.open(appOpenURL, options: [:], completionHandler: completion)
    }
}

class InvokeScreenshotViewController : UIViewController {
    private lazy var socialApps = { _ -> [SocialApp] in
        return [
            SocialApp(image: #imageLiteral(resourceName: "insta-launch"), urlScheme: "instagram", appStoreID: 389801252) { vc in
                UIApplication.shared.open(URL(string: "http://instagram.com")!, options: [:], completionHandler: nil)
            },
            SocialApp(image: #imageLiteral(resourceName: "snapchat-launch"), urlScheme: "snapchat", appStoreID: 447188370) { vc in
                let alert = UIAlertController(title: "Oops!", message: "You don't have Snapchat installed.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                vc.present(alert, animated: true, completion: nil)
            },
            SocialApp(image: #imageLiteral(resourceName: "fb-launch"), urlScheme: "fb", appStoreID: 284882215) { vc in
                UIApplication.shared.open(URL(string: "http://facebook.com")!, options: [:], completionHandler: nil)
            },
            SocialApp(image: #imageLiteral(resourceName: "google-launch"), urlScheme: "google", appStoreID: 284815942) { vc in
                UIApplication.shared.open(URL(string: "http://google.com")!, options: [:], completionHandler: nil)
            }
        ]
    }()
    
    private var titleLabel = UILabel()
    private var descriptionLabel = UILabel()
    private var buttonView = UIView()
    private var notificationSwitch = UISwitch()
    private var willEnterForegroundObserver: Any? = nil
    private var dismissesOnBecomingActive = true
    
    deinit {
        if let observer = willEnterForegroundObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        willEnterForegroundObserver = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        view.layoutMargins = UIEdgeInsets(top: Geometry.extendedPadding, left: 5 + Geometry.padding, bottom: Geometry.extendedPadding, right: 5 + Geometry.padding)
        
        willEnterForegroundObserver = NotificationCenter.default.addObserver(forName: .UIApplicationWillEnterForeground, object: nil, queue: nil) { note in
            if (self.dismissesOnBecomingActive) {
                self.presentingViewController?.dismiss(animated: false, completion: nil)
            } else {
                self.updateNotificationSwitchStatus()
                self.dismissesOnBecomingActive = true
            }
        }
        
        setupTitleLabel()
        setupDescriptionLabel()
        setupNotificationView()
        setupButtons()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    
        updateNotificationSwitchStatus()
    }
    
    // MARK: -
    
    private func updateNotificationSwitchStatus() {
        let hasPermission = PermissionsManager.shared().hasPermission(for: .push)
        
        notificationSwitch.setOn(hasPermission, animated: true)
        notificationSwitch.isEnabled = !hasPermission
    }
    
    private func setupTitleLabel() {
        titleLabel.text = "Now leave the app!"
        titleLabel.textAlignment = .center
        titleLabel.textColor = .red
        titleLabel.minimumScaleFactor = 0.7
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.font = UIFont.preferredFont(forTextStyle: .title1)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
    
        view.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            titleLabel.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
        ])
    }
    
    private func setupDescriptionLabel() {
        let attributedText = NSMutableAttributedString()
        let attributedStringData = [
            AttributedStringData(text: "No, seriously. ", attributes:[ NSFontAttributeName : UIFont.preferredFont(forTextStyle: .title2), NSForegroundColorAttributeName : UIColor.gray ]),
            AttributedStringData(text: "Close this app.\n\n", attributes:[ NSFontAttributeName : UIFont.preferredFont(forTextStyle: .title2), NSForegroundColorAttributeName : UIColor.black ]),
            AttributedStringData(text: "Go to your favorite places for fashion inspiration - Instagram, Snapchat, Google, anywhere -- ", attributes: [ NSFontAttributeName : UIFont.preferredFont(forTextStyle: .title2), NSForegroundColorAttributeName : UIColor.gray ]),
            AttributedStringData(text: "take screenshots", attributes: [ NSFontAttributeName : UIFont.preferredFont(forTextStyle: .title2), NSForegroundColorAttributeName : UIColor.black ]),
            AttributedStringData(text: ", then come back and ", attributes: [ NSFontAttributeName : UIFont.preferredFont(forTextStyle: .title2), NSForegroundColorAttributeName : UIColor.gray ]),
            AttributedStringData(text: "shop them here!", attributes: [ NSFontAttributeName : UIFont.preferredFont(forTextStyle: .title2), NSForegroundColorAttributeName : UIColor.black ])
        ]
        
        var currentStringIndex = 0
        attributedStringData.forEach { data in
            let string = NSAttributedString(string: data.text, attributes: data.attributes ?? [:])
            attributedText.insert(string, at: currentStringIndex)
            currentStringIndex += data.text.count
        }
        
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.attributedText = attributedText
        descriptionLabel.numberOfLines = 0
        descriptionLabel.lineBreakMode = .byWordWrapping
        
        view.addSubview(descriptionLabel)
        
        NSLayoutConstraint.activate([
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: Geometry.padding),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor)
        ])
    }
    
    private func setupButtons() {
        let stackView = UIStackView()
        stackView.alignment = .center
        stackView.axis = .horizontal
        stackView.distribution = .equalCentering
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stackView)
        
        socialApps.enumerated().forEach { i, app in
            let button = UIButton()
            button.tag = i
            button.translatesAutoresizingMaskIntoConstraints = false
            button.setImage(app.image, for: .normal)
            button.addTarget(self, action: #selector(socialButtonTapped(button:)), for: .touchUpInside)
            
            stackView.addArrangedSubview(button)
        }
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 50),
        ])
    }
    
    private func setupNotificationView() {
        let topLabel = UILabel()
        let bottomLabel = UILabel()
        
        topLabel.translatesAutoresizingMaskIntoConstraints = false
        topLabel.text = "Enable notifications"
        topLabel.font = UIFont.preferredFont(forTextStyle: .title3)
        
        view.addSubview(topLabel)
        
        bottomLabel.translatesAutoresizingMaskIntoConstraints = false
        bottomLabel.text = "We'll send you a notification when your\nscreenshot is ready to be shopped."
        bottomLabel.numberOfLines = 0
        bottomLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        bottomLabel.textColor = .gray6
        
        view.addSubview(bottomLabel)
        
        notificationSwitch.addTarget(self, action: #selector(notificationSwitchChanged(_:)), for: .valueChanged)
        notificationSwitch.translatesAutoresizingMaskIntoConstraints = false
        notificationSwitch.onTintColor = .crazeRed
        view.addSubview(notificationSwitch)
        
        NSLayoutConstraint.activate([
            topLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            topLabel.bottomAnchor.constraint(equalTo: bottomLabel.topAnchor, constant: -Geometry.padding),
            topLabel.trailingAnchor.constraint(equalTo: notificationSwitch.leadingAnchor, constant: -Geometry.padding),
            
            bottomLabel.leadingAnchor.constraint(equalTo: topLabel.leadingAnchor),
            bottomLabel.trailingAnchor.constraint(equalTo: notificationSwitch.leadingAnchor, constant: -Geometry.padding),
            bottomLabel.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor),
            
            notificationSwitch.centerYAnchor.constraint(equalTo: topLabel.centerYAnchor),
            notificationSwitch.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor)
        ])
    }
    
    // MARK: Actions
    
    @objc func notificationSwitchChanged(_ aSwitch: UISwitch) {
        if aSwitch.isOn {
            if PermissionsManager.shared().permissionStatus(for: .push) == .denied {
                // We're about to go to the native Settings screen, don't dismiss the view when we become active again
                self.dismissesOnBecomingActive = false
            }
            
            PermissionsManager.shared().requestPermission(for: .push, openSettingsIfNeeded: true) { accepted in
                aSwitch.setOn(accepted, animated: true)
                aSwitch.isEnabled = accepted == false
            }
        }
    }
    
    @objc func socialButtonTapped(button: UIButton) {
        guard PermissionsManager.shared().hasPermission(for: .push) == false else {
            // Already has permission, navigate to the app.
            self.navigateToSocialApp(withTag: button.tag)
            return
        }
        
        let alert = UIAlertController(title: "Turn on Notifications!", message: "We’ll let you know when your screenshots are shoppable", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Later", style: .cancel) { action in
            self.navigateToSocialApp(withTag: button.tag)
        })
        
        alert.addAction(UIAlertAction(title: "OK", style: .default) { action in
            PermissionsManager.shared().requestPermission(for: .push) { accepted in
                self.updateNotificationSwitchStatus()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.75, execute: {
                    self.navigateToSocialApp(withTag: button.tag)
                })
            }
        })
        
        present(alert, animated: true, completion: nil)
    }
    
    private func navigateToSocialApp(withTag tag: Int) {
        guard tag < socialApps.count else {
            return
        }

        let app = socialApps[tag]
        guard app.isInstalled else {
            app.notInstalled(self)
            
            return
        }
        
        app.open() { opened in
             if opened == false {
                app.notInstalled(self)
            }
        }
    }
}
