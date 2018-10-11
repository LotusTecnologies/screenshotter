//
//  SettingsViewController.swift
//  screenshot
//
//  Created by Corey Werner on 12/7/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

import Foundation
import PromiseKit
import Whisper

class SettingsViewController : BaseViewController {
    fileprivate enum Section : Int {
        // Order reflects in the TableView
        case follow
        case about
    }
    
    fileprivate enum Row : Int {
        case usageStreak
        case contactUs
        case bug
        case version
        case termsOfService
        case privacyPolicy
        case followFacebook
        case followInstagram
        case partners
    }
    
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
    
    deinit {
        if isViewLoaded {
            tableView.delegate = nil
            tableView.dataSource = nil
        }
    }
    
    // MARK: Data
    
    fileprivate let data: [Section : [Row]] = [
        .about: [
            .contactUs,
            .bug,
            .usageStreak,
            .termsOfService,
            .privacyPolicy,
            .partners,
            .version
        ],
        .follow: [
            .followInstagram,
            .followFacebook
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
    
    // MARK: Debug
    
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
        tableViewHeaderFooterView.textLabel?.font = .screenshopFont(.quicksandMedium, textStyle: .subheadline)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let row = settingsRow(for: indexPath) else {
            return UITableViewCell()
        }
        
        let cell = self.tableView(tableView, defaultCellForRowAt: indexPath, withRow: row)
        cell.accessoryType = cellAccessoryType(for: row)
        return cell
    }
    
    private func tableView(_ tableView: UITableView, defaultCellForRowAt indexPath: IndexPath, withRow row: Row) -> UITableViewCell {
        let reusableCell = tableView.dequeueReusableCell(withIdentifier: "cell")
        let cell = reusableCell ?? UITableViewCell(style: .value1, reuseIdentifier: "cell")
        
        cell.imageView?.image = cellImage(for: row)
        cell.textLabel?.text = cellText(for: row)
        cell.textLabel?.font = .preferredFont(forTextStyle: .body)
        cell.textLabel?.textColor = .gray4
        cell.detailTextLabel?.font = .preferredFont(forTextStyle: .body, symbolicTraits: .traitBold)
        cell.detailTextLabel?.textColor = .gray5
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
            
        
        case .usageStreak, .version:
            break;
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

fileprivate extension SettingsViewController {
    func sectionText(for section: Section) -> String {
        switch section {
        case .about:
            return "settings.section.about".localized
        case .follow:
            return "settings.section.follow".localized
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
        case .version:
            return "settings.row.version.title".localized
        case .termsOfService:
            return "legal.terms_of_service".localized
        case .privacyPolicy:
            return "legal.privacy_policy".localized
        case .followInstagram:
            return "settings.row.instagram.title".localized
        case .followFacebook:
            return "settings.row.facebook.title".localized
        case .partners:
            return "settings.row.partners.title".localized
        }
    }
    
    func cellDetailedText(for row: Row) -> String? {
        switch (row) {
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
            
        default:
            return nil
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
        
        var indexPaths: [IndexPath] = []
        append(section: .about, row: .usageStreak, to: &indexPaths)
        
        tableView.reloadRows(at: indexPaths, with: .none)
    }
}

// MARK: - Mail

extension SettingsViewController {
    func presentMailComposerForContactUs(){
        let recipient = "Info+\(Bundle.displayVersionBuild)@screenshopit.com"
        self.presentMail(recipient: recipient, gmailMessage: "", subject: "To Screenshop:", message: "", isHTML: false, delegate: nil, noEmailErrorMessage: "email.setup.message.contactUs".localized, attachLogs:false)
        
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
        let recipient = "support+\(Bundle.displayVersionBuild)@screenshopit.com"
        
        
        
        
        self.presentMail(recipient: recipient, gmailMessage: gmailMessage, subject: subject, message: message, isHTML: false, delegate: nil, noEmailErrorMessage: "email.setup.message.bug".localized, attachLogs:true)
    }
    
}
