//
//  FormViewController.swift
//  screenshot
//
//  Created by Corey Werner on 3/26/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class FormViewController: BaseViewController {
    fileprivate let form: Form
    
    // MARK: View
    
    fileprivate var formView: FormView {
        return view as! FormView
    }
    
    fileprivate var tableView: UITableView {
        return formView.tableView
    }
    
    override func loadView() {
        view = FormView()
    }
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(with form: Form) {
        self.form = form
        
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(FormTextTableViewCell.self, forCellReuseIdentifier: String(describing: Form.Text.self))
        tableView.register(FormEmailTableViewCell.self, forCellReuseIdentifier: String(describing: Form.Email.self))
    }
    
    deinit {
        tableView.dataSource = nil
        tableView.delegate = nil
    }
}

extension FormViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return form.rows.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = form.rows[indexPath.row]
        let identifier = String(describing: type(of: row))
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        
        cell.selectionStyle = .none
        
        if let cell = cell as? FormTextTableViewCell {
            cell.textField.placeholder = row.placeholder
        }
        else {
            cell.textLabel?.text = row.placeholder
        }
        
//        switch row {
//        case is Form.Card:
//            break
//        case is Form.Date:
//            break
//        case is Form.Email:
//            break
//        case is Form.Number:
//            break
//        case is Form.Phone:
//            break
//        case is Form.Selection:
//            break
//        case is Form.Text:
//            break
//        default:
//            break
//        }
        
        return cell
    }
}

extension FormViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else {
            return
        }
        
        cell.becomeFirstResponder()
    }
}
