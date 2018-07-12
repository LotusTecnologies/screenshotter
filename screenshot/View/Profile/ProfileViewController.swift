//
//  ProfileViewController.swift
//  screenshot
//
//  Created by Corey Werner on 6/6/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit
import Firebase
import FBSDKLoginKit
import FirebaseStorage

@objc protocol ProfileViewControllerDelegate: NSObjectProtocol {
    func profileViewControllerDidGrantPermission(_ viewController: ProfileViewController)
}

class ProfileViewController: BaseTableViewController {
    enum Section: Int {
        case account
        case invite
        case facebook
        case options
        case permissions
        case logout
    }
    
    enum Row: Int {
        case optionCurrency
        case optionOpenIn
        
        case permissionPhoto
        case permissionPush
        case permissionGDRP
        
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
    
    private let dataSource = DataSource<Section, Row>(data: [
        .account: [],
        .invite: [],
        .options: [
            .optionCurrency,
            .optionOpenIn
        ],
        .permissions: [
            .permissionPhoto,
            .permissionPush,
            .permissionGDRP
        ]
    ])
    
    weak var delegate: ProfileViewControllerDelegate?
    
    private let profileAccountView = ProfileAccountView()
    
    private lazy var inviteView: UIView = {
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
        button.isExclusiveTouch = true
        button.adjustInsetsForImage()
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
    
    private lazy var facebookView: UIView = {
        let view = UIView()
        view.layoutMargins = UIEdgeInsets(top: 0, left: .padding, bottom: 0, right: .padding)
        
        let button = FacebookButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(facebookLoginAction(_:)), for: .touchUpInside)
        button.actionCopy = .connect
        button.hasArrow = false
        button.clipsToBounds = true
        button.isExclusiveTouch = true
        button.layer.cornerRadius = MainButton.cornerRadius
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
        reloadChangeableIndexPaths()
        syncLoggedIn()
        super.viewWillAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if presentedViewController == nil {
            UIView.performWithoutAnimation {
                self.animateProfileAccountView(isExpanded: false)
            }
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
        Analytics.trackDevLog(file: #file, line: #line, message: "syncLoggedIn")
        let isLoggedIn = (UserAccountManager.shared.user?.isAnonymous == false)
        profileAccountView.isLoggedIn = isLoggedIn
        
        if isLoggedIn {
            profileAccountView.name = UserDefaults.standard.string(forKey: UserDefaultsKeys.name)
            profileAccountView.email = UserDefaults.standard.string(forKey: UserDefaultsKeys.email)
            
            if let string = UserDefaults.standard.string(forKey: UserDefaultsKeys.avatarURL), let url = URL.init(string: string) {
                profileAccountView.avatarURL = url
            }else{
                profileAccountView.avatarURL = nil
            }
            
            if UserAccountManager.shared.isFacebookConnected {
                dataSource.removeSection(.facebook)
            }
            else {
                dataSource.addSection(.facebook, rows: [])
            }
            
            dataSource.addSection(.logout, rows: [.logout])
        }
        else {
            dataSource.removeSection(.facebook)
            dataSource.removeSection(.logout)
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
    
    // MARK: Facebook
    
    @objc private func facebookLoginAction(_ button: FacebookButton) {
        // TODO: analytics
        
        button.isLoading = true
        button.isUserInteractionEnabled = false
        
        UserAccountManager.shared.loginWithFacebook()
            .then { result -> Void in
                self.syncLoggedIn()
            }
            .catch { error in
                let e = error as NSError

                if !UserAccountManager.shared.isIgnorableFacebookError(error: e) {
                    let alert = UserAccountManager.shared.alertViewForUndefinedError(error: e, viewController: self)
                    self.present(alert, animated: true)
                }
            }
            .always {
                button.isLoading = false
                button.isUserInteractionEnabled = true
        }
    }
    
    // MARK: Permissions
    
    private func createExclamationLabel() -> UILabel {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 18, height: 18))
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = .crazeRed
        label.text = "!"
        label.textAlignment = .center
        label.font = UIFont(name: "Optima-ExtraBlack", size: 14)
        label.textColor = .white
        label.layer.cornerRadius = label.bounds.height / 2
        label.layer.masksToBounds = true
        return label
    }
    
    private lazy var exclamationImage: UIImage = {
        let label = createExclamationLabel()
        let renderer = UIGraphicsImageRenderer(bounds: label.bounds)
        return renderer.image { rendererContext in
            label.layer.render(in: rendererContext.cgContext)
        }
    }()
}

extension ProfileViewController: ProfileAccountViewDelegate {
    func profileAccountViewAuthorize(_ view: ProfileAccountView) {
        let vc = RegisterViewController.init()
        vc.isOnboardingLayout = false
        vc.delegate = self
        let navVC = UINavigationController.init(rootViewController: vc)
        navVC.isNavigationBarHidden = true
        self.present(navVC, animated: true, completion: nil)
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

extension ProfileViewController : RegisterViewControllerDelegate, ConfirmCodeViewControllerDelegate {
    func confirmCodeViewControllerDidConfirm(_ viewController: ConfirmCodeViewController) {
        self.dismiss(animated: true, completion: nil)
        self.didLogin()
    }
    
    func confirmCodeViewControllerDidCancel(_ viewController: ConfirmCodeViewController) {
        viewController.navigationController?.popViewController(animated: true)
    }
    
    func registerViewControllerDidSkip(_ viewController: RegisterViewController) {
        self.dismiss(animated: true, completion: nil)
    }
    func registerViewControllerDidCreateAccount(_ viewController: RegisterViewController){
        self.dismiss(animated: true, completion: nil)
        self.didLogin()

    }
    
    func didLogin(){
        self.syncLoggedIn()
    }
    
    func registerViewControllerDidSignin(_ viewController: RegisterViewController) {
        self.dismiss(animated: true, completion: nil)
        self.didLogin()
    }
    
    func registerViewControllerDidFacebookLogin(_ viewController: RegisterViewController) {
        self.dismiss(animated: true, completion: nil)
        self.didLogin()
    }
    
    func registerViewControllerDidFacebookSignup(_ viewController: RegisterViewController) {
        self.dismiss(animated: true, completion: nil)
        self.didLogin()
    }
}

// MARK: - Table View

extension ProfileViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.rows(section)?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if let s = dataSource.section(section) {
            switch s {
            case .account:
                if profileAccountView.isExpanded {
                    return profileAccountView.maxHeight
                }
                else {
                    return profileAccountView.minHeight
                }
            case .invite:
                return inviteView.bounds.height
            case .facebook:
                return facebookView.bounds.height
            case let _section:
                if sectionText(for: _section) != nil {
                    return tableView.sectionHeaderHeight
                }
            }
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let s = dataSource.section(section) {
            switch s {
            case .account:
                return profileAccountView
            case .invite:
                return inviteView
            case .facebook:
                return facebookView
            default:
                break
            }
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let tableViewHeaderFooterView = view as? UITableViewHeaderFooterView else {
            return
        }
        
        tableViewHeaderFooterView.textLabel?.textColor = .gray3
        tableViewHeaderFooterView.textLabel?.font = .screenshopFont(.quicksandMedium, textStyle: .subheadline)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let s = dataSource.section(section) else {
            return nil
        }
        return sectionText(for: s)
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let row = dataSource.row(indexPath) else {
            return UITableViewCell()
        }
        
        let cell: UITableViewCell
        
        if dataSource.section(indexPath.section) == Section.logout {
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
            cell.textLabel?.font = .preferredFont(forTextStyle: .body)
            cell.textLabel?.textColor = .gray4
            
            cell.detailTextLabel?.font = .preferredFont(forTextStyle: .body, symbolicTraits: .traitBold)
            cell.detailTextLabel?.textColor = .gray3
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
        guard let row = dataSource.row(indexPath) else {
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
        guard let row = dataSource.row(indexPath) else {
            return
        }
        
        switch (row) {
        case .optionCurrency:
            let viewController = CurrencyViewController()
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
                    tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                    tableView.deselectRow(at: indexPath, animated: true)
                }))
            })
            alert.addAction(UIAlertAction(title: "generic.cancel".localized, style: .cancel, handler: { alertAction in
                tableView.deselectRow(at: indexPath, animated: true)
            }))
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
            
        case .permissionGDRP:
            navigationController?.pushViewController(GDPRViewController(), animated: true)
            
        case .logout:
            UserAccountManager.shared.logout().then(on: .main, execute: { () -> () in
                self.syncLoggedIn()
            })
        }
    }
    
    private func sectionText(for section: Section) -> String? {
        switch section {
        case .permissions:
            return "profile.section.permission".localized
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
            return "profile.row.push_permission.title".localized
        case .permissionPhoto:
            return "profile.row.photo_permission.title".localized
        case .permissionGDRP:
            return "profile.row.gdpr.title".localized
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
        default:
            return nil
        }
    }
    
    private func cellDetailedAttributedText(for row: Row) -> NSAttributedString? {
        switch (row) {
        case .permissionPhoto, .permissionPush:
            guard let permissionType = row.permissionType else {
                return nil
            }
            
            let string: String
            let attributes: [NSAttributedStringKey: Any]
            
            if PermissionsManager.shared.hasPermission(for: permissionType) {
                string = "generic.enabled".localized
                attributes = [
                    NSAttributedStringKey.foregroundColor: UIColor.crazeGreen
                ]
            }
            else {
                string = "generic.disabled".localized
                attributes = [
                    NSAttributedStringKey.foregroundColor: UIColor.gray7
                ]
            }
            
            return NSAttributedString(string: string, attributes: attributes)
            
        case .permissionGDRP:
            if !UserDefaults.standard.bool(forKey: UserDefaultsKeys.gdpr_agreedToEmail) ||
                !UserDefaults.standard.bool(forKey: UserDefaultsKeys.gdpr_agreedToImageDetection)
            {
                let textAttachment = NSTextAttachment()
                textAttachment.image = exclamationImage
                return NSAttributedString(attachment: textAttachment)
            }
            else {
                return nil
            }
            
        default:
            return nil
        }
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
        case .optionCurrency, .permissionGDRP:
            return .disclosureIndicator
        default:
            return .none
        }
    }
    
    private func cellAccessoryView(for row: Row) -> UIView? {
        switch (row) {
        case .permissionPhoto, .permissionPush:
            if let permissionType = row.permissionType, !PermissionsManager.shared.hasPermission(for: permissionType) {
                let label = createExclamationLabel()
                
                var viewFrame = label.frame
                viewFrame.size.width += 8 // offset
                let view = UIView(frame: viewFrame)
                
                view.addSubview(label)
                label.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
                label.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
                label.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
                label.widthAnchor.constraint(equalTo: label.heightAnchor).isActive = true
                
                return view
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
            if let indexPath = dataSource.indexPath(row: row, section: section) {
                indexPaths.append(indexPath)
            }
        }
        
        var indexPaths: [IndexPath] = []
        append(section: .options, row: .optionCurrency, to: &indexPaths)
        append(section: .permissions, row: .permissionPhoto, to: &indexPaths)
        append(section: .permissions, row: .permissionPush, to: &indexPaths)
        
        let selectedIndexPath = indexPaths.first { indexPath -> Bool in
            return tableView.indexPathsForSelectedRows?.contains(indexPath) ?? false
        }
        
        tableView.reloadRows(at: indexPaths, with: .none)
        
        if let selectedIndexPath = selectedIndexPath {
            tableView.selectRow(at: selectedIndexPath, animated: false, scrollPosition: .none)
        }
    }
}
