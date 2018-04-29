//
//  CheckoutListViewController.swift
//  screenshot
//
//  Created by Corey Werner on 4/26/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class CheckoutListViewController: BaseViewController {
    fileprivate var isPoppingViewController = false
    
    // MARK: View
    
    let tableView = UITableView()
    let addButton = UIButton()
    
    override func loadView() {
        view = tableView
    }
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.separatorInset = .zero
        
        addButton.contentEdgeInsets = UIEdgeInsets(top: .padding, left: .padding, bottom: .padding, right: .padding)
        addButton.imageView?.contentMode = .scaleAspectFit
        addButton.setTitleColor(.gray3, for: .normal)
        addButton.setTitleColor(.black, for: .highlighted)
        addButton.adjustInsetsForImage(withPadding: 6)
        addButton.sizeToFit()
        tableView.tableFooterView = addButton
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Allow the sync to come from the FRC when popping
        if !isPoppingViewController {
            syncSelectedCell()
        }
        
        isPoppingViewController = false
    }
    
    // MARK: Selection
    
    fileprivate func syncSelectedCell() {
        if let indexPath = indexPathForSelectedCell() {
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        }
    }
    
    func indexPathForSelectedCell() -> IndexPath? {
        fatalError("indexPathForSelectedCell() has not been implemented")
    }
}

extension CheckoutListViewController: CheckoutFormViewControllerDelegate {
    func checkoutFormViewControllerDidAdd(_ viewController: CheckoutFormViewController) {
        isPoppingViewController = true
        navigationController?.popViewController(animated: true)
    }
    
    func checkoutFormViewControllerDidEdit(_ viewController: CheckoutFormViewController) {
        isPoppingViewController = true
        navigationController?.popViewController(animated: true)
    }
    
    func checkoutFormViewControllerDidRemove(_ viewController: CheckoutFormViewController) {
        isPoppingViewController = true
        navigationController?.popViewController(animated: true)
    }
}

extension CheckoutListViewController: FetchedResultsControllerManagerDelegate {
    func managerDidChangeContent(_ controller: NSObject, change: FetchedResultsControllerManagerChange) {
        if isViewLoaded {
            change.applyChanges(tableView: tableView)
            syncSelectedCell()
        }
    }
}
