//
//  CheckoutConfirmPaymentViewController.swift
//  screenshot
//
//  Created by Corey Werner on 4/11/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class CheckoutConfirmPaymentViewController: UIViewController {
    fileprivate let cvvTextFieldController = TextFieldFormatter(with: .cvv)
    fileprivate let cvvBorderColor: UIColor = .gray3
    
    fileprivate let transitioning = ViewControllerTransitioningDelegate(presentation: .intrinsicContentSize, transition: .modal)
    
    // MARK: View
    
    let cvvTextField = UITextField()
    
    var orderButton: MainButton {
        return _view.continueButton
    }
    
    var cancelButton: UIButton {
        return _view.cancelButton
    }
    
    fileprivate var _view: AlertTemplate {
        return view as! AlertTemplate
    }
    
    override func loadView() {
        view = AlertTemplate()
    }
    
    // MARK: Life Cycle
    
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
        
        _view.titleLabel.text = "checkout.confirm.payment.enter_cvv".localized
        
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
//        cvvTextField.setContentCompressionResistancePriority(.required, for: .vertical)
//        cvvTextField.setContentHuggingPriority(.required, for: .vertical)
        cvvTextField.topAnchor.constraint(equalTo: _view.contentLayoutGuide.topAnchor).isActive = true
        cvvTextField.leadingAnchor.constraint(equalTo: _view.contentLayoutGuide.leadingAnchor).isActive = true
        cvvTextField.bottomAnchor.constraint(equalTo: _view.contentLayoutGuide.bottomAnchor).isActive = true
        cvvTextField.trailingAnchor.constraint(equalTo: _view.contentLayoutGuide.centerXAnchor).isActive = true
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
        
        _view.continueButton.setTitle("checkout.order.title".localized, for: .normal)
        _view.cancelButton.setTitle("generic.cancel".localized, for: .normal)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        cvvTextField.resignFirstResponder()
    }
    
    // MARK: Interaction
    
    @objc fileprivate func presentCVVExplanation() {
        Analytics.trackCartCvvWhatsThis()
        let webViewController = CheckoutWhatIsCVVWebViewController()
        let navigationController = ModalNavigationController(rootViewController: webViewController)
        navigationController.modalPresentationStyle = .custom // Very important for the presenting vc frame
        present(navigationController, animated: true, completion: nil)
    }
    
    func displayCVVError() {
        cvvTextField.text = nil
        cvvTextField.layer.borderColor = UIColor.crazeRed.cgColor
        
        ActionFeedbackGenerator().actionOccurred(.nope)
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
