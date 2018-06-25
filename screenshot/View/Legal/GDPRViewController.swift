//
//  GDPRViewController.swift
//  screenshot
//
//  Created by Corey Werner on 6/13/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class GDPRViewController: UITableViewController {
    enum Rows: Int {
        case notification
        case imageDetection
    }
    var agreedToEmail = UserDefaults.standard.bool(forKey: UserDefaultsKeys.gdpr_agreedToEmail)
    var agreedToImageDetection = UserDefaults.standard.bool(forKey: UserDefaultsKeys.gdpr_agreedToImageDetection)

    override init(style: UITableViewStyle) {
        super.init(style: style)
        
        title = "gdpr.title".localized
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
}

typealias GDPRViewControllerTableView = GDPRViewController
extension GDPRViewControllerTableView {
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
            isSelected = self.agreedToEmail
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
            self.agreedToEmail = false
        }
        else if indexPath.row == GDPRViewController.Rows.imageDetection.rawValue {
            self.agreedToImageDetection = false
        }
        UserAccountManager.shared.setGDPR(agreedToEmail: self.agreedToEmail, agreedToImageDetection: self.agreedToImageDetection)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == GDPRViewController.Rows.notification.rawValue {
            self.agreedToEmail = true
        }
        else if indexPath.row == GDPRViewController.Rows.imageDetection.rawValue {
            self.agreedToImageDetection = true
        }
        UserAccountManager.shared.setGDPR(agreedToEmail: self.agreedToEmail, agreedToImageDetection: self.agreedToImageDetection)
    }
}
