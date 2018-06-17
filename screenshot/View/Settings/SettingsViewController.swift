//
//  SettingsViewController.swift
//  screenshot
//
//  Created by Corey Werner on 12/7/17.
//  Copyright 2017 crazeapp. All rights reserved.
//

import Foundation
import MessageUI
import PromiseKit
import Whisper

@objc protocol SettingsViewControllerDelegate : NSObjectProtocol {
    func settingsViewControllerDidGrantPermission(_ viewController: SettingsViewController)
}

class SettingsViewController : BaseViewController {
    fileprivate enum Section : Int {
        // Order reflects in the TableView
        case permission
        case product
        case follow
        case about
    }
    
    fileprivate enum Row : Int {
        case photoPermission
        case pushPermission
        case usageStreak
        case contactUs
        case bug
        case version
        case termsOfService
        case privacyPolicy
        case followFacebook
        case followInstagram
        case partners
        case openIn
        case region
    }
    
    weak var delegate: SettingsViewControllerDelegate?
    
    fileprivate let tableView = UITableView(frame: .zero, style: .grouped)
    fileprivate let tableFooterTextView = UITextView()
    
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
        
        self.restorationIdentifier = String(describing: type(of: self))
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive(_:)), name: .UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground(_:)), name: .UIApplicationWillEnterForeground, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadChangeableIndexPaths), name: .InAppPurchaseManagerDidUpdate, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableFooterTextView.backgroundColor = .clear
        tableFooterTextView.isEditable = false
        tableFooterTextView.scrollsToTop = false
        tableFooterTextView.isScrollEnabled = false
        tableFooterTextView.dataDetectorTypes = .link
        tableFooterTextView.textAlignment = .center
        tableFooterTextView.font = .screenshopFont(.hindLight, textStyle: .footnote)
        tableFooterTextView.adjustsFontForContentSizeCategory = true
        tableFooterTextView.text = "settings.contact".localized
        tableFooterTextView.linkTextAttributes = [
            NSAttributedStringKey.underlineStyle.rawValue: NSUnderlineStyle.styleSingle.rawValue,
            NSAttributedStringKey.underlineColor.rawValue: UIColor.gray7
        ]
        tableFooterTextView.frame = rectForTableFooterTextView()
        
        tableView.frame = view.bounds
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundView = nil
        tableView.backgroundColor = .clear
        tableView.tableFooterView = tableFooterTextView
        tableView.keyboardDismissMode = .onDrag
        view.addSubview(tableView)
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        let tapper = UITapGestureRecognizer.init(target: self, action: #selector(didTripleTapTableView(_:)))
        tapper.numberOfTapsRequired = 3
        tapper.numberOfTouchesRequired = 2
        tableView.addGestureRecognizer(tapper)
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
        
        reloadChangeableIndexPaths()
    }
    
    @objc private func applicationDidBecomeActive(_ notification: Notification) {
        if view?.window != nil {
            // Use did become active since the permissions values can change through an alert view
            reloadChangeableIndexPaths()
        }
    }
    
    @objc private func applicationWillEnterForeground(_ notification: Notification) {
        if view?.window != nil {
            reloadChangeableIndexPaths()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        
        tableView.delegate = nil
        tableView.dataSource = nil
    }
    
    // MARK: Data
    
    fileprivate let data: [Section : [Row]] = [
        .permission: [
            .photoPermission,
            .pushPermission
        ],
        .about: [
            .contactUs,
            .bug,
            .usageStreak,
            .termsOfService,
            .privacyPolicy,
//            .region,  // Revert to never use USC.
            .partners,
            .version
        ],
        .follow: [
            .followInstagram,
            .followFacebook
        ],
        .product: [
            .openIn
        ]
    ]
    
    fileprivate func settingsRow(for indexPath: IndexPath) -> Row? {
        guard let section = Section(rawValue: indexPath.section) else {
            return nil
        }
        return data[section]?[indexPath.row]
    }
    
    fileprivate func indexPath(for row: Row, in section: Section) -> IndexPath? {
        guard let rowValue = data[section]?.index(of: row) else {
            return nil
        }
        return IndexPath(row: rowValue, section: section.rawValue)
    }
}

// MARK: - Table View

extension SettingsViewController : UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let settingsSection = Section(rawValue: section) else {
            return 0
        }
        return data[settingsSection]?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let settingsSection = Section(rawValue: section) else {
            return nil
        }
        return sectionText(for: settingsSection)
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let tableViewHeaderFooterView = view as? UITableViewHeaderFooterView else {
            return
        }
        
        tableViewHeaderFooterView.textLabel?.textColor = .gray3
        tableViewHeaderFooterView.textLabel?.font = .screenshopFont(.hind, textStyle: .subheadline)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let row = settingsRow(for: indexPath) else {
            return UITableViewCell()
        }
        
        let cell = self.tableView(tableView, defaultCellForRowAt: indexPath, withRow: row)
        cell.accessoryType = cellAccessoryType(for: row)
        cell.accessoryView = cellAccessoryView(for: row)
        return cell
    }
    
    private func tableView(_ tableView: UITableView, defaultCellForRowAt indexPath: IndexPath, withRow row: Row) -> UITableViewCell {
        let reusableCell = tableView.dequeueReusableCell(withIdentifier: "cell")
        let cell = reusableCell ?? UITableViewCell(style: .value1, reuseIdentifier: "cell")
        
        cell.imageView?.image = cellImage(for: row)
        cell.textLabel?.text = cellText(for: row)
        cell.textLabel?.font = .screenshopFont(.hindLight, textStyle: .body)
        cell.textLabel?.textColor = .black
        cell.detailTextLabel?.font = .screenshopFont(.hindSemibold, textStyle: .body)
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
        case .version, .usageStreak:
            return false
            
        case .pushPermission, .photoPermission:
            if let permissionType = row.permissionType, !PermissionsManager.shared.hasPermission(for: permissionType) {
                return true
            }
            else {
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
            presentMailComposerForBug()
            
        case .contactUs:
            presentMailComposerForContactUs()
            
        case .termsOfService:
            if let viewController = LegalViewControllerFactory.termsOfServiceViewController() {
                present(viewController, animated: true, completion: nil)
            }
            
        case .privacyPolicy:
            if let viewController = LegalViewControllerFactory.privacyPolicyViewController() {
                present(viewController, animated: true, completion: nil)
            }
            
        case .pushPermission, .photoPermission:
            if let permissionType = row.permissionType {
                PermissionsManager.shared.requestPermission(for: permissionType, openSettingsIfNeeded: true, response: { granted in
                    if granted {
                        tableView.reloadRows(at: [indexPath], with: .fade)
                        self.delegate?.settingsViewControllerDidGrantPermission(self)
                    }
                })
            }
            
        case .openIn:
            let alert = UIAlertController.init(title: nil, message: nil, preferredStyle: .actionSheet)
            
            let options:[OpenWebPage] = [.embededSafari, .safari, .chrome]
            options.forEach({ (setting) in
                alert.addAction(UIAlertAction.init(title:setting.localizedDisplayString(), style: .default, handler: { (a) in
                    setting.saveToUserDefaults()
                    tableView.reloadRows(at: [indexPath], with: .none)
                }))
            })
            
            alert.addAction(UIAlertAction(title: "generic.cancel".localized, style: .cancel, handler: nil))
            
            present(alert, animated: true, completion: nil)
            
        case .followInstagram:
            if let url = URL(string: "https://www.instagram.com/screenshopit/") {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            
        case .followFacebook:
            if let url = URL(string: "https://www.facebook.com/screenshopit/") {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            
        case .partners:
            let viewController = PartnersViewController()
            viewController.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(viewController, animated: true)
        case .region:
            let alert = UIAlertController.init(title: nil, message: nil, preferredStyle: .actionSheet)
            
            alert.addAction(UIAlertAction(title: "settings.region.us".localized, style: .default, handler: { (alertAction) in
                UserDefaults.standard.set(true, forKey: UserDefaultsKeys.isUSC)
                UserDefaults.standard.synchronize()
                NotificationCenter.default.post(name: .isUSCUpdated, object: nil)
                tableView.reloadRows(at: [indexPath], with: .none)
            }))
            alert.addAction(UIAlertAction(title: "settings.region.other".localized, style: .default, handler: { (alertAction) in
                UserDefaults.standard.set(false, forKey: UserDefaultsKeys.isUSC)
                UserDefaults.standard.synchronize()
                NotificationCenter.default.post(name: .isUSCUpdated, object: nil)
                tableView.reloadRows(at: [indexPath], with: .none)
            }))

            alert.addAction(UIAlertAction(title: "generic.cancel".localized, style: .cancel, handler: nil))
            
            present(alert, animated: true, completion: nil)
            
        case .usageStreak:
            break;
        case .version:
            break;
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

fileprivate extension SettingsViewController {
    func sectionText(for section: Section) -> String {
        switch section {
        case .permission:
            return "settings.section.permission".localized
        case .about:
            return "settings.section.about".localized
        case .follow:
            return "settings.section.follow".localized
        case .product:
            return "settings.section.product".localized
        }
    }
    
    func cellImage(for row: Row) -> UIImage? {
        switch (row) {
        case .followInstagram:
            return UIImage(named: "SettingsInstagram")
        case .followFacebook:
            return UIImage(named: "SettingsFacebook")
        default:
            return nil
        }
    }
    
    func cellText(for row: Row) -> String {
        switch (row) {
        case .usageStreak:
            return "settings.row.usage_streak.title".localized
        case .bug:
            return "settings.row.bug.title".localized
        case .contactUs:
            return "settings.row.contact.title".localized
        case .pushPermission:
            return "settings.row.push_permission.title".localized
        case .photoPermission:
            return "settings.row.photo_permission.title".localized
        case .version:
            return "settings.row.version.title".localized
        case .termsOfService:
            return "legal.terms_of_service".localized
        case .privacyPolicy:
            return "legal.privacy_policy".localized
        case .openIn:
            return "settings.row.open_in.title".localized
        case .followInstagram:
            return "settings.row.instagram.title".localized
        case .followFacebook:
            return "settings.row.facebook.title".localized
        case .partners:
            return "settings.row.partners.title".localized
        case .region:
            return "settings.row.region.title".localized
        }
    }
    
    func cellDetailedText(for row: Row) -> String? {
        switch (row) {
        case .photoPermission, .pushPermission:
            return cellEnabledText(for: row)
        case .openIn:
            return OpenWebPage.fromSystemInfo().localizedDisplayString()
        case .usageStreak:
            let streak = UserDefaults.standard.integer(forKey: UserDefaultsKeys.dailyStreak)
            if streak == 1 {
                return "settings.row.usage_streak.detail.single".localized(withFormat: streak)
            }
            else {
                return "settings.row.usage_streak.detail.plural".localized(withFormat: streak)
            }
        case .version:
            return "\(Bundle.displayVersionBuild)\(Constants.buildEnvironmentSuffix)"
        case .region:
            if UserDefaults.standard.object(forKey: UserDefaultsKeys.isUSC) == nil {
                return "settings.region.unknown".localized
            } else {
                if UIApplication.isUSC {
                    return "settings.region.us".localized
                } else {
                    return "settings.region.other".localized
                }
            }
            
        default:
            return nil
        }
    }
    
    func cellEnabledText(for row: Row) -> String? {
        guard let permissionType = row.permissionType else {
            return nil
        }
        
        if PermissionsManager.shared.hasPermission(for: permissionType) {
            return "generic.enabled".localized
        }
        else {
            return "generic.disabled".localized
        }
    }
    
    func cellAccessoryType(for row: Row) -> UITableViewCellAccessoryType {
        switch row {
        case .partners:
            return .disclosureIndicator
        default:
            return .none
        }
    }
    
    func cellAccessoryView(for row: Row) -> UIView? {
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
    
    @objc func reloadChangeableIndexPaths() {
        func append(section: Section, row: Row, to indexPaths: inout [IndexPath]) {
            if let indexPath = indexPath(for: row, in: section) {
                indexPaths.append(indexPath)
            }
        }
        
        func sectionIndexPaths(_ section: Section) -> [IndexPath] {
            var indexPaths: [IndexPath] = []
            
            data[section]?.forEach { row in
                append(section: section, row: row, to: &indexPaths)
            }
            
            return indexPaths
        }
        
        var indexPaths = sectionIndexPaths(.permission)
        append(section: .about, row: .usageStreak, to: &indexPaths)
        
        tableView.reloadRows(at: indexPaths, with: .none)
    }
}

// MARK: - Debug

extension SettingsViewController {
    @objc func didTripleTapTableView(_ tapper:UITapGestureRecognizer){
        if tapper.state == .recognized {
            if let index = self.indexPath(for: .version, in: .about), let cell = self.tableView.cellForRow(at: index) {
                let point = tapper.location(in: cell)
                if cell.bounds.contains(point) {
                    let enabled = UserDefaults.standard.bool(forKey: UserDefaultsKeys.showsDebugAnalyticsUI)
                    if enabled {
                        UserDefaults.standard.set(false, forKey: UserDefaultsKeys.showsDebugAnalyticsUI)
                    }else{
                        UserDefaults.standard.set(true, forKey: UserDefaultsKeys.showsDebugAnalyticsUI)
                    }
                    if let viewController = AppDelegate.shared.window?.rootViewController {
                        let announcement = Announcement(title: "Analytics debug UI", subtitle: (enabled ? "Disabled":"Enabled"), image: nil, duration:10.0, action:{
                        })
                        Whisper.show(shout: announcement, to: viewController, completion: {
                        })
                    }
                }
                
            }
        }
    }
}

// MARK: - Mail

extension SettingsViewController : MFMailComposeViewControllerDelegate {
    func presentMail(recipient:String, gmailMessage:String, subject:String, message:String ){
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setSubject(subject)
            mail.setMessageBody(message, isHTML: false)
            mail.setToRecipients([recipient])
            present(mail, animated: true, completion: nil)
            
        } else if let url = URL.googleMailUrl(to: recipient, body: gmailMessage, subject: subject), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            
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
    
    func presentMailComposerForContactUs(){
        let recipient = "Info+\(Bundle.displayVersionBuild)@screenshopit.com"
        self.presentMail(recipient: recipient, gmailMessage: "", subject: "To Screenshop:", message: "")
        
    }
    
    func presentMailComposerForBug() {
        let message = [
            "\n\n\n",
            "-----------------",
            "Don't edit below.\n",
            "version: \(Bundle.displayVersionBuild)"
        ].joined(separator: "\n")
        let gmailMessage = "(Don't edit) version: \(Bundle.displayVersionBuild)"  //gmail has a bug that it won't respect new line charactors in a URL
        let subject = "Bug Report"
        let recipient = "support@screenshopit.com"
        
        self.presentMail(recipient: recipient, gmailMessage: gmailMessage, subject: subject, message: message)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - Permissions

fileprivate extension SettingsViewController.Row {
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
