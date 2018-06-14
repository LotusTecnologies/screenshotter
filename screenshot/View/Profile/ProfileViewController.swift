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
        case activity
        case logout
    }
    
    enum Row: Int {
        case currency
        case tutorial
        case logout
    }
    
    private var data: [Section: [Row]] = [
        .account: [],
        .invite: [],
        .options: [
            .currency
        ],
        .activity: [
            .tutorial
        ]
    ]
    
    private let profileAccountView = ProfileAccountView()
    
    private let inviteView: UIView = {
        let view = UIView()
        view.layoutMargins = UIEdgeInsets(top: 0, left: .padding, bottom: 0, right: .padding)
        
        let button = MainButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setBackgroundImage(UIImage(named: "BrandGradientControl"), for: .normal)
        button.setTitle("Tell a Friend!", for: .normal)
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
        let isLoggedIn = true // TODO:
        
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
            profileAccountView.isLoggedIn = true
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
            
        case .tutorial:
            let viewController = TutorialVideoViewController()
            viewController.showsReplayButtonUponFinishing = false
            viewController.delegate = self
            viewController.modalTransitionStyle = .crossDissolve
            present(viewController, animated: true)
            
        case .logout:
            break
        }
    }
    
    private func cellText(for row: Row) -> String? {
        switch (row) {
        case .currency:
            return "settings.row.currency.title".localized
        case .logout:
            return "Logout"
        case .tutorial:
            return "settings.row.tutorial.title".localized
        }
    }
    
    private func cellDetailedText(for row: Row) -> String? {
        switch (row) {
        case .currency:
            return CurrencyViewController.currentCurrency
        default:
            return nil
        }
    }
    
    private func cellDetailedAttributedText(for row: Row) -> NSAttributedString? {
        switch (row) {
        case .tutorial:
            let textAttachment = NSTextAttachment()
            textAttachment.image = UIImage(named: "ProfilePlayVideo")
            return NSAttributedString(attachment: textAttachment)
            
        default:
            return nil
        }
    }
    
    private func cellAccessoryType(for row: Row) -> UITableViewCellAccessoryType {
        switch row {
        case .currency, .tutorial:
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
