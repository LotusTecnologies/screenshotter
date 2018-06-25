//
//  OnboardingGDPRViewController.swift
//  screenshot
//
//  Created by Corey Werner on 6/13/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

protocol OnboardingGDPRViewControllerDelegate: NSObjectProtocol {
    func onboardingGDPRViewControllerDidComplete(_ viewController: OnboardingGDPRViewController)
}

class OnboardingGDPRView: UIView {
    let tableView = UITableView(frame: .zero, style: .grouped)
    let editButton = BorderButton()
    let continueButton = MainButton()
    var editButtonHiddenConstraints:[NSLayoutConstraint] = []
    var editButtonShownConstraints:[NSLayoutConstraint] = []
    var editButtonHidden: Bool = false {
        didSet {
            if editButtonHidden {
                NSLayoutConstraint.deactivate(editButtonShownConstraints)
                NSLayoutConstraint.activate(editButtonHiddenConstraints)
            }else{
                NSLayoutConstraint.deactivate(editButtonHiddenConstraints)
                NSLayoutConstraint.activate(editButtonShownConstraints)

            }
        }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
        
        let headerImageView = UIImageView(image: UIImage(named: "BrandConfettiBackgroundSmall"))
        headerImageView.translatesAutoresizingMaskIntoConstraints = false
        headerImageView.contentMode = .scaleAspectFill
        headerImageView.layoutMargins = {
            var insets = UIEdgeInsets(top: .containerPaddingY, left: .containerPaddingX, bottom: .containerPaddingY, right: .containerPaddingX)
            if #available(iOS 11, *) {
                insets.top = 8
            }
            return insets
        }()
        addSubview(headerImageView)
        headerImageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        headerImageView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        headerImageView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        headerImageView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .screenshopFont(.quicksandMedium, size: 28)
        titleLabel.textColor = .gray2
        titleLabel.text = "gdpr.onboarding.title".localized
        titleLabel.textAlignment = .center
        titleLabel.minimumScaleFactor = 0.7
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.baselineAdjustment = .alignCenters
        headerImageView.addSubview(titleLabel)
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        titleLabel.topAnchor.constraint(equalTo: headerImageView.layoutMarginsGuide.topAnchor).isActive = true
        titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: headerImageView.layoutMarginsGuide.leadingAnchor).isActive = true
        titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: headerImageView.layoutMarginsGuide.trailingAnchor).isActive = true
        titleLabel.centerXAnchor.constraint(equalTo: headerImageView.layoutMarginsGuide.centerXAnchor).isActive = true
        
        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = .systemFont(ofSize: 16)
        subtitleLabel.textColor = .gray2
        subtitleLabel.text = "gdpr.onboarding.subtitle".localized
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 3
        headerImageView.addSubview(subtitleLabel)
        subtitleLabel.setContentHuggingPriority(.required, for: .vertical)
        subtitleLabel.topAnchor.constraint(equalTo: titleLabel.lastBaselineAnchor, constant: .padding).isActive = true
        subtitleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: headerImageView.layoutMarginsGuide.leadingAnchor).isActive = true
        subtitleLabel.lastBaselineAnchor.constraint(equalTo: headerImageView.layoutMarginsGuide.bottomAnchor).isActive = true
        subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: headerImageView.layoutMarginsGuide.trailingAnchor).isActive = true
        subtitleLabel.centerXAnchor.constraint(equalTo: headerImageView.layoutMarginsGuide.centerXAnchor).isActive = true
        
        headerImageView.addSubview(BorderView(edge: .bottom))
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .background
        tableView.estimatedRowHeight = 200
        addSubview(tableView)
        tableView.topAnchor.constraint(equalTo: headerImageView.bottomAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
        let footerView = UIView()
        footerView.translatesAutoresizingMaskIntoConstraints = false
        footerView.layoutMargins = UIEdgeInsets(top: .marginY, left: .marginX, bottom: .marginY, right: .marginX)
        addSubview(footerView)
        footerView.topAnchor.constraint(equalTo: tableView.bottomAnchor).isActive = true
        footerView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        footerView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        footerView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
        editButton.translatesAutoresizingMaskIntoConstraints = false
        editButton.setTitleColor(.crazeGreen, for: .normal)
        editButton.setTitle("gdpr.onboarding.edit".localized, for: .normal)
        footerView.addSubview(editButton)
        
        let top = editButton.topAnchor.constraint(equalTo: footerView.layoutMarginsGuide.topAnchor)
        self.editButtonShownConstraints.append(top)
        top.isActive = true
        let topNone = editButton.topAnchor.constraint(equalTo: footerView.topAnchor)
        self.editButtonHiddenConstraints.append(topNone)
        let noHeight = editButton.heightAnchor.constraint(equalToConstant: 0.0)
        self.editButtonHiddenConstraints.append(noHeight)
        
        editButton.leadingAnchor.constraint(equalTo: footerView.layoutMarginsGuide.leadingAnchor).isActive = true
        editButton.trailingAnchor.constraint(equalTo: footerView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.backgroundColor = .crazeGreen
        continueButton.setTitle("gdpr.onboarding.continue".localized, for: .normal)
        continueButton.setTitle("gdpr.onboarding.continue".localized, for: .highlighted)
        continueButton.setTitle("generic.continue".localized, for: .selected)
        continueButton.setTitle("generic.continue".localized, for: [.selected, .highlighted])

        footerView.addSubview(continueButton)
        continueButton.topAnchor.constraint(equalTo: editButton.bottomAnchor, constant: .padding).isActive = true
        continueButton.leadingAnchor.constraint(equalTo: footerView.layoutMarginsGuide.leadingAnchor).isActive = true
        continueButton.bottomAnchor.constraint(equalTo: footerView.layoutMarginsGuide.bottomAnchor).isActive = true
        continueButton.trailingAnchor.constraint(equalTo: footerView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        footerView.addSubview(BorderView(edge: .top))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class OnboardingGDPRViewController: UIViewController {
    
    weak var delegate:OnboardingGDPRViewControllerDelegate?
    var managingSettings = false
    var agreedToEmail = true
    var agreedToImageDetection = true

    var classForView: OnboardingGDPRView.Type {
        return OnboardingGDPRView.self
    }
    
    var _view: OnboardingGDPRView {
        return view as! OnboardingGDPRView
    }
    
    private var tableView: UITableView {
        return _view.tableView
    }
    
    var editButton: UIButton {
        return _view.editButton
    }
    
    var continueButton: UIButton {
        return _view.continueButton
    }
    
    override func loadView() {
        view = classForView.self.init()
    }
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(TextExplanationTableViewCell.self, forCellReuseIdentifier: "cell")
        
        editButton.addTarget(self, action: #selector(editAction), for: .touchUpInside)
        continueButton.isExclusiveTouch = true
        continueButton.addTarget(self, action: #selector(continueAction), for: .touchUpInside)

    }
    
    deinit {
        tableView.dataSource = nil
        tableView.delegate = nil
    }
    
    // MARK: Edit
    @objc private func editAction() {
        editButton.isHidden = true
        UIView.animate(withDuration: .defaultAnimationDuration) {
            self._view.editButtonHidden = true
            self.view.layoutIfNeeded()
        }
        managingSettings = true
        tableView.allowsSelection = true
        tableView.allowsMultipleSelection = true
        self.tableView.reloadData()
    }
    
    @objc private func continueAction() {
        Analytics.trackOnboardingGdpr(agreedToEmail: agreedToEmail, agreedToImageDetection: agreedToImageDetection)
        UserAccountManager.shared.setGDPR(agreedToEmail: agreedToEmail, agreedToImageDetection: agreedToImageDetection)
        
        print("agreedToEmail :\(agreedToEmail),agreedToImageDetection: \(agreedToImageDetection)" )
        self.delegate?.onboardingGDPRViewControllerDidComplete(self)
    }
}

extension OnboardingGDPRViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? TextExplanationTableViewCell else {
            return UITableViewCell()
        }
        
        cell.hasSelectableAppearance = self.managingSettings

        
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
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        var isSelected = true
        
        if indexPath.row == GDPRViewController.Rows.notification.rawValue {
            isSelected = agreedToEmail
        }
        else if indexPath.row == GDPRViewController.Rows.imageDetection.rawValue {
            isSelected = agreedToImageDetection
        }
        
        if isSelected {
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.managingSettings {
            if indexPath.row == GDPRViewController.Rows.notification.rawValue {
                agreedToEmail = true
            }
            else if indexPath.row == GDPRViewController.Rows.imageDetection.rawValue {
                agreedToImageDetection = true
            }
            self.continueButton.isSelected = (!agreedToEmail && !agreedToImageDetection)
        }
    }
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if self.managingSettings {
            if indexPath.row == GDPRViewController.Rows.notification.rawValue {
                agreedToEmail = false
            }
            else if indexPath.row == GDPRViewController.Rows.imageDetection.rawValue {
                agreedToImageDetection = false
            }
            
            self.continueButton.isSelected = (!agreedToEmail && !agreedToImageDetection)
        }
        
    }
}

extension OnboardingGDPRViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
}
