//
//  CheckoutConfirmPaymentViewController.swift
//  screenshot
//
//  Created by Corey Werner on 4/11/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class CheckoutConfirmPaymentViewController: UIViewController {
    let cvvTextField = UITextField()
    let orderButton = MainButton()
    let cancelButton = UIButton()
    
    fileprivate let cvvTextFieldController = TextFieldFormatter(with: .cvv)
    fileprivate let cvvBorderColor: UIColor = .gray3
    
    fileprivate let transitioning = ViewControllerTransitioningDelegate(presentation: .intrinsicContentSize, transition: .modal)
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        transitioningDelegate = transitioning
        modalPresentationStyle = .custom
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        let layoutGuide = UIView()
        layoutGuide.translatesAutoresizingMaskIntoConstraints = false
        layoutGuide.isHidden = true
        view.addSubview(layoutGuide)
        layoutGuide.topAnchor.constraint(equalTo: view.topAnchor, constant: .padding).isActive = true
        layoutGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: .padding).isActive = true
        layoutGuide.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -.padding).isActive = true
        layoutGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -.padding).isActive = true
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .gray3
        label.font = .screenshopFont(.hindMedium, textStyle: .title2, staticSize: true)
        label.adjustsFontForContentSizeCategory = true
        label.minimumScaleFactor = 0.7
        label.adjustsFontSizeToFitWidth = true
        label.text = "checkout.confirm.payment.enter_cvv".localized
        view.addSubview(label)
        label.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        label.setContentHuggingPriority(UILayoutPriority.required, for: .vertical)
        label.topAnchor.constraint(equalTo: layoutGuide.topAnchor).isActive = true
        label.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor).isActive = true
        label.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor).isActive = true
        
        cvvTextField.translatesAutoresizingMaskIntoConstraints = false
        cvvTextField.placeholder = "checkout.confirm.payment.cvv".localized
        cvvTextField.keyboardType = .numberPad
        cvvTextField.textAlignment = .center
        cvvTextField.font = .monospacedDigitSystemFont(ofSize: 20, weight: UIFont.Weight.medium)
        cvvTextField.textColor = .gray3
        cvvTextField.delegate = self
        cvvTextField.layer.borderColor = cvvBorderColor.cgColor
        cvvTextField.layer.borderWidth = 1
        cvvTextField.layer.cornerRadius = .defaultCornerRadius
        cvvTextField.layer.masksToBounds = true
        view.addSubview(cvvTextField)
        cvvTextField.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        cvvTextField.setContentHuggingPriority(UILayoutPriority.required, for: .vertical)
        cvvTextField.topAnchor.constraint(equalTo: label.bottomAnchor, constant: .padding).isActive = true
        cvvTextField.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor).isActive = true
        cvvTextField.trailingAnchor.constraint(equalTo: layoutGuide.centerXAnchor).isActive = true
        cvvTextField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        let whatButton = UIButton()
        whatButton.translatesAutoresizingMaskIntoConstraints = false
        whatButton.setTitle("checkout.confirm.payment.what".localized, for: .normal)
        whatButton.setTitleColor(.crazeGreen, for: .normal)
        whatButton.setTitleColor(UIColor.crazeGreen.darker(), for: .highlighted)
        whatButton.titleLabel?.font = .screenshopFont(.hindMedium, size: 14)
        whatButton.titleLabel?.minimumScaleFactor = 0.7
        whatButton.titleLabel?.adjustsFontSizeToFitWidth = true
        whatButton.titleLabel?.baselineAdjustment = .alignCenters
        whatButton.contentHorizontalAlignment = {
            if #available(iOS 11.0, *) {
                return .leading
            }
            else {
                return traitCollection.layoutDirection == .rightToLeft ? .right : .left
            }
        }()
        whatButton.contentEdgeInsets = UIEdgeInsets(top: .padding, left: .padding, bottom: .padding, right: .padding)
        whatButton.addTarget(self, action: #selector(presentCVVExplanation), for: .touchUpInside)
        view.addSubview(whatButton)
        whatButton.leadingAnchor.constraint(equalTo: cvvTextField.trailingAnchor).isActive = true
        whatButton.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        whatButton.centerYAnchor.constraint(equalTo: cvvTextField.centerYAnchor).isActive = true
        
        orderButton.translatesAutoresizingMaskIntoConstraints = false
        orderButton.backgroundColor = .crazeGreen
        orderButton.setTitle("checkout.order.title".localized, for: .normal)
        view.addSubview(orderButton)
        orderButton.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        orderButton.setContentHuggingPriority(UILayoutPriority.required, for: .vertical)
        orderButton.topAnchor.constraint(equalTo: cvvTextField.bottomAnchor, constant: .padding).isActive = true
        orderButton.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor).isActive = true
        orderButton.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor).isActive = true
        
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.setTitle("generic.cancel".localized, for: .normal)
        cancelButton.setTitleColor(.gray3, for: .normal)
        cancelButton.titleLabel?.font = .screenshopFont(.hindMedium, size: UIFont.buttonFontSize)
        cancelButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 0, bottom: 6, right: 0)
        view.addSubview(cancelButton)
        cancelButton.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        cancelButton.setContentHuggingPriority(UILayoutPriority.required, for: .vertical)
        cancelButton.topAnchor.constraint(equalTo: orderButton.bottomAnchor, constant: .padding).isActive = true
        cancelButton.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor).isActive = true
        cancelButton.bottomAnchor.constraint(equalTo: layoutGuide.bottomAnchor).isActive = true
        cancelButton.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor).isActive = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        cvvTextField.resignFirstResponder()
    }
    
    @objc fileprivate func presentCVVExplanation() {
        // TODO:
    }
    
    func displayCVVError() {
        cvvTextField.text = nil
        cvvTextField.layer.borderColor = UIColor.crazeRed.cgColor
        
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}

extension CheckoutConfirmPaymentViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if range.location == 0 && range.length == 0 {
            cvvTextField.layer.borderColor = cvvBorderColor.cgColor
        }
        
        return cvvTextFieldController.textField(textField, shouldChangeCharactersIn: range, replacementString: string)
    }
}
