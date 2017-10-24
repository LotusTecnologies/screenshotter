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
            SocialApp(image: #imageLiteral(resourceName: "SettingsScreenshot"), urlScheme: "snapchat", appStoreID: 447188370) { vc in
                let alert = UIAlertController(title: "Oops!", message: "You don't have Snapchat installed.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                vc.present(alert, animated: true, completion: nil)
            },
            SocialApp(image: #imageLiteral(resourceName: "SettingsInstagram"), urlScheme: "instagram", appStoreID: 389801252) { vc in
                UIApplication.shared.open(URL(string: "http://instagram.com")!, options: [:], completionHandler: nil)
            },
            SocialApp(image: #imageLiteral(resourceName: "SettingsFacebook"), urlScheme: "fb", appStoreID: 284882215) { vc in
                UIApplication.shared.open(URL(string: "http://facebook.com")!, options: [:], completionHandler: nil)
            },
            SocialApp(image: #imageLiteral(resourceName: "SettingsScreenshot"), urlScheme: "google", appStoreID: 284815942) { vc in
                UIApplication.shared.open(URL(string: "http://google.com")!, options: [:], completionHandler: nil)
            }
        ]
    }()
    
    private var label = UILabel()
    private var buttonView = UIView()
    private var notificationLabel = UILabel()
    private var notificationSwitch = UISwitch()
    private var didResignActiveObserver: Any? = nil
    private var didBecomeActiveObserver: Any? = nil
    private var ignoringResignActiveEvent = false
    
    deinit {
        if let observer = didResignActiveObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        if let observer = didBecomeActiveObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        didBecomeActiveObserver = nil
        didResignActiveObserver = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        didResignActiveObserver = NotificationCenter.default.addObserver(forName: .UIApplicationWillResignActive, object: nil, queue: nil) { note in
            guard self.ignoringResignActiveEvent == false else {
                return
            }
            
            guard self.presentingViewController?.presentedViewController == self else {
                return
            }
            
            self.presentingViewController?.dismiss(animated: false, completion: nil)
        }
        
        didBecomeActiveObserver = NotificationCenter.default.addObserver(forName: .UIApplicationDidBecomeActive, object: nil, queue: nil) { note in
            self.updateNotificationSwitchStatus()
        }
        
        setupLabel()
        setupNotificationView()
        setupButtons()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        ignoringResignActiveEvent = false
        updateNotificationSwitchStatus()
    }
    
    // MARK: -
    
    private func updateNotificationSwitchStatus() {
        PermissionsManager.shared().requestPermission(for: .push) {
            self.notificationSwitch.isOn = $0
            self.notificationSwitch.isEnabled = $0 == false
        }
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
        
        notificationSwitch.addTarget(self, action: #selector(notificationSwitchChanged(_:)), for: .valueChanged)
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
    
    @objc func notificationSwitchChanged(_ aSwitch: UISwitch) {
        if aSwitch.isOn {
            if PermissionsManager.shared().permissionStatus(for: .push) == .denied {
                // We're about to go to the native Settings screen, ignore the resign active event
                self.ignoringResignActiveEvent = true
            }
                
            PermissionsManager.shared().requestPermission(for: .push, openSettingsIfNeeded: true) { accepted in
                aSwitch.isOn = accepted
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
                self.navigateToSocialApp(withTag: button.tag)
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
