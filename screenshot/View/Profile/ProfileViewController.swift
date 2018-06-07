//
//  ProfileViewController.swift
//  screenshot
//
//  Created by Corey Werner on 6/6/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class ProfileViewController: UITableViewController {
    enum Section: Int {
        case invite
        case account
        case activity
        case logout
    }
    
    enum Row: Int {
        case currency
        case email
        case purchases
        case tutorial
        case logout
    }
    
    private var data: [Section: [Row]] = [
        .invite: [],
        .account: [
            .currency,
            .email
        ],
        .activity: [
            .purchases,
            .tutorial
        ]
    ]
    
    lazy var textFieldRows: [IndexPath?] = {
        return [
            self.indexPath(for: .email, in: .account)
        ]
    }()
    
    // MARK: Life Cycle
    
    override var title: String? {
        set {}
        get {
            return "Profile" // TODO: localize
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewStyle) {
        super.init(style: style)
        
        restorationIdentifier = String(describing: type(of: self))
        
        addNavigationItemLogo()
    }
    
    convenience init() {
        self.init(style: .grouped)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.keyboardDismissMode = .onDrag
        tableView.backgroundColor = .background
    }
    
    // MARK: Login
    
    private func syncLoggedIn() {
        let isLoggedIn = true
        
        if isLoggedIn {
            data[.logout] = [.logout]
        }
        else {
            data.removeValue(forKey: .logout)
        }
    }
}

// MARK: - Table View

extension ProfileViewController {
    private func row(for indexPath: IndexPath) -> Row? {
        guard let section = Section(rawValue: indexPath.section) else {
            return nil
        }
        return data[section]?[indexPath.row]
    }
    
    private func indexPath(for row: Row, in section: Section) -> IndexPath? {
        guard let rowValue = data[section]?.index(of: row) else {
            return nil
        }
        return IndexPath(row: rowValue, section: section.rawValue)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return data.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let settingsSection = Section(rawValue: section) else {
            return 0
        }
        return data[settingsSection]?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let row = row(for: indexPath) else {
            return UITableViewCell()
        }
        
        var cell: UITableViewCell
        
        if textFieldRows.contains(indexPath) {
            cell = self.tableView(tableView, textFieldCellForRowAt: indexPath, withRow: row)
        }
        else {
            cell = self.tableView(tableView, defaultCellForRowAt: indexPath, withRow: row)
        }
        
        cell.accessoryType = cellAccessoryType(for: row)
        return cell
    }
    
    private func tableView(_ tableView: UITableView, textFieldCellForRowAt indexPath: IndexPath, withRow row: Row) -> UITableViewCell {
        let reusableCell = tableView.dequeueReusableCell(withIdentifier: "input") as? TextFieldTableViewCell
        let cell = reusableCell ?? TextFieldTableViewCell(style: .default, reuseIdentifier: "input")
        
        if reusableCell == nil {
//            cell.textField.delegate = self
            
            if row == .email {
                cell.textField.autocorrectionType = .no
                cell.textField.autocapitalizationType = .none
                cell.textField.spellCheckingType = .no
                cell.textField.keyboardType = .emailAddress
            }
        }
        
        cell.textField.text = cellText(for: row)
        cell.textField.placeholder = cellDetailedText(for: row)
        return cell
    }
    
    private func tableView(_ tableView: UITableView, defaultCellForRowAt indexPath: IndexPath, withRow row: Row) -> UITableViewCell {
        let reusableCell = tableView.dequeueReusableCell(withIdentifier: "cell")
        let cell = reusableCell ?? UITableViewCell(style: .value1, reuseIdentifier: "cell")
        
        cell.textLabel?.text = cellText(for: row)
        cell.textLabel?.font = .screenshopFont(.hindLight, textStyle: .body)
        cell.textLabel?.textColor = .black
        
        cell.detailTextLabel?.font = .screenshopFont(.hindSemibold, textStyle: .body)
        cell.detailTextLabel?.text = nil
        cell.detailTextLabel?.attributedText = nil
        
        if let text = cellDetailedText(for: row) {
            cell.detailTextLabel?.text = text
        }
        else if let attributedText = cellDetailedAttributedText(for: row) {
            cell.detailTextLabel?.attributedText = attributedText
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let row = row(for: indexPath) else {
            return
        }
        
        switch (row) {
        case .email:
            if let cell = tableView.cellForRow(at: indexPath) {
                cell.becomeFirstResponder()
            }
            
        case .currency:
            let viewController = CurrencyViewController()
//            viewController.lifeCycleDelegate = self
            viewController.title = cellText(for: row)
            viewController.hidesBottomBarWhenPushed = true
            viewController.selectedCurrencyCode = UserDefaults.standard.string(forKey: UserDefaultsKeys.productCurrency)
            navigationController?.pushViewController(viewController, animated: true)
            
        case .tutorial:
            let viewController = TutorialVideoViewController()
            viewController.showsReplayButtonUponFinishing = false
//            viewController.view.backgroundColor = .black
            viewController.delegate = self
            viewController.modalTransitionStyle = .crossDissolve
            present(viewController, animated: true)
            
        case .purchases:
            break
            
        case .logout:
            break
        }
    }
    
    private func cellText(for row: Row) -> String? {
        switch (row) {
        case .currency:
            return "Currency"
        case .email:
            return UserDefaults.standard.string(forKey: UserDefaultsKeys.email)
        case .logout:
            return "Logout"
        case .purchases:
            return "Recent Purchases"
        case .tutorial:
            return "Watch Tutorial"
        }
    }
    
    private func cellDetailedText(for row: Row) -> String? {
        switch (row) {
        case .currency:
            return CurrencyViewController.currentCurrency
        case .email:
            return "Email"
        default:
            return nil
        }
    }
    
    private func cellDetailedAttributedText(for row: Row) -> NSAttributedString? {
        switch (row) {
        case .purchases:
            let textAttachment = NSTextAttachment()
            textAttachment.image = UIImage(named: "SettingsCreditCard")
            return NSAttributedString(attachment: textAttachment)
            
        case .tutorial:
            let textAttachment = NSTextAttachment()
            textAttachment.image = UIImage(named: "SettingsCreditCard")
            return NSAttributedString(attachment: textAttachment)
            
        default:
            return nil
        }
    }
    
    private func cellAccessoryType(for row: Row) -> UITableViewCellAccessoryType {
        switch row {
        case .currency, .purchases, .tutorial:
            return .disclosureIndicator
        default:
            return .none
        }
    }
}

// MARK: - Tutorial

extension ProfileViewController: VideoDisplayingViewControllerDelegate {
    func videoDisplayingViewControllerDidTapDone(_ viewController: UIViewController) {
        dismiss(animated: true)
    }
    
    func videoDisplayingViewControllerDidEnd(_ viewController: UIViewController) {
        dismiss(animated: true)
        Analytics.trackAutomaticallyExitedTutorialVideo()
    }
}
