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

@objc protocol SettingsViewControllerDelegate : NSObjectProtocol {
    func settingsViewControllerDidGrantPermission(_ viewController: SettingsViewController)
}

class SettingsViewController : BaseViewController {
    weak var delegate: SettingsViewControllerDelegate?
    
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
    
    fileprivate let productsOptionsControls = ProductsOptionsControls()
    
    override var title: String? {
        set {}
        get {
            return "settings.title".localized
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
        tableFooterTextView.text = "settings.contact".localized
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

        if tableView.tableFooterView?.bounds.height != tableFooterTextViewRect.height {
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
            .pushPermission
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
        
        if screenshotCount == 1 {
            return "settings.screenshot.single".localized(withFormat: screenshotCount)
            
        } else {
            return "settings.screenshot.plural".localized(withFormat: screenshotCount)
        }
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
        let integer = ProductsOptionsGender(offsetValue: control.selectedSegmentIndex).rawValue
        UserDefaults.standard.set(integer, forKey: UserDefaultsKeys.productGender)
    }
    
    @objc fileprivate func sizeControlAction(_ control: UISegmentedControl) {
        let integer = ProductsOptionsSize(offsetValue: control.selectedSegmentIndex).rawValue
        UserDefaults.standard.set(integer, forKey: UserDefaultsKeys.productSize)
    }
}

extension SettingsViewController : ViewControllerLifeCycle {
    func viewController(_ viewController: UIViewController, willDisappear animated: Bool) {
        if viewController.isKind(of: CurrencyViewController.self), let indexPath = indexPath(for: .currency, in: .info) {
            tableView.reloadRows(at: [indexPath], with: .none)
        }
    }
}

// MARK: - Table View

extension SettingsViewController : UITableViewDataSource {
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
        
        if indexPath.section == SettingsSection.info.rawValue && (row == .name || row == .email) {
            cell = self.tableView(tableView, inputCellForRowAt: indexPath, withRow: row)
            
        } else {
            cell = self.tableView(tableView, defaultCellForRowAt: indexPath, withRow: row)
        }
        
        cell.accessoryType = cellAccessoryType(for: row)
        cell.accessoryView = cellAccessoryView(for: row)
        return cell;
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let row = settingsRow(for: indexPath) else {
            return
        }
        
        if indexPath.section == SettingsSection.product.rawValue && (row == .productGender || row == .productSize) {
            let width = max(productsOptionsControls.genderControl.bounds.width, productsOptionsControls.sizeControl.bounds.width)
            
            var frame = productsOptionsControls.genderControl.frame
            frame.size.width = width
            productsOptionsControls.genderControl.frame = frame
            
            frame = productsOptionsControls.sizeControl.frame
            frame.size.width = width
            productsOptionsControls.sizeControl.frame = frame
        }
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

extension SettingsViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        guard let row = settingsRow(for: indexPath) else {
            return true
        }
        
        switch (row) {
        case .version, .email, .coins, .productGender, .productSize, .usageStreak:
            return false
        case .pushPermission, .photoPermission:
            if let permissionType = row.permissionType, !PermissionsManager.shared.hasPermission(for: permissionType) {
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
            var viewController: TutorialVideoViewController
            
            if let username = UserDefaults.standard.string(forKey: UserDefaultsKeys.ambasssadorUsername) {
                viewController = TutorialVideoViewController(video: .ambassador(username: username))
                
            } else {
                viewController = TutorialVideoViewController(video: .standard)
            }
            
            viewController.showsReplayButtonUponFinishing = false
            viewController.delegate = self
            viewController.modalTransitionStyle = .crossDissolve
            present(viewController, animated: true, completion: nil)
        
        case .contactUs:
            IntercomHelper.sharedInstance.presentMessagingUI()
            
        case .pushPermission, .photoPermission:
            if let permissionType = row.permissionType {
                PermissionsManager.shared.requestPermission(for: permissionType, openSettingsIfNeeded: true, response: { granted in
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

fileprivate extension SettingsViewController {
    func sectionText(for section: SettingsSection) -> String {
        switch section {
        case .permission:
            return "settings.section.permission".localized
        case .about:
            return "settings.section.about".localized
        case .info:
            return "settings.section.info".localized
        case .follow:
            return "settings.section.follow".localized
        case .product:
            return "settings.section.product".localized
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
            return "settings.row.usage_streak.title".localized
        case .bug:
            return "settings.row.bug.title".localized
        case .tellFriend:
            return "settings.row.tell_friend.title".localized
        case .contactUs:
            return "settings.row.contact.title".localized
        case .tutorialVideo:
            return "settings.row.tutorial.title".localized
        case .name:
            return UserDefaults.standard.string(forKey: UserDefaultsKeys.name) ?? ""
        case .email:
            return UserDefaults.standard.string(forKey: UserDefaultsKeys.email) ?? ""
        case .pushPermission:
            return "settings.row.push_permission.title".localized
        case .photoPermission:
            return "settings.row.photo_permission.title".localized
        case .version:
            return "settings.row.version.title".localized
        case .coins:
            return "settings.row.coins.title".localized
        case .productGender:
            return "settings.row.gender.title".localized
        case .productSize:
            return "settings.row.size.title".localized
        case .currency:
            return "settings.row.currency.title".localized
        case .followInstagram:
            return "settings.row.instagram.title".localized
        case .followFacebook:
            return "settings.row.facebook.title".localized
        }
    }
    
    func cellDetailedText(for row: SettingsRow) -> String? {
        switch (row) {
        case .photoPermission, .pushPermission:
            return cellEnabledText(for: row)
        case .usageStreak:
            let streak = UserDefaults.standard.integer(forKey: UserDefaultsKeys.dailyStreak)
            if streak == 1 {
                return "settings.row.usage_streak.detail.single".localized(withFormat: streak)
            } else {
                return "settings.row.usage_streak.detail.plural".localized(withFormat: streak)
            }
        case .version:
            return "\(Bundle.displayVersionBuild)\(Constants.buildEnvironmentSuffix)"
        case .name:
            return "settings.row.name.detail".localized
        case .email:
            return "settings.row.email.detail".localized
        case .coins:
            return "\(UserDefaults.standard.integer(forKey: UserDefaultsKeys.gameScore))"
        case .currency:
            return CurrencyViewController.currentCurrency
        default:
            return nil
        }
    }
    
    func cellEnabledText(for row: SettingsRow) -> String? {
        guard let permissionType = row.permissionType else {
            return nil
        }
        
        if PermissionsManager.shared.hasPermission(for: permissionType) {
            return "generic.enabled".localized
            
        } else {
            return "generic.disabled".localized
        }
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
            if let permissionType = row.permissionType, !PermissionsManager.shared.hasPermission(for: permissionType) {
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
            let integer = UserDefaults.standard.integer(forKey: UserDefaultsKeys.productGender)
            let control = productsOptionsControls.genderControl
            control.tintColor = .crazeGreen
            control.selectedSegmentIndex = ProductsOptionsGender(intValue: integer).offsetValue
            control.isExclusiveTouch = true
            control.addTarget(self, action: #selector(genderControlAction(_:)), for: .valueChanged)
            return control
            
        case .productSize:
            let integer = UserDefaults.standard.integer(forKey: UserDefaultsKeys.productSize)
            let control = productsOptionsControls.sizeControl
            control.tintColor = .crazeGreen
            control.selectedSegmentIndex = ProductsOptionsSize(intValue: integer).offsetValue
            control.isExclusiveTouch = true
            control.addTarget(self, action: #selector(sizeControlAction(_:)), for: .valueChanged)
            return control
            
        default:
            return nil
        }
    }
    
    func rectForTableFooterTextView() -> CGRect {
        let maxWidth = view.bounds.width - tableFooterTextView.textContainerInset.left - tableFooterTextView.textContainerInset.right
        let size = CGSize(width: maxWidth, height: .greatestFiniteMagnitude)
        var rect = tableFooterTextView.attributedText.boundingRect(with: size, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        rect.size.width = ceil(rect.width) + tableFooterTextView.textContainerInset.left + tableFooterTextView.textContainerInset.right
        rect.size.height = ceil(rect.height) + tableFooterTextView.textContainerInset.top + tableFooterTextView.textContainerInset.bottom + .padding
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

extension SettingsViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.returnKeyType == .done {
            textField.resignFirstResponder()
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let key = userDefaultsKey(for: textField) {
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

extension SettingsViewController : TutorialVideoViewControllerDelegate {
    func tutorialVideoViewControllerDidTapDone(_ viewController: TutorialVideoViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    func tutorialVideoViewControllerDidEnd(_ viewController: TutorialVideoViewController) {
        dismiss(animated: true, completion: nil)
        
        AnalyticsTrackers.standard.track("Automatically Exited Tutorial Video")
    }
}

// MARK: - Mail

extension SettingsViewController : MFMailComposeViewControllerDelegate {
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
            let alertController = UIAlertController(title: "email.setup.title".localized, message: "email.setup.message".localized, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "generic.later".localized, style: .cancel, handler: nil))
            
            if let mailURL = URL(string: "message://"), UIApplication.shared.canOpenURL(mailURL) {
                alertController.addAction(UIAlertAction(title: "generic.setup".localized, style: .default, handler: { action in
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
        case .pushPermission:
            return PermissionType.push
        default:
            return nil
        }
    }
}
