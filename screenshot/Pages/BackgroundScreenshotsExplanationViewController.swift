//
//  BackgroundScreenshotsExplanationViewController.swift
//  screenshot
//
//  Created by Jacob Relkin on 10/23/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import UIKit

fileprivate struct AttributedStringData {
    let text: String
    let attributes: [String : Any]?
}

fileprivate struct SocialApp {
    let image: UIImage?
    let urlScheme: String
    let appStoreID: Int
    let notInstalled: (BackgroundScreenshotsExplanationViewController) -> Void
    
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

class BackgroundScreenshotsExplanationViewController : UIViewController {
    private lazy var socialApps = { _ -> [SocialApp] in
        return [
            SocialApp(image: UIImage(named: "TutorialInstagram"), urlScheme: "instagram", appStoreID: 389801252) { vc in
                UIApplication.shared.open(URL(string: "http://instagram.com")!, options: [:], completionHandler: nil)
            },
            SocialApp(image: UIImage(named: "TutorialSnapchat"), urlScheme: "snapchat", appStoreID: 447188370) { vc in
                let alert = UIAlertController(title: "Oops!", message: "You don't have Snapchat installed.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                vc.present(alert, animated: true, completion: nil)
            },
            SocialApp(image: UIImage(named: "TutorialFacebook"), urlScheme: "fb", appStoreID: 284882215) { vc in
                UIApplication.shared.open(URL(string: "http://facebook.com")!, options: [:], completionHandler: nil)
            },
            SocialApp(image: UIImage(named: "TutorialGoogle"), urlScheme: "google", appStoreID: 284815942) { vc in
                UIApplication.shared.open(URL(string: "http://google.com")!, options: [:], completionHandler: nil)
            }
        ]
    }()
    
    private var titleLabel = UILabel()
    private var descriptionLabel = UILabel()
    private var buttonView = UIView()
    private var notificationSwitch = UISwitch()
    private var dismissesOnBecomingActive = true
    
    
    // MARK: Life Cycle
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground(_:)), name: .UIApplicationWillEnterForeground, object: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let padding = Geometry.padding
        
        view.backgroundColor = .white
        
        titleLabel.text = "Now leave the app!"
        titleLabel.textAlignment = .center
        titleLabel.textColor = .crazeRed
        titleLabel.minimumScaleFactor = 0.7
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.font = UIFont.preferredFont(forTextStyle: .title1)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        titleLabel.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor).isActive = true
        
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.attributedText = descriptionAttributedText()
        descriptionLabel.numberOfLines = 0
        descriptionLabel.lineBreakMode = .byWordWrapping
        view.addSubview(descriptionLabel)
        descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: padding).isActive = true
        descriptionLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor).isActive = true
        descriptionLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor).isActive = true
        
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .center
        stackView.axis = .horizontal
        stackView.distribution = .equalCentering
        view.addSubview(stackView)
        stackView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: padding).isActive = true
        stackView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor).isActive = true
        stackView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor).isActive = true
        
        addSocialAppsToView(stackView)
        
        notificationSwitch.translatesAutoresizingMaskIntoConstraints = false
        notificationSwitch.onTintColor = .crazeRed
        notificationSwitch.addTarget(self, action: #selector(notificationSwitchChanged(_:)), for: .valueChanged)
        view.addSubview(notificationSwitch)
        notificationSwitch.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: padding).isActive = true
        notificationSwitch.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor).isActive = true
        
        updateNotificationSwitchStatus(animated: false)
        
        let notificationLabel = UILabel()
        notificationLabel.translatesAutoresizingMaskIntoConstraints = false
        notificationLabel.text = "Enable notifications"
        notificationLabel.font = UIFont.preferredFont(forTextStyle: .title3)
        view.addSubview(notificationLabel)
        notificationLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor).isActive = true
        notificationLabel.trailingAnchor.constraint(equalTo: notificationSwitch.leadingAnchor, constant: -padding).isActive = true
        notificationLabel.centerYAnchor.constraint(equalTo: notificationSwitch.centerYAnchor).isActive = true
        
        let notificationDescription = UILabel()
        notificationDescription.translatesAutoresizingMaskIntoConstraints = false
        notificationDescription.text = "We'll send you a notification when your screenshot is ready to be shopped"
        notificationDescription.numberOfLines = 0
        notificationDescription.font = UIFont.preferredFont(forTextStyle: .subheadline)
        notificationDescription.textColor = .gray6
        view.addSubview(notificationDescription)
        notificationDescription.topAnchor.constraint(equalTo: notificationSwitch.bottomAnchor, constant: padding).isActive = true
        notificationDescription.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor).isActive = true
        notificationDescription.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor).isActive = true
        notificationDescription.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor).isActive = true
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        let offset = CGPoint(x: Geometry.padding, y: Geometry.extendedPadding)
        view.layoutMargins = UIEdgeInsets(top: offset.y, left: offset.x, bottom: offset.y, right: offset.x)
    }
    
    func applicationWillEnterForeground(_ notification: Notification) {
        if view.window != nil {
            if dismissesOnBecomingActive {
                presentingViewController?.dismiss(animated: false, completion: nil)
                
            } else {
                updateNotificationSwitchStatus()
                dismissesOnBecomingActive = true
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Description
    
    private func descriptionAttributedText() -> NSAttributedString {
        let defaultAttributes = [
            NSFontAttributeName: UIFont.preferredFont(forTextStyle: .title2),
            NSForegroundColorAttributeName: UIColor.gray6
        ]
        let highlightedAttributes = [
            NSFontAttributeName: UIFont.preferredFont(forTextStyle: .title2),
            NSForegroundColorAttributeName: UIColor.black
        ]
        let attributedStringData = [
            AttributedStringData(text: "No, seriously. ", attributes: defaultAttributes),
            AttributedStringData(text: "Close this app.\n\n", attributes: highlightedAttributes),
            AttributedStringData(text: "Go to your favorite places for fashion inspiration - Instagram, Snapchat, Google, anywhere -- ", attributes: defaultAttributes),
            AttributedStringData(text: "take screenshots", attributes: highlightedAttributes),
            AttributedStringData(text: ", then come back and ", attributes: defaultAttributes),
            AttributedStringData(text: "shop them here!", attributes: highlightedAttributes)
        ]
        
        let attributedText = NSMutableAttributedString()
        var currentStringIndex = 0
        
        attributedStringData.forEach { data in
            let string = NSAttributedString(string: data.text, attributes: data.attributes ?? [:])
            attributedText.insert(string, at: currentStringIndex)
            currentStringIndex += data.text.count
        }
        
        return attributedText
    }
    
    // MARK: Social
    
    private func addSocialAppsToView(_ stackView: UIStackView) {
        socialApps.enumerated().forEach { i, app in
            let button = UIButton()
            button.tag = i
            button.translatesAutoresizingMaskIntoConstraints = false
            button.setImage(app.image, for: .normal)
            button.addTarget(self, action: #selector(socialButtonTapped(button:)), for: .touchUpInside)
            
            stackView.addArrangedSubview(button)
        }
    }
    
    // MARK: - Notification
    
    private func updateNotificationSwitchStatus(animated: Bool = true) {
        let hasPermission = PermissionsManager.shared().hasPermission(for: .push)
        
        notificationSwitch.setOn(hasPermission, animated: animated)
        notificationSwitch.isEnabled = !hasPermission
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
