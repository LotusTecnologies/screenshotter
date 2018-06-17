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
        case account
        case invite
        case options
        case logout
    }
    
    enum Row: Int {
        case currency
        case logout
        case openIn
    }
    
    private var data: [Section: [Row]] = [
        .account: [],
        .invite: [],
        .options: [
            .currency
        ]
    ]
    
    private let profileAccountView = ProfileAccountView()
    
    private let inviteView: UIView = {
        let view = UIView()
        view.layoutMargins = UIEdgeInsets(top: 0, left: .padding, bottom: 0, right: .padding)
        
        let button = MainButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setBackgroundImage(UIImage(named: "BrandGradientControl"), for: .normal)
        button.setBackgroundImage(UIImage(named: "BrandGradientHighlightedControl"), for: .highlighted)
        button.setTitle("profile.tell_friend".localized, for: .normal)
        button.addTarget(self, action: #selector(inviteAction), for: .touchUpInside)
        button.clipsToBounds = true
        view.addSubview(button)
        button.sizeToFit()
        button.setContentHuggingPriority(.required, for: .vertical)
        button.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor).isActive = true
        button.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor).isActive = true
        button.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor).isActive = true
        button.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor).isActive = true
        
        var frame = view.frame
        frame.size.height = button.bounds.height
        view.frame = frame
        
        return view
    }()
    
    // MARK: Life Cycle
    
    override var title: String? {
        set {}
        get {
            return "profile.title".localized
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
        
        profileAccountView.delegate = self
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        UIView.performWithoutAnimation {
            self.animateProfileAccountView(isExpanded: false)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if #available(iOS 11.0, *) {
            profileAccountView.maxHeight = tableView.bounds.size.height - tableView.safeAreaInsets.top - tableView.safeAreaInsets.bottom
        }
        else {
            profileAccountView.maxHeight = tableView.bounds.size.height - tableView.contentInset.top - tableView.contentInset.bottom
        }
    }
    
    deinit {
        profileAccountView.delegate = nil
    }
    
    // MARK: Login
    
    private func syncLoggedIn() {
        let isLoggedIn = false // TODO:
        
        if isLoggedIn {
            data[.logout] = [.logout]
        }
        else {
            data.removeValue(forKey: .logout)
        }
    }
    
    // MARK: Invite
    
    @objc private func inviteAction() {
        guard let url = URL(string: Constants.itunesConnect) else {
            return
        }
        
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        activityViewController.excludedActivityTypes = [
            .addToReadingList,
            .airDrop,
            .init("com.apple.reminders.RemindersEditorExtension"),
            .init("com.apple.mobilenotes.SharingExtension")
        ]
        present(activityViewController, animated: true)
    }
}

extension ProfileViewController: ViewControllerLifeCycle {
    func viewController(_ viewController: UIViewController, willDisappear animated: Bool) {
        if viewController.isKind(of: CurrencyViewController.self),
            let indexPath = indexPath(for: .currency, in: .options)
        {
            tableView.reloadRows(at: [indexPath], with: .none)
        }
    }
}

extension ProfileViewController: ProfileAccountViewDelegate {
    func profileAccountViewAuthorize(_ view: ProfileAccountView) {
        // TODO:
    }
    
    func profileAccountViewWantsToContract(_ view: ProfileAccountView) {
        animateProfileAccountView(isExpanded: false)
    }
    
    func profileAccountViewWantsToExpand(_ view: ProfileAccountView) {
        animateProfileAccountView(isExpanded: true)
    }
    
    func profileAccountViewPresentImagePickerInViewController(_ view: ProfileAccountView) -> UIViewController {
        return self
    }
    
    private func animateProfileAccountView(isExpanded: Bool) {
        tableView.endEditing(true)
        
        UIView.animate(withDuration: .defaultAnimationDuration) {
            self.profileAccountView.isExpanded = isExpanded
            self.profileAccountView.layoutIfNeeded()
        }
        
        tableView.contentOffset = {
            if #available(iOS 11.0, *) {
                return CGPoint(x: 0, y: -view.safeAreaInsets.top)
            }
            else {
                return CGPoint(x: 0, y: -topLayoutGuide.length)
            }
        }()
        tableView.isScrollEnabled = !profileAccountView.isExpanded
        tableView.beginUpdates()
        tableView.endUpdates()
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
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if Section.account.rawValue == section {
            if profileAccountView.isExpanded {
                return profileAccountView.maxHeight
            }
            else {
                return profileAccountView.minHeight
            }
        }
        else if Section.invite.rawValue == section {
            return inviteView.bounds.height
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == Section.account.rawValue {
//            profileAccountView.isLoggedIn = true
            return profileAccountView
        }
        else if section == Section.invite.rawValue {
            return inviteView
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let row = row(for: indexPath) else {
            return UITableViewCell()
        }
        
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
        
        cell.accessoryType = cellAccessoryType(for: row)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let row = row(for: indexPath) else {
            return
        }
        
        switch (row) {
        case .currency:
            let viewController = CurrencyViewController()
            viewController.lifeCycleDelegate = self
            viewController.title = cellText(for: row)
            viewController.hidesBottomBarWhenPushed = true
            viewController.selectedCurrencyCode = UserDefaults.standard.string(forKey: UserDefaultsKeys.productCurrency)
            navigationController?.pushViewController(viewController, animated: true)
            
        case .openIn:
            let alert = UIAlertController.init(title: nil, message: nil, preferredStyle: .actionSheet)
            let browsers: [OpenWebPage] = [.safari, .chrome]
            browsers.forEach({ browser in
                alert.addAction(UIAlertAction.init(title: browser.localizedDisplayString(), style: .default, handler: { alertAction in
                    browser.saveToUserDefaults()
                    tableView.reloadRows(at: [indexPath], with: .none)
                }))
            })
            alert.addAction(UIAlertAction(title: "generic.cancel".localized, style: .cancel, handler: nil))
            present(alert, animated: true)
            
        case .logout:
            break
        }
    }
    
    private func cellText(for row: Row) -> String? {
        switch (row) {
        case .currency:
            return "profile.row.currency.title".localized
        case .logout:
            return "profile.row.logout.title".localized
        case .openIn:
            return "profile.row.open_in.title".localized
        }
    }
    
    private func cellDetailedText(for row: Row) -> String? {
        switch (row) {
        case .currency:
            return CurrencyViewController.currentCurrency
        case .openIn:
            return OpenWebPage.fromSystemInfo().localizedDisplayString()
        default:
            return nil
        }
    }
    
    private func cellDetailedAttributedText(for row: Row) -> NSAttributedString? {
        // Template code in case product creates another cell with an image and an arrow
//        switch (row) {
//        case .:
//            let textAttachment = NSTextAttachment()
//            textAttachment.image = UIImage(named: "")
//            return NSAttributedString(attachment: textAttachment)
//
//        default:
            return nil
//        }
    }
    
    private func cellAccessoryType(for row: Row) -> UITableViewCellAccessoryType {
        switch row {
        case .currency:
            return .disclosureIndicator
        default:
            return .none
        }
    }
}
