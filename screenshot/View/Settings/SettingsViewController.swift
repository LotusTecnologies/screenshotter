//
//  SettingsViewController.swift
//  screenshot
//
//  Created by Corey Werner on 12/7/17.
//  Copyright © 2017 crazeapp. All rights reserved.
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
        case info
        case permission
        case product
        case follow
        case about
    }
    
    fileprivate enum Row : Int {
        case photoPermission
        case pushPermission
        case email
        case name
        case tutorialVideo
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
        case partners
        case restoreInAppPurchase
        case talkToStylist
        case openIn
        case region
        case payment
        case address
    }
    
    weak var delegate: SettingsViewControllerDelegate?
    
    fileprivate let tableView = UITableView(frame: .zero, style: .grouped)
    fileprivate let tableFooterTextView = UITextView()
    
    fileprivate var nameTextField: UITextField?
    fileprivate var emailTextField: UITextField?
    fileprivate var isRestoring = false
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
        
        self.restorationIdentifier = String(describing: type(of: self))
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive(_:)), name: .UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground(_:)), name: .UIApplicationWillEnterForeground, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadChangeableIndexPaths), name: .InAppPurchaseManagerDidUpdate, object: nil)

        addNavigationItemLogo()
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        dismissKeyboard()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // Very important to clear the controls to prevent retaining
        // the same property in multiple cells. Not doing this will
        // freeze the app on subsequent view will appears.
        productsOptionsControls.genderControl = nil
        productsOptionsControls.sizeControl = nil
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
        .info: [
            .name,
            .email,
            .payment,
            .address,
            .currency
        ],
        .about: [
            .tutorialVideo,
            .contactUs,
            .bug,
            .restoreInAppPurchase,
            .talkToStylist,
            .usageStreak,
            .coins,
            .region,
            .version,
            .partners
        ],
        .follow: [
            .followInstagram,
            .followFacebook
        ],
        .product: [
            .productGender,
            .productSize,
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
    
    // MARK: Product Options
    
    @objc fileprivate func genderControlAction(_ control: UISegmentedControl) {
        let gender = ProductsOptionsGender(offsetValue: control.selectedSegmentIndex)
        let integer = gender.rawValue
        Analytics.trackSetGlobalGenderFiler(gender: gender.stringValue)
        UserDefaults.standard.set(integer, forKey: UserDefaultsKeys.productGender)
    }
    
    @objc fileprivate func sizeControlAction(_ control: UISegmentedControl) {
        let size = ProductsOptionsSize(offsetValue: control.selectedSegmentIndex)
        let integer = size.rawValue
        
        Analytics.trackSetGlobalSizeFiler(size: size.stringValue)
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
        tableViewHeaderFooterView.textLabel?.font = .screenshopFont(.dinCondensedBold, textStyle: .title3)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let row = settingsRow(for: indexPath) else {
            return UITableViewCell()
        }
        
        var cell: UITableViewCell
        
        if indexPath.section == Section.info.rawValue && (row == .name || row == .email) {
            cell = self.tableView(tableView, inputCellForRowAt: indexPath, withRow: row)
            
        } else {
            cell = self.tableView(tableView, defaultCellForRowAt: indexPath, withRow: row)
        }
        
        cell.accessoryType = cellAccessoryType(for: row)
        cell.accessoryView = cellAccessoryView(for: row)
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let row = settingsRow(for: indexPath) else {
            return
        }
        
        if indexPath.section == Section.product.rawValue &&
            (row == .productGender || row == .productSize),
            let genderControl = productsOptionsControls.genderControl,
            let sizeControl = productsOptionsControls.sizeControl,
            let width = [genderControl.bounds.width, sizeControl.bounds.width].max()
        {
            var frame = genderControl.frame
            frame.size.width = width
            genderControl.frame = frame
            
            frame = sizeControl.frame
            frame.size.width = width
            sizeControl.frame = frame
        }
    }
    
    private func tableView(_ tableView: UITableView, inputCellForRowAt indexPath: IndexPath, withRow row: Row) -> UITableViewCell {
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
    
    private func tableView(_ tableView: UITableView, defaultCellForRowAt indexPath: IndexPath, withRow row: Row) -> UITableViewCell {
        let reusableCell = tableView.dequeueReusableCell(withIdentifier: "cell")
        let cell = reusableCell ?? UITableViewCell(style: .value1, reuseIdentifier: "cell")
        
        cell.imageView?.image = cellImage(for: row)
        cell.textLabel?.text = cellText(for: row)
        cell.textLabel?.font = .screenshopFont(.hindLight, textStyle: .body)
        
        if (row == .restoreInAppPurchase && self.isRestoring) ||
            (row == .talkToStylist && InAppPurchaseManager.sharedInstance.isInProcessOfBuying()) {
            cell.textLabel?.textColor = .gray
        }
        else {
            cell.textLabel?.textColor = .black
        }
        
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
}

extension SettingsViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        guard let row = settingsRow(for: indexPath) else {
            return true
        }
        
        switch (row) {
        case .version, .name, .email, .productGender, .productSize, .usageStreak:
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
            presentMailComposer()
            
        case .tutorialVideo:
            let viewController = TutorialVideoViewController()
            viewController.showsReplayButtonUponFinishing = false
            viewController.delegate = self
            viewController.modalTransitionStyle = .crossDissolve
            present(viewController, animated: true, completion: nil)
        
        case .contactUs:
            IntercomHelper.sharedInstance.presentMessagingUI()
            
        case .coins:
            let navigationController = ModalNavigationController(rootViewController: GameViewController())
            present(navigationController, animated: true, completion: nil)
            
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
            
        case .partners:
            let viewController = PartnersViewController()
            viewController.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(viewController, animated: true)
            
        case .restoreInAppPurchase:
            if self.isRestoring == false {
                self.isRestoring = true
                tableView.reloadRows(at: [indexPath], with: .none)
                
                InAppPurchaseManager.sharedInstance.restoreInAppPurchases().then(on: .main, execute: { (array) -> Promise<Bool>  in
                    self.isRestoring = false
                    tableView.reloadRows(at: [indexPath], with: .none)
                    var message = "settings.in_app_purchase.restore".localized
                    
                    if array.isEmpty {
                        message = "settings.in_app_purchase.restore.none".localized
                    }
                    
                    let alert = UIAlertController.init(title: nil, message: message, preferredStyle: .alert)
                    alert.addAction(UIAlertAction.init(title: "generic.ok".localized, style: .default, handler: nil))
                    
                    if (self.isViewLoaded && self.view.window != nil) {
                        self.present(alert, animated: true, completion: nil)
                    }
                    return Promise(value: true)
                    
                }).catch(on: .main, execute: { (error) in
                    self.isRestoring = false
                    tableView.reloadRows(at: [indexPath], with: .none)
                })
            }
            
        case .talkToStylist:
            if InAppPurchaseManager.sharedInstance.isInProcessOfBuying() {
                // do nothing
            } else if InAppPurchaseManager.sharedInstance.didPurchase(_inAppPurchaseProduct: .personalStylist) {
                IntercomHelper.sharedInstance.presentMessagingUI()
            } else {
                if InAppPurchaseManager.sharedInstance.canPurchase() {
                    let alertController = UIAlertController.init(title: nil, message: "personal_stylist.loading".localized, preferredStyle: .alert)
                    
                    let action = UIAlertAction.init(title: "generic.continue".localized, style: .default, handler: { (action) in
                        if let product = InAppPurchaseManager.sharedInstance.productIfAvailable(product: .personalStylist) {
                            InAppPurchaseManager.sharedInstance.buy(product: product, success: {
//                                IntercomHelper.sharedInstance.presentMessagingUI()
                                //If on the page the user will see cell change to 'talk to your stylist' with the lock.  If not on the page it can be jarring
                            }, failure: { (error) in
                                //no reason to present alert - Apple does it for us
                            })
                        }
                    })
                    
                    if let product = InAppPurchaseManager.sharedInstance.productIfAvailable(product: .personalStylist) {
                        action.isEnabled = true
                        alertController.message = String.init(format: "personal_stylist.unlock".localized, product.localizedPriceString())
                    } else {
                        action.isEnabled = false
                        InAppPurchaseManager.sharedInstance.load(product: .personalStylist, success: { (product) in
                            action.isEnabled = true
                            alertController.message = String.init(format: "personal_stylist.unlock".localized, product.localizedPriceString())
                        }, failure: { (error) in
                            alertController.message = String.init(format: "personal_stylist.error".localized, error.localizedDescription)
                        })
                    }
                    
                    alertController.addAction(action)
                    alertController.addAction(UIAlertAction.init(title: "generic.cancel".localized, style: .cancel, handler: nil))
                    alertController.preferredAction = action
                    self.present(alertController, animated: true, completion: nil)
                    
                }else{
                    let errorMessage = "personal_stylist.error.invalid_device".localized
                    let alertController = UIAlertController.init(title: nil, message: errorMessage, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction.init(title: "generic.ok".localized, style: .cancel, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                }
            }
 
        case .region:
            let alert = UIAlertController.init(title: nil, message: nil, preferredStyle: .actionSheet)
            
            alert.addAction(UIAlertAction(title: "settings.region.us".localized, style: .default, handler: { (alertAction) in
                UserDefaults.standard.set(true, forKey: UserDefaultsKeys.isUSC)
                tableView.reloadRows(at: [indexPath], with: .none)
            }))
            alert.addAction(UIAlertAction(title: "settings.region.other".localized, style: .default, handler: { (alertAction) in
                UserDefaults.standard.set(false, forKey: UserDefaultsKeys.isUSC)
                tableView.reloadRows(at: [indexPath], with: .none)
            }))

            alert.addAction(UIAlertAction(title: "generic.cancel".localized, style: .cancel, handler: nil))
            
            present(alert, animated: true, completion: nil)
            
        case .address:
            let viewController = CheckoutShippingListViewController()
            viewController.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(viewController, animated: true)
            
        case .payment:
            let viewController = CheckoutPaymentListViewController()
            viewController.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(viewController, animated: true)
            
        default:
            break
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
        case .info:
            return "settings.section.info".localized
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
        case .openIn:
            return "settings.row.open_in.title".localized
        case .currency:
            return "settings.row.currency.title".localized
        case .followInstagram:
            return "settings.row.instagram.title".localized
        case .followFacebook:
            return "settings.row.facebook.title".localized
        case .partners:
            return "settings.row.partners.title".localized
        case .restoreInAppPurchase:
            return "settings.row.restore_in_app_purchase.title".localized
        case .talkToStylist:
            return "settings.row.talk_to_stylist.title".localized
        case .region:
            return "settings.row.region.title".localized
        case .payment:
            return "settings.row.payment.title".localized
        case .address:
            return "settings.row.address.title".localized
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
        case .name:
            return "settings.row.name.detail".localized
        case .email:
            return "settings.row.email.detail".localized
        case .coins:
            return "\(UserDefaults.standard.integer(forKey: UserDefaultsKeys.gameScore))"
        case .currency:
            return CurrencyViewController.currentCurrency
        case .talkToStylist:
            if InAppPurchaseManager.sharedInstance.isInProcessOfBuying() || InAppPurchaseManager.sharedInstance.didPurchase(_inAppPurchaseProduct: .personalStylist) {
                return nil
            }
            else {
                return "🔒"
            }
        case .region:
            if UserDefaults.standard.object(forKey: UserDefaultsKeys.isUSC) == nil {
                return "settings.region.unknown".localized
            } else {
                if UserDefaults.standard.bool(forKey: UserDefaultsKeys.isUSC) {
                    return "settings.region.us".localized
                } else {
                    return "settings.region.other".localized
                }
            }
            
        default:
            return nil
        }
    }
    
    func cellDetailedAttributedText(for row: Row) -> NSAttributedString? {
        switch (row) {
        case .address:
            let textAttachment = NSTextAttachment()
            textAttachment.image = UIImage(named: "SettingsTruck")
            return NSAttributedString(attachment: textAttachment)
            
        case .payment:
            let textAttachment = NSTextAttachment()
            textAttachment.image = UIImage(named: "SettingsCreditCard")
            return NSAttributedString(attachment: textAttachment)
            
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
        case .currency, .partners, .address, .payment:
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
            
        case .productGender:
            let integer = UserDefaults.standard.integer(forKey: UserDefaultsKeys.productGender)
            let control: UISegmentedControl
            
            if productsOptionsControls.genderControl != nil {
                control = productsOptionsControls.genderControl!
                
            } else {
                control = productsOptionsControls.createGenderControl()
                control.tintColor = .crazeGreen
                control.isExclusiveTouch = true
                control.addTarget(self, action: #selector(genderControlAction(_:)), for: .valueChanged)
            }
            
            control.selectedSegmentIndex = ProductsOptionsGender(intValue: integer).offsetValue
            productsOptionsControls.sync()
            
            return control
            
        case .productSize:
            let integer = UserDefaults.standard.integer(forKey: UserDefaultsKeys.productSize)
            let control: UISegmentedControl
            
            if productsOptionsControls.sizeControl != nil {
                control = productsOptionsControls.sizeControl!
                
            } else {
                control = productsOptionsControls.createSizeControl()
                control.tintColor = .crazeGreen
                control.isExclusiveTouch = true
                control.addTarget(self, action: #selector(sizeControlAction(_:)), for: .valueChanged)
            }
            
            control.selectedSegmentIndex = ProductsOptionsSize(intValue: integer).offsetValue
            productsOptionsControls.sync()
            return control
            
        case .restoreInAppPurchase:
            if isRestoring {
                let activityView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
                activityView.startAnimating()
                return activityView
            }
            else {
                return nil
            }
            
        case .talkToStylist:
            if InAppPurchaseManager.sharedInstance.isInProcessOfBuying() {
                let activityView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
                activityView.startAnimating()
                return activityView
            }
            else {
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
        append(section: .about, row: .coins, to: &indexPaths)
        append(section: .about, row: .talkToStylist, to: &indexPaths)
        append(section: .about, row: .restoreInAppPurchase, to: &indexPaths)

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
                self.previousTexts[key] = trimmedText
                textField.text = trimmedText
                
                UserDefaults.standard.set(trimmedText, forKey: key)
                UserDefaults.standard.synchronize()
                
                reidentify()
                
            } else {
                textField.text = self.previousTexts[key]
            }
        }
    }
    
    fileprivate func userDefaultsKey(for textField: UITextField) -> String? {
        if textField == self.emailTextField {
            return UserDefaultsKeys.email
            
        } else if textField == self.nameTextField {
            return UserDefaultsKeys.name
        }
        
        return nil
    }
    
    fileprivate func reidentify() {
        let name = nameTextField?.text?.trimmingCharacters(in: .whitespaces)
        let email = emailTextField?.text?.trimmingCharacters(in: .whitespaces)
        let user = AnalyticsUser(name: name, email: email)
        
        user.sendToServers()
        
    }
    
    fileprivate func dismissKeyboard() {
        tableView.endEditing(true)
    }
}

// MARK: - Tutorial

extension SettingsViewController : VideoDisplayingViewControllerDelegate {
    func videoDisplayingViewControllerDidTapDone(_ viewController: UIViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    func videoDisplayingViewControllerDidEnd(_ viewController: UIViewController) {
        dismiss(animated: true, completion: nil)
        Analytics.trackAutomaticallyExitedTutorialVideo()
    }
}

// MARK: - Mail

extension SettingsViewController : MFMailComposeViewControllerDelegate {
  
    
    func presentMailComposer() {
        let message = [
            "\n\n\n",
            "-----------------",
            "Don't edit below.\n",
            "version: \(Bundle.displayVersionBuild)"
        ].joined(separator: "\n")
        let gmailMessage = "(Don't edit) version: \(Bundle.displayVersionBuild)"  //gmail has a bug that it won't respect new line charactors in a URL
        let subject = "Bug Report"
        let recipient = "support@screenshopit.com"
        
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
