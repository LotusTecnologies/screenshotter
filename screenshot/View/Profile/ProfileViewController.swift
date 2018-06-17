//
//  ProfileViewController.swift
//  screenshot
//
//  Created by Corey Werner on 6/6/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

@objc protocol ProfileViewControllerDelegate: NSObjectProtocol {
    func profileViewControllerDidGrantPermission(_ viewController: ProfileViewController)
}

class ProfileViewController: UITableViewController {
    enum Section: Int {
        case account
        case invite
        case options
        case permissions
        case logout
    }
    
    enum Row: Int {
        case optionCurrency
        case optionOpenIn
        
        case permissionPhoto
        case permissionPush
        
        case logout
        
        var permissionType: PermissionType? {
            switch self {
            case .permissionPhoto:
                return PermissionType.photo
            case .permissionPush:
                return PermissionType.push
            default:
                return nil
            }
        }
    }
    
    private var data: [Section: [Row]] = [
        .account: [],
        .invite: [],
        .options: [
            .optionCurrency,
            .optionOpenIn
        ],
        .permissions: [
            .permissionPhoto,
            .permissionPush
        ]
    ]
    
    weak var delegate: ProfileViewControllerDelegate?
    
    private let profileAccountView = ProfileAccountView()
    
    private let inviteView: UIView = {
        let view = UIView()
        view.layoutMargins = UIEdgeInsets(top: 0, left: .padding, bottom: 0, right: .padding)
        
        let button = MainButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setBackgroundImage(UIImage(named: "BrandGradientControl"), for: .normal)
        button.setBackgroundImage(UIImage(named: "BrandGradientHighlightedControl"), for: .highlighted)
        button.setImage(UIImage(named: "ProfileFriends"), for: .normal)
        button.setTitle("profile.tell_friend".localized, for: .normal)
        button.addTarget(self, action: #selector(inviteAction), for: .touchUpInside)
        button.clipsToBounds = true
        button.adjustInsetsForImage(withPadding: 6)
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive(_:)), name: .UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground(_:)), name: .UIApplicationWillEnterForeground, object: nil)
        
        addNavigationItemLogo()
    }
    
    convenience init() {
        self.init(style: .grouped)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.keyboardDismissMode = .onDrag
        tableView.backgroundColor = .background
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "logout")
        
        profileAccountView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        reloadChangeableIndexPaths()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        UIView.performWithoutAnimation {
            self.animateProfileAccountView(isExpanded: false)
        }
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
        NotificationCenter.default.removeObserver(self)
        profileAccountView.delegate = nil
    }
    
    // MARK: Login
    
    private func syncLoggedIn() {
        let isLoggedIn = true // TODO:
        
        if isLoggedIn {
            data[.logout] = [.logout]
        }
        else {
            data.removeValue(forKey: .logout)
        }
        
        tableView.reloadData()
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
            let indexPath = indexPath(for: .optionCurrency, in: .options)
        {
            tableView.reloadRows(at: [indexPath], with: .none)
        }
    }
}

extension ProfileViewController: ProfileAccountViewDelegate {
    func profileAccountViewAuthorize(_ view: ProfileAccountView) {
        // TODO: do login
        view.isLoggedIn = true
        
        syncLoggedIn()
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
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let profileSection = Section(rawValue: section) else {
            return nil
        }
        
        return sectionText(for: profileSection)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let row = row(for: indexPath) else {
            return UITableViewCell()
        }
        
        let cell: UITableViewCell
        
        if indexPath.section == Section.logout.rawValue {
            cell = tableView.dequeueReusableCell(withIdentifier: "logout", for: indexPath)
            
            cell.textLabel?.text = cellText(for: row)
            cell.textLabel?.font = .screenshopFont(.hindLight, textStyle: .body)
            cell.textLabel?.textColor = .crazeRed
            cell.textLabel?.textAlignment = .center
        }
        else {
            let reusableCell = tableView.dequeueReusableCell(withIdentifier: "cell")
            cell = reusableCell ?? UITableViewCell(style: .value1, reuseIdentifier: "cell")
            
            cell.textLabel?.text = cellText(for: row)
            cell.textLabel?.font = .screenshopFont(.hindLight, textStyle: .body)
            cell.textLabel?.textColor = .gray4
            
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
            cell.accessoryView = cellAccessoryView(for: row)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        guard let row = row(for: indexPath) else {
            return true
        }
        
        switch (row) {
        case .permissionPush, .permissionPhoto:
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let row = row(for: indexPath) else {
            return
        }
        
        switch (row) {
        case .optionCurrency:
            let viewController = CurrencyViewController()
            viewController.lifeCycleDelegate = self
            viewController.title = cellText(for: row)
            viewController.hidesBottomBarWhenPushed = true
            viewController.selectedCurrencyCode = UserDefaults.standard.string(forKey: UserDefaultsKeys.productCurrency)
            navigationController?.pushViewController(viewController, animated: true)
            
        case .optionOpenIn:
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
            
        case .permissionPhoto, .permissionPush:
            if let permissionType = row.permissionType {
                PermissionsManager.shared.requestPermission(for: permissionType, openSettingsIfNeeded: true, response: { granted in
                    if granted {
                        tableView.reloadRows(at: [indexPath], with: .fade)
                        self.delegate?.profileViewControllerDidGrantPermission(self)
                    }
                })
            }
            
        case .logout:
            // TODO:
            syncLoggedIn()
        }
    }
    
    private func sectionText(for section: Section) -> String? {
        switch section {
        case .permissions:
            return "settings.section.permission".localized
        default:
            return nil
        }
    }
    
    private func cellText(for row: Row) -> String? {
        switch (row) {
        case .optionCurrency:
            return "profile.row.currency.title".localized
        case .optionOpenIn:
            return "profile.row.open_in.title".localized
        case .permissionPush:
            return "settings.row.push_permission.title".localized
        case .permissionPhoto:
            return "settings.row.photo_permission.title".localized
        case .logout:
            return "profile.row.logout.title".localized
        }
    }
    
    private func cellDetailedText(for row: Row) -> String? {
        switch (row) {
        case .optionCurrency:
            return CurrencyViewController.currentCurrency
        case .optionOpenIn:
            return OpenWebPage.fromSystemInfo().localizedDisplayString()
        case .permissionPhoto, .permissionPush:
            return cellEnabledText(for: row)
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
    
    private func cellEnabledText(for row: Row) -> String? {
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
    
    private func cellAccessoryType(for row: Row) -> UITableViewCellAccessoryType {
        switch row {
        case .optionCurrency:
            return .disclosureIndicator
        default:
            return .none
        }
    }
    
    private func cellAccessoryView(for row: Row) -> UIView? {
        switch (row) {
        case .permissionPhoto, .permissionPush:
            if let permissionType = row.permissionType, !PermissionsManager.shared.hasPermission(for: permissionType) {
                let size: CGFloat = 18
                let label = UILabel(frame: CGRect(x: 0, y: 0, width: size, height: size))
                label.backgroundColor = .crazeRed
                label.text = "!"
                label.textAlignment = .center
                label.font = UIFont(name: "Optima-ExtraBlack", size: 14)
                label.textColor = .white
                label.layer.cornerRadius = size / 2
                label.layer.masksToBounds = true
                return label
            }
            else {
                return nil
            }
        default:
            return nil
        }
    }
    
    @objc private func reloadChangeableIndexPaths() {
        func append(section: Section, row: Row, to indexPaths: inout [IndexPath]) {
            if let indexPath = indexPath(for: row, in: section) {
                indexPaths.append(indexPath)
            }
        }
        
        var indexPaths: [IndexPath] = []
        append(section: .permissions, row: .permissionPhoto, to: &indexPaths)
        append(section: .permissions, row: .permissionPush, to: &indexPaths)
        
        tableView.reloadRows(at: indexPaths, with: .none)
    }
}
