//
//  GDPRViewController.swift
//  screenshot
//
//  Created by Corey Werner on 6/13/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class GDPRViewController: BaseTableViewController {
    enum Rows: Int {
        case notification
        case imageDetection
    }
    var agreedToNotification = UserDefaults.standard.bool(forKey: UserDefaultsKeys.gdpr_agreedToNotification)
    var agreedToImageDetection = UserDefaults.standard.bool(forKey: UserDefaultsKeys.gdpr_agreedToImageDetection)

    override init(style: UITableViewStyle) {
        super.init(style: style)
        
        title = "gdpr.title".localized
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground(_:)), name: .UIApplicationWillEnterForeground, object: nil)
    }
    
    convenience init() {
        self.init(style: .grouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.backgroundColor = .background
        tableView.estimatedRowHeight = 200
        tableView.allowsMultipleSelection = true
        tableView.register(TextExplanationTableViewCell.self, forCellReuseIdentifier: "cell")
    }
    
    @objc private func applicationWillEnterForeground(_ notification: Notification) {
        if view.window != nil {
            syncGDPRWithSettings()
        }
    }
    
    // MARK: GDPR
    
    /// Insure the GDPR state is always in sync
    static func updateUserAccountGDPR() {
        let agreedToImageDetection = UserDefaults.standard.bool(forKey: UserDefaultsKeys.gdpr_agreedToImageDetection)
        let hasPushPermissions = PermissionsManager.shared.hasPermission(for: .push)
        UserDefaults.standard.set(hasPushPermissions, forKey: UserDefaultsKeys.gdpr_agreedToNotification)
        
        UserAccountManager.shared.setGDPR(agreedToEmail: hasPushPermissions, agreedToImageDetection: agreedToImageDetection)
    }
    
    private func updateUserAccountGDPR() {
        UserAccountManager.shared.setGDPR(agreedToEmail: self.agreedToNotification, agreedToImageDetection: self.agreedToImageDetection)
    }
    
    private func syncGDPRWithSettings() {
        let hasPushPermissions = PermissionsManager.shared.hasPermission(for: .push)
        
        if self.agreedToNotification != hasPushPermissions {
            self.agreedToNotification = hasPushPermissions
            updateUserAccountGDPR()
        }
        
        let indexPath = indexPathFor(.notification)
        let isIndexPathSelected = tableView.indexPathsForSelectedRows?.contains(indexPath) ?? false
        
        if hasPushPermissions != isIndexPathSelected {
            if isIndexPathSelected {
                tableView.deselectRow(at: indexPath, animated: true)
            }
            else {
                tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            }
        }
    }
}

typealias GDPRViewControllerTableView = GDPRViewController
extension GDPRViewControllerTableView {
    private func indexPathFor(_ row: GDPRViewController.Rows) -> IndexPath {
        return IndexPath(row: row.rawValue, section: 0)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? TextExplanationTableViewCell else {
            return UITableViewCell()
        }
        
        cell.hasSelectableAppearance = true
        
        if indexPath.row == GDPRViewController.Rows.notification.rawValue {
            cell.titleLabel.text = "gdpr.notification.title".localized
            cell.explanationLabel.text = "gdpr.notification.message".localized
        }
        else if indexPath.row == GDPRViewController.Rows.imageDetection.rawValue {
            cell.titleLabel.text = "gdpr.image.title".localized
            cell.explanationLabel.text = "gdpr.image.message".localized
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        var isSelected = true
        
        if indexPath.row == GDPRViewController.Rows.notification.rawValue {
            isSelected = self.agreedToNotification
        }
        else if indexPath.row == GDPRViewController.Rows.imageDetection.rawValue {
            isSelected = self.agreedToImageDetection
        }
        
        if isSelected {
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        }
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if indexPath.row == GDPRViewController.Rows.notification.rawValue {
            if PermissionsManager.shared.hasPermission(for: .push) {
                let alertController = PermissionsManager.shared.disableAlertController(for: .push) { opened in
                    print("||| opened? = \(opened)")
                }
                alertController?.addAction(UIAlertAction(title: "generic.cancel".localized, style: .cancel, handler: { action in
                    tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                }))
                
                if let alertController = alertController {
                    present(alertController, animated: true)
                }
                else {
                    fatalError("PermissionsManager is not supporting disableAlertController for .push")
                }
            }
            else {
                // This should not be possible if everything is synced correctly
                self.agreedToNotification = false
                updateUserAccountGDPR()
            }
        }
        else if indexPath.row == GDPRViewController.Rows.imageDetection.rawValue {
            self.agreedToImageDetection = false
            updateUserAccountGDPR()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == GDPRViewController.Rows.notification.rawValue {
            PermissionsManager.shared.requestPermission(for: .push, openSettingsIfNeeded: true) { granted in
                if granted {
                    self.agreedToNotification = true
                    self.updateUserAccountGDPR()
                }
            }
        }
        else if indexPath.row == GDPRViewController.Rows.imageDetection.rawValue {
            self.agreedToImageDetection = true
            updateUserAccountGDPR()
        }
    }
}
