//
//  CheckoutOrderViewController.swift
//  screenshot
//
//  Created by Corey Werner on 4/9/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class CheckoutOrderViewController: BaseViewController {
    var cvv: String?
    var confirmPaymentViewController: CheckoutConfirmPaymentViewController?
    
    // MARK: View
    
    fileprivate var _view: CheckoutOrderView {
        return view as! CheckoutOrderView
    }
    
    fileprivate var tableView: UITableView {
        return _view.tableView
    }
    
    override func loadView() {
        view = CheckoutOrderView()
    }
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        title = "Place Your Order"
        restorationIdentifier = String(describing: type(of: self))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        _view.nameLabel.text = "Corey Werner"
        _view.addressLabel.text = "326 N. Blaine Ave, Santa Rosa, CA  80002"
        _view.cardLabel.text = "Visa ending in …4568"
        _view.itemsPriceLabel.text = "$117"
        _view.shippingPriceLabel.text = "$8.42"
        _view.beforeTaxPriceLabel.text = "$125.42"
        _view.estimateTaxLabel.text = "6%"
        _view.totalPriceLabel.text = "$134.62"
        
        _view.paymentControl.addTarget(self, action: #selector(navigateToPaymentList), for: .touchUpInside)
        _view.shippingControl.addTarget(self, action: #selector(navigateToShippingList), for: .touchUpInside)
        _view.orderButton.addTarget(self, action: #selector(orderAction), for: .touchUpInside)
        _view.cancelButton.addTarget(self, action: #selector(cancelAction), for: .touchUpInside)
        
        // TODO: remove the tableview since its not being used for it reuse functionality. insert normal views
        tableView.dataSource = self
        tableView.register(CheckoutOrderItemTableViewCell.self, forCellReuseIdentifier: "cell")
    }
    
    deinit {
        tableView.dataSource = nil
    }
    
    // MARK: Navigation
    
    @objc fileprivate func navigateToPaymentList() {
        let paymentListViewController = CheckoutPaymentListViewController()
        navigationController?.pushViewController(paymentListViewController, animated: true)
    }
    
    @objc fileprivate func navigateToShippingList() {
        let shippingListViewController = CheckoutShippingListViewController()
        navigationController?.pushViewController(shippingListViewController, animated: true)
    }
    
    // MARK: Order
    
    @objc fileprivate func orderAction() {
        if let cvv = cvv {
            _view.orderButton.isLoading = true
            _view.orderButton.isEnabled = false
            
            // TODO: make model request to validate card and place order.
            func pseudoValidateOrder(_ callback: @escaping (Bool)->()) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    callback(true)
                }
            }
            
            pseudoValidateOrder { [weak self] isValid in
                self?._view.orderButton.isLoading = false
                self?._view.orderButton.isEnabled = true
                
                if isValid {
                    self?.navigationController?.pushViewController(CheckoutConfirmationViewController(), animated: true)
                }
                else {
                    // TODO: display errors
                }
            }
        }
        else {
            let confirmPaymentViewController = CheckoutConfirmPaymentViewController()
            confirmPaymentViewController.orderButton.addTarget(self, action: #selector(confirmOrderAction), for: .touchUpInside)
            confirmPaymentViewController.cancelButton.addTarget(self, action: #selector(confirmCancelAction), for: .touchUpInside)
            present(confirmPaymentViewController, animated: true, completion: nil)
            self.confirmPaymentViewController = confirmPaymentViewController
        }
    }
    
    @objc fileprivate func cancelAction() {
        if tabBarController != nil {
            MainTabBarController.resetViewControllerHierarchy(self, select: .screenshots)
        }
        else {
            presentingViewController?.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc fileprivate func confirmOrderAction() {
        guard let cvv = confirmPaymentViewController?.cvvTextField.text, !cvv.isEmpty else {
            confirmPaymentViewController?.displayCVVError()
            return
        }
        
        confirmPaymentViewController?.orderButton.isLoading = true
        confirmPaymentViewController?.orderButton.isEnabled = false
        
        // TODO: make model request to validate card and place order.
        func pseudoValidateOrder(_ callback: @escaping (Bool)->()) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                callback(true)
            }
        }
        
        pseudoValidateOrder { [weak self] isValid in
            self?.confirmPaymentViewController?.orderButton.isLoading = false
            self?.confirmPaymentViewController?.orderButton.isEnabled = true
            
            if isValid {
                self?.dismiss(animated: true, completion: nil)
                self?.confirmPaymentViewController = nil
                self?.navigationController?.pushViewController(CheckoutConfirmationViewController(), animated: true)
            }
            else {
                // TODO: display errors
//                confirmPaymentViewController?.displayCVVError()
            }
        }
    }
    
    @objc fileprivate func confirmCancelAction() {
        dismiss(animated: true, completion: nil)
    }
}

extension CheckoutOrderViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        if let cell = cell as? CheckoutOrderItemTableViewCell {
            cell.titleLabel.text = "Huchie PuffySleeve Gold Edition"
            cell.detailLabel.text = "Qty: 1, Color: Brown, Size: Med"
        }
        
        return cell
    }
}
