//
//  SettingsViewController.swift
//  screenshot
//
//  Created by Corey Werner on 12/7/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation
import MessageUI

fileprivate enum SettingsSection : Int {
    // Order reflects in the TableView
    case info
    case permission
    case product
    case follow
    case about
}

fileprivate enum SettingsRow : Int {
    case photoPermission
    case pushPermission
    case locationPermission // ???: should this be removed
    case email
    case name
    case tutorialVideo
    case tellFriend
    case usageStreak
    case contactUs
    case bug
    case version
    case coins
    case productGender
    case productSize
    case currency
    case followFacebook
    case followInstagram
}

@objc protocol _SettingsViewControllerDelegate : NSObjectProtocol {
    func settingsViewControllerDidGrantPermission(_ viewController: _SettingsViewController)
}

class _SettingsViewController : BaseViewController {
    weak var delegate: _SettingsViewControllerDelegate?
    
    fileprivate let tableView = UITableView(frame: .zero, style: .grouped)
    fileprivate let tableHeaderContentView = UIView()
    fileprivate let screenshotsCountLabel = UILabel()
    fileprivate let tableFooterTextView = UITextView()
    
    fileprivate var nameTextField: UITextField?
    fileprivate var emailTextField: UITextField?
    fileprivate lazy var previousTexts = {
        return [
            UserDefaultsKeys.name: self.cellText(for: .name),
            UserDefaultsKeys.email: self.cellText(for: .email)
        ]
    }()
    
    override var title: String? {
        set {}
        get {
            return "Settings"
        }
    }
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive(_:)), name: .UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground(_:)), name: .UIApplicationWillEnterForeground, object: nil)
        
        addNavigationItemLogo()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tableHeaderView: UIView = {
            let view = UIView()
            view.layoutMargins = UIEdgeInsets(top: .padding, left: .padding, bottom: 0, right: .padding)

            tableHeaderContentView.translatesAutoresizingMaskIntoConstraints = false
            tableHeaderContentView.backgroundColor = .white
            tableHeaderContentView.layoutMargins = UIEdgeInsets(top: .padding, left: .padding, bottom: .padding, right: .padding)
            tableHeaderContentView.layer.cornerRadius = .defaultCornerRadius
            tableHeaderContentView.layer.shadowColor = Shadow.basic.color.cgColor
            tableHeaderContentView.layer.shadowOffset = Shadow.basic.offset
            tableHeaderContentView.layer.shadowRadius = Shadow.basic.radius
            tableHeaderContentView.layer.shadowOpacity = 1
            view.addSubview(tableHeaderContentView)
            tableHeaderContentView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor).isActive = true
            tableHeaderContentView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor).isActive = true
            tableHeaderContentView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
            tableHeaderContentView.leftAnchor.constraint(greaterThanOrEqualTo: view.layoutMarginsGuide.leftAnchor).isActive = true
            tableHeaderContentView.rightAnchor.constraint(lessThanOrEqualTo: view.layoutMarginsGuide.rightAnchor).isActive = true

            let imageView = UIImageView(image: UIImage(named: "SettingsAddPhotos"))
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.contentMode = .scaleAspectFit
            imageView.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -.padding)
            tableHeaderContentView.addSubview(imageView)
            imageView.setContentHuggingPriority(UILayoutPriorityRequired, for: .horizontal)
            imageView.topAnchor.constraint(equalTo: tableHeaderContentView.layoutMarginsGuide.topAnchor).isActive = true
            imageView.leftAnchor.constraint(equalTo: tableHeaderContentView.layoutMarginsGuide.leftAnchor).isActive = true
            imageView.bottomAnchor.constraint(equalTo: tableHeaderContentView.layoutMarginsGuide.bottomAnchor).isActive = true

            screenshotsCountLabel.translatesAutoresizingMaskIntoConstraints = false
            screenshotsCountLabel.textAlignment = .center
            screenshotsCountLabel.font = UIFont.systemFont(ofSize: 20, weight: UIFontWeightSemibold)
            screenshotsCountLabel.adjustsFontSizeToFitWidth = true
            screenshotsCountLabel.minimumScaleFactor = 0.7
            tableHeaderContentView.addSubview(screenshotsCountLabel)
            screenshotsCountLabel.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, for: .horizontal)
            screenshotsCountLabel.topAnchor.constraint(equalTo: tableHeaderContentView.layoutMarginsGuide.topAnchor).isActive = true
            screenshotsCountLabel.leftAnchor.constraint(equalTo: imageView.layoutMarginsGuide.rightAnchor).isActive = true
            screenshotsCountLabel.bottomAnchor.constraint(equalTo: tableHeaderContentView.layoutMarginsGuide.bottomAnchor).isActive = true
            screenshotsCountLabel.rightAnchor.constraint(equalTo: tableHeaderContentView.layoutMarginsGuide.rightAnchor).isActive = true

            var rect = view.frame
            rect.size.height = view.layoutMargins.top + view.layoutMargins.bottom + tableHeaderContentView.layoutMargins.top + tableHeaderContentView.layoutMargins.bottom + (imageView.image?.size.height ?? 0)
            view.frame = rect

            return view
        }()

        tableFooterTextView.backgroundColor = .clear
        tableFooterTextView.isEditable = false
        tableFooterTextView.scrollsToTop = false
        tableFooterTextView.isScrollEnabled = false
        tableFooterTextView.dataDetectorTypes = .link
        tableFooterTextView.textAlignment = .center
        tableFooterTextView.font = UIFont.preferredFont(forTextStyle: .footnote)
        tableFooterTextView.adjustsFontForContentSizeCategory = true
        tableFooterTextView.text = "Questions? Get in touch: info@screenshopit.com"
        tableFooterTextView.linkTextAttributes = [
            NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue,
            NSUnderlineColorAttributeName: UIColor.gray7
        ]
        tableFooterTextView.frame = rectForTableFooterTextView()

        tableView.frame = view.bounds
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundView = nil
        tableView.backgroundColor = .clear
        tableView.tableHeaderView = tableHeaderView
        tableView.tableFooterView = tableFooterTextView
        tableView.keyboardDismissMode = .onDrag
        view.addSubview(tableView)
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let tableFooterTextViewRect = rectForTableFooterTextView()

        if tableView.tableFooterView?.bounds.size.height != tableFooterTextViewRect.size.height {
            tableFooterTextView.frame = tableFooterTextViewRect
            tableView.tableFooterView = tableFooterTextView
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateScreenshotsCount()
        reloadChangeableIndexPaths()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        dismissKeyboard()
    }
    
    @objc private func applicationDidBecomeActive(_ notification: Notification) {
        if view?.window != nil {
            // Use did become active since the permissions values can change through an alert view
            reloadChangeableIndexPaths()
        }
    }
    
    @objc private func applicationWillEnterForeground(_ notification: Notification) {
        if view?.window != nil {
            updateScreenshotsCount()
            reloadChangeableIndexPaths()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        
        tableView.delegate = nil
        tableView.dataSource = nil
    }
    
    // MARK: Data
    
    fileprivate let data: [SettingsSection : [SettingsRow]] = [
        .permission: [
            .photoPermission,
            .pushPermission,
//            .locationPermission
        ],
        .info: [
            .name,
            .email,
            .currency
        ],
        .about: [
            .tellFriend,
            .tutorialVideo,
            .contactUs,
            .bug,
            .usageStreak,
            .coins,
            .version
        ],
        .follow: [
            .followInstagram,
            .followFacebook
        ],
        .product: [
            .productGender,
            .productSize
        ]
    ]
    
    fileprivate func settingsRow(for indexPath: IndexPath) -> SettingsRow? {
        guard let section = SettingsSection(rawValue: indexPath.section) else {
            return nil
        }
        return data[section]?[indexPath.row]
    }
    
    fileprivate func indexPath(for row: SettingsRow, in section: SettingsSection) -> IndexPath? {
        guard let rowValue = data[section]?.index(of: row) else {
            return nil
        }
        return IndexPath(row: rowValue, section: section.rawValue)
    }
    
    // MARK: Screenshots
    
    var screenshotsCountText: String {
        let screenshotCount = DataModel.sharedInstance.countTotalScreenshots()
        let suffix = screenshotCount == 1 ? "" : "s"
        
        return "\(screenshotCount) screenshot\(suffix)"
    }
    
    private func layoutScreenshotsCountShadow() {
        tableHeaderContentView.layoutIfNeeded()
        tableHeaderContentView.layer.shadowPath = UIBezierPath(roundedRect: tableHeaderContentView.bounds, cornerRadius: tableHeaderContentView.layer.cornerRadius).cgPath
    }
    
    private func updateScreenshotsCount() {
        screenshotsCountLabel.text = screenshotsCountText
        layoutScreenshotsCountShadow()
    }
    
    // MARK: Product Options
    
    @objc fileprivate func genderControlAction(_ control: UISegmentedControl) {
        // TODO: use the swift version
        let integer = _ProductsOptionsGender.toOffsetValue(control.selectedSegmentIndex)
        UserDefaults.standard.set(integer, forKey: UserDefaultsKeys.productGender)
    }
}

extension _SettingsViewController : ViewControllerLifeCycle {
    func viewController(_ viewController: UIViewController, willDisappear animated: Bool) {
        if viewController.isKind(of: CurrencyViewController.self), let indexPath = indexPath(for: .currency, in: .info) {
            tableView.reloadRows(at: [indexPath], with: .none)
        }
    }
}

// MARK: - Table View

extension _SettingsViewController : UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let settingsSection = SettingsSection(rawValue: section) else {
            return 0
        }
        return data[settingsSection]?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let settingsSection = SettingsSection(rawValue: section) else {
            return nil
        }
        return sectionText(for: settingsSection)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let row = settingsRow(for: indexPath) else {
            return UITableViewCell()
        }
        
        var cell: UITableViewCell
        
        if indexPath.section == SettingsSection.info.rawValue && (row == SettingsRow.name || row == SettingsRow.email) {
            cell = self.tableView(tableView, inputCellForRowAt: indexPath, withRow: row)
            
        } else {
            cell = self.tableView(tableView, defaultCellForRowAt: indexPath, withRow: row)
        }
        
        cell.accessoryType = cellAccessoryType(for: row)
        cell.accessoryView = cellAccessoryView(for: row)
        return cell;
    }
    
    private func tableView(_ tableView: UITableView, inputCellForRowAt indexPath: IndexPath, withRow row: SettingsRow) -> UITableViewCell {
        let reusableCell = tableView.dequeueReusableCell(withIdentifier: "input") as? TextFieldTableViewCell
        let cell = reusableCell ?? TextFieldTableViewCell(style: .default, reuseIdentifier: "input")
        
        if reusableCell == nil {
            cell.textField.delegate = self
            
            if row == .email {
                emailTextField = cell.textField
                cell.textField.keyboardType = .emailAddress
                
            } else if row == .name {
                nameTextField = cell.textField
                cell.textField.keyboardType = .default
            }
        }
        
        cell.textField.text = cellText(for: row)
        cell.textField.placeholder = cellDetailedText(for: row)
        return cell
    }
    
    private func tableView(_ tableView: UITableView, defaultCellForRowAt indexPath: IndexPath, withRow row: SettingsRow) -> UITableViewCell {
        let reusableCell = tableView.dequeueReusableCell(withIdentifier: "cell")
        let cell = reusableCell ?? UITableViewCell(style: .value1, reuseIdentifier: "cell")
        cell.imageView?.image = cellImage(for: row)
        cell.textLabel?.text = cellText(for: row)
        cell.detailTextLabel?.text = cellDetailedText(for: row)
        return cell
    }
}

extension _SettingsViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        guard let row = settingsRow(for: indexPath) else {
            return true
        }
        
        switch (row) {
        case .version, .email, .coins, .productGender, .productSize:
            return false
        case .locationPermission, .pushPermission, .photoPermission:
            if let permissionType = row.permissionType, !PermissionsManager.shared().hasPermission(for: permissionType) {
                return true
            } else {
                return false
            }
        default:
            return true
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let row = settingsRow(for: indexPath) else {
            return
        }
        
        switch (row) {
        case .bug:
            presentMailComposer()
            
        case .tellFriend:
            let viewController = InviteViewController()
            viewController.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(viewController, animated: true)
        
        case .tutorialVideo:
            // TODO: does the below function have a swift version?
            let viewController = TutorialVideoViewControllerFactory.replayViewController
            viewController.showsReplayButtonUponFinishing = false
            viewController.delegate = self
            viewController.modalTransitionStyle = .crossDissolve
            present(viewController, animated: true, completion: nil)
        
        case .contactUs:
            IntercomHelper.sharedInstance.presentMessagingUI()
            
        case .locationPermission, .pushPermission, .photoPermission:
            if let permissionType = row.permissionType {
                PermissionsManager.shared().requestPermission(for: permissionType, openSettingsIfNeeded: true, response: { granted in
                    if granted {
                        tableView.reloadRows(at: [indexPath], with: .fade)
                        self.delegate?.settingsViewControllerDidGrantPermission(self)
                    }
                })
            }
            
        case .currency:
            let viewController = CurrencyViewController()
            viewController.lifeCycleDelegate = self
            viewController.title = cellText(for: row)
            viewController.hidesBottomBarWhenPushed = true
            viewController.selectedCurrencyCode = UserDefaults.standard.string(forKey: UserDefaultsKeys.productCurrency)
            navigationController?.pushViewController(viewController, animated: true)
        
        case .followInstagram:
            if let url = URL(string: "https://www.instagram.com/screenshopit/") {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            
        case .followFacebook:
            if let url = URL(string: "https://www.facebook.com/screenshopit/") {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            
        default:
            break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

fileprivate extension _SettingsViewController {
    func sectionText(for section: SettingsSection) -> String {
        switch section {
        case .permission:
            return "Permissions"
        case .about:
            return "About"
        case .info:
            return "Your Info"
        case .follow:
            return "Follow Us"
        case .product:
            return "Product Options"
        }
    }
    
    func cellImage(for row: SettingsRow) -> UIImage? {
        switch (row) {
        case .followInstagram:
            return UIImage(named: "SettingsInstagram")
        case .followFacebook:
            return UIImage(named: "SettingsFacebook")
        default:
            return nil
        }
    }
    
    func cellText(for row: SettingsRow) -> String {
        switch (row) {
        case .usageStreak:
            return "Daily Streak"
        case .bug:
            return "Submit a Bug"
        case .tellFriend:
            return "Tell a Friend"
        case .contactUs:
            return "Contact Us"
        case .tutorialVideo:
            return "Replay Tutorial"
        case .name:
            return UserDefaults.standard.string(forKey: UserDefaultsKeys.name) ?? ""
        case .email:
            return UserDefaults.standard.string(forKey: UserDefaultsKeys.email) ?? ""
        case .locationPermission:
            return "Location Services"
        case .pushPermission:
            return "Push Notifications"
        case .photoPermission:
            return "Camera Roll"
        case .version:
            return "App Version"
        case .coins:
            return "Coins Collected"
        case .productGender:
            return "Gender"
        case .productSize:
            return "Size"
        case .currency:
            return "Currency"
        case .followInstagram:
            return "Instagram"
        case .followFacebook:
            return "Facebook"
        }
    }
    
    func cellDetailedText(for row: SettingsRow) -> String? {
        switch (row) {
        case .photoPermission, .pushPermission, .locationPermission:
            return cellEnabledText(for: row)
        case .usageStreak:
            let streak = UserDefaults.standard.integer(forKey: UserDefaultsKeys.dailyStreak)
            let suffix = streak == 1 ? "" : "s"
            return "\(streak) day\(suffix)"
        case .version:
            return "\(Bundle.displayVersionBuild)\(Constants.buildEnvironmentSuffix)"
        case .name:
            return "Enter Your Name"
        case .email:
            return "Enter Your Email"
        case .coins:
            return "\(UserDefaults.standard.integer(forKey: UserDefaultsKeys.gameScore))"
        case .currency:
            return UserDefaults.standard.string(forKey: UserDefaultsKeys.productCurrency)
        default:
            return nil
        }
    }
    
    func cellEnabledText(for row: SettingsRow) -> String? {
        guard let permissionType = row.permissionType else {
            return nil
        }
        return PermissionsManager.shared().hasPermission(for: permissionType) ? "Enabled" : "Disabled"
    }
    
    func cellAccessoryType(for row: SettingsRow) -> UITableViewCellAccessoryType {
        switch row {
        case .tellFriend, .currency:
            return .disclosureIndicator
        default:
            return .none
        }
    }
    
    func cellAccessoryView(for row: SettingsRow) -> UIView? {
        switch (row) {
        case .photoPermission, .pushPermission:
            if let permissionType = row.permissionType, !PermissionsManager.shared().hasPermission(for: permissionType) {
                let size = CGFloat(18)
                
                let label = UILabel(frame: CGRect(x: 0, y: 0, width: size, height: size))
                label.backgroundColor = .crazeRed
                label.text = "!"
                label.textAlignment = .center
                label.font = UIFont(name: "Optima-ExtraBlack", size: 14)
                label.textColor = .white
                label.layer.cornerRadius = size / 2
                label.layer.masksToBounds = true
                return label
                
            } else {
                return nil
            }
            
        case .productGender:
            // TODO: use swift version of getting gender string value
            let integer = UserDefaults.standard.integer(forKey: UserDefaultsKeys.productGender)
            
            let control = UISegmentedControl(items: ["Female", "Male", "All"])
            control.tintColor = .crazeGreen
            control.selectedSegmentIndex = _ProductsOptionsGender.fromOffsetValue(integer)
            control.addTarget(self, action: #selector(genderControlAction(_:)), for: .valueChanged)
            return control
            
        default:
            return nil
        }
    }
    
    func rectForTableFooterTextView() -> CGRect {
        let maxWidth = view.bounds.size.width - tableFooterTextView.textContainerInset.left - tableFooterTextView.textContainerInset.right
        let size = CGSize(width: maxWidth, height: .greatestFiniteMagnitude)
        var rect = tableFooterTextView.attributedText.boundingRect(with: size, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        rect.size.width = ceil(rect.size.width) + tableFooterTextView.textContainerInset.left + tableFooterTextView.textContainerInset.right
        rect.size.height = ceil(rect.size.height) + tableFooterTextView.textContainerInset.top + tableFooterTextView.textContainerInset.bottom + .padding
        return rect
    }
    
    func reloadChangeableIndexPaths() {
        func sectionIndexPaths(_ section: SettingsSection) -> [IndexPath] {
            var indexPaths: [IndexPath] = []
            
            data[section]?.forEach { row in
                if let indexPath = indexPath(for: row, in: section) {
                    indexPaths.append(indexPath)
                }
            }
            
            return indexPaths
        }
        
        var indexPaths = sectionIndexPaths(.permission) + sectionIndexPaths(.product)
        
        if let indexPath = indexPath(for: .usageStreak, in: .about) {
            indexPaths.append(indexPath)
        }
        
        tableView.reloadRows(at: indexPaths, with: .none)
    }
}

// MARK: - Text Field

extension _SettingsViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.returnKeyType == .done {
            textField.resignFirstResponder()
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let key = userDefaultsKey(for: textField) {
            // TODO: can trimWhitespace be removed?
//            NSString *trimmedText = [textField.text trimWhitespace];
            let trimmedText = textField.text?.trimmingCharacters(in: .whitespaces)
            var canContinue = false
            
            if key == UserDefaultsKeys.email {
                canContinue = textField.text?.isValidEmail ?? false
                
            } else if key == UserDefaultsKeys.name {
                canContinue = (trimmedText?.count ?? 0) > 0
            }
            
            if (canContinue) {
                self.previousTexts[key] = trimmedText;
                textField.text = trimmedText;
                
                UserDefaults.standard.set(trimmedText, forKey: key)
                UserDefaults.standard.synchronize()
                
                reidentify()
                
            } else {
                textField.text = self.previousTexts[key];
            }
        }
    }
    
    fileprivate func userDefaultsKey(for textField: UITextField) -> String? {
        if textField == self.emailTextField {
            return UserDefaultsKeys.email;
            
        } else if textField == self.nameTextField {
            return UserDefaultsKeys.name;
        }
        
        return nil
    }
    
    fileprivate func reidentify() {
        let name = nameTextField?.text?.trimmingCharacters(in: .whitespaces)
        let email = emailTextField?.text?.trimmingCharacters(in: .whitespaces)
        let user = AnalyticsUser(name: name, email: email)
        
        AnalyticsTrackers.standard.identify(user)
        AnalyticsTrackers.branch.identify(user)
    }
    
    fileprivate func dismissKeyboard() {
        tableView.endEditing(true)
    }
}

// MARK: - Tutorial

extension _SettingsViewController : TutorialViewControllerDelegate {
    func tutoriaViewControllerDidComplete(_ viewController: TutorialViewController) {
        navigationController?.popViewController(animated: true)
    }
}

extension _SettingsViewController : TutorialVideoViewControllerDelegate {
    func tutorialVideoViewControllerDoneButtonTapped(_ viewController: TutorialVideoViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    func tutorialVideoViewControllerDidEnd(_ viewController: TutorialVideoViewController) {
        AnalyticsTrackers.standard.track("Automatically Exited Tutorial Video")

        // TODO: look into why the dispatch is here - corey
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
        }
    }
}

// MARK: - Mail

extension _SettingsViewController : MFMailComposeViewControllerDelegate {
    func presentMailComposer() {
        if MFMailComposeViewController.canSendMail() {
            let message = [
                "\n\n\n",
                "-----------------",
                "Don't edit below.\n",
                "version: \(Bundle.displayVersionBuild)"
            ]

            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setSubject("Bug Report")
            mail.setMessageBody(message.joined(separator: "\n"), isHTML: false)
            mail.setToRecipients(["support@screenshopit.com"])
            present(mail, animated: true, completion: nil)

        } else {
            let alertController = UIAlertController(title: "Setup Email", message: "You need to setup an email on your device in order to send a bug report.", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Later", style: .cancel, handler: nil))
            
            if let mailURL = URL(string: "message://"), UIApplication.shared.canOpenURL(mailURL) {
                alertController.addAction(UIAlertAction(title: "Setup", style: .default, handler: { action in
                    UIApplication.shared.open(mailURL, options: [:], completionHandler: nil)
                }))
            }
            
            present(alertController, animated: true, completion: nil)
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - Permissions

fileprivate extension SettingsRow {
    var permissionType: PermissionType? {
        switch self {
        case .photoPermission:
            return PermissionType.photo
        case .locationPermission:
            return PermissionType.location
        case .pushPermission:
            return PermissionType.push
        default:
            return nil
        }
    }
}
